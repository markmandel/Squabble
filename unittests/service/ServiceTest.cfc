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
    </cfscript>
</cffunction>

<cffunction name="registerTestTest" hint="test registering tests (yes, I had as much fun writing that as you did reading it)" access="public" returntype="void" output="false">
	<cfscript>
		var expected = {
			testname = "foo"
			,variations = StructCopy(testConfig)
			,percentageVisitorTraffic = 99
			,options = {}
		};

		//add in control
		ArrayPrepend(expected.variations.barSection, "control");
		ArrayPrepend(expected.variations.fooSection, "control");

		service.registerTest("foo", testConfig, 99);

		//use underlying equals, as built in assertEquals is not great for structs.
		assertTrue(expected.equals(service.getTestConfigurations().foo));
    </cfscript>
</cffunction>

<cffunction name="testListTests" hint="testing list tests" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig, 99);
		service.registerTest("bar", testConfig);
		service.registerTest("yerk", testConfig);

		var expected = ["foo", "bar", "yerk"];

		assertArrayEqualsNonOrdered(expected, service.listTests());
	</cfscript>
</cffunction>

<cffunction name="testGetTestConfig" hint="testing getting test config" access="public" returntype="void" output="false">
	<cfscript>
		var expected = {
			testname = "foo"
			,variations = StructCopy(testConfig)
			,percentageVisitorTraffic = 99
			,options={}
		};

		//add in control
		ArrayPrepend(expected.variations.barSection, "control");
		ArrayPrepend(expected.variations.fooSection, "control");

		service.registerTest("foo", testConfig, 99);

		//use underlying equals, as built in assertEquals is not great for structs.
		assertTrue(expected.equals(service.getTestConfig("foo")));
	</cfscript>
</cffunction>

<cffunction name="testCombinations" hint="test all the combinations are accounted for" access="public" returntype="void" output="false">
	<cfscript>
		//test the number of combinations are right, and that they are all different, therefore they will all be there.


		//test 1 levels
		var myTestConfig = duplicate(testConfig);
		StructDelete(myTestConfig, "fooSection");

		service.registerTest("bar", myTestConfig);
		var combinations = service.listTestCombinations("bar");

		var comboNumber = 4; //control +1
		assertEquals(comboNumber, ArrayLen(combinations));

		//sort by natural order, makes checking for duplicates easy.
		textCombinations = convertCombinationsToStrings(combinations);
		ArraySort(textCombinations, "text" );

		var len = ArrayLen(combinations);

        for(var counter=2; counter <= len; counter++)
        {
        	var combo = textCombinations[local.counter];
        	var previous = textCombinations[local.counter - 1];

        	if(combo.equals(previous))
        	{
        		debug(combinations);
        		debug(textCombinations);
        		fail("Two combinations are the same!");

        	}
        }


		//test 2 levels next
		service.registerTest("foo", duplicate(testConfig), 99);
		var combinations = service.listTestCombinations("foo");

		debug(combinations);

		var comboNumber = 4 * 4; //control +1
		assertEquals(comboNumber, ArrayLen(combinations));

		//sort by natural order, makes checking for duplicates easy.
		textCombinations = convertCombinationsToStrings(combinations);
		ArraySort(textCombinations, "text" );

		var len = ArrayLen(combinations);

        for(var counter=2; counter <= len; counter++)
        {
        	var combo = textCombinations[local.counter];
        	var previous = textCombinations[local.counter - 1];

        	if(combo.equals(previous))
        	{
        		debug(combinations);
        		debug(textCombinations);
        		fail("Two combinations are the same!");
        	}
        }

		//let's do 3 levels next.
		myTestConfig = duplicate(testConfig);
		myTestConfig.gandalf = [ "test7", "test8", "test9", "test10" ];

		service.registerTest("gandalf", myTestConfig);

		var combinations = service.listTestCombinations("gandalf");


		var comboNumber = 4 * 4 * 5; //control +1
		assertEquals(comboNumber, ArrayLen(combinations));

		//sort by natural order, makes checking for duplicates easy.
		textCombinations = convertCombinationsToStrings(combinations);
		ArraySort(textCombinations, "text" );

		var len = ArrayLen(combinations);
        for(var counter=2; counter <= len; counter++)
        {
        	var combo = textCombinations[local.counter];
        	var previous = textCombinations[local.counter - 1];

        	if(combo.equals(previous))
        	{
        		debug(combinations);
        		debug(textCombinations);
        		fail("Two combinations are the same!");
        	}
        }
    </cfscript>
</cffunction>

