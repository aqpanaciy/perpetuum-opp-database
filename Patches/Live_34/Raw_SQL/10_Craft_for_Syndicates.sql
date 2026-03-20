
USE perpetuumsa;
GO

---- Shift tech tree to give space

DECLARE @group INT
DECLARE @definition INT

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common1')

UPDATE techtree SET y = y + 8 WHERE groupID = @group

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_a')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_b')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_c')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_d')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_a')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_b')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_c')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_d')

UPDATE techtree SET y = y - 8 WHERE groupId = @group AND childdefinition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_longrange_standard_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_longrange_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_longrange_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_longrange_medium_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_autocannon')

UPDATE techtree SET y = y - 7 WHERE groupId = @group AND childdefinition = @definition

GO

---- Position in tech tree ----

DECLARE @item INT
DECLARE @parent INT

DECLARE @group INT

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common1')

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_autocannon')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 1, 6, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 3, 6, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 5, 6, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_legatus_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 7, 6, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_legatus_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 9, 6, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ikarus_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 2, 7, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_helix_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 2, 8, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hermes_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 4, 7, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_cronus_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_locust_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 4, 8, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_daidalos_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 7, NULL)

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_callisto_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 6, 8, NULL)

--

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_metis_bot')
SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_legatus_bot')

DELETE FROM techtree WHERE childdefinition = @item

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @item, @group, 8, 7, NULL)

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

GO

---- Create CT for ares

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_walker_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_bot_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_bot_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

-- set base ct efficiency

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

GO

---- Production and prototyping cost in materials, modules and components ----

DECLARE @definition INT

DECLARE @titanium INT
DECLARE @flux INT

DECLARE @biotichrin INT
DECLARE @polynitrocol INT
DECLARE @polynucleit INT
DECLARE @phlobotil INT

DECLARE @bryochite INT
DECLARE @espitium INT
DECLARE @hydrobenol INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT
DECLARE @pelistal_expert_components INT
DECLARE @nuimqol_expert_components INT
DECLARE @thelodica_expert_components INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')

SET @biotichrin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_biotichrin')
SET @polynitrocol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynitrocol')
SET @polynucleit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynucleit')
SET @phlobotil = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_phlobotil')

SET @hydrobenol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hydrobenol')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite
SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')

SET @common_basic_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
SET @common_advanced_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
SET @common_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

SET @pelistal_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')
SET @nuimqol_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')
SET @thelodica_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')

-- ares --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @biotichrin, 10000),
(@definition, @phlobotil, 12000),
(@definition, @polynucleit, 12000),
(@definition, @polynitrocol, 12000),
(@definition, @titanium, 20000),
(@definition, @hydrobenol, 9000),
(@definition, @espitium, 9000),
(@definition, @bryochite, 9000),
(@definition, @flux, 2400),
(@definition, @common_expert_components, 45),
(@definition, @pelistal_expert_components, 45),
(@definition, @nuimqol_expert_components, 45),
(@definition, @thelodica_expert_components, 45)

-- ares Prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @biotichrin, 10000),
(@definition, @phlobotil, 12000),
(@definition, @polynucleit, 12000),
(@definition, @polynitrocol, 12000),
(@definition, @titanium, 20000),
(@definition, @hydrobenol, 9000),
(@definition, @espitium, 9000),
(@definition, @bryochite, 9000),
(@definition, @flux, 2400),
(@definition, @common_expert_components, 45),
(@definition, @pelistal_expert_components, 45),
(@definition, @nuimqol_expert_components, 45),
(@definition, @thelodica_expert_components, 45)

GO

---- Research levels ----

DECLARE @definition INT
DECLARE @calibration INT

-- ares prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

GO

---- Link items and their prototypes----

DECLARE @item int
DECLARE @prototype int

-- ares

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ares_bot')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ares_bot_pr')

DELETE FROM prototypes WHERE definition = @item AND prototype = @prototype

INSERT INTO prototypes (definition, prototype) VALUES (@item, @prototype)

GO

---- Create prototypes for hell cannons

