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
<cfcomponent hint="Class that manages Visitor identity" output="false">

<cfscript>
	//contants
	meta = getMetadata(this);

	if(!structKeyExists(meta, "const"))
	{
		const = {};
		const.PREVIEW_KEY = "squabble_enable_preview";

		meta.const = const;
	}
</cfscript>

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Visitor" output="false">
	<cfscript>
		//don't do get/set functions just for performance for cookie names.
		variables.cookieIDNames = {};
		variables.cookieComboNames = {};

		return this;
	</cfscript>
</cffunction>

<cffunction name="hasID" hint="Whether or not the current visitor has been assigned an id yet or not" access="public" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfscript>
		var key = createTestIDCookieKey(arguments.testName);

		//have to do length, as deleting the cookie just makes the length 0.
		return (structKeyExists(cookie, key) AND Len(cookie[key]));
    </cfscript>
</cffunction>

<cffunction name="getID" hint="get the current visitor ID" access="public" returntype="string" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfscript>
		if(!isEnabled())
		{
			return "";
		}

		return cookie[createTestIDCookieKey(arguments.testName)];
    </cfscript>
</cffunction>

<cffunction name="setID" hint="set the ID for the current visitor" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfargument name="id" hint="the id to set" type="string" required="Yes">
	<cfcookie name="#createTestIDCookieKey(arguments.testName)#" value="#arguments.id#" expires="183">
</cffunction>

<cffunction name="setCombination" hint="set the combination for the current visitor" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfargument name="combination" hint="The combination to set" type="struct" required="Yes">
	<cfcookie name="#createTestCombinationCookieKey(arguments.testName)#" value="#serializeJSON(arguments.combination)#" expires="183">
</cffunction>

<cffunction name="getCombination" hint="get the current visitor combination. If an inactive visitor, returns an empty struct." access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfscript>
		if(!isEnabled())
		{
			return {};
		}

		if(structKeyExists(url, meta.const.PREVIEW_KEY) && url.squabble_enable_preview eq arguments.testName)
		{
			return getPreviewCombination();
		}

		return deserializeJSON(cookie[createTestCombinationCookieKey(arguments.testName)]);
    </cfscript>
</cffunction>

<cffunction name="isEnabled" hint="Whether or not we can track this user. At the moment this defaults to whether or not cookies are enabled.
			<br/>Credits to Alex Baban for his cflib udf 'isCookiesEnabled'"
			access="public" returntype="boolean" output="false">
	<!---<cfreturn IsBoolean(URLSessionFormat("True")) />--->
	<!--- for now, just assume cookies, not sure what else to do about it --->
	<cfreturn true />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="getPreviewCombination" hint="returns a preview combination" access="public" returntype="struct" output="false">
	<cfscript>
		var combination = {};
		//have to use duplicate, or URL scope goes all wonky.
		var urlCopy = duplicate(url);

		structDelete(urlCopy, meta.const.PREVIEW_KEY);

		for(var key in urlCopy)
		{
			if(lcase(key).startsWith("squabble_"))
			{
				combination[replaceNoCase(key, "squabble_", "")] = urlCopy[key];
			}
		}

		return combination;
    </cfscript>
</cffunction>

<!--- cache em, so as not to be creating tons of strings all the time --->

<cffunction name="createTestIDCookieKey" hint="create the key for the cookie, that stores the current users id" access="private" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfscript>
		if(!structKeyExists(cookieIDNames, arguments.testName))
		{
			cookieIDNames[arguments.testName] = "squabble-#hash(arguments.testName)#-id";
		}

		return cookieIDNames[arguments.testName];
    </cfscript>
</cffunction>

<cffunction name="createTestCombinationCookieKey" hint="create the key for the cookie, that stores the current users variation" access="private" returntype="string" output="false">
	<cfargument name="testName" hint="the name of the test." type="string" required="Yes">
	<cfscript>
		if(!structKeyExists(cookieComboNames, arguments.testName))
		{
			cookieComboNames[arguments.testName] = "squabble-#hash(arguments.testName)#-c";
		}

		return cookieComboNames[arguments.testName];
    </cfscript>
</cffunction>

</cfcomponent>