-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:44:12 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_mass_reductor
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_mass_reductor', 1, 524320, 327951, N'#moduleFlag=i20#tier=$tierlevel_t4', N'', 1, 0.5, 1.9, 0, 100, N'def_weasel_named4_mass_reductor_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 17, 0.85);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 2.85);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 6.65);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 582, -0.4);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 331, 1.4);

COMMIT TRANSACTION;
