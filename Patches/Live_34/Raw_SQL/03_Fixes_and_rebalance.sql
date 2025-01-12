---- Increase enabler extensions level for Spectator

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 6)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 6 WHERE definition = @definition AND extensionid = @extension
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 3 WHERE definition = @definition AND extensionid = @extension
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 6)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 6 WHERE definition = @definition AND extensionid = @extension
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 3 WHERE definition = @definition AND extensionid = @extension
END

GO

---- Turm Spectator and Terramotus into mk1

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definitionname = 'def_terramotus_bot'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definitionname = 'def_spectator_bot'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL, options = NULL WHERE definitionname = 'def_spectator_bot_cprg'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL, options = NULL WHERE definitionname = 'def_terramotus_bot_cprg'

GO

-- Fix module property modifiers for excavators

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_stealth_strength_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_mining_amount_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_harvesting_amount_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO

-- Decrease masking penalty for excavator modules

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

GO

-- Fix module property modifiers for dreadnoughts

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

GO

---- Add +4 flux fields to Daoden

UPDATE mineralconfigs SET maxnodes = 8 WHERE zoneid = 2 AND materialtype = 16

GO

---- Fix Server-Wide Boosters loot

DECLARE @npc INT
DECLARE @loot INT

-- Add T2 to Radamanthys
SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

DELETE FROM npcloot WHERE definition = @npc AND lootdefinition = @loot

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t2')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

-- Add T3 to Commendant main boss

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_sh70_mainboss')

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

DELETE FROM npcloot WHERE definition = @npc AND lootdefinition = @loot

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t3')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

GO

---- Disable Santa

UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_santa_z8'

GO

---- Fix flux guardians on Daoden

DECLARE @zoneid INT
DECLARE @presenceid INT

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM npcreinforcements WHERE zoneId = @zoneid

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_1_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.1, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_2_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.2, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_3_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.3, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_4_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.4, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_5_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.5, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_6_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.6, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_7_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.7, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_8_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.8, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_9_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.9, @presenceid, @zoneid)

GO

---- Remove t0 ep boosters from Daoden syndishop and place them to observers

DECLARE @npc INT
DECLARE @loot INT

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

DELETE FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 10000000, 500, null, 0, null)
END

--

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

--

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

--

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

GO

---- Add extra head slot for Hydra

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8,8' WHERE definitionname = 'def_hydra_bot_head'

GO