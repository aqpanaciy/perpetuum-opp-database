-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-14 07:56:02 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new robot: def_archer_gropho_mk3_bot
DECLARE @robotDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_gropho_mk3_bot', 1, 0, 264961, N'#head=n3036
#chassis=n3037
#leg=n3038
#inventory=n332
#tier=$tierlevel_mk3', N'', 1, 22.5, 0, 0, 100, N'def_archer_gropho_mk3_bot_desc', 1, 1, 3);
SET @robotDef = SCOPE_IDENTITY();
INSERT INTO definitionconfig (definition, [tint]) VALUES (@robotDef, N'#062A0D');
DECLARE @headDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_gropho_mk3_bot_head', 1, 1024, 262480, N'#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f475.00', N'', 1, 2.5, 1710, 1, 100, N'def_archer_gropho_mk3_bot_head_desc', 0, NULL, NULL);
SET @headDef = SCOPE_IDENTITY();
DECLARE @chassisDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_gropho_mk3_bot_chassis', 1, 1024, 262736, N'#height=f0.8#slotFlags=4d2,d2,2d2,2d2,4d2,4d2,4d0', N'', 1, 13, 25175, 1, 100, N'def_archer_gropho_mk3_bot_chassis_desc', 0, NULL, NULL);
SET @chassisDef = SCOPE_IDENTITY();
DECLARE @legDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_gropho_mk3_bot_leg', 1, 1024, 262992, N'#slotFlags=420,20,20,20,20
#height=f1.15
#powerdown_time=f15.00
#powerup_delay=f5.00
#speed=f1.20
#default_mass=f31500.00
#slope=f5.00', N'', 1, 7, 3591, 1, 100, N'def_archer_gropho_mk3_bot_leg_desc', 0, NULL, NULL);
SET @legDef = SCOPE_IDENTITY();
DECLARE @inventoryDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) 
VALUES (N'def_archer_gropho_mk3_bot_inventory', 1, 4195336, 198933, N'#capacity=f18.0', N'', 1, 0, 0, 0, 100, N'def_robot_inventory_desc', 0, NULL, NULL);
SET @inventoryDef = SCOPE_IDENTITY();
UPDATE entitydefaults SET options = N'#tier=$tierlevel_mk3' + '#head=n' + CAST(@headDef AS VARCHAR(10)) + '#chassis=n' + CAST(@chassisDef AS VARCHAR(10)) + '#leg=n' + CAST(@legDef AS VARCHAR(10)) + '#inventory=n' + CAST(@inventoryDef AS VARCHAR(10)) WHERE definition = @robotDef;
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 62, 481.95);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 225, 8);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 228, 35.7);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 231, 12500);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 315, 90);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 587, 6);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 588, 30);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 589, 90);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 593, 405);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 601, 90);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@headDef, 603, 90);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 9, 9500);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 16, 4200);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 26, 3412.5);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 29, 684);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 262, 1299.375);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 303, 30);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 306, 45);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 309, 10);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 312, 150);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 323, 25);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 341, 0.9);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 643, 7);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@chassisDef, 668, 7);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@legDef, 326, 5);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@legDef, 330, 1.95);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 142, 0.05, 138, 0, NULL);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 142, 0.05, 253, 0, NULL);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 355, 0.07, 232, 0, NULL);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 358, 0.05, 138, 0, NULL);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 358, 0.05, 254, 0, NULL);
INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer, note) VALUES (@chassisDef, 145, 0.05, 319, 0, NULL);
DECLARE @templateId INT;
INSERT INTO robottemplates (name, description, note) VALUES (N'archer_gropho_mk3_empty', '#robot=i' + FORMAT(@robotDef, 'x') + '#head=i' + FORMAT(@headDef, 'x') + '#chassis=i' + FORMAT(@chassisDef, 'x') + '#leg=i' + FORMAT(@legDef, 'x') + '#container=i' + FORMAT(@inventoryDef, 'x'), N'');
SET @templateId = SCOPE_IDENTITY();
INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, missionlevel, missionleveloverride, killep, note) VALUES (@robotDef, @templateId, 0, 1, 0, 0, 0, N'def_archer_gropho_mk3_bot');

COMMIT TRANSACTION;
