-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 09:22:56 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] seasons: insert 'Archer and Weasel. Chapter II: The Weasel' with season, 19 rates, 54 objectives, 5 tiers, 3 leaderboard entries
DECLARE @seasonId INT;
INSERT INTO seasons (name, description, start_time, end_time, is_active, is_recurring, recurrence_gap_days, recurrence_iteration, recurrence_base_name, scoring_mode)
VALUES (N'Archer and Weasel. Chapter II: The Weasel, Run #1', N'Syndicate intents to reproduce technologies used by Archer and Weasel. Samples would be distributed across the most experienced Agents to test. Equipment parameters are still a matter of fine-tuning and might change in future.

Become the Chosen and get your Weasel Set!

Top-1 Agent would also receive working Weasel Arbalest Mk3',
  '2026-08-29T00:00:00', '2026-09-14T00:00:00', 0, 1, 90, 1, N'Archer and Weasel. Chapter II: The Weasel', 1);
SET @seasonId = SCOPE_IDENTITY();
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 1, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 2, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 3, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 4, 1, 10000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 7, 1, 1000000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 8, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 9, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 10, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 11, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 12, 1, 1);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 13, 1, 10000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 14, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 15, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 16, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 17, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 18, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 19, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 20, 1, 1000);
INSERT INTO season_activity_rates (season_id, activity_type, points_per_unit, unit_scale)
VALUES (@seasonId, 21, 1, 10000);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Too many Niani', N'Kill 100 NPC', 1, 100, 1000, 0);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Still too many Niani', N'Kill 250 NPC', 1, 250, 2000, 1);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Niani, Niani everywhere!', N'Kill 500 NPC', 1, 500, 3500, 2);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Where they are coming from?!', N'Kill 1000 NPC', 1, 1000, 5500, 3);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Nianicyde', N'Kill 2000 NPC', 1, 2000, 8000, 4);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Dreadful actions', N'Kill 5 players', 2, 5, 1000, 5);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Burn the Phantom', N'Kill 10 players', 2, 10, 2000, 6);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Hungry Beast', N'Kill 25 players', 2, 25, 3500, 7);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'A real hunter', N'Kill 50 players', 2, 50, 5500, 8);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'The Show is over, do not blink', N'Kill 100 players', 2, 100, 8000, 9);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Report for Duty', N'Complete 20 missions', 3, 20, 1000, 10);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Busy Bee', N'Complete 40 missions', 3, 40, 2000, 11);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'All work and no play', N'Complete 70 missions', 3, 70, 3500, 12);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Harder, Better, Faster, Stronger', N'Complete 110 missions', 3, 110, 5500, 13);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Work is never over', N'Complete 160 missions', 3, 160, 8000, 14);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Lights are on, but nobody home', N'Complete 10 SAPs', 8, 10, 1000, 15);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Knock-knock!', N'Complete 20 SAPs', 8, 20, 2000, 16);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Halt, who goes there?', N'Complete 35 SAPs', 8, 35, 3500, 17);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Didn''t need that anyway', N'Complete 55 SAPs', 8, 55, 5500, 18);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'All your base belongs to us', N'Complete 80 SAPs', 8, 80, 8000, 19);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Payday', N'Spend 10 000 000 NIC', 7, 10, 1000, 20);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Checkout', N'Spend 20 000 000 NIC', 7, 20, 2000, 21);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Cash smash', N'Spend 35 000 000 NIC', 7, 35, 3500, 22);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Buyin'' large', N'Spend 55 000 000 NIC', 7, 55, 5500, 23);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Buy''n''bye', N'Spend 110 000 000 NIC', 7, 110, 8000, 24);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Intruder! Intruder!', N'Complete 3 SAPs', 8, 3, 1000, 25);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Titanic work', N'Mine 5 000 000 of Titan ore', 4, 500, 1000, 26);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Memento Imentium', N'Mine 5 000 000 of Imentium', 4, 500, 1000, 27);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Liquidator', N'Mine 5 000 000 of Liquizit', 4, 500, 1000, 28);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Fiat Flux', N'Mine 500 000 of Flux ore', 4, 50, 1000, 29);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'All that oil', N'Mine 5 000 000 of HDT', 4, 500, 1000, 30);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Traces of Epriton', N'Mine 5 000 000 of Epriton', 4, 500, 1000, 31);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Sic Transit Silgium', N'Mine 5 000 000 of Silgium', 4, 500, 1000, 32);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Stermonit? I''m on it', N'Mine 5 000 000 of Stermonit', 4, 500, 1000, 33);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Finally, pure Unobtainium!', N'Mine 500 000 of Colixium', 4, 50, 1000, 34);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Juicy fruits', N'Harvest 200 000 of Helioptris', 21, 20, 1000, 35);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Hot potatoes', N'Harvest 200 000 of Noralghis', 21, 20, 1000, 36);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Sharp crystals', N'Harvest 200 000 of Prismocytae', 21, 20, 1000, 37);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Back to your roots', N'Harvest 200 000 of Triandlus', 21, 20, 1000, 38);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Few more Niani left', N'Kill 25 NPC', 1, 25, 1000, 39);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'One more Soul to the call', N'Kill 1 player', 2, 1, 1000, 40);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Stay late today', N'Complete 5 missions', 3, 5, 1000, 41);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Daily Daisies', N'Harvest 1 000 000 pnalts', 21, 100, 1000, 42);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Doesn''t hurt', N'Lose 50 000 HP', 15, 50, 1000, 43);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Doesn''t bleed', N'Restore 50 000 HP', 16, 50, 1000, 44);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Treating the Threat', N'Deal 50 000 HP damage', 14, 50, 1000, 45);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Exhausting', N'Drain or neutralize 50 000 AP', 17, 50, 1000, 46);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Exhausted', N'Get drained or neutralized by 50 000 AP', 18, 50, 1000, 47);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Get rest', N'Transfer 50 000 AP', 19, 50, 1000, 48);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Well-rested', N'Receive 50 000 AP by energy transfer', 20, 50, 1000, 49);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Shiny toys', N'Prototype 5 items', 9, 5, 1000, 50);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'What it made of?', N'Reverse-engineer 5 items', 10, 5, 1000, 51);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Mass-production', N'Fabricate 5 items', 11, 5, 1000, 52);
INSERT INTO season_objectives (season_id, name, description, activity_type, target_value, bonus_points, display_order)
VALUES (@seasonId, N'Hidden Treasures', N'Find 10 Artifacts or Relics', 12, 10, 1000, 53);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 1, N'Tier 1', 20000, 29);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 2, N'Tier 2', 50000, 29);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 3, N'Tier 3', 90000, 29);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 4, N'Tier 4', 150000, 29);
INSERT INTO season_tiers (season_id, tier_number, tier_name, points_required, package_id)
VALUES (@seasonId, 5, N'Tier 5', 212000, 29);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 1, 1, 29);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 2, 2, 29);
INSERT INTO season_leaderboard_rewards (season_id, rank_min, rank_max, package_id)
VALUES (@seasonId, 3, 3, 28);

COMMIT TRANSACTION;
