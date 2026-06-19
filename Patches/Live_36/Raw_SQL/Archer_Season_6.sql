-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:19:57 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_sensor_booster
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_sensor_booster', 1, 16656, 66575, N'#moduleFlag=i8
#ammoCapacity=i0
#powergrid_usage=f9.27
#cpu_usage=f19.57
#cycle_time=f10
#core_usage=f12.36
#tier=$tierlevel_t5', N'', 1, 0.5, 95, 0, 100, N'def_archer_named4_sensor_booster_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 12.36);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 19.57);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 10000);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 9.27);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 181, 0.665);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 180, 1.595);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (66575, 64, 94);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (66575, 32, 53);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (66575, 180, 167);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (66575, 181, 168);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (66575, 32, 53);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (66575, 64, 94);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (66575, 180, 167);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (66575, 181, 168);

COMMIT TRANSACTION;
