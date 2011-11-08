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

<cfcomponent hint="Gateway method for mysql reporting" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Gateway" output="false">
	<cfscript>
		return this;
	</cfscript>
</cffunction>

<cffunction name="getCategorisedTests" hint="Returns a categorised structure of tests" access="public" returntype="struct" output="false">
	<cfset var tests = getAllTestsByLastVisit()>
	<cfset var thisTest = "">

	<cfset var categorised = structNew()>
	<cfset categorised.total = 0>
	<cfset categorised.order = "Today,Past Week,Past Month,Past Quarter,Past Year,Older">
	<cfset categorised["Today"] = arrayNew(1)>
	<cfset categorised["Past Week"] = arrayNew(1)>
	<cfset categorised["Past Month"] = arrayNew(1)>
	<cfset categorised["Past Quarter"] = arrayNew(1)>
	<cfset categorised["Past Year"] = arrayNew(1)>
	<cfset categorised["Older"] = arrayNew(1)>

	<cfloop query="tests">
		<cfset thisTest = structNew()>
		<cfset thisTest[test_name] = most_recent_visit>

		<cfif dateCompare(most_recent_visit, now(), "d") EQ 0>
			<cfset arrayAppend(categorised["Today"], duplicate(thisTest))>
		<cfelseif most_recent_visit GT dateAdd("d", -7, now())>
			<cfset arrayAppend(categorised["Past Week"], duplicate(thisTest))>
		<cfelseif most_recent_visit GT dateAdd("m", -1, now())>
			<cfset arrayAppend(categorised["Past Month"], duplicate(thisTest))>
		<cfelseif most_recent_visit GT dateAdd("m", -3, now())>
			<cfset arrayAppend(categorised["Past Quarter"], duplicate(thisTest))>
		<cfelseif most_recent_visit GT dateAdd("yyyy", -1, now())>
			<cfset arrayAppend(categorised["Past Year"], duplicate(thisTest))>
		<cfelse>
			<cfset arrayAppend(categorised["Older"], duplicate(thisTest))>
		</cfif>

		<cfset categorised.total = categorised.total + 1>
	</cfloop>

	<cfreturn categorised>
</cffunction>

<cffunction name="getAllTestsByLastVisit" hint="Retutns All Tests Ordered By The Last Visit" access="public" returntype="query" output="false">
	<cfset var getAllTestsQuery = "">

	<cfquery name="getAllTestsQuery">
		SELECT DISTINCT test_name, MAX(visit_date) AS most_recent_visit
		FROM squabble_visitors
		GROUP BY test_name
		ORDER BY visit_date DESC, test_name
	</cfquery>

	<cfreturn getAllTestsQuery>
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

<cffunction name="getCombinationTotalVisitors" hint="Returns a query of visitor totals per combination" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfargument name="unitGrouping" type="string" required="false" hint="Optional grouping for data by either 'hour' or 'minute'">

	<cfset var getCombinationTotalVisitorsQuery = "">

	<cfquery name="getCombinationTotalVisitorsQuery">
		SELECT
			count(squabble_visitors.id) as total_visitors
			,squabble_visitors.flat_combination
			<cfif StructKeyExists(arguments, "unitGrouping")>
				,date(squabble_visitors.visit_date) as date
				,#arguments.unitGrouping#(squabble_visitors.visit_date) as unit
			<cfelse>
				,MAX(squabble_visitors.visit_date) AS most_recent_visit
			</cfif>
		FROM
			squabble_visitors
		WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">
		GROUP BY
			flat_combination

		<cfif StructKeyExists(arguments, "unitGrouping")>
				,date, unit

			ORDER BY
				flat_combination, date, unit
		</cfif>
	</cfquery>

	<cfreturn getCombinationTotalVisitorsQuery>
</cffunction>