DECLARE @categoryflags BIGINT

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannons')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_hell_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i3c
	#powergrid_usage=f175.50
	#cpu_usage=f49.50
	#accuracy=f44.00
	#cycle_time=f8.00
	#optimal_range=f15.00
	#damage_modifier=f2.2
	#falloff=f20.00
	#core_usage=f2.00
	#ammoType=L103030a
	#tier=$tierlevel_t2_pr',
	'', 1, 1.8, 940.5, 0, 100, 'def_hell_cannon_desc', 1, 2, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_hell_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i2d
	#powergrid_usage=f214.50
	#cpu_usage=f60.50
	#accuracy=f44.00
	#cycle_time=f8.00
	#optimal_range=f16.50
	#damage_modifier=f2.53
	#falloff=f22.00
	#core_usage=f2.00
	#ammoType=L103030a
	#tier=$tierlevel_t3_pr',
	'', 1, 1.8, 1045, 0, 100, 'def_hell_cannon_desc', 1, 2, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_hell_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i2d
	#powergrid_usage=f234.00
	#cpu_usage=f66.00
	#accuracy=f44.00
	#cycle_time=f7.00
	#optimal_range=f17.50
	#damage_modifier=f2.42
	#falloff=f25.00
	#core_usage=f2.00
	#ammoType=L103030a
	#tier=$tierlevel_t4_pr',
	'', 1, 1.8, 1254, 0, 100, 'def_hell_cannon_desc', 1, 2, 4)
END

---- Create CT for hell cannons

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_projectile_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_hell_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_hell_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_hell_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_hell_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

---- Create prototypes for RAVEN cannons

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannons')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_raven_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i14
	#powergrid_usage=f270.00
	#cpu_usage=f63.00
	#accuracy=f46.00
	#cycle_time=f17.00
	#optimal_range=f38.00
	#damage_modifier=f1.65
	#falloff=f40.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t2_pr',
	'', 1, 1.8, 1326, 0, 100, 'def_raven_cannon_desc', 1, 2, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_raven_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i1f
	#powergrid_usage=f330.00
	#cpu_usage=f77.00
	#accuracy=f46.00
	#cycle_time=f17.00
	#optimal_range=f40.00
	#damage_modifier=f1.9
	#falloff=f44.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t3_pr',
	'', 1, 1.8, 1330, 0, 100, 'def_raven_cannon_desc', 1, 2, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_raven_cannon_pr', 1, 402128, @categoryflags, '
	#moduleFlag=i111
	#ammoCapacity=i1f
	#powergrid_usage=f360.00
	#cpu_usage=f84.00
	#accuracy=f46.00
	#cycle_time=f15.00
	#optimal_range=f42.00
	#damage_modifier=f1.82
	#falloff=f50.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t4_pr',
	'', 1, 1.8, 1596, 0, 100, 'def_raven_cannon_desc', 1, 2, 4)
END

---- Create CT for raven cannons

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_projectile_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_raven_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_raven_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_raven_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_raven_cannon_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

GO

---- set base ct efficiency

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 70, 70)

GO

-- Add production duration and decalibtarion

DECLARE @categoryFlags BIGINT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannons')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 3)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannons')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 3)
END

GO

------------ Guns ------------

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

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')
SET @t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100),
(@definition, @t1, 1),
(@definition, @common_basic_components, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @hydrobenol, 100),
(@definition, @espitium, 100),
(@definition, @flux, 25),
(@definition, @biotichrin, 250),
(@definition, @t2, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 60)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @axicoline, 200),
(@definition, @hydrobenol, 200),
(@definition, @espitium, 120),
(@definition, @bryochite, 300),
(@definition, @flux, 50),
(@definition, @biotichrin, 500),
(@definition, @t3, 1),
(@definition, @common_basic_components, 30),
(@definition, @common_advanced_components, 90),
(@definition, @common_expert_components, 120)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100),
(@definition, @t1, 1),
(@definition, @common_basic_components, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @hydrobenol, 100),
(@definition, @espitium, 100),
(@definition, @flux, 25),
(@definition, @biotichrin, 250),
(@definition, @t2, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 60)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @axicoline, 200),
(@definition, @hydrobenol, 200),
(@definition, @espitium, 120),
(@definition, @bryochite, 300),
(@definition, @flux, 50),
(@definition, @biotichrin, 500),
(@definition, @t3, 1),
(@definition, @common_basic_components, 30),
(@definition, @common_advanced_components, 90),
(@definition, @common_expert_components, 120)

