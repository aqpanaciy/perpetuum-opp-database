-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:41:50 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_adaptive_alloy
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_adaptive_alloy', 1, 524292, 100925711, N'#moduleFlag=i20  #tier=$tierlevel_t4', N'', 1, 1.5, 475, 0, 100, N'def_weasel_named4_adaptive_alloy_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 44.29);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 14.42);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 723, 125);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (100925711, 64, 65);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (100925711, 265, 266);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (100925711, 64, 65);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (100925711, 265, 266);

COMMIT TRANSACTION;
