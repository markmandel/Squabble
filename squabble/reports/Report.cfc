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

<cfcomponent hint="Service layer for report based queries" accessors="true" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cfproperty name="gateway">

<cffunction name="init" hint="Constructor" access="public" returntype="Report" output="false">
	<cfargument name="datasource" type="string" required="false" default="squabble" />

	<cfdbinfo datasource="#arguments.datasource#" type="Version" name="local.dbinfo">

	<cfscript>
		var gateway = createObject("component", "squabble.reports.#Lcase(local.dbinfo.database_productname)#.Gateway").init(argumentCollection = arguments);

		setGateway(gateway);

		return this;
	</cfscript>
</cffunction>

<cffunction	name="onMissingMethod" access="public" returntype="any" output="false" hint="Proxy methods down to the gateway.">
	<cfargument	name="missingMethodName" type="string"	required="true"	hint=""	/>
	<cfargument	name="missingMethodArguments" type="struct" required="true"	hint=""/>

	<cfinvoke component="#getGateway()#" method="#arguments.missingMethodName#" argumentcollection="#arguments.missingMethodArguments#" returnvariable="local.return">
	<cfreturn local.return />
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>