-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-19 04:49:56 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] season_leaderboard_rewards: update id 6
UPDATE season_leaderboard_rewards SET rank_min = 3, rank_max = 3, package_id = 28, equipment_set_id = NULL WHERE id = 6
;

COMMIT TRANSACTION;
