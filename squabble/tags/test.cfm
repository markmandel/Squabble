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
 ---><cfsilent>

	<!--- This is the top-level parent custom tag for adding tests to a page. --->

	<cfparam name="attributes.name" type="string" /> <!--- The name of the test. --->
	<cfparam name="attributes.squabble" type="any" default="" /> <!--- The Squabble service (optional). --->

	<cfif thisTag.executionMode eq "start">

		<!--- If the Squabble service is passed in, use it... --->
		<cfif isObject(attributes.squabble)>
			<cfset squabble = attributes.squabble />
		<!--- otherwise, it is expected to exist as the "squabble" key in the application scope. --->
		<cfelse>
			<cfset squabble = application.squabble />
		</cfif>

		<!--- Initialize the test. --->
		<cfset squabble.runTest(attributes.name) />

		<!--- Get the combination for the current visitor. --->
		<cfset currentCombination = squabble.getCurrentCombination(attributes.name) />

	</cfif>

</cfsilent>