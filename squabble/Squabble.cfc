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

<cfcomponent hint="Service Layer for Squabble. To be instantiated on applications start up as a singleton." output="false" accessors="true">

<cfproperty name="testConfigurations" type="struct" hint="The test configurations"/>
<cfproperty name="testCombinations" type="struct" hint="The set of combinations for each test"/>
<cfproperty name="disabledTests" type="struct" hint="List of disabled tests">
<cfproperty name="gateway" type="any" hint="Data access gateway">
<cfproperty name="visitor" type="any" hint="The visitor details">
<cfproperty name="browser" type="any" hint="The browser details">
<cfproperty name="hashRegistry" type="any" hint="hash registry">
<cfproperty name="baseRequestKey" type="string" hint="A unique key for caching in the request scope">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Squabble" output="false">
	<cfargument name="datasource" type="string" required="false" default="squabble" />

	<cfscript>
		setTestConfigurations({});
		setTestCombinations({});
		setTestVariationPool({});
		setDisabledTests({});

		setHashRegistry(new HashRegistry());
		setGateway(new SquabbleGateway(datasource = arguments.datasource));
		setVisitor(new Visitor(getHashRegistry()));
		setBrowser(new util.Browser());

		setBaseRequestKey("squabble-#createUUID()#");

		return this;
	</cfscript>
</cffunction>

<cffunction name="registerTest" hint="Register a multivariate test with the system" access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test. (500 character limit)" type="string" required="Yes">
	<cfargument name="variations" hint="Structure of variations. Should be in the format: { sectionName = [ variationName, variationName, variationName] }. Variation names should not include 'control', as it is a reserved word"
			   	type="struct" required="Yes">
	<cfargument name="percentageVisitorTraffic" hint="A percentage from 0 to 100 of the amount of visitor traffic should be included in this test. Defaults to 100 percent"
			   type="numeric" required="No" default="100">
	<cfargument name="options" hint="extra options to be added with this registration, to be used with other integration points, e.g. google analytics inegration"
			   type="struct" required="no" default="#{}#">
	<cfscript>
		for(var section in arguments.variations)
		{
			ArrayPrepend(arguments.variations[section], "control");
		}

		structInsert(getTestConfigurations(), arguments.testName, arguments);

		//setup the pool
		structInsert(getTestVariationPool(), arguments.testName, 1);

		calculateCombinations(arguments.testName);

		getHashRegistry().registerTest(arguments.testName);
	</cfscript>
</cffunction>

<cffunction name="runTest" hint="This method needs to be run before calling 'getCurrentCombination'. It sets up the cookie and variation information for the current user,
									if it doesn't exist."
			access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfargument name="customVariation" hint="a custom variation to set." type="struct" required="No" default="#structNew()#">
	<cfscript>
		//skip disabled
		if(isTestDisabled(arguments.testname))
		{
			return;
		}

		//skip ignored visitors
		var requestKey = arguments.testName & "-" & getBaseRequestKey();
		if(structKeyExists(request, requestKey))
		{
			//clear any existing combination
			if(getVisitor().hasCombination(arguments.testName))
			{
				getVisitor().clearCombination(arguments.testName);
			}

			return;
		}

		if(getVisitor().hasCombination(arguments.testName))
		{
			//if they have been skipped over.
			if(structIsEmpty(getCurrentCombination(arguments.testName)))
			{
				return;
			}

			if(arrayContains(listTestCombinations(arguments.testName), getCurrentCombination(arguments.testName)))
			{
				return;
			}

			//if the test has been disabled, or if someone has messed with their cookie, give them something new.
			getVisitor().clearCombination(arguments.testName);
		}

		//if it's a crawler, then dump it.
		if(getBrowser().isCrawler())
		{
			return;
		}

		//do percentage of visitor traffic
		if(isVisitorInPercentage(arguments.testName))
		{
			var variation = getNextCombination(arguments.testName);

			if (!structIsEmpty(arguments.customVariation))
			{
				variation = arguments.customVariation;
			}

			var id = getGateway().insertVisitor(arguments.testName, variation);
		}
		else
		{
			//no test is active, so don't place them in the database.
			var variation = {};
			var id = createUUID();
		}

		getVisitor().setCombination(arguments.testName, id, variation);
    </cfscript>
</cffunction>

<cffunction name="listTests" hint="list of all test names registered with squabble." access="public" returntype="array" output="false">
	<cfreturn structKeyArray(getTestConfigurations()) />
</cffunction>

<cffunction name="getTestConfig" hint="get a specific test configuration" access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the configuration for." type="string" required="Yes">
	<cfreturn structFind(getTestConfigurations(), arguments.testname) />
</cffunction>

<cffunction name="listTestCombinations" hint="get all the combinations for all sections and variations for a given test" access="public" returntype="array" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfreturn structFind(getTestCombinations(), arguments.testname) />
</cffunction>

