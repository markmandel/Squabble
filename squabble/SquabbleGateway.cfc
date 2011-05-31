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
	<cfargument name="visitDate" type="date" required="false" default="#now()#" hint="First visit date/time of this visitor">
	<cfargument name="testName" type="string" required="true" hint="The test this visitor is being recorded for">
	<cfset var visitorID = createUUID()>
	
	<cfquery>
		INSERT INTO squabble_visitors (
			id,
			visit_date,
			test_name
		)
		VALUES (
			<cfqueryparam cfsqltype="cf_sql_char" value="#visitorID#" maxlength="35">
			, <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.visitDate#">
			, <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
		)
	</cfquery>
	
	<cfreturn visitorID>
</cffunction>


<cffunction name="getVisitor" hint="Returns a visitor query" access="public" returntype="query" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="ID of the visitor to return">
	<cfset var getVisitorQuery = "">

	<cfquery name="getVisitorQuery">
		SELECT id, visit_date, test_name
		FROM squabble_visitors
		WHERE id = <cfqueryparam cfsqltype="cf_sql_char" value="#visitorID#" maxlength="35">
	</cfquery>
	
	<cfreturn getVisitorQuery>
</cffunction>


<cffunction name="insertConversion" hint="Inserts a visitor to the database when they come across a test" access="public" returntype="string" output="false">
	<cfargument name="visitorID" type="string" required="true" hint="The visitor ID to record the conversion for">
	<cfargument name="conversionDate" type="date" required="false" default="#now()#" hint="The date the conversion happened">
	<cfargument name="conversionRevenue" type="string" required="false" default="" hint="The revenue amount to record for this conversion">
	<cfset var conversionID = createUUID()>
	
	<cfquery>
		INSERT INTO squabble_conversions (
			id,
			visitor_id,
			conversion_date,
			conversion_revenue
		)
		VALUES (
			<cfqueryparam cfsqltype="cf_sql_char" value="#conversionID#" maxlength="35">
			, <cfqueryparam cfsqltype="cf_sql_char" value="#arguments.visitorID#" maxlength="35">
			, <cfqueryparam cfsqltype="cf_sql_timestamp" value="#arguments.conversionDate#">
			, <cfqueryparam cfsqltype="cf_sql_double" value="#arguments.conversionRevenue#" null="#NOT isNumeric(arguments.conversionRevenue)#">
		)
	</cfquery>
	
	<cfreturn conversionID>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>





}
