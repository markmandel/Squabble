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

<!--- doesn't hurt --->
<cfsetting requesttimeout="9600">

<cfoutput>
<cfscript>
	base = expandPath("../../../squabble");
	path = expandPath("../../api/squabble");

	if(directoryExists(path))
	{
		directoryDelete(path, true);
	}

	colddoc = createObject("component", "colddoc.ColdDoc").init();
	strategy = createObject("component", "colddoc.strategy.api.HTMLAPIStrategy").init(path, "Squabble");
	colddoc.setStrategy(strategy);

	colddoc.generate(base, "squabble");
</cfscript>
</cfoutput>
<cfdump var="#base#">
<h1>Done!</h1>

<p>
<cfoutput>#now()#</cfoutput>
</p>

<a href="../../api/squabble">Documentation</a>
