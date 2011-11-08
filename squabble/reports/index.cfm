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

<!---
	A very simple report output to screen.
--->

<cfif structKeyExists(form, "fieldnames")>
	<cfparam name="form.testName" type="string" default="">

	<cfscript>
		totalVisitors = application.report.getTotalVisitors(form.testName);
	</cfscript>
</cfif>

<cfimport taglib="./tags" prefix="report">

</cfsilent><!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="utf-8" />
	<title>Squabble Simple Report</title>

	<link rel="stylesheet" type="text/css" href="./css/styles.css" />
</head>
<body>
	<form method="post">
		<cfset tests = application.report.getCategorisedTests()>

		<strong>Choose Test:</strong>

		<cfif tests.total>
			<select name="testName">
				<cfloop list="#tests.order#" index="category">
					<cfif arrayLen(tests[category])>
						<optgroup label="<cfoutput>#category#</cfoutput>">
							<cfloop array="#tests[category]#" index="test">
								<cfset testName = structKeyList(test)>
								<cfset isRecent = category EQ "Today" AND test[testName] GT dateAdd("h", -3, now())>
								<cfoutput>
									<option
										value="#testName#"
										<cfif structKeyExists(form, "testName") AND form.testName EQ testName>selected="selected"</cfif>
										>#testName#<cfif isRecent>*</cfif>
									</option>
								</cfoutput>
							</cfloop>
						</optgroup>
					</cfif>
				</cfloop>
			</select>

			<input type="submit" value="Show Me" />
			<br /><br />
			<span class="hint">* Test has had a visitor in the last 3 hours</span>
		<cfelse>
			No Tests Recorded!
		</cfif>

		<cfif structKeyExists(form, "fieldnames") AND totalVisitors GT 0>

		<report:stats report="#application.report#" testName="#form.testName#" />
		<report:section report="#application.report#" testName="#form.testName#" />
		<report:graphs report="#application.report#" testName="#form.testName#" />

		<cfelseif structKeyExists(form, "fieldnames")>
			<br /><br />No Test Data Found
		</cfif>
	</form>
</body>
</html>
