-- Perpetuum.AdminTool generated script
-- Generated: 2026-05-11 09:20:42 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] seasons: insert 'Seasons, oh May!' with season, 6 rates, 30 objectives, 10 tiers, 3 leaderboard entries
DECLARE @seasonId INT;
INSERT INTO seasons (name, description, start_time, end_time, is_active)
VALUES (N'Seasons, oh May!', N'We are running test for a brand new feature - Seasons! Complete tasks, achieve goals, get shiny rewards!',
  '2026-05-16 03:00:00', '2026-06-01 03:00:00', 1);
SET @seasonId = SCOPE_IDENTITY();
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 1, 20, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 2, 200, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 3, 50, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 4, 1, 10000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 5, 1, 20);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 6, 1, 10000);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Too many Niani', N'Kill NPCs to earn points', 1, 5, 1000, 0);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Still too many Niani', N'Kill NPCs to earn points', 1, 10, 2000, 1);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Niani, Niani everywhere!', N'Kill NPCs to earn points', 1, 15, 3500, 2);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Where they are coming from?!', N'Kill NPCs to earn points', 1, 20, 5500, 3);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Nianicyde', N'Kill NPCs to earn points', 1, 25, 8000, 4);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Dreadful actions', N'Kill players to earn points', 2, 25, 1000, 5);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'You will, eh?', N'Kill players to earn points', 2, 50, 2000, 6);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Like a Beast', N'Kill players to earn points', 2, 75, 3500, 7);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'A real Hunter', N'Kill players to earn points', 2, 100, 5500, 8);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Show is over, do not blink', N'Kill players to earn points', 2, 125, 8000, 9);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Report for Duty', N'Complete missions to earn points', 3, 5, 1000, 10);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Busy Bee', N'Complete missions to earn points', 3, 10, 2000, 11);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'All work and no play', N'Complete missions to earn points', 3, 15, 3500, 12);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Faster, better, harder, over', N'Complete missions to earn points', 3, 20, 5500, 13);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Syndicate prouds of you', N'Complete missions to earn points', 3, 25, 8000, 14);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Syndicate needs resources', N'Gather resources to earn points', 4, 50, 1000, 15);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Syndicate needs MORE resources', N'Gather resources to earn points', 4, 2000, 1500, 16);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Syndicate ALWAYS needs resources', N'Gather resources to earn points', 4, 3500, 2250, 17);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Digger', N'Gather resources to earn points', 4, 200, 5500, 18);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Diggest', N'Gather resources to earn points', 4, 250, 8000, 19);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Grow up, you little', N'Spend EP to earn points', 5, 10, 1000, 20);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Grow up little more', N'Spend EP to earn points', 5, 20, 2000, 21);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Trainee Agent', N'Spend EP to earn points', 5, 30, 3500, 22);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Experienced Agent', N'Spend EP to earn points', 5, 40, 5500, 23);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Master Agent', N'Spend EP to earn points', 5, 50, 8000, 24);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Not broke anymore', N'Get NIC to earn points', 6, 50, 1000, 25);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Can afford a burger', N'Get NIC to earn points', 6, 100, 2000, 26);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Can afford a lot', N'Get NIC to earn points', 6, 150, 3500, 27);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Did you finally bought that?', N'Get NIC to earn points', 6, 200, 5500, 28);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'The Guy Who Bought Everything', N'Get NIC to earn points', 6, 250, 8000, 29);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 1, N'Tier 1', 4000, 16);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 2, N'Tier 2', 9000, 17);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 3, N'Tier 3', 16000, 18);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 4, N'Tier 4', 25000, 19);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 5, N'Tier 5', 36000, 20);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 6, N'Tier 6', 49000, 21);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 7, N'Tier 7', 65000, 22);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 8, N'Tier 8', 83000, 23);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 9, N'Tier 9', 102000, 24);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 10, N'Tier 10', 110000, 25);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 3, 1, 26);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 6, 4, 27);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 10, 7, 28);

COMMIT TRANSACTION;