<cffunction name="getCombinationTotalConversions" hint="Returns a query of total conversions and value per combination" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">
	<cfargument name="unitGrouping" type="string" required="false" hint="Optional grouping for data by either 'hour' or 'minute'">

	<cfset var getCombinationTotalConversionsQuery = "">

	<cfquery name="getCombinationTotalConversionsQuery">
		SELECT
			COUNT(squabble_visitors.id) AS total_conversions,
			SUM(squabble_conversions.conversion_value) AS total_value,
			SUM(squabble_conversions.conversion_units) AS total_units,
			squabble_visitors.flat_combination
			<cfif StructKeyExists(arguments, "unitGrouping")>
				,date(squabble_conversions.conversion_date) as date
				,#arguments.unitGrouping#(squabble_conversions.conversion_date) as unit
			</cfif>
		FROM
			squabble_visitors
			INNER JOIN
			squabble_conversions
				ON squabble_conversions.visitor_id = squabble_visitors.id

		WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">

		GROUP BY flat_combination
			<cfif StructKeyExists(arguments, "unitGrouping")>
				,date, unit

				ORDER BY
				flat_combination, date, unit

			</cfif>
	</cfquery>

	<cfreturn getCombinationTotalConversionsQuery>
</cffunction>

<cffunction name="getGoalTotalConversions" hint="Returns a query of total conversions and value per combination and goal" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for">

	<cfset var getGoalTotalConversionsQuery = "">

	<cfquery name="getGoalTotalConversionsQuery">
		SELECT
			COUNT(squabble_visitors.id) AS total_conversions,
			SUM(squabble_conversions.conversion_value) AS total_value,
			SUM(squabble_conversions.conversion_units) AS total_units,
			squabble_visitors.flat_combination,
			squabble_conversions.conversion_name
		FROM
		squabble_visitors
		INNER JOIN
		squabble_conversions
			ON squabble_conversions.visitor_id = squabble_visitors.id
		WHERE
			squabble_visitors.test_name = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.testName#">

		GROUP BY flat_combination, squabble_conversions.conversion_name
		ORDER BY flat_combination, conversion_name
	</cfquery>

	<cfreturn getGoalTotalConversionsQuery>
</cffunction>

<cffunction name="getSectionConversions" hint="Get a per section breakdown for a given test" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for"/>

	<cfquery name="local.sectionConversions">
		select
			squabble_combinations.section_name
			,squabble_combinations.variation_name
			,COUNT(squabble_conversions.id) as total_conversions
			,SUM(squabble_conversions.conversion_value) as total_value
			,SUM(squabble_conversions.conversion_units) as total_units
		from
			squabble_conversions
			inner join
			squabble_visitors
				on squabble_visitors.id = squabble_conversions.visitor_id
			inner join
			squabble_combinations
				on squabble_visitors.id = squabble_combinations.visitor_id
		where
			squabble_visitors.test_name = <cfqueryparam value="#arguments.testName#" cfsqltype="cf_sql_varchar">
		group by
			squabble_combinations.section_name
			,squabble_combinations.variation_name
		order by
			squabble_combinations.section_name
			,squabble_combinations.variation_name
	</cfquery>

	<cfreturn local.sectionConversions/>
</cffunction>

<cffunction name="getSectionVisitors" hint="Get a per section breakdown for a given test" access="public" returntype="query" output="false">
	<cfargument name="testName" type="string" required="true" hint="The test name to return data for"/>

	<cfquery name="local.sectionConversions">
		select
			squabble_combinations.section_name
			,squabble_combinations.variation_name
			,COUNT(squabble_visitors.id) as total_visitors
		from
			squabble_visitors
			inner join
			squabble_combinations
				on squabble_visitors.id = squabble_combinations.visitor_id
		where
			squabble_visitors.test_name = <cfqueryparam value="#arguments.testName#" cfsqltype="cf_sql_varchar">
		group by
			squabble_combinations.section_name
			,squabble_combinations.variation_name
		order by
			squabble_combinations.section_name
			,squabble_combinations.variation_name
	</cfquery>

	<cfreturn local.sectionConversions/>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>