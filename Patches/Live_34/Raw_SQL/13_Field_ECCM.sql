
USE perpetuumsa;
GO

---- Create category flags for field eccm

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_eccm_capsule' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(3992, 'cf_mobile_field_eccm_capsule', 'Mobile field ECCM capsule', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_eccm' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(590456, 'cf_mobile_field_eccm', 'Mobile field ECCM', 0, 0)
END

GO

-- Add effect fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_field_sensor_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_field_sensor_strength_modifier', 1, 'effect_field_sensor_strength_modifier_unit', 1, 0, 3, 1, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_field_reactor_radiation_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_field_reactor_radiation_modifier', 0, 'effect_field_reactor_radiation_modifier_unit', 100, -100, 5, 2, 1, 1, NULL)
END

GO

---- Create entity defaults for field eccm

DECLARE @definition INT
DECLARE @categoryFlags INT

-- Field eccm

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_eccm')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_eccm', 1, 12583936, @categoryFlags, '#size=n2', '', 1, 1, 1, 0, 100, 'def_mobile_field_eccm_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#size=n2', descriptiontoken = 'def_mobile_field_eccm_desc', attributeflags = 12583936 WHERE definitionname = 'def_mobile_field_eccm'
END

-- Field eccm capsule

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm')

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_eccm_capsule')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm_capsule')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_eccm_capsule', 1, 25167872, @categoryFlags, CONCAT('#target=n', @definition), '', 1, 5, 50000, 0, 100, 'def_mobile_field_eccm_capsule_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#target=n', @definition), descriptiontoken = 'def_mobile_field_eccm_capsule_desc', attributeflags = 25167872 WHERE definitionname = 'def_mobile_field_eccm_capsule_capsule'
END

GO

---- Place field eccm capsule on markets

DECLARE @definition INT
DECLARE @category INT
DECLARE @price FLOAT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm_capsule')
SET @category = (SELECT categoryflags FROM dbo.entitydefaults WHERE definition=@definition)
SET @price = 5000000

INSERT dbo.marketitems (marketeid, submittereid, itemdefinition, duration, isSell, price, quantity, isvendoritem) 
SELECT marketeid, vendoreid, @definition, 0, 1, @price, -1, 1 FROM dbo.vendors WHERE marketEID NOT IN (SELECT eid FROM getLiveGammaMarkets())

GO

---- Set up aggregate fields for field eccm

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'despawn_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 900000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_sensor_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_reactor_radiation_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.75)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm_capsule')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'despawn_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 900000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_sensor_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_reactor_radiation_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.75)
END

GO

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_field_effect_generators')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_field_effect_generators', 54, 1, 'Field effect generators')
END

GO

---- Add field eccm effect

DECLARE @effectCategory BIGINT

SET @effectCategory = 9007199254740992 --2^53

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_field_eccm')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_field_eccm', 'effect_field_eccm_desc', 'Field ECCM effect', 1, 30, 1, 3, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 0 WHERE name = 'effect_field_eccm'
END

GO

---- Add definition configs

DECLARE @definition INT
DECLARE @targetdefinition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm_capsule')
SET @targetdefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_eccm')

DELETE FROM definitionconfig WHERE definition = @definition
DELETE FROM definitionconfig WHERE definition = @targetdefinition

INSERT INTO definitionconfig (definition, targetdefinition, emitradius) VALUES
(@targetdefinition, NULL, 30)

INSERT INTO definitionconfig (definition, targetdefinition) VALUES
(@definition, @targetdefinition)

GO
