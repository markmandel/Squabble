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

<cfcomponent hint="The Application.cfc for squabble unit tests" output="false">

<cfscript>
	this.name = "Squabble Demo Application";
	this.datasource = "Squabble";
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->
<cffunction name="onApplicationStart" hint="runs when the application is initialized" access="public" returntype="void" output="false">
	<cfscript>
		import "squabble.*";

		application.squabble = new Squabble();

		testConfig =
			{
				fooSection = [ "test1", "test2", "test3" ]
				, barSection = [ "test4", "test5", "test6" ]
			};

		conversionConfigs = ["conversion1", "conversion2"];

		application.squabble.registerTest("foo", testConfig, conversionConfigs);
    </cfscript>
</cffunction>


<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>