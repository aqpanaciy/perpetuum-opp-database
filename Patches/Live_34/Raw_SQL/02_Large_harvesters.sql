
USE perpetuumsa
GO

---- Create category flags for mass harvesting charges

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mass_harvesting_ammo' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(5130, 'cf_mass_harvesting_ammo', 'Mass harvesting ammo', 0, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET hidden = 0 WHERE name = 'cf_mass_harvesting_ammo'
END

GO

---- Add mass harvesting charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mass_harvesting_ammo')

-- Deeptanium mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mass_harvesting_standard', 1000, 2147485696, @categoryFlags, '#type=n0 #optimal_range_modifier=f1 #mineral=$plants', '', 1, 0.5, 0.1, 0, 100, 'def_ammo_harvesting_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 1, hidden = 0, categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mass_harvesting_standard'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mass_harvesting_standard_pr', 1, 2147485696, @categoryFlags, '#type=n0 #optimal_range_modifier=f1 #mineral=$plants', '', 1, 0.5, 0.1, 0, 100, 'def_ammo_harvesting_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 1, hidden = 0, categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mass_harvesting_standard_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_harvesting_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mass_harvesting_standard_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

GO

---- Create category flags for large harvesters

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_large_harvesters' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(50726415, 'cf_large_harvesters', 'Large harvesters', 0, 1)
END
ELSE
BEGIN
	UPDATE categoryflags SET value = 50726415, isunique = 1 WHERE name = 'cf_large_harvesters'
END

GO

---- Add large harvesters

DECLARE @categoryFlags INT

DECLARE @ammoType INT

SET @ammoType = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mass_harvesting_ammo')

-- T1 large harvester

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_harvesters')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_large_harvester', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t1'), '', 1, 2.5, 2000, 0, 100, 'def_large_harvester_desc', 1, 1, 1)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t1'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_standard_large_harvester'
END

-- T1 large harvester CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_large_harvester_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 large harvester

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_harvesters')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_harvester', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2'), '', 1, 2.5, 1500, 0, 100, 'def_large_harvester_desc', 1, 1, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named1_large_harvester'
END

-- T2 large harvester prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_harvester_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_harvester_desc', 1, 2, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2_pr'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named1_large_harvester_pr'
END

-- T2 large harvester CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_harvester_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 large harvester

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_harvesters')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_harvester', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3'), '', 1, 2.5, 1500, 0, 100, 'def_large_harvester_desc', 1, 1, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named2_large_harvester'
END

-- T3 large harvester prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_harvester_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_harvester_desc', 1, 2, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3_pr'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named2_large_harvester_pr'
END

-- T3 large harvester CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_harvester_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 large harvester

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_harvesters')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_harvester', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4'), '', 1, 2.5, 1500, 0, 100, 'def_large_harvester_desc', 1, 1, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named3_large_harvester'
END

-- T3 large harvester prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_harvester_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_harvester_desc', 1, 2, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4_pr'), descriptiontoken = 'def_large_harvester_desc', attributeflags = 393232 WHERE definitionname = 'def_named3_large_harvester_pr'
END

-- T3 large harvester CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_harvester_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Assign beams to ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'small_harvester')

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

GO

---- Adding chassis bonuses

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @sourceExtension INT
DECLARE @targetExtension INT
DECLARE @targetProperty INT

SET @sourceExtension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_heavyarmored_unit_piloting')
SET @targetExtension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_head')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus source WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_chassis')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_leg')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_head_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_chassis_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_symbiont_leg_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')

SET @targetProperty = (SELECT TOP 1 targetpropertyID FROM chassisbonus WHERE definition = @sourceDefinition AND extension = @sourceExtension)

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition AND targetpropertyID = @targetProperty)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition AND targetpropertyID = @targetProperty)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

GO

---- Setting up modifiers

DECLARE @sourceCategory INT
DECLARE @targetCategory INT

SET @sourceCategory = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_medium_harvesters')
SET @targetCategory = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_harvesters')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @targetCategory
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield)
(SELECT @targetCategory, basefield, modifierfield FROM modulepropertymodifiers WHERE categoryflags = @sourceCategory)

GO

---- Production and prorotyping cost in materials, modulesand components ----

DECLARE @definition INT

DECLARE @titanium INT
DECLARE @plasteosine INT
DECLARE @cryoperine INT

DECLARE @alligior INT
DECLARE @espitium INT
DECLARE @bryochite INT

DECLARE @flux INT

DECLARE @axicoline INT
DECLARE @polynitrocol INT
DECLARE @polynucleit INT
DECLARE @phlobotil INT

DECLARE @statichnol INT
DECLARE @metachropin INT
DECLARE @isopropentol INT

DECLARE @hydrobenol INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1_large_harvester INT
DECLARE @t2_large_harvester INT
DECLARE @t3_large_harvester INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol') -- axicoline Y U NO cryoperine

SET @alligior = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_alligior')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite

SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')

SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')

SET @axicoline = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicoline')
SET @polynitrocol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynitrocol')
SET @polynucleit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynucleit')
SET @phlobotil = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_phlobotil')

SET @statichnol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_statichnol')
SET @metachropin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_metachropin')
SET @isopropentol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_isopropentol')

SET @hydrobenol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hydrobenol')

SET @common_basic_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
SET @common_advanced_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
SET @common_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

