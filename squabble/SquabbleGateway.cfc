<!---
   Copyright 2011 Ezra Parker, Josh Wines, Mark Mandel

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

	   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
--->

<cfcomponent hint="Squabble Gateway" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="SquabbleGateway" output="false">
	<cfscript>
		return this;
	</cfscript>
</cffunction>


<cffunction name="insertVisitor" hint="Inserts a visitor to the database when they come across a test" access="public" returntype="string" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test this visitor is being recorded for">
	<cfargument name="variationData" type="struct" required="true" hint="A data structure of the Sections and Variation this customer will see">
	<cfargument name="visitDate" type="date" required="false" default="#now()#" hint="First visit date/time of this visitor">

	<cfscript>
		var visitorID = createUUID();
		var section = "";

		var sections = structKeyArray(arguments.variationData);
		arraySort(sections, "text");
		var values = [];
		for(var section in sections)
		{
			ArrayAppend(values, arguments.variationData[section]);
		}
	</cfscript>

	<cftransaction>
		<!--- Insert Main Visitor Record --->
		<cfquery>
			INSERT INTO squabble_visitors (
				id,
				visit_date,
				test_name,
				flat_combination
			)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_char" value="#visitorID#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.visitDate#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">,
				<cfqueryparam value="#arrayToList(values)#" cfsqltype="cf_sql_varchar">
			)
		</cfquery>

		<!--- Insert Combination(s) this user has been allocated --->
		<cfloop collection="#arguments.variationData#" item="section">
			<cfquery>
				INSERT INTO squabble_combinations (
					id,
					visitor_id,
					section_name,
					variation_name
				)
				VALUES (
					<cfqueryparam cfsqltype="cf_sql_char" value="#createUUID()#" maxlength="35">,
					<cfqueryparam cfsqltype="cf_sql_char" value="#visitorID#" maxlength="35">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#section#">,
					<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.variationData[section]#">
				)
			</cfquery>
		</cfloop>
	</cftransaction>

	<cfreturn visitorID>
</cffunction>


<cffunction name="getVisitor" hint="Returns a visitor record from the database" access="public" returntype="query" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to return">
	<cfset var getVisitorQuery = "">

	<cfquery name="getVisitorQuery">
		SELECT id, visit_date, test_name, flat_combination
		FROM squabble_visitors
		WHERE id = <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
	</cfquery>

	<cfreturn getVisitorQuery>
</cffunction>


<cffunction name="getVisitorCombinations" hint="Returns a visitor query along with any combinations the visitor received" access="public" returntype="query" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to return combinations for">
	<cfset var getVisitorCombinationsQuery = "">

	<cfquery name="getVisitorCombinationsQuery">
		SELECT 	v.id AS visitor_id, v.visit_date, v.test_name,
				com.id AS combination_id, com.section_name, com.variation_name

		FROM 	squabble_visitors v

		JOIN 	squabble_combinations com
		ON 		com.visitor_id = v.id

		WHERE 	v.id = <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
	</cfquery>

	<cfreturn getVisitorCombinationsQuery>
</cffunction>


<cffunction name="insertConversion" hint="Records a conversion for a visitor" access="public" returntype="string" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="The visitor ID to record the conversion for">
	<cfargument name="name" type="string" required="true" hint="The name/type of this conversion">
	<cfargument name="value" type="string" required="false" default="" hint="The value to record for this conversion">
	<cfargument name="units" type="string" required="false" default="" hint="The unit value to record for this conversion">
	<cfargument name="conversionDate" type="date" required="false" default="#now()#" hint="The date the conversion happened">
	<cfset var conversionID = createUUID()>

	<cfquery>
		INSERT INTO squabble_conversions (
			id,
			visitor_id,
			conversion_date,
			conversion_name,
			conversion_value,
			conversion_units
		)
		VALUES (
			<cfqueryparam cfsqltype="cf_sql_char" value="#conversionID#" maxlength="35">,
			<cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">,
			<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.conversionDate#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.name#">,
			<cfqueryparam cfsqltype="cf_sql_double" value="#arguments.value#" null="#NOT isNumeric(arguments.value)#">,
			<cfqueryparam cfsqltype="cf_sql_double" value="#arguments.units#" null="#NOT isNumeric(arguments.units)#">
		)
	</cfquery>

	<cfreturn conversionID>
</cffunction>


<cffunction name="getVisitorConversions" hint="Returns a query of conversions for a given visitor" access="public" returntype="query" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to return conversions for">
	<cfset var getVisitorConversionsQuery = "">

	<cfquery name="getVisitorConversionsQuery">
		SELECT 	v.id AS visitor_id, v.visit_date, v.test_name,
				con.id AS conversion_id, con.conversion_date, con.conversion_name, con.conversion_value, con.conversion_units

		FROM 	squabble_visitors v

		JOIN 	squabble_conversions con
		ON 		con.visitor_id = v.id

		WHERE 	v.id = <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
	</cfquery>

	<cfreturn getVisitorConversionsQuery>
</cffunction>

<cffunction name="getVisitorTags" hint="get all, or some of the visitor tags" access="public" returntype="query" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to return tags for">
	<cfargument name="filter" hint="a string, list or array of tags specifically look for against the visitor" type="array" required="true">

	<cfquery name="local.tags">
		SELECT tag_value
		from
			squabble_visitor_tags
		WHERE
			squabble_visitor_tags.visitor_id = <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
			<cfif !arrayIsEmpty(arguments.filter)>
				AND
				squabble_visitor_tags.tag_value IN ( <cfqueryparam value="#ArrayToList(arguments.filter)#" cfsqltype="cf_sql_varchar" list="true" > )
			</cfif>
	</cfquery>

	<cfreturn local.tags />
</cffunction>

<cffunction name="insertVisitorTag" hint="insert a visitor tag" access="public" returntype="void" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to insert a tag for">
	<cfargument name="tag" hint="the tag to insert" type="string" required="Yes">
	<cfquery>
		INSERT INTO	squabble_visitor_tags
		(visitor_id, tag_value)
		VALUES
		(
			<cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
			, <cfqueryparam value="#arguments.tag#" cfsqltype="cf_sql_varchar">
		)
	</cfquery>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>
