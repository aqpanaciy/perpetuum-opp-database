
USE perpetuumsa;
GO

---- Fix description for guns

UPDATE entitydefaults SET descriptiontoken = 'def_hell_cannon_desc' WHERE definitionname = 'def_standard_hell_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_hell_cannon_desc' WHERE definitionname = 'def_named1_hell_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_hell_cannon_desc' WHERE definitionname = 'def_named2_hell_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_hell_cannon_desc' WHERE definitionname = 'def_named3_hell_cannon'

UPDATE entitydefaults SET descriptiontoken = 'def_raven_cannon_desc' WHERE definitionname = 'def_standard_raven_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_raven_cannon_desc' WHERE definitionname = 'def_named1_raven_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_raven_cannon_desc' WHERE definitionname = 'def_named2_raven_cannon'
UPDATE entitydefaults SET descriptiontoken = 'def_raven_cannon_desc' WHERE definitionname = 'def_named3_raven_cannon'

GO

---- Set aggregate values for guns prototypes

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 47.025)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 166.725)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2.2)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 20)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 44)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 15)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 57.475)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 203.775)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2.53)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 22)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 44)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 16.5)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 62.7)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 222.3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 7000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2.42)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 25)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 44)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 17.5)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 59.85)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 256.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 17000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.65)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 40)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 46)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 38)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 73.15)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 313.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 17000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 44)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 46)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 40)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 79.8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 342)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.9)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 15000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.82)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 50)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 46)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 42)

GO

---- Add core usage modifiers

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'core_usage_projectile_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('core_usage_projectile_modifier', 0, 'core_usage_projectile_unit', 100, -100, 6, 0, 0, 1, NULL)
END

---- Assign modifiers

DECLARE @categoryflags BIGINT
DECLARE @base INT
DECLARE @modifier INT

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_single_projectile')
SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage_projectile_modifier')

DELETE FROM aggregatemodifiers WHERE categoryflag = @categoryflags AND basefield = @base AND modifierfield = @modifier

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryflags AND basefield = @base AND modifierfield = @modifier

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

GO

---- Add chassis bonuses and link them with extensions and aggregate fields

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage_projectile_modifier')
    
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_lightarmored_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_lightarmored_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_heavyarmored_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_legatus_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_heavyarmored_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.05, @field, 0)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.5, @field, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.5, @field, 0)
END

GO

DECLARE @category BIGINT

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_hell_cannon_ammo' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_t', 1000, 133120, @category, '
	#damageChemical=f36.00
	#damageKinetic=f6.00
	#damageExplosive=f6.00
	#damageThermal=f3.00
	#damageToxic=f240.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_t_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_t_pr', 1, 133120, @category, '
	#damageChemical=f36.00
	#damageKinetic=f6.00
	#damageExplosive=f6.00
	#damageThermal=f3.00
	#damageToxic=f240.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_a_desc', 1, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ammo_projectile_calibration_programs' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_t_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_raven_cannon_ammo' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_t', 1, 133120, @category, '
	#damageChemical=f48.00
	#damageKinetic=f8.00
	#damageExplosive=f8.00
	#damageThermal=f8.00
	#damageToxic=f320.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_t_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_t_pr', 1, 133120, @category, '
	#damageChemical=f48.00
	#damageKinetic=f8.00
	#damageExplosive=f8.00
	#damageThermal=f8.00
	#damageToxic=f320.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_t_desc', 1, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ammo_projectile_calibration_programs' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_t_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

GO

---- set base ct efficiency

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

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

DECLARE @biotichrin INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1 INT
DECLARE @t2 INT
DECLARE @t3 INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol') -- axicoline Y U NO cryoperine

SET @biotichrin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_biotichrin')

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

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Items --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 150),
(@definition, @plasteosine, 50),
(@definition, @flux, 2),
(@definition, @biotichrin, 600)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 150),
(@definition, @plasteosine, 50),
(@definition, @flux, 2),
(@definition, @biotichrin, 600)

----

-- Items --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 150),
(@definition, @plasteosine, 50),
(@definition, @flux, 2),
(@definition, @biotichrin, 600)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 150),
(@definition, @plasteosine, 50),
(@definition, @flux, 2),
(@definition, @biotichrin, 600)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_cprg')
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

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_t')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_t_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

--

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_t')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_t_pr')

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

---- Set aggregate values for ammo

DECLARE @definition INT
DECLARE @field INT

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 240)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 320)

----------------

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 240)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 320)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 72)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 18)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 18)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 72)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 18)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 36)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 18)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 96)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 32)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 80)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 32)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 96)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 48)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 24)

GO

---- Position in tech tree ----

DECLARE @item INT
DECLARE @parent INT

DECLARE @group INT

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common1')

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_legatus_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')
SET @parent = 0

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 9, 6, NULL)


--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ikarus_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_helix_bot')

DELETE FROM techtree WHERE childdefinition = @item

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hermes_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_cronus_bot')

