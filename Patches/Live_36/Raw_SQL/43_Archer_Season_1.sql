-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:06:15 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_core_recharger
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_core_recharger', 1, 524288, 262927, N'#moduleFlag=i20
#ammoCapacity=i0
#powergrid_usage=f2.00
#cpu_usage=f29.00
#tier=$tierlevel_t5', N'', 1, 0.5, 95, 0, 100, N'def_archer_named4_core_recharger_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 30, 0.78375);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 29.87);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 2.06);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (262927, 265, 267);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (262927, 64, 66);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (262927, 64, 66);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (262927, 265, 267);

COMMIT TRANSACTION;
