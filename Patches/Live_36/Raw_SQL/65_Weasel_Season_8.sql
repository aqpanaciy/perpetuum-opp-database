-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:38:19 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_stealth_modul
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_stealth_modul', 1, 16664, 656399, N'#moduleFlag=i8
#ammoCapacity=i0
#ammoType=L0
#powergrid_usage=f0.00
#cpu_usage=f0.00
#tier=$tierlevel_t4', N'', 1, 0.5, 237.5, 0, 100, N'def_weasel_named4_stealth_modul_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 2.115);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 118.45);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 10000);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 5.15);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 607, 75);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (656399, 64, 611);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (656399, 32, 612);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (656399, 607, 608);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (656399, 32, 612);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (656399, 64, 611);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (656399, 607, 608);

COMMIT TRANSACTION;