DELETE FROM techtree WHERE childdefinition = @item

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_daidalos_bot')

DELETE FROM techtree WHERE childdefinition = @item

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_callisto_bot')

DELETE FROM techtree WHERE childdefinition = @item

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_metis_bot')

DELETE FROM techtree WHERE childdefinition = @item

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_autocannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 3, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 3, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 8, 3, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 9, 3, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_longrange_standard_medium_autocannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 9, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 9, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 8, 9, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 9, 9, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 1, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 0, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 1, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 2, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 8, 2, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 11, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 10, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 11, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 12, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 8, 12, NULL)

GO

---- Add prototypes for t1 guns

DECLARE @categoryflags BIGINT

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannons')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_hell_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i2d
	#powergrid_usage=f185.25
	#cpu_usage=f52.25
	#accuracy=f44.00
	#cycle_time=f8.00
	#optimal_range=f15.00
	#damage_modifier=f2.2
	#falloff=f20.00
	#core_usage=f1.80
	#ammoType=L103030a
	#tier=$tierlevel_t1_pr',
	'', 1, 1.8, 1045, 0, 100, 'def_hell_cannon_desc', 1, 2, 1)
END

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannons')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_raven_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=if
	#powergrid_usage=f285.00
	#cpu_usage=f66.50
	#accuracy=f18.00
	#cycle_time=f46.00
	#optimal_range=f38.00
	#damage_modifier=f1.65
	#falloff=f40.00
	#core_usage=f1.80
	#ammoType=L203030A
	#tier=$tierlevel_t1_pr',
	'', 1, 1.8, 1330, 0, 100, 'def_raven_cannon_desc', 1, 2, 1)
END

---- Set aggregate values for guns

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_pr')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 52.25)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 185.25)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 8000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2.2)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 20)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 44)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 15)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 66.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 285)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 17000)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 1.65)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 40)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 46)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 38)

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

DECLARE @biotichrin INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1 INT
DECLARE @t2 INT
DECLARE @t3 INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol') -- axicoline Y U NO cryoperine

SET @biotichrin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_biotichrin')

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

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 200),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100)

MERGE components AS Target
USING (SELECT definition, componentdefinition, componentamount FROM @tempTable) AS Source
ON (Target.definition = Source.definition AND Target.componentdefinition = Source.componentdefinition)
WHEN MATCHED THEN
    UPDATE SET Target.componentamount = Source.componentamount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, componentdefinition, componentamount)
    VALUES (Source.definition, Source.componentdefinition, Source.componentamount);

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_standard_hell_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_standard_hell_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

--

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_standard_raven_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_standard_raven_cannon_pr')

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

---- Fix missing tier LEVEL

UPDATE entitydefaults SET tiertype = 1, tierlevel = 1 WHERE definitionname = 'def_standard_raven_cannon'

GO

---- Fix incorrect description token

UPDATE entitydefaults SET descriptiontoken = 'def_ammo_hell_cannon_t_desc' WHERE definitionname = 'def_ammo_hell_cannon_t_pr'

GO

---- Fix ammo capacity

UPDATE entitydefaults SET options = '
	#moduleFlag=i111
	#ammoCapacity=if
	#powergrid_usage=f330.00
	#cpu_usage=f77.00
	#accuracy=f46.00
	#cycle_time=f17.00
	#optimal_range=f40.00
	#damage_modifier=f1.9
	#falloff=f44.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t3'
WHERE definitionname = 'def_named2_raven_cannon'

UPDATE entitydefaults SET options = '	
	#moduleFlag=i111
	#ammoCapacity=if
	#powergrid_usage=f360.00
	#cpu_usage=f84.00
	#accuracy=f46.00
	#cycle_time=f15.00
	#optimal_range=f42.00
	#damage_modifier=f1.82
	#falloff=f50.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t4'
WHERE definitionname = 'def_named3_raven_cannon'

GO

---- Fix chassis bonuses

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis
    
SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')

UPDATE chassisbonus SET bonus = -0.7 WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')

UPDATE chassisbonus SET bonus = -0.7 WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field

GO

---- Fix accu consumption

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage_projectile_modifier')

DELETE FROM aggregatemodifiers WHERE modifierfield = @field

GO

---- Research levels ----

DECLARE @definition INT
DECLARE @calibration INT
DECLARE @tempTable TABLE (definition INT, researchlevel INT, calibrationprogram INT, enabled BIT)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
DELETE FROM itemresearchlevels WHERE definition = @definition
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')
DELETE FROM itemresearchlevels WHERE definition = @definition
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_cprg')
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

----Research cost ----

DECLARE @definition INT
DECLARE @common INT
DECLARE @hightech INT

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 68600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 145800)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 50000),
(@definition, @common, 100000)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 68600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 145800)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 50000),
(@definition, @common, 100000)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 68600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_t')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 145800)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 68600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 102400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_t')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 145800)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 500000),
(@definition, @hightech, 350000)

GO
