-- Perpetuum.AdminTool generated script
-- Generated: 2026-08-25 06:50:06 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_weasel_named4_small_armor_repairer
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_weasel_named4_small_armor_repairer', 1, 49168, 16908559, N'#moduleFlag=i20
#ammoCapacity=i0
#powergrid_usage=f17.00
#cpu_usage=f30.00
#cycle_time=f16
#repair_amount=f55
#core_usage=f35
#tier=$tierlevel_t4', N'', 1, 1, 237.5, 0, 100, N'def_weasel_named4_small_armor_repairer_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 70);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 41.2);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 11000);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 27.81);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 19, 100);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (16908559, 265, 266);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (16908559, 110, 22);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (16908559, 64, 65);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (16908559, 32, 34);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (16908559, 19, 20);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (16908559, 19, 20);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (16908559, 32, 34);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (16908559, 64, 65);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (16908559, 110, 22);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (16908559, 265, 266);

COMMIT TRANSACTION;
