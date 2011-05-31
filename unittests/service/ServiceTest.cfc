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

<cfimport path="squabble.*">

<cfcomponent extends="unittests.AbstractTestCase" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setup" hint="setup" access="public" returntype="void" output="false">
	<cfscript>
		service = new Squabble();
		//useful to have a default config
		testConfig =
			{
				fooSection = [ "test1", "test2", "test3" ]
				,barSection = [ "test4", "test5", "test6" ]
			};

		conversionConfigs = ["conversion1", "conversion2"];
    </cfscript>
</cffunction>

<cffunction name="registerTestTest" hint="test registering tests (yes, I had as much fun writing that as you did reading it)" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig, conversionConfigs, 99);

		var expected = {
			testname = "foo"
			,variations = testConfig
			,conversions = conversionConfigs
			,percentageVisitorTraffic = 99
		};

		//use underlying equals, as built in assertEquals is not great for structs.
		assertTrue(expected.equals(service.getTestConfigurations().foo));
    </cfscript>
</cffunction>

<cffunction name="testListTests" hint="testing list tests" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig, conversionConfigs, 99);
		service.registerTest("bar", testConfig, conversionConfigs);
		service.registerTest("yerk", testConfig, conversionConfigs);

		var expected = ["foo", "bar", "yerk"];

		assertArrayEqualsNonOrdered(expected, service.listTests());
	</cfscript>
</cffunction>

<cffunction name="testGetTestConfig" hint="testing getting test config" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig, conversionConfigs, 99);

		var expected = {
			testname = "foo"
			,variations = testConfig
			,conversions = conversionConfigs
			,percentageVisitorTraffic = 99
		};

		//use underlying equals, as built in assertEquals is not great for structs.
		assertTrue(expected.equals(service.getTestConfig("foo")));
	</cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>