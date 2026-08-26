-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 08:32:40 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] equipment_sets: insert 'Weasel_Set'
INSERT INTO equipment_sets (name) VALUES (N'Weasel_Set')
;

-- [2] equipment_set_members: add definition 9007 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9007)
;

-- [3] equipment_set_members: add definition 9008 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9008)
;

-- [4] equipment_set_members: add definition 9009 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9009)
;

-- [5] equipment_set_members: add definition 9010 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9010)
;

-- [6] equipment_set_members: add definition 9011 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9011)
;

-- [7] equipment_set_members: add definition 9012 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9012)
;

-- [8] equipment_set_members: add definition 9013 to set 'Weasel_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set'), 9013)
;

-- [9] equipment_set_bonus_thresholds: upsert set 'Weasel_Set' pieces 2
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set') AS set_id, 2 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 604, bonus_value = 15 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 2, 604, 15)
;

-- [10] equipment_set_bonus_thresholds: upsert set 'Weasel_Set' pieces 4
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set') AS set_id, 4 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 143, bonus_value = 1.05 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 4, 143, 1.05)
;

-- [11] equipment_set_bonus_thresholds: upsert set 'Weasel_Set' pieces 6
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set') AS set_id, 6 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 34, bonus_value = 1.1 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 6, 34, 1.1)
;

-- [12] equipment_set_bonus_thresholds: upsert set 'Weasel_Set' pieces 11
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Weasel_Set') AS set_id, 11 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 655, bonus_value = 50 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 11, 655, 50)
;

COMMIT TRANSACTION;
