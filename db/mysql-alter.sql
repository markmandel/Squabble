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

ALTER TABLE `squabble_visitors` ADD COLUMN `flat_combination` VARCHAR(1000) NOT NULL  AFTER `test_name` 
, ADD INDEX `idx_flat_combination` (`flat_combination` ASC) ;

drop table if exists temp_visitor_data ;

create table temp_visitor_data (
	`id` char(35) ,
	flat_combination varchar(1000)
	,PRIMARY KEY (`id`)
	)
;

insert into temp_visitor_data
	(id, flat_combination)
SELECT
	squabble_visitors.id,
	GROUP_CONCAT(squabble_combinations.variation_name ORDER BY squabble_combinations.section_name) AS combination
FROM
	squabble_visitors 
	INNER JOIN
	squabble_combinations
	ON squabble_combinations.visitor_id = squabble_visitors.id
group by
squabble_visitors.id
;

update
	squabble_visitors, temp_visitor_data
set
	squabble_visitors.flat_combination = temp_visitor_data.flat_combination
where 
	squabble_visitors.id = temp_visitor_data.id;
	and
	squabble_visitors.flat_combination is null

drop table if exists temp_visitor_data ;