<cffunction name="isActiveVariation" hint="Convenience method to check if a specific variation is active for the current visitor" access="public" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfargument name="section" hint="the name of the section to check if it is active" type="string" required="Yes">
	<cfargument name="variation" hint="the name of the variation to check if it is active" type="string" required="Yes">
	<cfscript>
		//if disabled, or not there at all, then control is always active.
		if(isTestDisabled(arguments.testname) || !getVisitor().hasCombination(arguments.testName))
		{
			return arguments.variation eq "control";
		}

		var currentCombination = getCurrentCombination(arguments.testName);

		if(!structKeyExists(currentCombination, arguments.section))
		{
			return false;
		}

		return (currentCombination[arguments.section] == arguments.variation);
    </cfscript>
</cffunction>

<cffunction name="convert" hint="Track a conversion for the current visitor" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to track the conversion for." type="string" required="Yes">
	<cfargument name="name" hint="The name/type of this conversion" type="string" required="false" default="The name of this conversion">
	<cfargument name="value" hint="The value to record for this conversion" type="string" required="false" default="">
	<cfargument name="units" hint="The unit amount to record for this conversion" type="string" required="false" default="">
	<cfargument name="tags" hint="An structure of key value pairs to tag the conversion. Key is the name, value is the value" type="struct" required="false" default="#{}#">
	<cfscript>
		//if for whatever reason they don't have an id, ignore them.
		if(!getVisitor().hasCombination(arguments.testName))
		{
			return;
		}

		//if the test is disabled, ignore them
		if(isTestDisabled(arguments.testname))
		{
			return;
		}

		//or if they have been skipped over.
		if(structIsEmpty(getCurrentCombination(arguments.testName)))
		{
			return;
		}

		var conversionID = getGateway().insertConversion(getCurrentVisitorID(arguments.testname), arguments.name, arguments.value, arguments.units);

		for(var key in arguments.tags)
		{
			getGateway().insertConversionTag(conversionID, key, arguments.tags[key]);
		}
	</cfscript>
</cffunction>

<cffunction name="convertAll" hint="Track a conversion for all registered tests" access="public" returntype="void" output="false">
	<cfargument name="name" hint="The name/type of this conversion" type="string" required="false" default="The name of this conversion">
	<cfargument name="value" hint="The value to record for this conversion" type="string" required="false" default="">
	<cfargument name="units" hint="The unit amount to record for this conversion" type="string" required="false" default="">
	<cfargument name="tags" hint="An structure of key value pairs to tag the conversion. Key is the name, value is the value" type="struct" required="false" default="#{}#">
	<cfscript>
		var registeredTests = listTests();
		var registeredTestCount = arrayLen(registeredTests);
		var i = 1;

		for (i; i <= registeredTestCount; i++)
		{
			convert(registeredTests[i], arguments.name, arguments.value, arguments.units, arguments.tags);
		}
	</cfscript>
</cffunction>

<cffunction name="disableTest" hint="A quick and easy way to disable a test without having to go and remove all the aspects of the test from your application"
			access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to disable." type="string" required="Yes">
	<cfscript>
		getDisabledTests()[arguments.testname] = 1;
    </cfscript>
</cffunction>

<cffunction name="isTestDisabled" hint="Whether or not a given test is disabled" access="public" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test potentially disabled." type="string" required="Yes">
	<cfreturn structKeyExists(getDisabledTests(), arguments.testName) />
</cffunction>

<cffunction name="removeCombination" hint="If you want to remove a combination from the generated list. Handy if you want to remove it from the test altoghether, or for removing poorly performing combinations."
			access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to remove the combination from." type="string" required="Yes">
	<cfargument name="combination" hint="the struct that represents the combination. Key is the section, value is the variation." type="struct" required="Yes">
	<cfscript>
		var combos = listTestCombinations(arguments.testName);

		arrayDelete(combos, arguments.combination);
    </cfscript>
</cffunction>

<cffunction name="getCurrentVisitorID" hint="get the current visitor ID" access="public" returntype="string" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfscript>
		if(isTestDisabled(arguments.testname))
		{
			return "";
		}

		if(getVisitor().hasCombination(arguments.testName))
		{
			return getVisitor().getID(arguments.testName);
		}

		return "";
    </cfscript>
</cffunction>

<cffunction name="getCurrentCombination" hint="get the current visitor combination. If an inactive visitor, returns an empty struct." access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfscript>
		if(isTestDisabled(arguments.testname))
		{
			return {};
		}

		if(getVisitor().hasCombination(arguments.testName))
		{
			return getVisitor().getCombination(arguments.testName);
		}

		return {};
    </cfscript>
</cffunction>

<cffunction name="ignoreVisitor" hint="ignores a specific visitor for a test" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to for which the visitor will be ignored" type="string" required="Yes">
	<cfscript>
		var requestKey = arguments.testname & "-" & getBaseRequestKey();

		request[requestKey] = true;
    </cfscript>
</cffunction>

