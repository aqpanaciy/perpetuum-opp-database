-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 09:28:57 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] season_tiers: update id 21
UPDATE season_tiers SET tier_number = 1, tier_name = N'Tier 1', points_required = 20000, package_id = NULL, equipment_set_id = 2 WHERE id = 21
;

-- [2] season_tiers: update id 22
UPDATE season_tiers SET tier_number = 2, tier_name = N'Tier 2', points_required = 50000, package_id = NULL, equipment_set_id = 2 WHERE id = 22
;

-- [3] season_tiers: update id 23
UPDATE season_tiers SET tier_number = 3, tier_name = N'Tier 3', points_required = 90000, package_id = NULL, equipment_set_id = 2 WHERE id = 23
;

-- [4] season_tiers: update id 24
UPDATE season_tiers SET tier_number = 4, tier_name = N'Tier 4', points_required = 150000, package_id = NULL, equipment_set_id = 2 WHERE id = 24
;

-- [5] season_tiers: update id 25
UPDATE season_tiers SET tier_number = 5, tier_name = N'Tier 5', points_required = 212000, package_id = NULL, equipment_set_id = 2 WHERE id = 25
;

COMMIT TRANSACTION;
