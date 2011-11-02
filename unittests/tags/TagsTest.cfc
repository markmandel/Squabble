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
		gateway = new SquabbleGateway();

		//useful to have a default config
		testConfig =
			{
				fooSection = [ "test1", "test2", "test3" ]
				,barSection = [ "test4", "test5", "test6" ]
			};
    </cfscript>
</cffunction>

<cffunction name="sectionContentTest" hint="test whether the expected section content is returned" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			var currentCombination = service.getCurrentCombination("foo");
			var fooSectionVariation = currentCombination["fooSection"];
			var barSectionVariation = currentCombination["barSection"];

			var expectedFooContent = fooSectionVariation & " content";
			var expectedBarContent = barSectionVariation & " content";

			var fooContent = "";
			var barContent = "";
		</cfscript>

		<cfimport prefix="squabble" taglib="/squabble/tags" />

		<cfsavecontent variable="fooContent">
			<squabble:test name="foo" squabble="#service#">
				<squabble:section name="fooSection">
					<squabble:control>control content</squabble:control>
					<squabble:variation name="test1">test1 content</squabble:variation>
					<squabble:variation name="test2">test2 content</squabble:variation>
					<squabble:variation name="test3">test3 content</squabble:variation>
				</squabble:section>
			</squabble:test>
		</cfsavecontent>

		<cfsavecontent variable="barContent">
			<squabble:test name="foo" squabble="#service#">
				<squabble:section name="barSection">
					<squabble:control>control content</squabble:control>
					<squabble:variation name="test4">test4 content</squabble:variation>
					<squabble:variation name="test5">test5 content</squabble:variation>
					<squabble:variation name="test6">test6 content</squabble:variation>
				</squabble:section>
			</squabble:test>
		</cfsavecontent>

		<cfset assertEquals(expectedFooContent, trim(fooContent)) />
		<cfset assertEquals(expectedBarContent, trim(barContent)) />

    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="noSectionTest" hint="test tag functionality for a user whose cookie is missing a test section" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			//mock out the response we want
			var visitor = mock(service.getVisitor());

			visitor.isEnabled().returns(true);
			visitor.hasCombination("foo").returns(true);
			visitor.getCombination().returns({ barSection = "test4" });
			service.setVisitor(visitor);

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			var expectedFooContent = "control content";
			var fooContent = "";
		</cfscript>

		<cfimport prefix="squabble" taglib="/squabble/tags" />

		<cfsavecontent variable="fooContent">
			<squabble:test name="foo" squabble="#service#">
				<squabble:section name="fooSection">
					<squabble:control>control content</squabble:control>
					<squabble:variation name="test1">test1 content</squabble:variation>
					<squabble:variation name="test2">test2 content</squabble:variation>
					<squabble:variation name="test3">test3 content</squabble:variation>
				</squabble:section>
			</squabble:test>
		</cfsavecontent>

		<cfset assertEquals(expectedFooContent, trim(fooContent)) />

    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="conversionTest" hint="test convert tag functionality" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			var visitorID = service.getCurrentVisitorID("foo");
		</cfscript>

		<cfimport prefix="squabble" taglib="/squabble/tags" />

		<squabble:convert test="foo" name="conversion1" squabble="#service#" />

		<cfset var conversions = gateway.getVisitorConversions(visitorID) />

		<cfset assertTrue(conversions.recordcount eq 1) />
		<cfset assertEquals(visitorID, conversions.visitor_id) />
		<cfset assertEquals("conversion1", conversions.conversion_name) />

		<cfimport prefix="squabble" taglib="/squabble/tags" />

		<squabble:convert test="foo" name="conversion1" squabble="#service#" />
		<squabble:convert test="foo" name="conversion2" squabble="#service#" />

		<cfset conversions = gateway.getVisitorConversions(visitorID) />

		<cfset assertTrue(conversions.recordcount eq 3) />
		<cfset assertEquals(visitorID, conversions.visitor_id[1]) />
		<cfset assertEquals("conversion1", conversions.conversion_name[1]) />
		<cfset assertEquals(visitorID, conversions.visitor_id[2]) />
		<cfset assertEquals("conversion1", conversions.conversion_name[2]) />
		<cfset assertEquals(visitorID, conversions.visitor_id[3]) />
		<cfset assertEquals("conversion2", conversions.conversion_name[3]) />

    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="conversionRevenueTest" hint="test convert tag functionality" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig);
			service.runTest("foo");

			var visitorID = service.getCurrentVisitorID("foo");
		</cfscript>

		<cfimport prefix="squabble" taglib="/squabble/tags" />

		<squabble:convert test="foo" name="conversion1" value="12.34" squabble="#service#" />

		<cfset var conversions = gateway.getVisitorConversions(visitorID) />

		<cfset assertTrue(conversions.recordcount eq 1) />
		<cfset assertEquals(visitorID, conversions.visitor_id) />
		<cfset assertEquals("conversion1", conversions.conversion_name) />
		<cfset assertEquals("12.34", conversions.conversion_value) />

		<squabble:convert test="foo" name="conversion1" value="5" squabble="#service#" />
		<squabble:convert test="foo" name="conversion2" value="1000" units="84" squabble="#service#" />

		<cfset conversions = gateway.getVisitorConversions(visitorID) />

		<cfset assertTrue(conversions.recordcount eq 3) />
		<cfset assertEquals(visitorID, conversions.visitor_id[1]) />
		<cfset assertEquals("conversion1", conversions.conversion_name[1]) />
		<cfset assertEquals("12.34", conversions.conversion_value[1]) />
		<cfset assertEquals(visitorID, conversions.visitor_id[2]) />
		<cfset assertEquals("conversion1", conversions.conversion_name[2]) />
		<cfset assertEquals("5", conversions.conversion_value[2]) />
		<cfset assertEquals("", conversions.conversion_units[2]) />
		<cfset assertEquals(visitorID, conversions.visitor_id[3]) />
		<cfset assertEquals("conversion2", conversions.conversion_name[3]) />
		<cfset assertEquals("1000", conversions.conversion_value[3]) />
		<cfset assertEquals("84", conversions.conversion_units[3]) />

    	<cftransaction action="rollback" />
	</cftransaction>
