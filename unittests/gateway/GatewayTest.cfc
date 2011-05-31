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

<cfimport path="squabble.*">

<cfcomponent extends="unittests.AbstractTestCase" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setup" hint="setup" access="public" returntype="void" output="false">
	<cfscript>
		service = new SquabbleGateway();
    </cfscript>
</cffunction>

<cffunction name="insertVisitorTest" hint="Tests inserting a new visitor" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			visitorID = service.insertVisitor(testName="foo");
			getVisitor = service.getVisitor(visitorID);
			
			assertTrue(getVisitor.recordcount EQ 1);
			assertEquals(visitorID, getVisitor.id);
	    </cfscript>
	    <cftransaction action="rollback" />
    </cftransaction>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>