/*
	Copyright 2013 Brian Ghidinelli - http://www.ghidinelli.com http://twitter.com/ghidinelli

	Licensed under the Apache License, Version 2.0 (the "License");
	you may not use this file except in compliance with the License.
	You may obtain a copy of the License at

	 http://www.apache.org/licenses/LICENSE-2.0

	Unless required by applicable law or agreed to in writing, software
	distributed under the License is distributed on an "AS IS" BASIS,
	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	See the License for the specific language governing permissions and
	limitations under the License.


	Squabble Database Create Script (PostgreSQL)
 */

DROP TABLE IF EXISTS squabble_visitors;
CREATE TABLE squabble_visitors (
  id char(35) PRIMARY KEY NOT NULL,
  visit_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  test_name varchar(500) NOT NULL,
  flat_combination varchar(1000) NOT NULL
) WITHOUT OIDS;

CREATE INDEX idx_test_name ON squabble_visitors (test_name);
CREATE INDEX idx_flat_combination ON squabble_visitors (flat_combination);



DROP TABLE IF EXISTS squabble_combinations;
CREATE TABLE squabble_combinations (
  id char(35) PRIMARY KEY NOT NULL,
  visitor_id char(35) DEFAULT NULL REFERENCES squabble_visitors (id) ON UPDATE CASCADE ON DELETE CASCADE,
  section_name varchar(500) NOT NULL,
  variation_name varchar(500) NOT NULL
) WITHOUT OIDS;

CREATE INDEX fk_combination_visitor_id ON squabble_combinations (visitor_id);



DROP TABLE IF EXISTS squabble_conversions;
CREATE TABLE squabble_conversions (
  id char(35) PRIMARY KEY NOT NULL,
  visitor_id char(35) DEFAULT NULL REFERENCES squabble_visitors (id) ON UPDATE CASCADE ON DELETE CASCADE,
  conversion_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  conversion_name varchar(500) NOT NULL,
  conversion_value double precision DEFAULT NULL,
  conversion_units double precision DEFAULT NULL
) WITHOUT OIDS;

CREATE INDEX fk_conversion_visitor_id ON squabble_conversions (visitor_id);



DROP TABLE IF EXISTS squabble_visitor_tags;
CREATE TABLE squabble_visitor_tags (
  visitor_id char(35) NOT NULL REFERENCES squabble_visitors (id) ON UPDATE CASCADE ON DELETE CASCADE,
  tag_value varchar(500) NOT NULL,
  PRIMARY KEY (visitor_id, tag_value)
) WITHOUT OIDS;

CREATE INDEX fk_visitor_tag_visitor_id ON squabble_visitor_tags (visitor_id);



DROP TABLE IF EXISTS squabble_conversion_tags;
CREATE TABLE squabble_conversion_tags (
  conversion_id CHAR(35) NOT NULL,
  tag_name VARCHAR(200) NOT NULL,
  tag_value VARCHAR(500) NOT NULL,
  PRIMARY KEY (conversion_id, tag_name, tag_value)
) WITHOUT OIDS;

CREATE INDEX squabble_conversion_tag_conversion_id ON squabble_conversion_tags (conversion_id ASC);