<cffunction name="testDefaultRunTest" hint="test running a given test. (integration test)" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			service.registerTest("foo", testConfig);

			var previousID = "";
			var previousVar = "";
			var mod16 = "";

			for(var counter = 1; counter lte 100; counter++)
			{
				clearSquabbleCookies();

				service.runTest("foo");

				assertNotEquals(service.getCurrentVisitorID("foo"), previousID, "Counter: #counter#");
				assertNotEquals(service.getCurrentCombination("foo"), previousID, "Counter: #counter#");

				previousID = service.getCurrentVisitorID("foo");
				previousVar = service.getCurrentCombination("foo");

				//should loop around every 16, as that is how many variations there are
				if(counter == 1)
				{
					mod16 = previousVar;
				}
				else if((counter - 1) % 16 == 0) //every 16th + 1, since not index of 0
				{
					assertTrue(mod16.equals(previousVar));
				}
			}
	    </cfscript>
    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testIsActiveVariation" hint="test running a given test. (integration test)" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);

			service.runTest("foo");

			//we know control,control should come first
			assertTrue(service.isActiveVariation("foo", "fooSection", "control"));
			assertTrue(service.isActiveVariation("foo", "barSection", "control"));

			//get out of the control section
			for(var counter = 1; counter <= 5; counter++)
			{
				clearSquabbleCookies();
				service.runTest("foo");
			}

			//should be after control, so these should be false
			assertFalse(service.isActiveVariation("foo", "fooSection", "control"));
			assertFalse(service.isActiveVariation("foo", "barSection", "control"));
	    </cfscript>
    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testIsActiveVariationonDisabledTest" hint="test that the active variation always comes back false, if it" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.disableTest("foo");

			service.runTest("foo");

			//control should always be true
			assertTrue(service.isActiveVariation("foo", "fooSection", "control"));
			assertTrue(service.isActiveVariation("foo", "barSection", "control"));

			//get out of the control section
			for(var counter = 1; counter <= 5; counter++)
			{
				clearSquabbleCookies();
				service.runTest("foo");
			}

			//control should always be true
			assertTrue(service.isActiveVariation("foo", "fooSection", "control"));
			assertTrue(service.isActiveVariation("foo", "barSection", "control"));

			//something else shoudl be false
			assertFalse(service.isActiveVariation("foo", "fooSection", "test2"));
			assertFalse(service.isActiveVariation("foo", "barSection", "test5"));
	    </cfscript>
    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testRunVisitorInsertionTest" hint="Ensure the runTest methods correctly inserts the visitor to the database" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			var visitorID = service.getCurrentVisitorID("foo");
			var combinations = service.getCurrentCombination("foo");

			var visitorQuery = service.getGateway().getVisitor(visitorID);
			assertEquals(1, visitorQuery.recordcount);

			var variationsQuery = service.getGateway().getVisitorCombinations(visitorID);
			assertEquals(2, variationsQuery.recordcount);
	    </cfscript>
	    <cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="convertTest" hint="Ensures the convert method correctly inserts a conversion record" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			service.convert("foo", "PayPal Checkout", 12);

			var conversion = service.getGateway().getVisitorConversions(service.getCurrentVisitorID("foo"));

			assertEquals(1, conversion.recordcount);
			assertEquals("PayPal Checkout", conversion.conversion_name);
			assertEquals(12, conversion.conversion_value);
	    </cfscript>
	    <cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="convertNoRunTest" hint="Clear everything, and run convert. It should not throw an error" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();
			service.registerTest("foo", testConfig);

			service.convert("foo", "PayPal Checkout", 12);

			var conversion = service.getGateway().getVisitorConversions(service.getCurrentVisitorID("foo"));

			assertEquals(0, conversion.recordcount);
	    </cfscript>
	    <cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="convertAllTest" hint="Ensures the convert method correctly inserts a conversion record for all active tests" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			// Register 3 tests and disable one of them
			service.registerTest("bart", testConfig);
			service.registerTest("lisa", testConfig);
			service.registerTest("maggie", testConfig);
			service.disableTest("lisa");

			// Run all 3 tests (although only 2 will actually run as 'lisa' is disabled)
			service.runTest("bart");
			service.runTest("lisa");
			service.runTest("maggie");

			// Convert for all tests
			service.convertAll("Simpsons Checkout", 12, 5);

			var bartConversions = service.getGateway().getVisitorConversions(service.getCurrentVisitorID("bart"));

			assertEquals(1, bartConversions.recordcount);
			assertEquals(0, service.getGateway().getVisitorConversions(service.getCurrentVisitorID("lisa")).recordcount);
			assertEquals(1, service.getGateway().getVisitorConversions(service.getCurrentVisitorID("maggie")).recordcount);

			assertEquals("Simpsons Checkout", bartConversions.conversion_name);
			assertEquals(12, bartConversions.conversion_value);
			assertEquals(5, bartConversions.conversion_units);
	    </cfscript>
	    <cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testPercentageVisitors" hint="test for percentage of visitors" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			service.registerTest("foo", testConfig, "50");
			var active = 0;
			var inactive = 0;

			for(var counter = 1; counter lte 1000; counter++)
			{
				clearSquabbleCookies();
				service.runTest("foo");

				if(structIsEmpty(service.getCurrentCombination("foo")))
				{
					inactive++;
				}
				else
				{
					active++;
				}
			}

			//to test, let's round up to the nearest 100 to make sure this is about accurate enough.
			active /= 100;
			inactive /= 100;

			assertEquals(Round(active), Round(inactive));

			debug(active); debug(inactive);
	    </cfscript>
    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="cookielessConversionTest" hint="test for percentage of visitors" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);

			// Try a conversion before running before even running a test (there should be no error thrown)
			service.convert("foo", "Checkout");

			service.runTest("foo");

			// Get a visitor
			var visitorID = service.getCurrentVisitorID("foo");

			// Clear the visitor's cookies
			clearSquabbleCookies();

			// Try and Record a conversion for the visitor
			service.convert("foo", "User Viewed About Page");

			// Get all conversions for this visitor
			var conversion = service.getGateway().getVisitorConversions(visitorID);

			// Visitor should have no conversions (as they had no cookies)
			assertEquals(0, conversion.recordcount);
	    </cfscript>
    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="crawlerTest" hint="test that a crawler will not cause a visitor" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			var testName = createUUID();

			//mock out browser
			var browser = mock(service.getBrowser());

			browser.isCrawler().returns(true);
			service.setBrowser(browser);

			service.registerTest(testName, testConfig);
			service.runTest(testName);

			//make sure asking for a conversion doesn't break, should return an empty struct
			assertEquals("", service.getCurrentVisitorID(testName));
			assertTrue(structIsEmpty(service.getCurrentCombination(testName)));
	    </cfscript>

	    <cfquery name="local.count">
			select count(id) as total
			from
			squabble_visitors
			where
			test_name = <cfqueryparam value="#testName#" cfsqltype="cf_sql_varchar">
		</cfquery>

		<cfscript>
			assertEquals(0, count.total);
        </cfscript>

    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testDisabled" hint="test disabled" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
				clearSquabbleCookies();

				var visitors = service.getGateway().getTotalVisitors("foo");
				var conversion = service.getGateway().getVisitorConversions("foo");

				service.registerTest("foo", testConfig);
				assertFalse(service.isTestDisabled("foo"));

				service.disableTest("foo");
				assertTrue(service.isTestDisabled("foo"));

				service.runTest("foo");
				service.convert("foo", "PayPal Checkout");

				assertEquals(visitors, service.getGateway().getTotalVisitors("foo"));
				assertEquals(conversion, service.getGateway().getVisitorConversions("foo"));
        </cfscript>

		<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="testListTestCombinations" hint="test listing all combinations" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig);
		var combos = service.listTestCombinations("foo");
		debug(combos);
		//4x4
		assertEquals(16, ArrayLen(combos));

		//easy way to make sure they are all different.
		var set = createObject("java", "java.util.HashSet").init(combos);

		assertEquals(16, set.size());
    </cfscript>
