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
<cfcomponent hint="Class that manages Visitor identity" output="false" accessors="true">

<cfproperty name="hashRegistry">

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
	<cfargument name="hashRegistry" hint="the hash registry component" type="any" required="Yes">
	<cfscript>
		setHashRegistry(arguments.hashRegistry);

		return this;
	</cfscript>
</cffunction>

<cffunction name="hasCombination" hint="Whether or not the current visitor has been assigned an id and a combination yet" access="public" returntype="boolean" output="false">
	<cfargument name="testname" hint="the name of the test we are looking at." type="string" required="Yes">
	<cfscript>
		//if no test, then no point in saying it's there.
		if(!getHashRegistry().hasTest(arguments.testName))
		{
			return false;
		}

		var key = getHashRegistry().getTestHash(arguments.testName);

		//have to do length, as deleting the cookie just makes the length 0.
		return (structKeyExists(cookie, key) AND Len(cookie[key]));
    </cfscript>
</cffunction>

<cffunction name="getID" hint="get the current visitor ID" access="public" returntype="string" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfscript>
		return deserialiseCombination(arguments.testName).id;
    </cfscript>
</cffunction>

<cffunction name="setCombination" hint="set the combination for the current visitor" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to get the combinations for." type="string" required="Yes">
	<cfargument name="id" hint="the id to set" type="string" required="Yes">
	<cfargument name="combination" hint="The combination to set" type="struct" required="Yes">

	<cfscript>
		var details = {
			id = arguments.id
			,c = arguments.combination
		};
    </cfscript>

	<cfcookie name="#getHashRegistry().getTestHash(arguments.testName)#" value="#serializeJSON(details)#" expires="183">
</cffunction>

<cffunction name="getCombination" hint="get the current visitor combination. If an inactive visitor, returns an empty struct." access="public" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">
	<cfscript>
		if(structKeyExists(url, meta.const.PREVIEW_KEY) && url.squabble_enable_preview eq arguments.testName)
		{
			return getPreviewCombination();
		}

		return deserialiseCombination(arguments.testName).c;
    </cfscript>
</cffunction>

<cffunction name="clearCombination" hint="clear out the combination for a given test" access="public" returntype="void" output="false">
	<cfargument name="testname" hint="the name of the test to get the variations for." type="string" required="Yes">

	<cfif hasCombination(arguments.testname)>
		<cfscript>
			var cookieKey = getHashRegistry().getTestHash(arguments.testName);
			var requestKey = getRequestScopeKey(arguments.testname);

			structDelete(request, requestKey);
        </cfscript>
	</cfif>
	<cfcookie name="#cookieKey#" value="" expires="183">
</cffunction>

<cffunction name="removeUnlistedCookies" hint="Remove squabble cookie (a cookie starting with 's-') that doesn't have a test registered with it. This does not remove disabled tests."
			access="public" returntype="void" output="false">
	<cfscript>
		var before = dateAdd("y" , -10, Now());
    </cfscript>

    <cfloop collection="#cookie#" item="local.key">
		<cfif LCase(local.key).startsWith("s-") and !getHashRegistry().hasTestHash(local.key)>
			<!--- kill it --->
			<cfcookie name="#local.key#" value="" expires="#before#">
		</cfif>
    </cfloop>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cffunction name="deserialiseCombination" hint="deserialise the combination, and store it in a thread local object so it doesn't need to be deserialised on every call.
												<br/>Call this before calling getID() or getCombination()"
			access="private" returntype="struct" output="false">
	<cfargument name="testname" hint="the name of the test to deserialise" type="string" required="Yes">
	<cfscript>
		//store all our bits in a request scope variable.
		var key = getRequestScopeKey(arguments.testName);
		if(!StructKeyExists(request, key))
		{
			request[key] = deserializeJSON(cookie[getHashRegistry().getTestHash(arguments.testName)]);
		}

		return request[key];
    </cfscript>
</cffunction>

<cffunction name="getRequestScopeKey" hint="create the request scope key for storing deserialised combos" access="private" returntype="string" output="false">
	<cfargument name="testname" hint="the name of the test to deserialise" type="string" required="Yes">
	<cfreturn "squabble-" & arguments.testName />
</cffunction>

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

</cfcomponent>