</cffunction>

<cffunction name="analyticsTest" hint="test the analytics integration" access="public" returntype="void" output="false">
	<cfscript>
		clearSquabbleCookies();

		service.registerTest(testName="foo", variations=testConfig, options={gaSlot=1});
	</cfscript>

	<!--- test, not run yet --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);
		assertEquals("", trim(local.script));
	</cfscript>

	<cfscript>
		service.runTest("foo");
    </cfscript>


	<!--- start with the default --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertTrue(Find("<script", local.script), "open script");
		assertTrue(Find("</script>", local.script), "close script");

		assertTrue(Find("_gaq", local.script), "_gaq should be there");
		assertTrue(Find("pt._setCustomVar(1, 'foo', 'con,con', 1);", local.script), "set custom var");
		assertTrue(Find("pt._trackEvent('Squabble', 'Test: foo', 'con,con', 1, false);", local.script), "track event");
    </cfscript>

	<!--- no script tags --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#" writeScriptTags="false"/>
	</cfsavecontent>
	<cfscript>
		debug(local.script);

		assertFalse(Find("<script", local.script), "open script");
		assertFalse(Find("</script>", local.script), "close script");

		assertTrue(Find("_gaq", local.script), "_gaq should be there");
		assertTrue(Find("pt._setCustomVar(1, 'foo', 'con,con', 1);", local.script), "set custom var");
		assertTrue(Find("pt._trackEvent('Squabble', 'Test: foo', 'con,con', 1, false);", local.script), "track event");
    </cfscript>

	<!--- no script tags, change in gaquq --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#" writeScriptTags="false" gaQueue="gacv"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertFalse(Find("<script", local.script), "open script");
		assertFalse(Find("</script>", local.script), "close script");

		assertFalse(Find("_gaq", local.script), "_gaq should not be there");
		assertTrue(Find("gacv.push", local.script), "gacv should be there");
		assertTrue(Find("pt._setCustomVar(1, 'foo', 'con,con', 1);", local.script), "set custom var");
		assertTrue(Find("pt._trackEvent('Squabble', 'Test: foo', 'con,con', 1, false);", local.script), "track event");
    </cfscript>

    <!--- customVariableIndex --->
<!---	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#" customVariableIndex="3"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertTrue(Find("<script", local.script), "open script");
		assertTrue(Find("</script>", local.script), "close script");

		assertTrue(Find("_gaq", local.script), "_gaq should be there");
		assertTrue(Find("_gaq.push(['_setCustomVar', 3, 'foo', 'BARSECTION:control, FOOSECTION:control', 1]);", local.script), "set custom var");
		assertTrue(Find("_gaq.push(['_trackEvent', 'Squabble', 'Test: foo', 'BARSECTION:control, FOOSECTION:control', 1, false]);", local.script), "track event");
    </cfscript>--->

	<!--- customVariableScope --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#" customVariableScope="3"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertTrue(Find("<script", local.script), "open script");
		assertTrue(Find("</script>", local.script), "close script");

		assertTrue(Find("_gaq", local.script), "_gaq should be there");
		assertTrue(Find("pt._setCustomVar(1, 'foo', 'con,con', 3);", local.script), "set custom var");
		assertTrue(Find("pt._trackEvent('Squabble', 'Test: foo', 'con,con', 1, false);", local.script), "track event");
    </cfscript>

	<!--- no tests --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#" customVariableScope="3" activeTests="#[]#"/>
	</cfsavecontent>
	<cfscript>
		assertEquals("", trim(local.script));
    </cfscript>

	<cfscript>
		service.registerTest("bar", testConfig);
    </cfscript>


	<!--- test, not run yet --->
	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertTrue(Find("<script", local.script), "open script");
		assertTrue(Find("</script>", local.script), "close script");

		assertTrue(Find("foo", local.script), "foo should be there");
		assertFalse(Find("bar", local.script), "bar should not be there");
	</cfscript>

</cffunction>

<cffunction name="multipleTestAnalytics" hint="test for multiple tests" access="public" returntype="void" output="false">
	<cfscript>
		clearSquabbleCookies();

		service.registerTest(testName="foo", variations=testConfig, options={gaSlot=1});
		service.registerTest(testName="bar", variations=testConfig, options={gaSlot=3});

		service.runTest("foo");
		service.runTest("bar");
	</cfscript>

	<cfsavecontent variable="local.script" >
		<squabble:analytics squabble="#service#"/>
	</cfsavecontent>

	<cfscript>
		debug(local.script);

		assertTrue(Find("pt._setCustomVar(1, 'foo', 'con,con', 1);", local.script), "set custom var");
		assertTrue(Find("pt._setCustomVar(3, 'bar', 'con,con', 1);", local.script), "set custom var");
    </cfscript>

</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>