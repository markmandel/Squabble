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

<cfcomponent hint="The Application.cfc for the squabble examples" output="false">

<cfscript>
	this.name = "Squabble Demo Application";
	this.datasource = "Squabble";
	this.sessionManagement = true;
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

<cffunction name="onRequestStart" hint="request start event handler" returnType="boolean" output="false">
    <cfargument type="String" name="targetPage" required=true/>

	<cfif structKeyExists(url, "resetCookies")>
		<cfset clearSquabbleCookies()>
	</cfif>

	<cfif structKeyExists(url, "resetApp")>
		<cfscript>
			applicationStop();
			location(".");
        </cfscript>
	</cfif>

    <cfreturn true>
</cffunction>



<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="clearSquabbleCookies" hint="removes all squabble cookies" access="private" returntype="void" output="false">
	<cfscript>
		var cookies = structKeyArray(cookie);
    </cfscript>
    <cfloop array="#cookies#" index="key">
		<cfif LCase(key).startsWith("squabble")>
			<cfset structDelete(cookie, key)>
		</cfif>
    </cfloop>
</cffunction>

</cfcomponent>