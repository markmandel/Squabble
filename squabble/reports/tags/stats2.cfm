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
				<th>Conv.</th>
				<th>Visitors</th>
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
				<cfif conversions>
					<td>#totalConversions.total_conversions#</td>
					<td>#totalVisitors#</td>
					<td>#decimalFormat(totalConversions.total_conversions / totalVisitors * 100)#%</td>
					<td>#dollarFormat(val(totalConversions.total_value))#</td>
					<td>#dollarFormat(val(totalConversions.total_value) / totalConversions.total_conversions)#</td>
					<cfif val(totalConversions.total_units) GT 0>
						<td>#val(totalConversions.total_units)#</td>
						<td>#dollarFormat(val(totalConversions.total_value) / totalConversions.total_units)#</td>
						<td>#decimalFormat(totalConversions.total_units / totalConversions.total_conversions)#</td>
					</cfif>
				<cfelse>
					<td>0</td>
					<td>#totalVisitors#</td>
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
				<th>Conversions</th>
				<th>Hits</th>
				<th>Conv. Rate</th>
				<th title="A 90% confidence that the conversion rate is within +/- this number">Conf. @ 90%</th>
				<th title="A 95% confidence that the conversion rate is within +/- this number">Conf. @ 95%</th>
				<th title="A 99% confidence that the conversion rate is within +/- this number">Conf. @ 99%</th>
				<th>% Imp.</th>
				<th title="When p = 0.10, 90% / p = 0.05, 95% / p = 0.01, 99%.  If 95%, says the results mean nothing (are caused by chance) 5% of the time.">P-value</th>
				<th title="The smaller the Std-Err, the more powerful the test.  Confidence level, commonly set to 95%, implies that 5% of the time we will incorrectly conclude that there is a difference when there is none (Type I error)">SE @ 95%</th>
				<th>Conv. Value</th>
				<th>Imp.</th>
				<th>% Imp.</th>

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

					if(haveControl)
					{
						pStats = calculateP(control.visitors, control.conversions, combinationVisitors, combinationConversions);
					}
					else
					{
						pStats = { p = 0, se = 0};
					}

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
								<cfif combinationVisitors GTE 1000 and isStatisticallySignificant(pStats.p)><img src="https://images-na.ssl-images-amazon.com/images/G/01/mobile-apps/devportal2/content/sdk/images/amazoninsights_orangecheck.png" /></cfif>								
							</td>
							<td rowspan="#totalGoals#">#combinationConversions#</td>
							<td rowspan="#totalGoals#">#combinationVisitors#</td>
							<td rowspan="#totalGoals#">
								#combinationConversionRate#%
							</td>
							<td rowspan="#totalGoals#">
								<!--- if data is normally distributed (assumed yes here), multiply SE * 1.65 to achieve 90% confidence --->
								&plusmn;#Round(1.65 * pStats.se * 10000)/100#%
							</td>
							<td rowspan="#totalGoals#">
								<!--- if data is normally distributed (assumed yes here), multiply SE * 1.96 to achieve 95% confidence --->
								&plusmn;#Round(1.96 * pStats.se * 10000)/100#%
							</td>
							<td rowspan="#totalGoals#">
								<!--- if data is normally distributed (assumed yes here), multiply SE * 2.58 to achieve 99% confidence --->
								&plusmn;#Round(2.58 * pStats.se * 10000)/100#%
							</td>
							
							<td rowspan="#totalGoals#">
								<cfif haveControl AND flat_combination NEQ controlName>
									<!--- cfset conversionImprovement = decimalFormat(((combinationConversionRate / control.conversionRate) - 1) * 100) --->
									<!--- as defined at: https://developer.amazon.com/sdk/ab-testing/reference/ab-math.html --->
									<cfset conversionImprovement = decimalFormat(100 * (combinationConversionRate - control.conversionRate)/control.conversionRate) />
									<span class="<cfif conversionImprovement GT 0>green<cfelseif conversionImprovement LT 0>red<cfelse>blue</cfif>"><cfif conversionImprovement GT 0>+</cfif>#conversionImprovement#%</span>
								<cfelse>
									NA
								</cfif>
							</td>
							<td rowspan="#totalGoals#">
								#(Round(pStats.p * 100))/100#
							</td>
							<td rowspan="#totalGoals#">
								<!--- if data is normally distributed (assumed yes here), multiply SE * 1.96 to achieve 95% confidence --->
								&plusmn;#Round(1.96 * pStats.se * 10000)/100#%
							</td>
							<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#dollarFormat(combinationConversionTotal)#<cfelse>NA</cfif></td>
							<td rowspan="#totalGoals#">
								<cfif haveControl AND flat_combination NEQ controlName AND isNumeric(combinationConversionTotal)>
									<cfset valueImprovement = combinationConversionTotal - control.value>
									<span class="<cfif valueImprovement GT 0>green<cfelseif valueImprovement LT 0>red<cfelse>blue</cfif>"><cfif valueImprovement GT 0>+<cfelseif valueImprovement LT 0>-</cfif>#dollarFormat(valueImprovement)#</span>
								<cfelse>
									NA
								</cfif>
							</td>
							<td rowspan="#totalGoals#">
								<cfif haveControl AND flat_combination NEQ controlName AND isNumeric(combinationConversionTotal)>
									<cfset valueImprovement = decimalFormat(((combinationConversionTotal / control.value) - 1) * 100)>
									<span class="<cfif valueImprovement GT 0>green<cfelseif valueImprovement LT 0>red<cfelse>blue</cfif>"><cfif valueImprovement GT 0>+</cfif>#valueImprovement#%</span>
								<cfelse>
									NA
								</cfif>
							</td>
							<td rowspan="#totalGoals#"><cfif isNumeric(combinationConversionTotal)>#dollarFormat(val(combinationConversionTotal) / combinationConversions)#<cfelse>NA</cfif></td>
							<cfif val(totalConversions.total_units) GT 0>
								<td rowspan="#totalGoals#">#val(combinationUnitsTotal)#</td>
								<td rowspan="#totalGoals#"><cfif val(combinationUnitsTotal) GT 0 AND val(combinationConversionTotal) gt 0>#dollarFormat(combinationConversionTotal / combinationUnitsTotal)#<cfelse>NA</cfif></td>
								<td rowspan="#totalGoals#"><cfif val(combinationConversions) GT 0 AND val(combinationUnitsTotal) GT 0>#decimalFormat(combinationUnitsTotal / combinationConversions)#<cfelse>NA</cfif></td>
							</cfif>
						</cfif>

						<td>#conversion_name#</td>
						<td>#total_conversions#</td>
						<td>#decimalFormat(total_conversions / combinationVisitors * 100)#%</td>
						<td><cfif isNumeric(total_value)>#dollarFormat(total_value)#<cfelse>NA</cfif></td>
						<td><cfif isNumeric(total_value)>#dollarFormat(val(total_value) / total_conversions)#<cfelse>NA</cfif></td>
						<cfif val(totalConversions.total_units) GT 0>
							<td>#val(total_units)#</td>
							<td><cfif val(total_units) GT 0 AND isNumeric(total_value)>#dollarFormat(total_value / total_units)#<cfelse>NA</cfif></td>
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

	// awesome info on chi-square: http://www.sagepub.com/upm-data/33663_Chapter4.pdf
	// not yet implemented

	// proability for up to 10 degrees of freedom at 95%, 99%, 99.9% from http://www.unc.edu/~farkouh/usefull/chi.html
	CHISQUARE_DOF_PROBABILITY_05 = [3.84, 5.99, 7.82, 9.49, 11.07, 12.53, 14.07, 15.51, 16.92, 18.31];
	CHISQUARE_DOF_PROBABILITY_01 = [6.64, 9.21, 11.34, 13.28, 15.09, 16.81, 18.48, 20.09, 21.67, 23.21];
	CHISQUARE_DOF_PROBABILITY_001 = [10.83, 13.82, 16.27, 18.47, 20.52, 22.46, 24.32, 26.12, 27.83, 29.59];

	function calculateChiSquareExpected(rowTotal, colTotal, grandTotal)
	{
		return ((rowTotal * colTotal) / grandTotal);
	}

	function calculateChiSquareCell(observed, expected)
	{
		return ((observed - expected)^2 / expected);
	}

	function calculateChiSquareTotal(values)
	{
		return arraySum(listToArray(values));
	}

	// the number of rows (variations (e.g. no degree, AA, BA, BS, MS, PHD)) and the number of cols (goals per variation (e.g., republican, democrat, libertarian, etc))
	function calculateDegreesOfFreedom(rows, cols)
	{
		return ((rows - 1) * (cols - 1));
	}




	// some constants/etc from https://github.com/ryanb/abingo/blob/master/lib/abingo/statistics.rb
	HANDY_Z_SCORE_CHEATSHEET = [[0.10, 1.29], [0.05, 1.65], [0.01, 2.33], [0.001, 3.08]];
	PERCENTAGES = {"0.10" = '90%', "0.05" = '95%', "0.01" = '99%', "0.001" = '99.9%'};
	DESCRIPTION_IN_WORDS = {"0.10" = 'fairly confident', "0.05" = 'confident', "0.01" = 'very confident', "0.001" = 'extremely confident'};

	//http://visualwebsiteoptimizer.com/split-testing-blog/ab-testing-significance-calculator-spreadsheet-in-excel/
	function calculateP(controlVisitors, controlConversions, variationVisitors, variationConversions)
	{
		if(controlConversions > controlVisitors || variationConversions > variationVisitors)
		{
			return {p=0, se=0};
		}

		var controlConvertPercentage = controlConversions / controlVisitors;//=control_conversions/control_visitors
		var variationConvertPercentage = variationConversions / variationVisitors;

		var controlSE = calculateStandardError(controlConvertPercentage, controlVisitors);
		var variationSE = calculateStandardError(variationConvertPercentage, variationVisitors);

		var zScore = calculateZ(controlConvertPercentage, variationConvertPercentage, controlSE, variationSE);

		return
		{
			z = zScore
			,p = NormDist(zScore, 0, 1)
			,se = variationSE
		};
	}

	function calculateZ(controlConvertPercentage, variationConvertPercentage, controlSE, variationSE)
	{
		var denom = sqr((controlSE ^ 2) + (variationSE ^ 2));

		if(denom == 0)
		{
			return 0;
		}

		return (controlConvertPercentage - variationConvertPercentage) / denom;
		//=(control_p-variation_p)/SQRT(POWER(control_se,2)+POWER(variation_se,2))
	}

	function calculateStandardError(convertPercentage, totalVisitors)
	{

		//math: SE = Square root of (p * (1-p) / n)
		//excel: =SQRT((control_p*(1-control_p)/control_visitors))
		return sqr((convertPercentage*(1-convertPercentage)/totalVisitors));
	}

	/**
	 * Calculates the normal distribution for a given mean and standard deviation with cumulative=true
	 * http://www.cflib.org/udf/NormDist
	 *
	 * @param x      Value to compute the cumulative normal distribution for. (Required)
	 * @param mean      Mean value. (Required)
	 * @param sd      Standard deviation. (Required)
	 * @return Returns a number.
	 * @author Rob Ingram (rob.ingram@broadband.co.uk)
	 * @version 1, June 14, 2003
	 */
	function NormDist(x, mean, sd) {
		var res = 0.0;
		var x2 = 0.0;
		var oor2pi = 0.0;
		var t = 0.0;
		var Math = createObject("java", "java.lang.Math");

		x2 = (x - mean) / sd;
		if (x2 eq 0) res = 0.5;
		else
		{
			oor2pi = 1/(sqr(2.0 * Math.PI));
			t = 1 / (1.0 + 0.2316419 * abs(x2));
			t = t * oor2pi * exp(-0.5 * x2 * x2)
			* (0.31938153   + t
			* (-0.356563782 + t
			* (1.781477937  + t
			* (-1.821255978 + t * 1.330274429))));
			if (x2 gte 0)
			{
				res = 1.0 - t;
			}
			else
			{
				res = t;
			}
		}
		return res;
	}


	function isStatisticallySignificant(p) {
		return p <= 0.05;
	}

</cfscript>