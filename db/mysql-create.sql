/*
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


	Squabble Database Create Script (MySQL with InnoDB)
 */


/*
 * 	Table structure for 'squabble_visitors'
 */

DROP TABLE IF EXISTS squabble_visitors;

CREATE TABLE squabble_visitors (
	id char(35) NOT NULL,
	visit_date timestamp DEFAULT now(),
	test_name varchar(500) NOT NULL,
	PRIMARY KEY (id)
) ENGINE=InnoDB;


/*
 * 	Table structure for 'squabble_combinations'
 */

DROP TABLE IF EXISTS squabble_combinations;

CREATE TABLE squabble_combinations (
	id char(35) NOT NULL,
	visitor_id char(35) REFERENCES squabble_visitors (id),
	section_name varchar(500) NOT NULL,
	variation_name varchar(500) NOT NULL
) ENGINE=InnoDB;


/*
 * 	Table structure for 'squabble_conversions'
 */

DROP TABLE IF EXISTS squabble_conversions;

CREATE TABLE squabble_conversions (
	id char(35) NOT NULL,
	visitor_id char(35) REFERENCES squabble_visitors (id),
	conversion_date timestamp DEFAULT now(),
	conversion_name varchar(500) NOT NULL,
	conversion_revenue double NULL DEFAULT NULL
) ENGINE=InnoDB;
