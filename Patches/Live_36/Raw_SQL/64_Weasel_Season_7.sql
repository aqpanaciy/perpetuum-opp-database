-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:30:29 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_small_railgun
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_small_railgun', 1, 303824, 17041167, N'#moduleFlag=i51#ammoCapacity=i2d#ammoType=L1010a#tier=$tierlevel_t4', N'', 1, 0.5, 261.25, 0, 100, N'def_weasel_named4_small_railgun_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 1, 5);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 5.15);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 30.9);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 6000);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 143, 2.2);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 207, 6);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 255, 13.5);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 38.11);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 338, 9);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (17041167, 143, 155);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (17041167, 265, 295);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (17041167, 64, 105);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 143, 158);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 207, 301);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 207, 336);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 255, 256);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 255, 302);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 255, 337);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 265, 295);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 265, 296);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 1, 2);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 32, 49);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 32, 59);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 64, 105);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 64, 106);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 110, 300);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 110, 335);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 110, 540);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 143, 143);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 143, 147);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (17041167, 143, 155);
INSERT INTO definitionconfig (definition, [tint]) VALUES (@mainDef, N'#106CB5');

COMMIT TRANSACTION;
