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

<cfproperty name="testConfigurations" type="struct">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Squabble" output="false">
	<cfscript>
		setTestConfigurations({});

		return this;
	</cfscript>
</cffunction>

<cffunction name="registerTest" hint="Register a multivariate test with the system" access="public" returntype="void" output="false">
	<cfargument name="testName" hint="the name of the test. (500 character limit)" type="string" required="Yes">
	<cfargument name="variations" hint="Structure of variations. Should be in the format: { sectionName = [ testname, testName, testName ] }. Test names should not include 'control', as it is a reserved word"
			   	type="struct" required="Yes">
	<cfargument name="conversions" hint="array of names of conversion endpoints" type="array" required="Yes">
	<cfargument name="percentageVisitorTraffic" hint="A percentage from 0 to 100 of the amount of visitor traffic should be included in this test. Defaults to 100 percent"
			   type="numeric" required="No" default="100">
	<cfscript>
		structInsert(getTestConfigurations(), arguments.testName, arguments);
	</cfscript>
</cffunction>

<cffunction name="listTests" hint="list of all test names registered with squabble." access="public" returntype="array" output="false">
	<cfreturn structKeyArray(getTestConfigurations()) />
</cffunction>

<cffunction name="getTestConfig" hint="get a specific test configuration" access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the configuration for." type="string" required="Yes">
	<cfreturn structFind(getTestConfigurations(), arguments.testname) />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>