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
<cfcomponent extends="unittests.AbstractTestCase" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setup" hint="setup" access="public" returntype="void" output="false">
	<cfscript>
		clearSquabbleCookies();

		visitor = new squabble.Visitor();
    </cfscript>
</cffunction>

<cffunction name="testPreview" hint="test out the preview functionality" access="public" returntype="void" output="false">
	<cfscript>
		id = createUUID();
		combination = { foo = "bar"};

		//gate
		visitor.setID("foo", id);
		visitor.setCombination("foo", combination);

		assertEquals(id, visitor.getID("foo"));
		assertTrue(combination.equals(visitor.getCombination("foo")));

		//shouldn't enable for this test
		url.squabble_enable_preview = "bar";
		assertTrue(combination.equals(visitor.getCombination("foo")));

		url.squabble_enable_preview = "foo";
		assertTrue(structIsEmpty(visitor.getCombination("foo")));

		url.squabble_bar = "foo";
		var expected = { bar = "foo" };

		assertFalse(combination.equals(visitor.getCombination("foo")));
		assertTrue(expected.equals(visitor.getCombination("foo")));
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>