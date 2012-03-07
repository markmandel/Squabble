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

CREATE  TABLE `squabble_conversion_tags` (
  `conversion_id` CHAR(35) NOT NULL ,
  `tag_name` VARCHAR(200) NOT NULL ,
  `tag_value` VARCHAR(500) NOT NULL ,
  PRIMARY KEY (`conversion_id`, `tag_name`, `tag_value`) ,
  INDEX `squabble_conversion_tag_conversion_id` (`conversion_id` ASC) );
