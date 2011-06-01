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

<cfproperty name="testConfigurations" type="struct" />
<cfproperty name="testCombinations" type="struct" />
<cfproperty name="gateway" type="any">

<!------------------------------------------- PUBLIC ------------------------------------------->

<!---
TODO:
	batch round robin'ing (i.e. in blocks of 5 or 10 for better performance)
	make percentage variation work
	convert()
	previewing
	Some basic reports
 --->

<cffunction name="init" hint="Constructor" access="public" returntype="Squabble" output="false">
	<cfscript>
		setTestConfigurations({});
		setTestCombinations({});
		setTestVariationPool({});

		setGateway(new SquabbleGateway());

		return this;
	</cfscript>
</cffunction>

<cffunction name="registerTest" hint="Register a multivariate test with the system" access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test. (500 character limit)" type="string" required="Yes">
	<cfargument name="variations" hint="Structure of variations. Should be in the format: { sectionName = [ variationName, variationName, variationName] }. Variation names should not include 'control', as it is a reserved word"
			   	type="struct" required="Yes">
	<cfargument name="conversions" hint="array of names of conversion endpoints" type="array" required="Yes">
	<cfargument name="percentageVisitorTraffic" hint="A percentage from 0 to 100 of the amount of visitor traffic should be included in this test. Defaults to 100 percent"
			   type="numeric" required="No" default="100">
	<cfscript>
		for(var section in arguments.variations)
		{
			ArrayPrepend(arguments.variations[section], "control");
		}

		structInsert(getTestConfigurations(), arguments.testName, arguments);

		//setup the pool
		structInsert(getTestVariationPool(), arguments.testName, 1);

		calculateCombinations(arguments.testName);
	</cfscript>
</cffunction>

<cffunction name="runTest" hint="This method needs to be run before calling 'getCurrentCombination'. It sets up the cookie and variation information for the current user,
									if it doesn't exist."
			access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfscript>
		//escape out if no cookies
		if(!isCookiesEnabled())
		{
			return;
		}

		var idKey = createTestIDCookieKey(arguments.testName);

		//make it easier for testing, as deleting a cookie just makes it an empty string, rather than removing the key.
		if(structKeyExists(cookie, idKey) AND Len(cookie[idkey]))
		{
			return;
		}

		var variationKey = createTestVariationCookieKey(arguments.testName);
		var variation = getNextVariation(arguments.testName);

		var id = getGateway().insertVisitor(arguments.testName, variation);
    </cfscript>

    <!--- if your test is still running in 6 months, something is wrong --->
    <cfcookie name="#idkey#" value="#id#" expires="183">
    <cfcookie name="#variationKey#" value="#serializeJSON(variation)#" expires="183">
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

<cffunction name="getCurrentVisitorID" hint="get the current visitor ID" access="public" returntype="string" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfscript>
		if(!isCookiesEnabled())
		{
			return "";
		}

		return cookie[createTestIDCookieKey(arguments.testName)];
    </cfscript>
</cffunction>

<cffunction name="getCurrentCombination" hint="get the current visitor variation" access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfscript>
		if(!isCookiesEnabled())
		{
			return {};
		}

		return deserializeJSON(cookie[createTestVariationCookieKey(arguments.testName)]);
    </cfscript>
</cffunction>

<cffunction name="isActiveVariation" hint="Convenience method to check if a specific variation is active for the current visitor" access="public" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfargument name="section" hint="the name of the section to check if it is active" type="string" required="Yes">
	<cfargument name="variation" hint="the name of the variation to check if it is active" type="string" required="Yes">
	<cfscript>
		var currentCombination = getCurrentCombination(arguments.testName);

		if(!structKeyExists(currentCombination, arguments.section))
		{
			return false;
		}

		return (currentCombination[arguments.section] == arguments.variation);
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getNextVariation" hint="gets the next variation in the pool for this test" access="private" returntype="struct" output="false">
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
				return getNextVariation(arguments.testName);
			}

			return combinations[index];
        </cfscript>
	</cflock>
</cffunction>

<cffunction name="createTestIDCookieKey" hint="create the key for the cookie, that stores the current users id" access="public" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfreturn "squabble-#hash(arguments.testName)#-id" />
</cffunction>

<cffunction name="createTestVariationCookieKey" hint="create the key for the cookie, that stores the current users variation" access="public" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfreturn "squabble-#hash(arguments.testName)#-v" />
</cffunction>

<cffunction name="calculateCombinations" hint="calculate all the combinations of a given test, into an array that can be looped through." access="public" returntype="void" output="false">
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

		//convert it over to a list, as it's easier for CF to process
		var list = createObject("java", "java.util.ArrayList").init(combinations);

		structInsert(getTestCombinations(), arguments.testName, list);
    </cfscript>
</cffunction>

<cfscript>
	/**
	 * Returns true if browser cookies are enabled.
	 *
	 * @return Returns a boolean.
	 * @author Alex Baban (alexbaban@gmail.com)
	 * @version 1, March 13, 2009
	 */
	private function isCookiesEnabled()
	{
	    return IsBoolean(URLSessionFormat("True"));
	}
</cfscript>

<!--- made this private, as I *really* don't want people touching this --->
<cffunction name="getTestVariationPool" access="private" returntype="struct" output="false">
	<cfreturn instance.testVariationPool />
</cffunction>

<cffunction name="setTestVariationPool" access="private" returntype="void" output="false">
	<cfargument name="testVariationPool" type="struct" required="true">
	<cfset instance.testVariationPool = arguments.testVariationPool />
</cffunction>

</cfcomponent>