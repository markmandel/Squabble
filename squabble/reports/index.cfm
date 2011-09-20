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
 ---><cfsilent>


<!---
	A very simple report output to screen for now.

	TODO: 	Move template in custom tag wrappers
			Add some styling to format the output nicely
			Move Data structure into API call
--->

<cfif structKeyExists(form, "fieldnames")>
	<cfparam name="form.testName" type="string" default="">

	<cfscript>
		totalVisitors = application.squabble.getGateway().getTotalVisitors(form.testName);
	</cfscript>
</cfif>

</cfsilent><!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Squabble Simple Report</title>
	<style type="text/css">
		* { margin: 0; padding: 0; font-family: inherit; }
		html { height: 100%; width: 100%; }
		body { margin: 20px; font-family: Ubuntu, Arial, Helvetica; font-size: 9pt; }
		h2 { margin-bottom: 5px; }

		#testData { margin-top: 20px; }
		#testData table { margin-top: 15px; border: solid 1px #ccc; }

		#previewURL { width: 350px; }

		th { font-weight: bold; }
		td, th { text-align: center; padding: 6px 12px; }
		.header { background-color: #ddd; }
		.odd { background-color: #efefef;  }
		.green {color: #00CC00; }
		.red {color: #CC0000; }
		.combination-name { font-weight: bold; cursor: pointer; text-decoration: underline; }
		.combination-name:hover { text-decoration: none; }
		.hint { color: grey; font-style: italic; }
		.old { color: grey; }
	</style>

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
</head>
<body>
	<form method="post">
		<cfset tests = application.squabble.getGateway().getCategorisedTests()>

		<strong>Choose Test:</strong>

		<cfif tests.total>
			<select name="testName">
				<cfloop list="#tests.order#" index="category">
					<cfif arrayLen(tests[category])>
						<optgroup label="<cfoutput>#category#</cfoutput>">
							<cfloop array="#tests[category]#" index="test">
								<cfset testName = structKeyList(test)>
								<cfset isRecent = category EQ "Today" AND test[testName] GT dateAdd("h", -3, now())>
								<cfoutput>
									<option
										value="#testName#"
										<cfif structKeyExists(form, "testName") AND form.testName EQ testName>selected="selected"</cfif>
										>#testName#<cfif isRecent>*</cfif>
									</option>
								</cfoutput>
							</cfloop>
						</optgroup>
					</cfif>
				</cfloop>
			</select>

			<input type="submit" value="Show Me" />
			<br /><br />
			<span class="hint">* Test has had a visitor in the last 3 hours</span>
		<cfelse>
			No Tests Recorded!
		</cfif>

		<cfif structKeyExists(form, "fieldnames") AND totalVisitors GT 0>
			<cfscript>
				totalConversions = application.squabble.getGateway().getTotalConversions(form.testName);
				conversions = totalConversions.recordcount EQ 1 AND totalConversions.total_conversions GT 0;
				sections = application.squabble.getGateway().getTestSections(form.testName);
				sectionCount = listLen(sections);
			</cfscript>

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
						combinationTotalVisitors = application.squabble.getGateway().getCombinationTotalVisitors(form.testName);
						combinationTotalConversions = application.squabble.getGateway().getCombinationTotalConversions(form.testName);
						goalTotalConversions = application.squabble.getGateway().getGoalTotalConversions(form.testName);

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
						SELECT total_visitors FROM combinationTotalVisitors WHERE combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#controlName#">;
					</cfquery>

					<cfif controlVisitors.recordcount EQ 1 AND controlVisitors.total_visitors GT 0>
						<cfset haveControl = true>

						<cfquery name="controlConversions" dbtype="query">
							SELECT total_conversions, total_value FROM combinationTotalConversions WHERE combination = <cfqueryparam cfsqltype="cf_sql_varchar" value="#controlName#">;
						</cfquery>

						<cfset control = {
							visitors = controlVisitors.total_visitors,
							conversions = controlConversions.total_conversions,
							value = controlConversions.total_value
						}>

						<cfset control.conversionRate = decimalFormat(control.conversions / control.visitors * 100)>
					</cfif>

					<table cellspacing="0">
						<tr class="header">
							<th>Combination</th>
							<th>Hits</th>
							<th>Conversions</th>
							<th>Conv. Rate</th>
							<th>% Improvment</th>
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

						<cfset combinationCount = 0>

						<cfoutput query="goalTotalConversions" group="combination">
							<cfset combinationCount++>
							<cfset goalCount = 0>
							<cfset totalGoals = 0>
							<cfoutput><cfset totalGoals++></cfoutput>

							<cfoutput>
								<cfscript>
									goalCount++;
									combinationVisitors = combinationTotalVisitors.total_visitors[combinationCount];
									combinationLastVisit = combinationTotalVisitors.most_recent_visit[combinationCount];
									combinationConversions = combinationTotalConversions.total_conversions[combinationCount];
									combinationConversionTotal = combinationTotalConversions.total_value[combinationCount];
									combinationUnitsTotal = combinationTotalConversions.total_units[combinationCount];
									combinationConversionRate = decimalFormat(combinationConversions / combinationVisitors * 100);

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

								<tr class="#combinationRowClass#">
									<cfif goalCount EQ 1>
										<td rowspan="#totalGoals#">
											<cfset combinationPreviewQS = "squabble_enable_preview=#form.testName#">
											<cfset sectionCount = 0>

											<cfloop list="#combination#" index="comboName">
												<cfset sectionCount++>
												<cfset combinationPreviewQS = listAppend(combinationPreviewQS, "squabble_#listGetAt(sections, sectionCount)#=#comboName#", "&")>
											</cfloop>

											<a href="javascript:previewCombination('#combinationPreviewQS#')" class="combination-name">#combination#</a>
										</td>
										<td rowspan="#totalGoals#">#combinationVisitors#</td>
										<td rowspan="#totalGoals#">#combinationConversions#</td>
										<td rowspan="#totalGoals#">#combinationConversionRate#%</td>
										<td rowspan="#totalGoals#">
											<cfif haveControl AND combination NEQ controlName>
												<cfset conversionImprovement = decimalFormat(((combinationConversions / control.conversions) - 1) * 100)>
												<span class="<cfif conversionImprovement GT 0>green<cfelse>red</cfif>"><cfif conversionImprovement GT 0>+</cfif>#conversionImprovement#%</span>
											<cfelse>
												NA
											</cfif>
										</td>
										<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#combinationConversionTotal#<cfelse>NA</cfif></td>
										<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#decimalFormat(val(combinationConversionTotal) / combinationConversions)#<cfelse>NA</cfif></td>
										<cfif val(totalConversions.total_units) GT 0>
											<td rowspan="#totalGoals#">#val(combinationUnitsTotal)#</td>
											<td rowspan="#totalGoals#"><cfif val(combinationUnitsTotal) GT 0>#combinationConversionTotal / combinationUnitsTotal#<cfelse>NA</cfif></td>
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

					</table>
				</cfif>
			</div>
		<cfelseif structKeyExists(form, "fieldnames")>
			<br /><br />No Test Data Found
		</cfif>
	</form>
</body>
</html>