SET @t1_large_harvester = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
SET @t2_large_harvester = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')
SET @t3_large_harvester = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 600),
(@definition, @t1_large_harvester, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_large_harvester, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_large_harvester, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600),
(@definition, @t1_large_harvester, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_large_harvester, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_large_harvester, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

-- Ammo --

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

MERGE components AS Target
USING (SELECT definition, componentdefinition, componentamount FROM @tempTable) AS Source
ON (Target.definition = Source.definition AND Target.componentdefinition = Source.componentdefinition)
WHEN MATCHED THEN
    UPDATE SET Target.componentamount = Source.componentamount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, componentdefinition, componentamount)
    VALUES (Source.definition, Source.componentdefinition, Source.componentamount);

GO

---- Research levels ----

DECLARE @definition INT
DECLARE @calibration INT
DECLARE @tempTable TABLE (definition INT, researchlevel INT, calibrationprogram INT, enabled BIT)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

MERGE itemresearchlevels AS Target
USING (SELECT definition, researchlevel, calibrationprogram, enabled FROM @tempTable) AS Source
ON (Target.definition = Source.definition)
WHEN MATCHED THEN
    UPDATE SET 
		Target.researchlevel = Source.researchlevel,
		Target.calibrationprogram = Source.calibrationprogram,
		Target.enabled = Source.enabled
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, researchlevel, calibrationprogram, enabled)
    VALUES (Source.definition, Source.researchlevel, Source.calibrationprogram, Source.enabled);

GO

---- Position in tech tree ----

DECLARE @robot INT
DECLARE @t1 INT
DECLARE @t2 INT
DECLARE @t3 INT
DECLARE @t4 INT
DECLARE @plant INT
DECLARE @group INT
DECLARE @tempTable TABLE (parentdefinition INT, childdefinition INT, groupID INT, x INT, y INT, enablerextensionid INT)

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester')
SET @plant = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'indy')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@robot, @t1, @group, 6, 16, NULL),
(@t1, @t2, @group, 7, 16, NULL),
(@t2, @t3, @group, 8, 16, NULL),
(@t3, @t4, @group, 9, 16, NULL),
(@t1, @plant, @group, 6, 17, NULL)

MERGE techtree AS Target
USING (SELECT parentdefinition, childdefinition, groupID, x, y, enablerextensionid FROM @tempTable) AS Source
ON (Target.childdefinition = Source.childdefinition AND Target.groupID = Source.groupID)
WHEN MATCHED THEN
    UPDATE SET 
		Target.parentdefinition = Source.parentdefinition,
		Target.x = Source.x,
		Target.y = Source.y,
		Target.enablerextensionid = Source.enablerextensionid
WHEN NOT MATCHED BY TARGET THEN
    INSERT (parentdefinition, childdefinition, groupID, x, y, enablerextensionid)
    VALUES (Source.parentdefinition, Source.childdefinition, Source.groupID, Source.x, Source.y, Source.enablerextensionid);

GO

----Research cost ----

DECLARE @definition INT
DECLARE @common INT
DECLARE @hightech INT
DECLARE @industrial INT

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')
SET @industrial = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'industrial')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 34300),
(@definition, @industrial, 34300)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 51200),
(@definition, @industrial, 51200)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 72900),
(@definition, @industrial, 72900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 50000),
(@definition, @industrial, 100000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mass_harvesting_standard')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 51450),
(@definition, @industrial, 102900)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_large_harvester')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_large_harvester_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_large_harvester')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_large_harvester_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_large_harvester')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_large_harvester_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mass_harvesting_standard')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mass_harvesting_standard_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

MERGE prototypes AS Target
USING (SELECT definition, prototype FROM @tempTable) AS Source
ON (Target.definition = Source.definition)
WHEN MATCHED THEN
    UPDATE SET 
		Target.prototype = Source.prototype
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, prototype)
    VALUES (Source.definition, Source.prototype);

GO

---- Set up aggregate fields for large harvesters

DECLARE @definition INT
DECLARE @field INT

-- T1 Large harvester

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_harvester')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 450)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 450 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 12000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1350)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1350 WHERE definition = @definition AND field = @field
END


-- T2 Large harvester

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 432)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 432 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 12000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1215)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1215 WHERE definition = @definition AND field = @field
END

-- T2 Large harvester prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_harvester_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 195)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 195 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 414)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 414 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 12000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1152)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1152 WHERE definition = @definition AND field = @field
END

-- T3 Large harvester

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 468)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 468 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 11000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

-- T3 Large harvester prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_harvester_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 240)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 240 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 441)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 441 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 11000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1368)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1368 WHERE definition = @definition AND field = @field
END

-- T4 Large harvester

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 195)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 195 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 495)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 495 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 10000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1458)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1458 WHERE definition = @definition AND field = @field
END

-- T4 Large harvester prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_harvester_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 252)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 252 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 468)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 468 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 10000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1458)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 1458 WHERE definition = @definition AND field = @field
END

GO

-- Add excavator effect fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_harvesting_amount_modifier', 0, 'effect_excavator_harvesting_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_enhancer_harvesting_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_enhancer_harvesting_amount_modifier', 0, 'effect_excavator_enhancer_harvesting_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

-- Set up aggregate values for excavator modules

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)

GO

-- Set up module property modifiers

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_stealth_strength_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_mining_amount_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_harvesting_amount_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO
