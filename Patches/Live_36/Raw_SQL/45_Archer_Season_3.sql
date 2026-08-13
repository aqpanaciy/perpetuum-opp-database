-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:11:27 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_medium_core_battery
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_medium_core_battery', 1, 589828, 34079503, N'#moduleFlag=i20#tier=$tierlevel_t5', N'', 1, 1, 1425, 0, 100, N'def_archer_named4_medium_core_battery_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 26, 494.5);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 47.38);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 112.27);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (34079503, 265, 267);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (34079503, 64, 66);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (34079503, 64, 66);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (34079503, 265, 267);

COMMIT TRANSACTION;
