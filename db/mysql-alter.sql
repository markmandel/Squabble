ALTER TABLE `squabble_visitors` 
ADD INDEX `idx_test_name` (`test_name` ASC) ;

delete
from
squabble_combinations
where
visitor_id NOT IN (select squabble_visitors.id from squabble_visitors);

ALTER TABLE `squabble_combinations` 
  ADD CONSTRAINT `fk_combination_visitor_id`
  FOREIGN KEY (`visitor_id` )
  REFERENCES `squabble_visitors` (`id` )
  ON DELETE RESTRICT
  ON UPDATE RESTRICT
, ADD INDEX `fk_combination_visitor_id` (`visitor_id` ASC) ;

ALTER TABLE `squabble_conversions` 
  ADD CONSTRAINT `fk_conversion_visitor_id`
  FOREIGN KEY (`visitor_id` )
  REFERENCES `squabble_visitors` (`id` )
  ON DELETE RESTRICT
  ON UPDATE RESTRICT
, ADD INDEX `fk_conversion_visitor_id` (`visitor_id` ASC) ;