----

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')
SET @t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 200),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 200),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100),
(@definition, @t1, 1),
(@definition, @common_basic_components, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 100),
(@definition, @hydrobenol, 100),
(@definition, @espitium, 100),
(@definition, @flux, 25),
(@definition, @biotichrin, 250),
(@definition, @t2, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 60)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @cryoperine, 200),
(@definition, @axicoline, 200),
(@definition, @hydrobenol, 200),
(@definition, @espitium, 120),
(@definition, @bryochite, 300),
(@definition, @flux, 50),
(@definition, @biotichrin, 500),
(@definition, @t3, 1),
(@definition, @common_basic_components, 30),
(@definition, @common_advanced_components, 90),
(@definition, @common_expert_components, 120)

-- Prototypes --

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 200),
(@definition, @espitium, 50),
(@definition, @alligior, 100),
(@definition, @flux, 10),
(@definition, @biotichrin, 100),
(@definition, @t1, 1),
(@definition, @common_basic_components, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 100),
(@definition, @hydrobenol, 100),
(@definition, @espitium, 100),
(@definition, @flux, 25),
(@definition, @biotichrin, 250),
(@definition, @t2, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 60)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @cryoperine, 200),
(@definition, @axicoline, 200),
(@definition, @hydrobenol, 200),
(@definition, @espitium, 120),
(@definition, @bryochite, 300),
(@definition, @flux, 50),
(@definition, @biotichrin, 500),
(@definition, @t3, 1),
(@definition, @common_basic_components, 30),
(@definition, @common_advanced_components, 90),
(@definition, @common_expert_components, 120)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')
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
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

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

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_hell_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_hell_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_hell_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_hell_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_hell_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_hell_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

--

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_raven_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_raven_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_raven_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_raven_cannon_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_raven_cannon')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_raven_cannon_pr')

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

---- Ammo ----

DECLARE @category BIGINT

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_hell_cannon_ammo' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_a_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f72.00
	#damageExplosive=f36.00
	#damageThermal=f0.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_a_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_b_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f24.00
	#damageExplosive=f24.00
	#damageThermal=f60.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_b_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_c_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f36.00
	#damageExplosive=f72.00
	#damageThermal=f0.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0
	#bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_c_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_d_pr', 1, 133120, @category, '
	#damageChemical=f24.00
	#damageKinetic=f24.00
	#damageExplosive=f8.00
	#damageThermal=f0.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0
	#bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_hell_cannon_d_desc', 1, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ammo_projectile_calibration_programs' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_a_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_b_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_c_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_hell_cannon_d_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_raven_cannon_ammo' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_a_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f96.00
	#damageExplosive=f48.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_a_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_b_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f32.00
	#damageExplosive=f32.00
	#damageThermal=f80.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_b_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_c_pr', 1, 133120, @category, '
	#damageChemical=f0.00
	#damageKinetic=f48.00
	#damageExplosive=f96.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_c_desc', 1, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_d_pr', 1, 133120, @category, '
	#damageChemical=f48.00
	#damageKinetic=f48.00
	#damageExplosive=f48.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	'', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_d_desc', 1, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ammo_projectile_calibration_programs' )

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_a_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_b_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_c_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_d_cprg', 1, 1024, @category, NULL, '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

GO

---- set base ct efficiency

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 80, 80)

GO

-- Add production duration and decalibtarion

DECLARE @categoryFlags BIGINT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannon_ammo')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.001, 0.0015, 0.3)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 0.2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannon_ammo')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.001, 0.0015, 0.3)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 0.2)
END

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
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @plasteosine, 50),
(@definition, @phlobotil, 100),
(@definition, @flux, 2),
(@definition, @biotichrin, 200)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @plasteosine, 50),
(@definition, @phlobotil, 100),
(@definition, @flux, 2),
(@definition, @biotichrin, 200)

----

-- Items --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @plasteosine, 50),
(@definition, @phlobotil, 100),
(@definition, @flux, 2),
(@definition, @biotichrin, 200)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @phlobotil, 150),
(@definition, @flux, 2)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 75),
(@definition, @plasteosine, 50),
(@definition, @phlobotil, 100),
(@definition, @flux, 2),
(@definition, @biotichrin, 200)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d_cprg')
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

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_a')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_a_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_b')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_b_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_c')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_c_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_d')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_hell_cannon_d_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

--

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_a')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_a_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_b')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_b_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_c')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_c_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_d')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_raven_cannon_d_pr')

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
