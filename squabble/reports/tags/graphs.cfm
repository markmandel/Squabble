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
	<!--[if lt IE 9]><script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/excanvas/r3/excanvas.js"></script><![endif]-->
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jquery/1.9.1/jquery-1.9.1.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/jquery.jqplot.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.dateAxisRenderer.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.canvasTextRenderer.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.canvasAxisLabelRenderer.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.cursor.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.highlighter.min.js"></script>
	<script language="javascript" type="text/javascript" src="//cdn.jsdelivr.net/jqplot/1.0.8/plugins/jqplot.enhancedLegendRenderer.min.js"></script>
	<link rel="stylesheet" type="text/css" href="//cdn.jsdelivr.net/jqplot/1.0.8/jquery.jqplot.css" />
</cfsavecontent>
<cfhtmlhead text="#js#" >

<cfscript>
	visitors = application.report.getCombinationTotalVisitors(attributes.testName, "hour");
	conversions = application.report.getCombinationTotalConversions(attributes.testName, "hour");

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


</cfsilent>

<cfoutput>
<h2>Graphs</h2>

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
				<cfif i++ neq 1>,</cfif>["#DateFormat(item.date, 'dd mmm yyyy')# #item.hour#:00", #item.conversionTotal#]
				</cfloop>
			];
		</cfloop>

		options.axes.yaxis.label = "Conversion Total";
		convTotal = $.jqplot('conversionTotal', [#vars#], options);

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

<h3>Conversion Total Per Hour</h3>
<div id="conversionTotal" ></div>
<div><button value="reset" type="button" onclick="convTotal.resetZoom();">Zoom Out</button></div>

<h3>Value Total Per Hour</h3>

<div id="value" ></div>
<div><button value="reset" type="button" onclick="values.resetZoom();">Zoom Out</button></div>

<h3>Unit Total Per Hour</h3>

<div id="units" ></div>
<div><button value="reset" type="button" onclick="units.resetZoom();">Zoom Out</button></div>