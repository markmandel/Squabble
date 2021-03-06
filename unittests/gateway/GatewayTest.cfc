﻿<!---
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

		// Set up some defaults
		variationData = {
			sectionFoo = "variationFoo",
			sectionBar = "variationBar"
		};
    </cfscript>
</cffunction>

<cffunction name="insertVisitorTest" hint="Tests inserting a new visitor" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			var visitorID = service.insertVisitor("foo", variationData);
			var getVisitor = service.getVisitor(visitorID);
			var getVisitorCombinations = service.getVisitorCombinations(visitorID);

			assertTrue(getVisitor.recordcount EQ 1);
			assertEquals(visitorID, getVisitor.id);
			assertEquals("variationBar,variationFoo", getVisitor.flat_combination);


			assertTrue(getVisitorCombinations.recordcount EQ 2);
			assertEquals(visitorID, getVisitorCombinations.visitor_id[1]);
			assertEquals(visitorID, getVisitorCombinations.visitor_id[2]);

			var expected = ["sectionfoo", "sectionbar"];
			assertArrayEqualsNonOrdered(expected, listToArray(lCase(valueList(getVisitorCombinations.section_name))));

			var expected = ["variationfoo", "variationbar"];
			assertArrayEqualsNonOrdered(expected, listToArray(lCase(valueList(getVisitorCombinations.variation_name))));
	    </cfscript>
	    <cftransaction action="rollback" />
    </cftransaction>
</cffunction>


<cffunction name="insertConversionTest" hint="Tests inserting a conversions for a visitor" access="public" returntype="void" output="false">
	<cftransaction>
		<cfscript>
			// Visitor with 1 conversion
			var expectedDate = dateAdd("d", -1, now());
			var visitorID = service.insertVisitor("foo", variationData);
			service.insertConversion(visitorID, "Credit Card Checkout", 2.2, 34.5, expectedDate);
			var conversions = service.getVisitorConversions(visitorID);
			assertTrue(conversions.recordcount EQ 1);
			assertEquals(visitorID, conversions.visitor_id);
			assertEquals(2.2, conversions.conversion_value);
			assertEquals(34.5, conversions.conversion_units);
			assertEquals("Credit Card Checkout", conversions.conversion_name);
			assertEquals(expectedDate, parseDateTime(conversions.conversion_date));

			// Visitor with 3 conversions
			visitorID = service.insertVisitor("bar", variationData);
			service.insertConversion(visitorID, "Credit Card Checkout", 2.2);
			service.insertConversion(visitorID, "PayPal Checkout", 24, 67);
			service.insertConversion(visitorID, "Credit Card Checkout", 9.63);
			conversions = service.getVisitorConversions(visitorID);

			assertTrue(conversions.recordcount EQ 3);
			assertEquals(visitorID, conversions.visitor_id[1]);
			assertEquals(2.2, conversions.conversion_value[1]);
			assertEquals("", conversions.conversion_units[1]);
			assertEquals(visitorID, conversions.visitor_id[2]);
			assertEquals(24.0, conversions.conversion_value[2]);
			assertEquals(67.0, conversions.conversion_units[2]);
			assertEquals(visitorID, conversions.visitor_id[3]);
			assertEquals(9.63, conversions.conversion_value[3]);
			assertEquals("", conversions.conversion_units[3]);
	    </cfscript>
	    <cftransaction action="rollback" />
    </cftransaction>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>