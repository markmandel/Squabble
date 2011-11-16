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
		//clearSquabbleCookies();

		hashRegistry = new squabble.HashRegistry();
    </cfscript>
</cffunction>

<cffunction name="testRegisterAndHasTestHash" hint="make sure the registratation and hash test works" access="public" returntype="void" output="false">
	<cfscript>
		var testName = "My New Test";

		hashRegistry.registerTest(testName);

		var hash = hashRegistry.getTestHash(testName);

		debug(hash);

		assertTrue(hash.startsWith("s-"));

		assertTrue(hashRegistry.hasTestHash(hash));

		assertFalse(hashRegistry.hasTestHash("fooBar!"));
    </cfscript>
</cffunction>

<cffunction name="testRegisterAndHasTestname" hint="make sure the registratation and hash test works" access="public" returntype="void" output="false">
	<cfscript>
		var testName = "My New Test";

		hashRegistry.registerTest(testName);

		assertTrue(hashRegistry.hasTest(testName));

		assertFalse(hashRegistry.hasTestHash("fooBar!"));
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>