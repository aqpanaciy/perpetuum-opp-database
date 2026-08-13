-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-13 12:01:06 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] Create new item: def_archer_named4_medium_shield_generator
DECLARE @mainDef INT;
INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES (N'def_archer_named4_medium_shield_generator', 1, 82200, 33620495, N'#moduleFlag=i20#tier=$tierlevel_t5', N'', 1, 0.5, 446.5, 0, 100, N'def_archer_named4_medium_shield_generator_desc', 1, 1, 5);
SET @mainDef = SCOPE_IDENTITY();
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 32, 12.875);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 64, 72.1);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 110, 6500);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 265, 293.55);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 318, 2.3);
INSERT INTO aggregatevalues (definition, field, value) VALUES (@mainDef, 322, 26.25);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33620495, 265, 287);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33620495, 64, 581);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33620495, 32, 56);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33620495, 110, 321);
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (33620495, 318, 319);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33620495, 32, 56);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33620495, 64, 581);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33620495, 110, 321);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33620495, 265, 287);
INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (33620495, 318, 319);

COMMIT TRANSACTION;
