/*© 2019 EvidNet, all rights reserved*/

--------------------------------------------------------------------------------------------------------------
---Adapted to PostgreSQL condition_era from Pure SQL drug_era written by Chris_Knoll: https://gist.github.com/chrisknoll/c820cc12d833db2e3d1e
---Upgraded to v5 OMOP
---INTERVAL set to 30 days

---Chris Knoll's comments are after two dashes
---Taylor Delehanty's comments are after three dashes
---proper schema name needs to replace "<schema>" in the code
---operates with a system that auto-generates condition_era_id
---can filter out unmapped condition_concept_id's /*see comment in code*/
--------------------------------------------------------------------------------------------------------------
-- * GENERATED BY DEFAULT AS IDENTITY
--TRUNCATE cdmpv532_daily.condition_era;
drop table if exists cdmpv532_daily.CONDITION_ERA;;

CREATE TABLE cdmpv532_daily.CONDITION_ERA
    (
     condition_era_id					    INTEGER	  GENERATED BY DEFAULT AS IDENTITY NOT NULL,
     person_id							      INTEGER     NOT NULL ,
     condition_concept_id			    INTEGER   NOT NULL ,
     condition_era_start_date			DATE      NOT NULL ,
     condition_era_end_date				DATE 	  NOT NULL ,
     condition_occurrence_count			INTEGER			NULL
	 )
;

WITH cteConditionTarget (condition_occurrence_id, person_id, condition_concept_id, condition_start_date, condition_end_date) AS
(
	SELECT
		co.condition_occurrence_id
		, co.person_id
		, co.condition_concept_id
		, co.condition_start_date
		, COALESCE(NULLIF(co.condition_end_date,NULL), condition_start_date + INTERVAL '1 day') AS condition_end_date
	FROM cdmpv532_daily.condition_occurrence co
	/* Depending on the needs of your data, you can put more filters on to your code. We assign 0 to our unmapped condition_concept_id's,
	 * and since we don't want different conditions put in the same era, we put in the filter below.
 	 */
	---WHERE condition_concept_id != 0
),
--------------------------------------------------------------------------------------------------------------
cteEndDates (person_id, condition_concept_id, end_date) AS -- the magic
(
	SELECT
		person_id
		, condition_concept_id
		, event_date - INTERVAL '30 days' AS end_date -- unpad the end date
	FROM
	(
		SELECT
			person_id
			, condition_concept_id
			, event_date
			, event_type
			, MAX(start_ordinal) OVER (PARTITION BY person_id, condition_concept_id ORDER BY event_date, event_type ROWS UNBOUNDED PRECEDING) AS start_ordinal -- this pulls the current START down from the prior rows so that the NULLs from the END DATES will contain a value we can compare with
			, ROW_NUMBER() OVER (PARTITION BY person_id, condition_concept_id ORDER BY event_date, event_type) AS overall_ord -- this re-numbers the inner UNION so all rows are numbered ordered by the event date
		FROM
		(
			-- select the start dates, assigning a row number to each
			SELECT
				person_id
				, condition_concept_id
				, condition_start_date AS event_date
				, -1 AS event_type
				, ROW_NUMBER() OVER (PARTITION BY person_id
				, condition_concept_id ORDER BY condition_start_date) AS start_ordinal
			FROM cteConditionTarget

			UNION ALL

			-- pad the end dates by 30 to allow a grace period for overlapping ranges.
			SELECT
				person_id
			       	, condition_concept_id
				, condition_end_date + INTERVAL '30 days'
				, 1 AS event_type
				, NULL
			FROM cteConditionTarget
		) RAWDATA
	) e
	WHERE (2 * e.start_ordinal) - e.overall_ord = 0
),
--------------------------------------------------------------------------------------------------------------
cteConditionEnds (person_id, condition_concept_id, condition_start_date, era_end_date) AS
(
SELECT
        c.person_id
	, c.condition_concept_id
	, c.condition_start_date
	, MIN(e.end_date) AS era_end_date
FROM cteConditionTarget c
JOIN cteEndDates e ON c.person_id = e.person_id AND c.condition_concept_id = e.condition_concept_id AND e.end_date >= c.condition_start_date
GROUP BY
        c.condition_occurrence_id
	, c.person_id
	, c.condition_concept_id
	, c.condition_start_date
)
--------------------------------------------------------------------------------------------------------------
INSERT INTO cdmpv532_daily.condition_era(person_id, condition_concept_id, condition_era_start_date, condition_era_end_date, condition_occurrence_count)
SELECT
	person_id
	, condition_concept_id
	, MIN(condition_start_date) AS condition_era_start_date
	, era_end_date AS condition_era_end_date
	, COUNT(*) AS condition_occurrence_count
FROM cteConditionEnds
GROUP BY person_id, condition_concept_id, era_end_date
ORDER BY person_id, condition_concept_id
;;
--> [2018-10-24 18:27:06] 2 071 471 rows affected in 46 s 641 ms

----INDEX
--SELECT * FROM cdmpv532_daily.condition_era;
ALTER TABLE cdmpv532_daily.condition_era ADD CONSTRAINT xpk_condition_era PRIMARY KEY ( condition_era_id ) ;;
alter table cdmpv532_daily.condition_era alter column person_id set not null;
alter table cdmpv532_daily.condition_era alter column condition_concept_id set not null;
alter table cdmpv532_daily.condition_era alter column condition_era_start_date set not null;
alter table cdmpv532_daily.condition_era alter column condition_era_end_date set not null;
CREATE INDEX idx_condition_era_person_id  ON cdmpv532_daily.condition_era  (person_id ASC);;
CLUSTER cdmpv532_daily.condition_era  USING idx_condition_era_person_id ;;
CREATE INDEX idx_condition_era_concept_id ON cdmpv532_daily.condition_era (condition_concept_id ASC);;