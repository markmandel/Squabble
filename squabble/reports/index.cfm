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

	<cfset testQuery = application.squabble.getGateway().getAllTestData(form.testName)>
	<cfset testData = structNew()>

	<cfif testQuery.recordcount GT 0>
		<cfset visitor_count = 0>
		<cfset conversion_count = 0>
		<cfset revenue_total = 0>
		<cfset testData.combinations = {}>

		<cfoutput query="testQuery" group="visitor_id">
			<cfset visitor_count++>

			<cfset combination = "">

			<cfoutput group="section_name">
				<cfset combination = listAppend(combination, variation_name, "-")>
			</cfoutput>

			<cfif !structKeyExists(testData.combinations, combination)>
				<cfset testData.combinations[combination] = {
					hits = 0,
					conversions = {},
					revenue = {},
					conversionsTotal = 0,
					revenueTotal = 0
				}>
			</cfif>

			<cfset testData.combinations[combination].hits++>

			<cfif isDate(conversion_date)>
				<cfset conversion_count++>
				<cfset testData.combinations[combination].conversionsTotal++>

				<cfif !structKeyExists(testData.combinations[combination].conversions, conversion_name)>
					<cfset testData.combinations[combination].conversions[conversion_name] = 0>
				</cfif>

				<cfif !structKeyExists(testData.combinations[combination].revenue, conversion_name)>
					<cfset testData.combinations[combination].revenue[conversion_name] = 0>
				</cfif>

				<cfset testData.combinations[combination].conversions[conversion_name]++>

				<cfif isNumeric(conversion_revenue)>
					<cfset revenue_total += conversion_revenue>
					<cfset testData.combinations[combination].revenue[conversion_name] += conversion_revenue>
					<cfset testData.combinations[combination].revenueTotal += conversion_revenue>
				</cfif>
			</cfif>
		</cfoutput>

		<cfset testData.visitorTotal = visitor_count>
		<cfset testData.conversionTotal = conversion_count>
		<cfset testData.revenueTotal = revenue_total>
		<cfset testData.testName = form.testName>
	</cfif>
</cfif>

</cfsilent><!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Squabble Simple Report</title>
	<style type="text/css">
		* { margin: 0; padding: 0; }
		html { height: 100%; width: 100%; }
		body { margin: 20px; }

		#testData { margin-top: 20px; }

		#testData table { margin-top: 15px; border: solid 1px #ccc; }
		th { font-weight: bold; }
		td, th { text-align: center; padding: 8px 15px; }
		.header { background-color: #ddd; }
		.odd { background-color: #efefef;  }
	</style>
</head>
<body>
	<form method="post">
		<cfset tests = application.squabble.getGateway().getAllTests()>

		<strong>Choose Test:</strong>

		<cfif arrayLen(tests)>
			<select name="testName">
				<cfloop array="#tests#" index="testName">
					<cfoutput><option value="#testName#" <cfif structKeyExists(form, "testName") AND form.testName EQ testName>selected="selected"</cfif>>#testName#</option></cfoutput>
				</cfloop>
			</select>

			<input type="submit" value="Show Me" />
		<cfelse>
			No Tests Recorded!
		</cfif>

		<cfif structKeyExists(form, "fieldnames") AND !structIsEmpty(testData)>
			<div id="testData">
				<cfoutput>
					<h2>#testData.testName#</h2>

					<table cellspacing="0">
						<tr class="header">
							<th>Conv.</th>
							<th>Visitors</th>
							<th>Conv. %</th>
							<th>Average Conv. Rate (All Visitors)</th>
							<th>Average Conv. Rate (Per Conversion)</th>
						</tr>
						<tr>
							<td>#testData.conversionTotal#</td>
							<td>#testData.visitorTotal#</td>
							<td>#decimalFormat(testData.conversionTotal / testData.visitorTotal * 100)#</td>
							<td>#dollarFormat(testData.revenueTotal / testData.visitorTotal)#</td>
							<td>
								<cfif testData.conversionTotal GT 0>
									#dollarFormat(testData.revenueTotal / testData.conversionTotal)#
								<cfelse>
									NA
								</cfif>
							</td>
						</tr>
					</table>

					<cfif testData.conversionTotal GT 0>
						<table cellspacing="0">
							<tr class="header">
								<th>Combination</th>
								<th>Hits</th>

								<th>Goal</th>
								<th>Conversions</th>
								<th>Conv. Rate</th>
								<th>Revenue</th>

								<th>Total Conversions</th>
								<th>Total Conv. Rate</th>
								<th>Total Revenue</th>
							</tr>

							<cfset currentCombination = 0>

							<cfloop collection="#testData.combinations#" item="combination">
								<cfset goalCount = 0>
								<cfset currentCombination++>
								<cfset combinationCount = structCount(testData.combinations[combination].conversions)>

								<cfloop collection="#testData.combinations[combination].conversions#" item="conversionName">
									<cfset goalCount++>
									<tr <cfif currentCombination MOD 2 EQ 0>class="odd"</cfif>>
										<cfif goalCount EQ 1>
											<td rowspan="#combinationCount#">#combination#</td>
											<td rowspan="#combinationCount#">#testData.combinations[combination].hits#</td>
										</cfif>

										<td>#conversionName#</td>
										<td>#testData.combinations[combination].conversions[conversionName]#</td>
										<td>#decimalFormat(testData.combinations[combination].conversions[conversionName] / testData.combinations[combination].hits * 100)#%</td>
										<td>#dollarFormat(testData.combinations[combination].revenue[conversionName])#</td>

										<cfif goalCount EQ 1>
											<td rowspan="#combinationCount#">#testData.combinations[combination].conversionsTotal#</td>
											<td rowspan="#combinationCount#">#decimalFormat(testData.combinations[combination].conversionsTotal / testData.combinations[combination].hits * 100)#%</td>
											<td rowspan="#combinationCount#">#dollarFormat(testData.combinations[combination].revenueTotal)#</td>
										</cfif>
									</tr>
								</cfloop>
							</cfloop>
						</table>
					<cfelse>
						<br />No conversions recorded for this test yet.
					</cfif>
				</cfoutput>
			</div>
		<cfelseif structKeyExists(form, "fieldnames")>
			<br /><br />No Test Data Found
		</cfif>
	</form>
</body>
</html>
