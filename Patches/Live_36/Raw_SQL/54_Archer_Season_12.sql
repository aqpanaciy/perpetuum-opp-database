-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-15 03:51:12 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] packages: insert 'Archer_Bot' with 1 item(s)
DECLARE @pkgId_1e9145cb INT;
INSERT INTO packages (name) VALUES (N'Archer_Bot');
SET @pkgId_1e9145cb = SCOPE_IDENTITY();
INSERT INTO packageitems (packageid, definition, quantity) VALUES (@pkgId_1e9145cb, 8965, 1);

UPDATE season_leaderboard_rewards SET rank_min = 1, rank_max = 1, package_id = @pkgId_1e9145cb, equipment_set_id = NULL WHERE id = 4

COMMIT TRANSACTION;
