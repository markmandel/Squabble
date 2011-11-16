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

<cfcomponent hint="Object whose job it is to look up our hash's for test names and combinations" output="false" accessors="true">

<cfproperty name="testNameLookup" type="struct">
<cfproperty name="testHashLookup" type="struct">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="HashRegistry" output="false">
	<cfscript>
		setTestNameLookup({});
		setTestHashLookup({});

		return this;
	</cfscript>
</cffunction>

<cffunction name="registerTest" hint="Register a multivariate test with the system" access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test. (500 character limit)" type="string" required="Yes">
	<cfscript>
		var hash = createTestNameHash(arguments.testName);
		getTestNameLookup()[hash] = arguments.testName;
		getTestHashLookup()[arguments.testName] = hash;
    </cfscript>
</cffunction>

<cffunction name="getTestHash" hint="get the has for a given test that has been registered" access="public" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test. (500 character limit)" type="string" required="Yes">
	<cfscript>
		return getTestHashLookup()[arguments.testName];
    </cfscript>
</cffunction>

<cffunction name="hasTestHash" hint="Is the test hash valid?" access="public" returntype="boolean" output="false">
	<cfargument name="hash" hint="the hash we use for the test" type="string" required="Yes">
	<cfreturn structKeyExists(getTestNameLookup(), arguments.hash) />
</cffunction>

<cffunction name="hasTest" hint="Is the test valid?" access="public" returntype="boolean" output="false">
	<cfargument name="testName" hint="the name of the test" type="string" required="Yes">
	<cfreturn structKeyExists(getTestHashLookup(), arguments.testName) />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="createTestNameHash" hint="create the hash for the given test name" access="private" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfscript>
		return "s-#hash(arguments.testName)#";
    </cfscript>
</cffunction>

</cfcomponent>