</cffunction>

<cffunction name="testRemoveCombination" hint="test removal of a combination" access="public" returntype="void" output="false">
	<cfscript>
		service.registerTest("foo", testConfig);
		var combos = service.listTestCombinations("foo");
		debug(combos);

		//gate
		assertEquals(16, ArrayLen(combos));

		service.removeCombination("foo", {barsection="test5", foosection="test2"});

		var combos = service.listTestCombinations("foo");

		debug(combos);

		assertEquals(15, ArrayLen(combos));

		for(var combo in combos)
		{
			if(combo.barsection eq "test5" && combo.foosection eq "test2")
			{
				fail("bar: Test5, foo: test2 still exists!");
			}
		}
	</cfscript>
</cffunction>

<cffunction name="testResetDisabledCombination" hint="test that a combination that has already been set, gets reset after it gets disabled"
			access="public" returntype="void" output="false">
	<cfscript>
		clearSquabbleCookies();
		service.registerTest("foo", testConfig);

		//make sure it's not on control
		service.runTest("foo");
		clearSquabbleCookies();
		service.runTest("foo");
		clearSquabbleCookies();
		service.runTest("foo");

		var combos = service.listTestCombinations("foo");
		combos = duplicate(combos);

		debug(service.getCurrentCombination("foo"));

		var combo = {barsection="test5", foosection="control"};

		assertEquals(combo, service.getCurrentCombination("foo"));

		service.removeCombination("foo", combo);

		var reget = service.listTestCombinations("foo");

		//make sure remove works
		assertNotEquals(reget, combos);

		service.runTest("foo");

		assertNotEquals(combo, service.getCurrentCombination("foo"));
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="convertCombinationsToStrings" hint="" access="private" returntype="array" output="false">
	<cfargument name="combinations" hint="array of combos" type="array" required="Yes">
	<cfscript>
		var newCombos = [];

		for(var item in arguments.combinations)
		{
			string = "";
			for(var key in item)
			{
				string = listAppend(string,key);
				string = listAppend(string,item[key]);
			}
			arrayAppend(newCombos, string);
		}

		return newCombos;
    </cfscript>
</cffunction>

</cfcomponent>