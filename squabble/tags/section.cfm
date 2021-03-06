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

	<!--- This is the intermediate parent custom tag used to display the variation for a test section. --->

	<cfparam name="attributes.name" type="string" /> <!--- The name of the section. --->

	<!--- Retrieve the parent tag data. --->
	<cfset testData = getBaseTagData("cf_test") />

	<cfif thisTag.executionMode eq "end">

		<!--- Find the combination for the current section... --->
		<cfif structKeyExists(testData.currentCombination, attributes.name)>
			<cfset sectionVariation = testData.currentCombination[attributes.name] />
		<!--- If not found, default to control. --->
		<cfelse>
			<cfset sectionVariation = "control" />
		</cfif>

		<cfset sectionContent = "" />

		<!--- Then find the content that matches that variation name. --->
		<cfloop array="#thisTag.variationData#" index="variation">
			<cfif variation.name eq sectionVariation>
				<cfset sectionContent = variation.tagContent />

				<cfbreak />
			</cfif>
		</cfloop>

		<!--- Reset generatedContent to control excessive whitespace. --->
		<cfset thisTag.generatedContent = "" />
	</cfif>

	<!--- More whitespace suppression. --->
	<cfsetting enablecfoutputonly="true" />

</cfsilent>

<cfif thisTag.executionMode eq "end">

	<!--- Output the variation content. --->
	<cfoutput>#sectionContent#</cfoutput>

</cfif>

<!--- Re-enable normal output. --->
<cfsetting enablecfoutputonly="false" />