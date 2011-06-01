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

	<!--- This is the child custom tag used to define the control for a section. --->

	<cfif thisTag.executionMode eq "end">

		<!--- Set the "control" variation name and content into the attributes scope to pass back to the parent tag. --->
		<cfset attributes.name = "control" />
		<cfset attributes.tagContent = thisTag.generatedContent />

		<cfassociate basetag="cf_section" datacollection="variationData" />

		<!--- Reset generatedContent to control excessive whitespace. --->
		<cfset thisTag.generatedContent = "" />

	</cfif>

</cfsilent>