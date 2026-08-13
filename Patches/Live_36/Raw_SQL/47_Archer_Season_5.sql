-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:26:36 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_missile_launcher
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_missile_launcher', 1, 336592, 33752847, N'#moduleFlag=i92
#ammoCapacity=i1e
#powergrid_usage=f175.10
#cpu_usage=f46.35
#cycle_time=f9.00
#damage_modifier=f1.00
#core_usage=f2.00
#accuracy=f1.00
#ammoType=L2040a
#tier=$tierlevel_t5', N'', 1, 2, 522.5, 0, 100, N'def_archer_named4_missile_launcher_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 1, 1);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 2);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 46.35);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 7500);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 143, 1);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 175.1);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 586, 1.26);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33752847, 265, 282);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33752847, 143, 138);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33752847, 64, 87);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 1, 2);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 32, 59);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 64, 87);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 64, 106);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 110, 253);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 110, 540);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 143, 138);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 143, 142);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 143, 143);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 204, 205);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 265, 282);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 265, 296);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 586, 254);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33752847, 586, 256);

COMMIT TRANSACTION;
