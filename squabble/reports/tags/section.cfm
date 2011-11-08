<cfsilent>
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

<cfif thisTag.executionMode eq "end">
	<cfexit method="exittag">
</cfif>

<!--- The report CFC --->
<cfparam name="attributes.report">

<!--- the name of the test to show --->
<cfparam name="attributes.testName">

<cfscript>
	sectionConversions = attributes.report.getSectionConversions(attributes.testName);
	sectionVisitors = attributes.report.getSectionVisitors(attributes.testName);
</cfscript>

<cfquery name="sections" dbtype="query">
	select
		section_name
		,count(variation_name) as total
	from
		sectionConversions
	group by
		section_name
	order by
		section_name
</cfquery>

</cfsilent>

<h2>Section Report</h2>

<div id="sectionData">
	<table>
		<thead>
			<tr class="header">
				<th>Section</th>
				<th>Variation</th>
				<th>Hits</th>
				<th>Conversions</th>
				<th>Conversion Rate</th>
				<th>Total Value</th>
				<th>Average Value</th>
				<th>Total Units</th>
				<th>Average Units</th>
			</tr>
		</thead>
		<tbody>
			<cfset sectionCounter = 1>
			<cfoutput group="section_name" query="sectionConversions">
				<cfsilent>
					<cfscript>
                	   counter = 1;
                	   sectionClass = sectionCounter++ % 2 == 0 ? "odd" : "";
                    </cfscript>

					<cfquery name="rowcount" dbtype="query">
						select total from sections where section_name = <cfqueryparam value="#section_name#" cfsqltype="cf_sql_varchar">
					</cfquery>
				</cfsilent>
				<tr class="#sectionClass#">
					<td rowspan="#rowcount.total#">
						#section_name#
					</td>
					<cfoutput>
						<cfsilent>
							<cfquery name="visitors" dbtype="query">
								select total_visitors from sectionVisitors
								where
								section_name = <cfqueryparam value="#section_name#" cfsqltype="cf_sql_varchar">
								and
								variation_name = <cfqueryparam value="#variation_name#" cfsqltype="cf_sql_varchar">
							</cfquery>
						</cfsilent>
						<cfsavecontent variable="row" >
							<td>
								#variation_name#
							</td>
							<td>
								#visitors.total_visitors#
							</td>
							<td>
								#sectionConversions.total_conversions#
							</td>
							<td>
								<cfset percent = roundTo2Decimal(sectionConversions.total_conversions/visitors.total_visitors)>
								#numberFormat(percent, "___.__")#%
							</td>
							<td>
								<cfif isNumeric(sectionConversions.total_value)>
									#sectionConversions.total_value#
								<cfelse>
									NA
								</cfif>
							</td>
							<td>
								<cfif isNumeric(sectionConversions.total_value)>
									#roundTo2Decimal(sectionConversions.total_value/visitors.total_visitors)#
								<cfelse>
									NA
								</cfif>
							</td>
							<td>
								<cfif isNumeric(sectionConversions.total_units)>
									#sectionConversions.total_units#
								<cfelse>
									NA
								</cfif>
							</td>
							<td>
								<cfif isNumeric(sectionConversions.total_units)>
									#roundTo2Decimal(sectionConversions.total_units/visitors.total_visitors)#
								<cfelse>
									NA
								</cfif>
							</td>
						</cfsavecontent>

						<cfif counter++ eq 1>
							#row#
						<cfelse>
						</tr>
						<tr class="#sectionClass#">
							#row#
						</cfif>
					</cfoutput>
				</tr>
			</cfoutput>
		</tbody>
	</table>
</div>

<cfsilent>
<cfscript>
	function roundTo2Decimal(required number)
	{
		return Round((arguments.number) * 100 * 100) / 100;
	}
</cfscript>

</cfsilent>