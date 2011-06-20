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
	</cfscript>

	<cftransaction>
		<!--- Insert Main Visitor Record --->
		<cfquery>
			INSERT INTO squabble_visitors (
				id,
				visit_date,
				test_name
			)
			VALUES (
				<cfqueryparam cfsqltype="cf_sql_char" value="#visitorID#" maxlength="35">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.visitDate#">,
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
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
		SELECT id, visit_date, test_name
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


<!--- REPORTING QUERIES --->

<cffunction name="getAllTests" hint="Returns an array of all the tests in the database" access="public" returntype="array" output="false">
	<cfset var getAllTestsQuery = "">
	<cfset var testNameArray = []>

	<cfquery name="getAllTestsQuery">
		SELECT DISTINCT test_name
		FROM squabble_visitors
	</cfquery>

	<cfif getAllTestsQuery.recordcount GT 0>
		<cfset testNameArray = listToArray(valueList(getAllTestsQuery.test_name))>
	</cfif>

	<cfreturn testNameArray>
</cffunction>


<cffunction name="getTotalVisitors" hint="Returns a count of all visitors for a test" access="public" returntype="numeric" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var totalVisitors = 0>
	<cfset var getTotalVisitorsQuery = "">

	<cfquery name="getTotalVisitorsQuery">
		SELECT COUNT(id) AS total_visitors
		FROM squabble_visitors
		WHERE test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
	</cfquery>

	<cfif getTotalVisitorsQuery.recordCount EQ 1>
		<cfset totalVisitors = getTotalVisitorsQuery.total_visitors>
	</cfif>

	<cfreturn totalVisitors>
</cffunction>


<cffunction name="getTestSections" hint="Returns an ordered list of sections for a given test" access="public" returntype="string" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var sections = "">
	<cfset var getTestSectionsQuery = "">

	<cfquery name="getTestSectionsQuery">
		SELECT DISTINCT squabble_combinations.section_name
		FROM squabble_visitors
		JOIN squabble_combinations
		ON squabble_combinations.visitor_id = squabble_visitors.id
		WHERE squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
		ORDER BY squabble_combinations.section_name
	</cfquery>

	<cfif getTestSectionsQuery.recordCount GT 0>
		<cfset sections = valueList(getTestSectionsQuery.section_name)>
	</cfif>

	<cfreturn sections>
</cffunction>


<cffunction name="getTotalConversions" hint="Returns a count of all conversions, revenue and units" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var getTotalConversionsQuery = "">

	<cfquery name="getTotalConversionsQuery">
		SELECT
			COUNT(squabble_visitors.id) AS total_conversions,
			SUM(squabble_conversions.conversion_value) AS total_value,
			SUM(squabble_conversions.conversion_units) AS total_units
		FROM
			squabble_conversions
			INNER JOIN squabble_visitors
			ON squabble_conversions.visitor_id = squabble_visitors.id
		WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
	</cfquery>

	<cfreturn getTotalConversionsQuery>
</cffunction>


<cffunction name="getCombinationTotalVisitors" hint="Returns a query of visitor totals per combination" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var getCombinationTotalVisitorsQuery = "">

	<cfquery name="getCombinationTotalVisitorsQuery">
		SELECT
			count(combinations.id) as total_visitors,
			combinations.combination
		FROM
		(
			SELECT
				squabble_visitors.id,
				GROUP_CONCAT(squabble_combinations.variation_name ORDER BY squabble_combinations.section_name) AS combination
			FROM
				squabble_visitors
				INNER JOIN
				squabble_combinations
				ON squabble_combinations.visitor_id = squabble_visitors.id
			WHERE
				squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
			GROUP BY squabble_visitors.id
		) combinations
		GROUP BY combination
	</cfquery>

	<cfreturn getCombinationTotalVisitorsQuery>
</cffunction>


<cffunction name="getCombinationTotalConversions" hint="Returns a query of total conversions and value per combination" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var getCombinationTotalConversionsQuery = "">

	<cfquery name="getCombinationTotalConversionsQuery">
		SELECT
			COUNT(combinations.id) AS total_conversions,
			SUM(squabble_conversions.conversion_value) AS total_value,
			SUM(squabble_conversions.conversion_units) AS total_units,
			combinations.combination
		FROM
		(
			SELECT
				squabble_visitors.id,
				GROUP_CONCAT(squabble_combinations.variation_name ORDER BY squabble_combinations.section_name) AS combination
			FROM
				squabble_visitors
				INNER JOIN
				squabble_combinations
				ON squabble_combinations.visitor_id = squabble_visitors.id
			WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
			GROUP BY squabble_visitors.id
		) combinations

		INNER JOIN
		squabble_conversions
		ON squabble_conversions.visitor_id = combinations.id

		GROUP BY combination
	</cfquery>

	<cfreturn getCombinationTotalConversionsQuery>
</cffunction>


<cffunction name="getGoalTotalConversions" hint="Returns a query of total conversions and value per combination and goal" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfset var getGoalTotalConversionsQuery = "">

	<cfquery name="getGoalTotalConversionsQuery">
		SELECT
			COUNT(combinations.id) AS total_conversions,
			SUM(squabble_conversions.conversion_value) AS total_value,
			SUM(squabble_conversions.conversion_units) AS total_units,
			combinations.combination,
			squabble_conversions.conversion_name
		FROM
		(
			SELECT
				squabble_visitors.id,
				GROUP_CONCAT(squabble_combinations.variation_name ORDER BY squabble_combinations.section_name) AS combination
			FROM
				squabble_visitors
				INNER JOIN
				squabble_combinations
					ON squabble_combinations.visitor_id = squabble_visitors.id
			WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
			GROUP BY squabble_visitors.id
		) combinations

		INNER JOIN
		squabble_conversions
			ON squabble_conversions.visitor_id = combinations.id

		GROUP BY combination, squabble_conversions.conversion_name
		ORDER BY combination, conversion_name
	</cfquery>

	<cfreturn getGoalTotalConversionsQuery>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>
