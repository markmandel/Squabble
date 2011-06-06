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
<cfcomponent hint="test out the Browser details" extends="unittests.AbstractTestCase" output="false">

<!------------------------------------------- PUBLIC ------------------------------------------->

<cffunction name="setup" hint="setup" access="public" returntype="void" output="false">
	<cfscript>
		super.setup();

		browser = new squabble.util.Browser();
    </cfscript>
</cffunction>

<cffunction name="testIsCrawler" hint="test to see if a given user agent is a crawler or not" access="public" returntype="void" output="false">
	<cfscript>
		//google
		timer = getTickCount();
		assertTrue(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"}));

		debug("Crawler: #getTickCount()- timer#");

		assertTrue(browser.isCrawler({http_user_agent = "Googlebot/2.1 (+http://www.googlebot.com/bot.html)"}));
		assertTrue(browser.isCrawler({http_user_agent = "Googlebot/2.1 (+http://www.google.com/bot.html)"}));

		//yahoo
		assertTrue(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"}));

		//scanalert
		assertTrue(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; MSIE 7.0; MSIE 6.0; ScanAlert; +http://www.scanalert.com/bot.jsp) Firefox/2.0.0.3"}));

		//bing
		assertTrue(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; MSIE 7.0; MSIE 6.0; ScanAlert; +http://www.scanalert.com/bot.jsp) Firefox/2.0.0.3c"}));
		assertTrue(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; MSIE 7.0; MSIE 6.0; ScanAlert; +http://www.scanalert.com/bot.jsp) Firefox/2.0.0.3"}));

		//Firefox
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; ru; rv:1.9.2b5) Gecko/20091204 Firefox/3.6b5"}));
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (Windows; Windows NT 5.1; es-ES; rv:1.9.2a1pre) Gecko/20090402 Firefox/3.6a1pre"}));

		//IE
		timer = getTickCount();
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; Media Center PC 6.0; InfoPath.3; MS-RTC LM 8; Zune 4.7)"}));
		debug("Browser: #getTickCount()- timer#");

		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; WOW64; Trident/4.0; SLCC2; Media Center PC 6.0; InfoPath.2; MS-RTC LM 8)"}));

		//chrome
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (X11; Linux i686) AppleWebKit/534.35 (KHTML, like Gecko) Ubuntu/10.10 Chromium/13.0.764.0 Chrome/13.0.764.0 Safari/534.35"}));
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (Windows NT 6.0; WOW64) AppleWebKit/534.24 (KHTML, like Gecko) Chrome/11.0.696.34 Safari/534.24"}));

		//safari
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (Windows; U; Windows NT 6.1; cs-CZ) AppleWebKit/533.20.25 (KHTML, like Gecko) Version/5.0.4 Safari/533.20.27"}));
		assertFalse(browser.isCrawler({http_user_agent = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_5; ar) AppleWebKit/533.19.4 (KHTML, like Gecko) Version/5.0.3 Safari/533.19.4"}));
    </cfscript>
</cffunction>

<!------------------------------------------- PACKAGE ------------------------------------------->

<!------------------------------------------- PRIVATE ------------------------------------------->

</cfcomponent>