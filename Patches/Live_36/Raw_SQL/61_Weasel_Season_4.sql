-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:40:05 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_eccm
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_eccm', 1, 524288, 263439, N'#moduleFlag=i8
#ammoCapacity=i0
#powergrid_usage=f17.00
#cpu_usage=f27.00
#tier=$tierlevel_t4', N'', 1, 0.5, 95, 0, 100, N'def_weasel_named4_eccm_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 316, 100);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 27.81);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 17.51);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 625, 632);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 265, 268);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 629, 630);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 64, 67);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 626, 631);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (263439, 316, 655);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (263439, 64, 67);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (263439, 265, 268);

COMMIT TRANSACTION;
