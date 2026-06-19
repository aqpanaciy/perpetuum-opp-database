-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:15:44 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_tracking_upgrade
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_tracking_upgrade', 1, 524288, 459791, N'#moduleFlag=i8
#ammoCapacity=i0
#powergrid_usage=f128.75
#cpu_usage=f41.20
#tier=$tierlevel_t5', N'', 1, 0.1, 47.5, 0, 100, N'def_archer_named4_tracking_upgrade_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 41.2);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 128.75);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 256, 1.265);

COMMIT TRANSACTION;
