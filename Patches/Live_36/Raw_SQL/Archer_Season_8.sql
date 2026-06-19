-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-14 07:12:55 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] equipment_sets: insert 'Archer_Set'
INSERT INTO equipment_sets (name) VALUES (N'Archer_Set')
;

-- [2] equipment_set_members: add definition 8958 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8958)
;

-- [3] equipment_set_members: add definition 8959 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8959)
;

-- [4] equipment_set_members: add definition 8960 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8960)
;

-- [5] equipment_set_members: add definition 8961 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8961)
;

-- [6] equipment_set_members: add definition 8962 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8962)
;

-- [7] equipment_set_members: add definition 8963 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8963)
;

-- [8] equipment_set_members: add definition 8964 to set 'Archer_Set'
INSERT INTO equipment_set_members (set_id, definition) VALUES ((SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set'), 8964)
;

-- [9] equipment_set_bonus_thresholds: upsert set 'Archer_Set' pieces 2
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set') AS set_id, 2 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 331, bonus_value = 1.05 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 2, 331, 1.05)
;

-- [10] equipment_set_bonus_thresholds: upsert set 'Archer_Set' pieces 5
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set') AS set_id, 5 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 319, bonus_value = 1.05 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 5, 319, 1.05)
;

-- [11] equipment_set_bonus_thresholds: upsert set 'Archer_Set' pieces 9
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set') AS set_id, 9 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 602, bonus_value = 30 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 9, 602, 30)
;

-- [12] equipment_set_bonus_thresholds: upsert set 'Archer_Set' pieces 15
MERGE INTO equipment_set_bonus_thresholds AS target USING (SELECT (SELECT set_id FROM equipment_sets WHERE name = N'Archer_Set') AS set_id, 15 AS required_pieces) AS src ON target.set_id = src.set_id AND target.required_pieces = src.required_pieces WHEN MATCHED THEN UPDATE SET aggregate_field = 108, bonus_value = 0.1 WHEN NOT MATCHED THEN INSERT (set_id, required_pieces, aggregate_field, bonus_value) VALUES (src.set_id, 15, 108, 0.1)
;

COMMIT TRANSACTION;