<cffunction name="tagVisitor" hint="Apply an arbitrary tag(s) to this visitor to track custom meta data against them" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to for which the visitor will be tagged" type="string" required="Yes">
	<cfargument name="tag" hint="a string, list or array of values to tag against the visitor" type="any" required="Yes">
	<cfscript>
		var id = getCurrentVisitorID(arguments.testName);

		//if we have no id, then don't do anything
		if(Len(id) == 0)
		{
			return;
		}

		//if for whatever reason they don't have a combo, ignore them.
		if(!getVisitor().hasCombination(arguments.testName))
		{
			return;
		}

		//or if they have been skipped over.
		if(structIsEmpty(getCurrentCombination(arguments.testName)))
		{
			return;
		}

		if(isSimpleValue(arguments.tag))
		{
			arguments.tag = listToArray(arguments.tag);
		}

		var currentTags = getVisitorTags(arguments.testName, arguments.tag);

		for(var item in arguments.tag)
		{
			if(!arrayContains(currentTags, item))
			{
				getGateway().insertVisitorTag(id, item);
			}
		}
    </cfscript>
</cffunction>

<cffunction name="tagVisitorAll" hint="Track a conversion for all registered tests" access="public" returntype="void" output="false">
	<cfargument name="tag" hint="a string, list or array of values to tag against the visitor" type="any" required="Yes">
	<cfscript>
		for (var test in listTests())
		{
			tagVisitor(test, arguments.tag);
		}
	</cfscript>
</cffunction>

<cffunction name="getVisitorTags" hint="get all, or some of the visitor tags" access="public" returntype="array" output="false">
	<cfargument name="testname" hint="the name of the test to for which the visitor will be tagged" type="string" required="Yes">
	<cfargument name="filter" hint="a string, list or array of tags specifically look for against the visitor" type="any" required="no" default="#[]#">
	<cfscript>
		var id = getCurrentVisitorID(arguments.testName);
		var tags = [];

		if(Len(id) == 0)
		{
			return tags;
		}

		var tagsQuery = getGateway().getVisitorTags(id, arguments.filter);
    </cfscript>
    <cfloop query="tagsQuery">
		<cfset arrayAppend(tags, tagsQuery.tag_value)>
    </cfloop>

    <cfreturn tags />
</cffunction>

<cffunction name="removeUnlistedCookies" hint="Remove squabble cookie (a cookie starting with 's-') that doesn't have a test registered with it.
			This does not remove disabled tests. Useful if you want to be aggressive on cookie cleanup."
			access="public" returntype="void" output="false">
	<cfscript>
		getVisitor().removeUnlistedCookies();
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="isVisitorInPercentage" hint="is the new visitor within the current percentage of visitors for this test" access="private" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test" type="string" required="Yes">
	<cfscript>
		var config = getTestConfig(arguments.testname);

		if(config.percentageVisitorTraffic == 100)
		{
			return true;
		}

		return (config.percentageVisitorTraffic >= randRange(1, 100));
    </cfscript>
</cffunction>

<cffunction name="getNextCombination" hint="gets the next combination of variations in the pool for this test" access="private" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the variation for." type="string" required="Yes">
	<cflock timeout="30" name="squabble.getNextVariation.#arguments.testname#">
		<cfscript>
			var pool = getTestVariationPool();
			var index = pool[arguments.testname]++;
			var combinations = listTestCombinations(arguments.testName);

			if(index > ArrayLen(combinations))
			{
				pool[arguments.testname] = 1;
				//go back around
				return getNextCombination(arguments.testName);
			}

			return combinations[index];
        </cfscript>
	</cflock>
</cffunction>

<cffunction name="calculateCombinations" hint="calculate all the combinations of a given test, into an array that can be looped through." access="private" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfscript>
		var config = getTestConfig(arguments.testName).variations;

		//use a set, so we are always sure not to get duplicates
		var combinations = createObject("java", "java.util.LinkedHashSet").init();
		var counter = 1;

		for(var section in config)
		{
			//start off the sections
			if(counter == 1)
			{
				var variations = config[section];
				for(var variation in variations)
				{
					var combination = {};
					combination[section] = variation;
					combinations.add(combination);
				}
			}
			else //now go deep into the sections
			{
					//start a new one, as we apply new combinations downwards
					var newCombinations = createObject("java", "java.util.LinkedHashSet").init();
					var iterator = combinations.iterator();
					while(iterator.hasNext())
					{
						var combination = iterator.next();
						var variations = config[section];

						for(var variation in variations)
						{
							//use copies, as otherwise you are just changing the original reference
							var newCombination = StructCopy(combination);
							newCombination[section] = variation;
							newCombinations.add(newCombination);
						}
					}

					combinations = newCombinations;
			}

			counter++;
		}

		//convert it over to a list, as it's easier for CF to process, and it passes by reference.
		var list = createObject("java", "java.util.ArrayList").init(combinations);

		structInsert(getTestCombinations(), arguments.testName, list);
    </cfscript>
</cffunction>

<!--- made this private, as I *really* don't want people touching this --->
<cffunction name="getTestVariationPool" access="private" returntype="struct" output="false">
	<cfreturn instance.testVariationPool />
</cffunction>

<cffunction name="setTestVariationPool" access="private" returntype="void" output="false">
	<cfargument name="testVariationPool" type="struct" required="true">
	<cfset instance.testVariationPool = arguments.testVariationPool />
</cffunction>

</cfcomponent>
