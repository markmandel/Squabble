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

<cfif thisTag.executionMode eq "end">
	<cfexit method="exittag" >
</cfif>

<cfparam name="attributes.squabble" type="any" default="" />

<!--- If the Squabble service is passed in, use it... --->
<cfif !isObject(attributes.squabble)>
	<!--- otherwise, it is expected to exist as the "squabble" key in the application scope. --->
	<cfset attributes.squabble = application.squabble />
</cfif>

<!--- Whether or not to wrap the javascript snippet in script tags --->
<cfparam name="attributes.writeScriptTags" type="boolean" default="true">

<!--- the name of the array queue to use. Defaults to _gaq --->
<cfparam name="attributes.gaQueue" type="string" default="_gaq">

<!--- The index for the google custom variable to use. Defaults to 1. --->
<cfparam name="attributes.customVariableIndex" type="numeric" default="1">

<!--- The custom variables scope to use. Defaults to Visitor (1) --->
<cfparam name="attributes.customVariableScope" type="numeric" default="1">

<!--- The tests to track. Defaults to all of them. It may be useful to specify this if you have multiple tests running. --->
<cfparam name="attributes.activeTests" type="array" default="#attributes.squabble.listTests()#">

<cfif arrayIsEmpty(attributes.activeTests)>
	<cfexit method="exittag" >
</cfif>

<cfscript>
	value = createObject("java", "java.lang.StringBuilder").init();
	js = createObject("java", "java.lang.StringBuilder").init();
	setValue = false;

	if(attributes.writeScriptTags)
	{
		js.append('<script type="text/javascript">');
	}

	js.append("window.#attributes.gaQueue# = window.#attributes.gaQueue# || [];");
</cfscript>

<cfloop array="#attributes.activeTests#" index="test">
	<cfscript>
		value.setLength(0); //clear it and start again.

		combo = attributes.squabble.getCurrentCombination(test);

		if(!structIsEmpty(combo))
		{
			setValue = true;

			sortedKeys = StructKeyArray(combo);
			ArraySort(sortedKeys, "textnocase");

			counter = 1;
			for(key in sortedKeys)
			{
				if(counter++ > 1)
				{
					value.append(", ");
				}
				value.append("#key#:#combo[key]#");
			}

			test = jsStringFormat(test);

			js.append("#attributes.gaQueue#.push(['_setCustomVar', #attributes.customVariableIndex#, '#test#', '#jsStringFormat(value.toString())#', #attributes.customVariableScope#]);");
			js.append("#attributes.gaQueue#.push(['_trackEvent', 'Squabble', 'Test: #test#']);");
		}
	</cfscript>
</cfloop>

<cfscript>
	//if we haven't done anything, display nothing
	if(!setValue)
	{
		js.setLength(0);
	}
	else if(attributes.writeScriptTags)
	{
		js.append('</script>');
	}
</cfscript>

</cfsilent><cfoutput>#js.toString()#</cfoutput>