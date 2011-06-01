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

<cfimport prefix="squabble" taglib="/squabble/tags" />

<squabble:test name="foo">
	<squabble:section name="fooSection">
		<squabble:control>control content</squabble:control>
		<squabble:variation name="test1">test1 content</squabble:variation>
		<squabble:variation name="test2">test2 content</squabble:variation>
		<squabble:variation name="test3">test3 content</squabble:variation>
	</squabble:section>
	<squabble:section name="barSection">
		<squabble:control>control content</squabble:control>
		<squabble:variation name="test4">test4 content</squabble:variation>
		<squabble:variation name="test5">test5 content</squabble:variation>
		<squabble:variation name="test6">test6 content</squabble:variation>
	</squabble:section>
</squabble:test>

<hr />
<a href="?resetCookies=1">Show Another Variation</a>

<!--- Commented out for now, as the service method doesn't exist yet. --->
<!--- <squabble:convert test="foo" name="conversion1" /> --->