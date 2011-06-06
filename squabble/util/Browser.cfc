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

<cfcomponent accessors="true">

<cfproperty name="spiderMatchers" type="array">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="init" hint="Constructor" access="public" returntype="Browser" output="false">
	<cfscript>
		var path = getDirectoryFromPath(getMetadata(this).path) & "/OceanSpiders.v4.browser.xml";

		var xMatchers = xmlSearch(path, "/browsers/browser/identification/userAgent/@match");
		var matchers = createObject("java", "java.util.LinkedHashSet").init();

		for(var item in xMatchers)
		{
			matchers.add(massageRegex(item.xmlValue));
		}

		//cf likes Lists better

		setSpiderMatchers(createObject("java", "java.util.ArrayList").init(matchers));

		return this;
	</cfscript>
</cffunction>

<cffunction name="isCrawler" hint="Is the current request a crawler or not?" access="public" returntype="boolean" output="false">
	<cfargument name="cgiScope" hint="the cgi scope. Defaults to the ColdFusion CGI scope" type="struct" required="no" default="#CGI#">
	<cfscript>
		var matchers = getSpiderMatchers();
		for(var pattern in matchers)
		{
			if(reFind(pattern, arguments.cgiScope.http_user_agent, 1, false) != 0)
			{
				return true;
			}
		}

		return false;
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

<cfscript>
	private String function massageRegex(required String regex) hint="converts regex into CF acceptable format" {
		regex = lCase(arguments.regex);
		regex = replace(regex, ".", "\.", "all");
		regex = replace(regex, "*", ".*", "all");
		regex = replace(regex, "?", ".", "all");
		regex = replace(regex, "(", "\(", "all");
		regex = replace(regex, ")", "\)", "all");
		regex = replace(regex, "[", "\[", "all");
		regex = replace(regex, "]", "\]", "all");
  		if (right(regex, 1) eq "*") { regex = regex & "$"; }
  		regex = "^" & regex;
		return regex;
	}
</cfscript>


</cfcomponent>