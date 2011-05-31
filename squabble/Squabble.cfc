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

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Squabble" output="false">
	<cfscript>
		setTestConfigurations({});
		setTestCombinations({});

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

		calculateCombinations(arguments.testName);
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

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

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

</cfcomponent>