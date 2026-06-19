-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:23:23 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_damage_mod_missile
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_damage_mod_missile', 1, 524292, 67438351, N'#moduleFlag=i8#tier=$tierlevel_t5', N'', 1, 0.5, 118.75, 0, 100, N'def_archer_named4_damage_mod_missile_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 142, 0.325);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 28.84);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 5.15);

COMMIT TRANSACTION;
