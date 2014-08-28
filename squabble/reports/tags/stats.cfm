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

<cfsavecontent variable="js" >
<script type="text/javascript">
	function previewCombination(qs)
	{
		var baseURL = document.getElementById('previewURL').value;

		if (baseURL.length > 0)
		{
			var qsSelector = baseURL.indexOf("?") == -1 ? "?" : "&";
			window.open(baseURL + qsSelector + qs);
		}
		else
		{
			alert('Please enter a base URL!');
		}
	}
</script>
</cfsavecontent>
<cfhtmlhead text="#js#" >

<cfscript>
	totalVisitors = application.report.getTotalVisitors(form.testName);
	totalConversions = attributes.report.getTotalConversions(form.testName);
	conversions = totalConversions.recordcount EQ 1 AND totalConversions.total_conversions GT 0;
	sections = attributes.report.getTestSections(form.testName);
	sectionCount = listLen(sections);
</cfscript>

</cfsilent>

<div id="testData">
	<cfoutput>
		<h2>#form.testName#</h2>

		Preview URL: <input type="text" id="previewURL" value="http://#cgi.SERVER_NAME#:#cgi.SERVER_PORT#/" />

		<table cellspacing="0">
			<tr class="header">
				<th>Visitors</th>
				<th>Conv.</th>
				<th>Conv. Rate</th>
				<th>Total Conv. Value</th>
				<th>Average Conv. Value</th>
				<cfif val(totalConversions.total_units) GT 0>
					<th>Units</th>
					<th>Avg. Value Per Unit</th>
					<th>Units Per Conv.</th>
				</cfif>
			</tr>
			<tr>
				<td>#totalVisitors#</td>
				<cfif conversions>
					<td>#totalConversions.total_conversions#</td>
					<td>#decimalFormat(totalConversions.total_conversions / totalVisitors * 100)#%</td>
					<td>#decimalFormat(val(totalConversions.total_value))#</td>
					<td>#decimalFormat(val(totalConversions.total_value) / totalConversions.total_conversions)#</td>
					<cfif val(totalConversions.total_units) GT 0>
						<td>#val(totalConversions.total_units)#</td>
						<td>#dollarFormat(val(totalConversions.total_value) / totalConversions.total_units)#</td>
						<td>#decimalFormat(totalConversions.total_units / totalConversions.total_conversions)#</td>
					</cfif>
				<cfelse>
					<td>0</td>
					<td>NA</td>
					<td>NA</td>
					<td>NA</td>
				</cfif>
			</tr>
		</table>
	</cfoutput>

	<cfif conversions>
		<cfscript>
			combinationTotalVisitors = attributes.report.getCombinationTotalVisitors(form.testName);
			combinationTotalConversions = attributes.report.getCombinationTotalConversions(form.testName);
			goalTotalConversions = attributes.report.getGoalTotalConversions(form.testName);

			/* Debug
				writeDump(var=sections, expand=false)
				writeDump(var=combinationTotalVisitors, expand=false);
				writeDump(var=combinationTotalConversions, expand=false);
				writeDump(var=goalTotalConversions, expand=false);
			 */
		</cfscript>

		<!--- Work out if we can measure against control --->
		<cfset haveControl = false>
		<cfset controlName = "">
		<cfloop from="1" to="#sectionCount#" index="i">
			<cfset controlName = listAppend(controlName, "control")>
		</cfloop>

		<cfquery name="controlVisitors" dbtype="query">
			SELECT total_visitors FROM combinationTotalVisitors WHERE flat_combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#controlName#">;
		</cfquery>

		<cfif controlVisitors.recordcount EQ 1 AND controlVisitors.total_visitors GT 0>
			<cfquery name="controlConversions" dbtype="query">
				SELECT total_conversions, total_value FROM combinationTotalConversions WHERE flat_combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#controlName#">;
			</cfquery>

			<cfif controlConversions.recordcount>
				<cfset haveControl = true>

				<cfset control = {
					visitors = controlVisitors.total_visitors,
					conversions = controlConversions.total_conversions,
					value = controlConversions.total_value
				}>

				<cfset control.conversionRate = decimalFormat(val(control.conversions) / control.visitors * 100)>
			</cfif>
		</cfif>

		<table cellspacing="0" id="combinationTable">
			<thead>
			<tr class="header">
				<th>Combination</th>
				<th>Hits</th>
				<th>Conversions</th>
				<th>Conv. Rate</th>
				<th>% Improvement</th>
				<th>Conv. Value</th>
				<th>Avg Conv. Value</th>
				<cfif val(totalConversions.total_units) GT 0>
					<th>Units</th>
					<th>Avg. Value Per Unit</th>
					<th>Units Per Conv.</th>
				</cfif>

				<th>Goal</th>
				<th>Conversions</th>
				<th>Conv. Rate</th>
				<th>Conv. Value</th>
				<th>Avg Conv. Value</th>
				<cfif val(totalConversions.total_units) GT 0>
					<th>Units</th>
					<th>Avg. Value Per Unit</th>
					<th>Units Per Conv.</th>
				</cfif>
			</tr>
			</thead>
			<tbody>

			<cfset combinationCount = 0>

			<cfoutput query="goalTotalConversions" group="flat_combination">
				<cfset combinationCount++>
				<cfset goalCount = 0>
				<cfset totalGoals = 0>
				<cfoutput><cfset totalGoals++></cfoutput>

				<!--- Get the data for this specific combination --->
				<cfquery name="comboVisitors" dbtype="query">
					SELECT total_visitors, most_recent_visit FROM combinationTotalVisitors WHERE flat_combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#flat_combination#">;
				</cfquery>

				<cfquery name="comboConversions" dbtype="query">
					SELECT total_conversions, total_value, total_units FROM combinationTotalConversions WHERE flat_combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#flat_combination#">;
				</cfquery>

				<cfscript>
					combinationVisitors = comboVisitors.total_visitors;
					combinationLastVisit = comboVisitors.most_recent_visit;
					combinationConversions = comboConversions.total_conversions;
					combinationConversionTotal = comboConversions.total_value;
					combinationUnitsTotal = comboConversions.total_units;
					combinationConversionRate = numberFormat((combinationConversions / combinationVisitors) * 100, ".00");

					isRecentCombination = combinationLastVisit GT dateAdd("h", -3, now());

					// Row Class
					combinationRowClass = "";

					if (combinationCount MOD 2 EQ 0)
					{
						combinationRowClass = listAppend(combinationRowClass, "odd", " ");
					}

					if (!isRecentCombination)
					{
						combinationRowClass = listAppend(combinationRowClass, "old", " ");
					}
				</cfscript>

				<cfoutput>
					<cfscript>
						goalCount++;
					</cfscript>
					<tr class="#combinationRowClass#">
						<cfif goalCount EQ 1>
							<td rowspan="#totalGoals#">
								<cfset combinationPreviewQS = "squabble_enable_preview=#form.testName#">

								<cfif sectionCount EQ 1>
									<cfset combinationPreviewQS = listAppend(combinationPreviewQS, "squabble_#sections#=#flat_combination#", "&")>
								<cfelse>
									<cfset s = 0>

									<cfloop list="#flat_combination#" index="comboName">
										<cfset s++>
										<cfset combinationPreviewQS = listAppend(combinationPreviewQS, "squabble_#listGetAt(sections, s)#=#comboName#", "&")>
									</cfloop>
								</cfif>

								<a href="javascript:previewCombination('#combinationPreviewQS#')" class="combination-name">#flat_combination#</a>
							</td>
							<td rowspan="#totalGoals#">#combinationVisitors#</td>
							<td rowspan="#totalGoals#">#combinationConversions#</td>
							<td rowspan="#totalGoals#">#combinationConversionRate#%</td>
							<td rowspan="#totalGoals#">
								<cfif haveControl AND flat_combination NEQ controlName>
									<cfset conversionImprovement = decimalFormat(((combinationConversions / control.conversions) - 1) * 100)>
									<span class="<cfif conversionImprovement GT 0>green<cfelseif conversionImprovement LT 0>red<cfelse>blue</cfif>"><cfif conversionImprovement GT 0>+</cfif>#conversionImprovement#%</span>
								<cfelse>
									NA
								</cfif>
							</td>
							<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#combinationConversionTotal#<cfelse>NA</cfif></td>
							<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#decimalFormat(val(combinationConversionTotal) / combinationConversions)#<cfelse>NA</cfif></td>
							<cfif val(totalConversions.total_units) GT 0>
								<td rowspan="#totalGoals#">#val(combinationUnitsTotal)#</td>
								<td rowspan="#totalGoals#"><cfif val(combinationUnitsTotal) GT 0 AND val(combinationConversionTotal) gt 0>#decimalFormat(combinationConversionTotal / combinationUnitsTotal)#<cfelse>NA</cfif></td>
								<td rowspan="#totalGoals#"><cfif val(combinationConversions) GT 0 AND val(combinationUnitsTotal) GT 0>#decimalFormat(combinationUnitsTotal / combinationConversions)#<cfelse>NA</cfif></td>
							</cfif>
						</cfif>

						<td>#conversion_name#</td>
						<td>#total_conversions#</td>
						<td>#decimalFormat(total_conversions / combinationVisitors * 100)#%</td>
						<td><cfif isNumeric(total_value)>#total_value#<cfelse>NA</cfif></td>
						<td><cfif isNumeric(total_value)>#decimalFormat(val(total_value) / total_conversions)#<cfelse>NA</cfif></td>
						<cfif val(totalConversions.total_units) GT 0>
							<td>#val(total_units)#</td>
							<td><cfif val(total_units) GT 0 AND isNumeric(total_value)>#decimalFormat(total_value / total_units)#<cfelse>NA</cfif></td>
							<td><cfif val(total_units) GT 0 AND isNumeric(total_conversions)>#decimalFormat(total_units / total_conversions)#<cfelse>NA</cfif></td>
						</cfif>
					</tr>
				</cfoutput>
			</cfoutput>
			</tbody>
		</table>
	</cfif>
</div>