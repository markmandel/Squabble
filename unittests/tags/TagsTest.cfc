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

<cffunction name="sectionContentTest" hint="test whether the expected section content is returned" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			clearSquabbleCookies();

			service.registerTest("foo", testConfig, conversionConfigs);
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
			clearSquabbleCookies();

			service.registerTest("foo", testConfig, conversionConfigs);
			service.runTest("foo");

			var expectedFooContent = "control content";
			var fooContent = "";

			var cookies = structKeyArray(cookie);
			var cookieName = service.createTestVariationCookieKey("foo");
			var cookieValue = { barSection = "test4" };

			cookie[cookieName] = serializeJSON(cookieValue);
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

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>