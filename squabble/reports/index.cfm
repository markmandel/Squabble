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
	A very simple report output to screen.
--->

<cfif structKeyExists(form, "fieldnames")>
	<cfparam name="form.testName" type="string" default="">

	<cfscript>
		totalVisitors = application.report.getTotalVisitors(form.testName);
	</cfscript>
</cfif>

</cfsilent><!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Squabble Simple Report</title>

	<!--[if lt IE 9]><script language="javascript" type="text/javascript" src="./js/jqPlot/excanvas.js"></script><![endif]-->
	<script language="javascript" type="text/javascript" src="./js/jqPlot/jquery.min.js"></script>
	<script language="javascript" type="text/javascript" src="./js/jqPlot/jquery.jqplot.min.js"></script>
	<script type="text/javascript" language="javascript" src="./js/jqPlot/plugins/jqplot.dateAxisRenderer.js"></script>
	<script type="text/javascript" language="javascript" src="./js/jqPlot/plugins/jqplot.canvasTextRenderer.js"></script>
	<script type="text/javascript" language="javascript" src="./js/jqPlot/plugins/jqplot.canvasAxisLabelRenderer.js"></script>
	<script language="javascript" type="text/javascript" src="./js/jqPlot/plugins/jqplot.cursor.min.js"></script>
	<script language="javascript" type="text/javascript" src="./js/jqPlot/plugins/jqplot.highlighter.min.js"></script>
	<script language="javascript" type="text/javascript" src="./js/jqPlot/plugins/jqplot.enhancedLegendRenderer.min.js"></script>
	<link rel="stylesheet" type="text/css" href="./js/jqPlot/jquery.jqplot.css" />

	<style type="text/css">
		* { margin: 0; padding: 0; font-family: inherit; }
		html { height: 100%; width: 100%; }
		body { margin: 20px; font-family: Ubuntu, Arial, Helvetica; font-size: 9pt; }
		h2 { margin-bottom: 5px; }
		h3 { margin-top: 10px; clear: both; }

		#testData { margin-top: 20px; }
		#testData table { margin-top: 15px; border: solid 1px #ccc; }

		#previewURL { width: 350px; }

		th { font-weight: bold; }
		td, th { text-align: center; padding: 6px 12px; }
		.header { background-color: #ddd; }
		.odd { background-color: #efefef;  }
		.red {color: #CC0000; }
		.green {color: #00CC00; }
		.blue {color: #0000CC; }
		.combination-name { font-weight: bold; cursor: pointer; text-decoration: underline; }
		.combination-name:hover { text-decoration: none; }
		.hint { color: grey; font-style: italic; }
		.old { color: grey; }

		#conversions, #value, #units {
			height: 600px;
			width: 100%;
		}
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
		<cfset tests = application.report.getCategorisedTests()>

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
				totalConversions = application.report.getTotalConversions(form.testName);
				conversions = totalConversions.recordcount EQ 1 AND totalConversions.total_conversions GT 0;
				sections = application.report.getTestSections(form.testName);
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
						combinationTotalVisitors = application.report.getCombinationTotalVisitors(form.testName);
						combinationTotalConversions = application.report.getCombinationTotalConversions(form.testName);
						goalTotalConversions = application.report.getGoalTotalConversions(form.testName);

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
											<td rowspan="#totalGoals#"><cfif val(combinationUnitsTotal) GT 0>#decimalFormat(combinationConversionTotal / combinationUnitsTotal)#<cfelse>NA</cfif></td>
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
			<cfscript>
				visitors = application.report.getCombinationTotalVisitors(form.testName, "hour");
				conversions = application.report.getCombinationTotalConversions(form.testName, "hour");

				data = createObject("java", "java.util.LinkedHashMap").init();
            </cfscript>

            <cfoutput query="visitors" group="flat_combination">
				<cfscript>
					//keep the order
					data[flat_combination] = createObject("java", "java.util.LinkedHashMap").init();
                </cfscript>

				<cfoutput>
					<cfscript>
						key = dateformat(visitors.date, "yyyymmdd") & " " & visitors.unit & ":00";

						item = { conversions = 0, units = 0, value = 0 };
						item.hour = visitors.unit;
						item.date = visitors.date;
						item.visitors = visitors.total_visitors;

						data[flat_combination][key] = item;
                    </cfscript>
				</cfoutput>
			</cfoutput>

            <cfoutput query="conversions" group="flat_combination">
				<cfoutput>
					<cfscript>
						key = dateformat(conversions.date, "yyyymmdd") & " " & conversions.unit & ":00";

						item = structKeyExists(data[flat_combination], key) ? data[flat_combination][key] : { visitors = 0 };

						item.hour = conversions.unit;
						item.date = conversions.date;
						item.conversions = conversions.total_conversions;
						item.units = conversions.total_units;
						item.value = conversions.total_value;

						data[flat_combination][key] = item;
                    </cfscript>
				</cfoutput>
			</cfoutput>

			<!--- now we process it, and calculate totals --->
			<cfscript>
				for(combination in data)
				{
					combo = data[combination];
					visitorTotal = 0;
					conversionTotal = 0;
					valueTotal = 0;
					unitTotal = 0;

					for(date in combo)
					{
						item = combo[date];
						visitorTotal += item.visitors;
						conversionTotal += item.conversions;
						valueTotal += val(item.value);
						unitTotal += val(item.units);

						//take a snapshot at now.
						item.visitorTotal = visitorTotal;
						item.conversionTotal = conversionTotal;
						item.valueTotal = valueTotal;
						item.unitTotal = unitTotal;

						if(visitorTotal == 0)
						{
							item.conversionRate = 0;
						}
						else
						{
							item.conversionRate = (conversionTotal/visitorTotal) * 100;
						}
					}
				}
            </cfscript>

			<cfoutput>
			<script type="text/javascript">
				$(document).ready(function(){
					$.jqplot.config.enablePlugins = true;
					var options =
					{
						legend:
						{
           					renderer: $.jqplot.EnhancedLegendRenderer,
           					show:true,
           					rendererOptions:{
               					numberRows: 1
           					},
           					placement: 'outsideGrid',
           					location: 's'
							,labels:
							[
							<cfset i = 1>
							<cfloop collection="#data#" item="combination">
							<cfif i++ neq 1>,</cfif>'#JSStringFormat(combination)#'
							</cfloop>
							]
						}
						,axesDefaults:
						{
							autoscale: true
						}
						,axes:
						{
							xaxis:
							{
								label: "Date, Hourly Breakdown"
								,renderer:$.jqplot.DateAxisRenderer
								,tickOptions:{formatString:'%d %b %H:00'}
						  	}
							,yaxis:
							{
								label: "Conversion Percentage"
								,labelRenderer: $.jqplot.CanvasAxisLabelRenderer
								,labelOptions:
								{
									angle: 270
								}
								,min: 0
							}
						}
						,cursor:{zoom:true}
						,highlighter:{show:true}
					};

					<cfset counter = 1>
					<cfset vars = "">
				    <cfloop collection="#data#" item="combination">
						<cfset vars =ListAppend(vars, "series#counter#")>
						<cfset combo = data[combination]>
						series#counter++# =
						[
							<cfset i = 1>
							<cfloop collection="#combo#" item="date"><cfset item = combo[date]>
							<cfif i++ neq 1>,</cfif>["#DateFormat(item.date, 'dd mmm yyyy')# #item.hour#:00", #item.conversionRate#]
							</cfloop>
						];
					</cfloop>


				    conv = $.jqplot('conversions', [#vars#], options);

					<cfset vars = "">
					<cfloop collection="#data#" item="combination">
						<cfset vars =ListAppend(vars, "series#counter#")>
						<cfset combo = data[combination]>
						series#counter++# =
						[
							<cfset i = 1>
							<cfloop collection="#combo#" item="date"><cfset item = combo[date]>
							<cfif i++ neq 1>,</cfif>["#DateFormat(item.date, 'dd mmm yyyy')# #item.hour#:00", #item.valueTotal#]
							</cfloop>
						];
					</cfloop>

					options.axes.yaxis.label = "Total Value";
					values = $.jqplot('value', [#vars#], options);

					<cfset vars = "">
					<cfloop collection="#data#" item="combination">
						<cfset vars =ListAppend(vars, "series#counter#")>
						<cfset combo = data[combination]>
						series#counter++# =
						[
							<cfset i = 1>
							<cfloop collection="#combo#" item="date"><cfset item = combo[date]>
							<cfif i++ neq 1>,</cfif>["#DateFormat(item.date, 'dd mmm yyyy')# #item.hour#:00", #item.unitTotal#]
							</cfloop>
						];
					</cfloop>

					options.axes.yaxis.label = "Total Units";
					units = $.jqplot('units', [#vars#], options);

				  });
			</script>
			</cfoutput>

		<h3>Conversion Rate Per Hour</h3>
		<div id="conversions" ></div>
		<div><button value="reset" type="button" onclick="conv.resetZoom();">Zoom Out</button></div>

		<h3>Total Value Per Hour</h3>

		<div id="value" ></div>
		<div><button value="reset" type="button" onclick="values.resetZoom();">Zoom Out</button></div>

		<h3>Total Units Per Hour</h3>

		<div id="units" ></div>
		<div><button value="reset" type="button" onclick="units.resetZoom();">Zoom Out</button></div>

		<cfelseif structKeyExists(form, "fieldnames")>
			<br /><br />No Test Data Found
		</cfif>
	</form>
</body>
</html>
