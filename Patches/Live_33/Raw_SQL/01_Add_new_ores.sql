USE perpetuumsa

GO

---- Add new ores

---- Dummy entity to be immediately deleted so that resources match eds

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_absolutely_dummy_thing')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_absolutely_dummy_thing', 1, 2048, 1685, '', '', 0, 0.1, 0.1, 1, 100, 'def_geoscan_document_desc', 0, NULL, NULL)
END

DELETE FROM entitydefaults WHERE definitionname = 'def_absolutely_dummy_thing'

-- Geoscan document definition

DECLARE @scanDocumentId INT

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_geoscan_document_deeptanium')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_geoscan_document_deeptanium', 1, 2048, 1685, '', '', 0, 0.1, 0.1, 1, 100, 'def_geoscan_document_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_geoscan_document_deeptanium'
END

SET @scanDocumentId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_geoscan_document_deeptanium')

-- Ore definition

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ore')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_deeptanium')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_deeptanium', 1, 2048, @categoryFlags, '', '', 0, 2.5E-05, 0.02, 1, 100, 'def_deeptanium_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_deeptanium'
END

-- Ore type

DECLARE @oreDefinitionId INT

SET @oreDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_deeptanium')

IF NOT EXISTS (SELECT 1 FROM minerals WHERE name = 'deeptanium')
BEGIN
	INSERT INTO minerals (idx, name, definition, amount, extractionType, enablereffectrequired, note, geoscandocument) VALUES
	(17, 'deeptanium', @oreDefinitionId, 1500, 0, 0, 'deeptanium ore', @scanDocumentId)
END

GO

---- Add geoscanner charges (no use)

-- Directional charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_deeptanium_direction')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_deeptanium_direction', 1000, 2048, 395530, '#mineral=$deeptanium', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_direction_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_deeptanium_direction'
END


-- Tile charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_deeptanium_tile')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_deeptanium_tile', 1000, 2048, 133386, '#mineral=$deeptanium #type=n1', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_tile_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_deeptanium_tile'
END

GO

---- Create category flags for deep mining charges

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_deep_mining_ammo' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4874, 'cf_deep_mining_ammo', 'Deep mining ammo', 0, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET hidden = 0 WHERE name = 'cf_deep_mining_ammo'
END

GO

---- Add deep mining charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- Deeptanium mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_titan', 1000, 2147485696, @categoryFlags, '#mineral=$titan', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 1, hidden = 0 WHERE definitionname = 'def_ammo_mining_deep_titan'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_titan_pr', 1, 2147485696, @categoryFlags, '#mineral=$titan', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 1, hidden = 0 WHERE definitionname = 'def_ammo_mining_deep_titan_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_titan_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

GO

---- Create category flags for large drillers

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_large_drillers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(50398735, 'cf_large_drillers', 'Large drillers', 0, 1)
END
ELSE
BEGIN
	UPDATE categoryflags SET value = 50398735, isunique = 1 WHERE name = 'cf_large_drillers'
END

GO

---- Add large drillers

DECLARE @categoryFlags INT

DECLARE @ammoType INT

SET @ammoType = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- T1 large driller

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_large_driller', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t1'), '', 1, 2.5, 2000, 0, 100, 'def_large_driller_desc', 1, 1, 1)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t1'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_standard_large_driller'
END

-- T1 large driller CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_large_driller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_large_driller_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 large driller

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_driller', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2'), '', 1, 2.5, 1500, 0, 100, 'def_large_driller_desc', 1, 1, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named1_large_driller'
END

-- T2 large driller prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_driller_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_driller_desc', 1, 2, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t2_pr'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named1_large_driller_pr'
END

-- T2 large driller CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_large_driller_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 large driller

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_driller', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3'), '', 1, 2.5, 1500, 0, 100, 'def_large_driller_desc', 1, 1, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named2_large_driller'
END

-- T3 large driller prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_driller_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_driller_desc', 1, 2, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t3_pr'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named2_large_driller_pr'
END

-- T3 large driller CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_large_driller_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 large driller

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_driller', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4'), '', 1, 2.5, 1500, 0, 100, 'def_large_driller_desc', 1, 1, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named3_large_driller'
END

-- T3 large driller prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_driller_pr', 1, 393232, @categoryFlags, CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4_pr'), '', 1, 2.5, 1250, 0, 100, 'def_large_driller_desc', 1, 2, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#moduleFlag=iA20#ammoCapacity=i2d#ammoType=L', FORMAT(@ammoType, 'X'), '#tier=$tierlevel_t4_pr'), descriptiontoken = 'def_large_driller_desc', attributeflags = 393232 WHERE definitionname = 'def_named3_large_driller_pr'
END

-- T3 large driller CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industry_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_large_driller_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Create entity defaults for Terramotus

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_chassis', 1, 1024, @category, '#height=f2#slotFlags=40', 1, 100, 78000, 1, 100, 'def_terramotus_chassis_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f2#slotFlags=40' WHERE definitionname = 'def_terramotus_chassis'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_head', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.10', 1, 3, 3000, 1, 100, 'def_terramotus_head_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_leg', 1, 1024, @category, '#slotFlags=4A20,20,20,20,20  #height=f1.10', 1, 20, 18000, 1, 100, 'def_terramotus_leg_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4A20,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_robot_inventory_terramotus', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walkers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_bot', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 123, 0, 0, 100, 'def_terramotus_bot_desc', 1, 1, 3)
END

GO

---- Create robot template and link it with definition

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'terramotus_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('terramotus_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'Terramotus')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')) WHERE name = 'terramotus_empty'
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'terramotus_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_terramotus_bot')
END

GO

---- Set up aggregate fields for Terramotus

DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @definition AND field = @field
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2300)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 21)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 95)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 50)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 500)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 95)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 720 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

GO

---- Create entity defaults for Terramotus prototype

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_chassis_pr', 1, 1024, @category, '#height=f2#slotFlags=40', 1, 100, 78000, 1, 100, 'def_terramotus_chassis_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f2#slotFlags=40' WHERE definitionname = 'def_terramotus_chassis_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_head_pr', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.10', 1, 3, 3000, 1, 100, 'def_terramotus_head_pr_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_leg_pr', 1, 1024, @category, '#slotFlags=4A20,20,20,20,20  #height=f1.10', 1, 20, 18000, 1, 100, 'def_terramotus_leg_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4A20,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_robot_inventory_terramotus_pr', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus_pr')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walkers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_bot_pr', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo, '#tier=$tierlevel_pr'), 1, 123, 0, 0, 100, 'def_terramotus_bot_pr_desc', 1, 2, NULL)
END

GO

---- Create robot template and link it with definition

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_terramotus_pr')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'terramotus_pr_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('terramotus_pr_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'Terramotus prototype')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')) WHERE name = 'terramotus_pr_empty'
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'terramotus_pr_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_terramotus_bot_pr')
END

GO

---- Set up aggregate fields for Terramotus prototype

DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @definition AND field = @field
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2300)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 21)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 95)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 50)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 500)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 95)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 720 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

GO

---- Assign beams to ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'medium_laser')

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

GO

---- Set up aggregate fields for large drillers

DECLARE @definition INT
DECLARE @field INT

-- T1 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')

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


-- T2 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')

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

-- T2 Large Driller prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_pr')

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

-- T3 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')

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

-- T3 Large Driller prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_pr')

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

-- T4 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')

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

-- T4 Large Driller prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_pr')

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

---- Deepriton

-- Geoscan document definition

DECLARE @scanDocumentId INT

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_geoscan_document_deepriton')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_geoscan_document_deepriton', 1, 2048, 1685, '', '', 0, 0.1, 0.1, 1, 100, 'def_geoscan_document_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_geoscan_document_deepriton'
END

SET @scanDocumentId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_geoscan_document_deepriton')

-- Ore definition

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_liquid')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_deepriton')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_deepriton', 1, 2048, @categoryFlags, '', '', 0, 2.5E-05, 0.02, 1, 100, 'def_deepriton_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1, categoryflags = @categoryFlags WHERE definitionname = 'def_deepriton'
END

-- Ore type

DECLARE @oreDefinitionId INT

SET @oreDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_deepriton')

IF NOT EXISTS (SELECT 1 FROM minerals WHERE name = 'deepriton')
BEGIN
	INSERT INTO minerals (idx, name, definition, amount, extractionType, enablereffectrequired, note, geoscandocument) VALUES
	(18, 'deepriton', @oreDefinitionId, 450, 1, 0, 'deepriton ore', @scanDocumentId)
END

-- Ore config

DECLARE @mineralId INT

SET @mineralId = (SELECT TOP 1 idx FROM minerals WHERE name = 'deepriton')

DELETE FROM mineralconfigs WHERE materialtype = @mineralId

/*
INSERT INTO mineralconfigs (zoneid, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold) VALUES
(3, @mineralId, 3, 125, 45000000, 0.5),
(4, @mineralId, 3, 125, 45000000, 0.5),
(5, @mineralId, 3, 125, 45000000, 0.5),
(8, @mineralId, 3, 125, 45000000, 0.5),
(9, @mineralId, 3, 125, 45000000, 0.5),
(10, @mineralId, 3, 125, 45000000, 0.5)
(100, @mineralId, 7, 500, 45000000, 0.5),
(101, @mineralId, 7, 500, 45000000, 0.5),
(102, @mineralId, 7, 500, 45000000, 0.5),
(103, @mineralId, 7, 500, 45000000, 0.5),
(104, @mineralId, 7, 500, 45000000, 0.5),
(105, @mineralId, 7, 500, 45000000, 0.5),
(106, @mineralId, 7, 500, 45000000, 0.5),
(107, @mineralId, 7, 500, 45000000, 0.5),
(108, @mineralId, 7, 500, 45000000, 0.5),
(109, @mineralId, 7, 500, 45000000, 0.5),
(110, @mineralId, 7, 500, 45000000, 0.5),
(111, @mineralId, 7, 500, 45000000, 0.5),
(112, @mineralId, 7, 500, 45000000, 0.5),
(113, @mineralId, 7, 500, 45000000, 0.5),
(114, @mineralId, 7, 500, 45000000, 0.5),
(115, @mineralId, 7, 500, 45000000, 0.5),
(116, @mineralId, 7, 500, 45000000, 0.5),
(117, @mineralId, 7, 500, 45000000, 0.5),
(118, @mineralId, 7, 500, 45000000, 0.5),
(119, @mineralId, 7, 500, 45000000, 0.5),
(120, @mineralId, 7, 500, 45000000, 0.5),
(121, @mineralId, 7, 500, 45000000, 0.5),
(122, @mineralId, 7, 500, 45000000, 0.5),
(123, @mineralId, 7, 500, 45000000, 0.5),
(124, @mineralId, 7, 500, 45000000, 0.5),
(125, @mineralId, 7, 500, 45000000, 0.5),
(126, @mineralId, 7, 500, 45000000, 0.5),
(127, @mineralId, 7, 500, 45000000, 0.5),
(128, @mineralId, 7, 500, 45000000, 0.5),
(129, @mineralId, 7, 500, 45000000, 0.5),
(130, @mineralId, 7, 500, 45000000, 0.5),
(131, @mineralId, 7, 500, 45000000, 0.5),
(132, @mineralId, 7, 500, 45000000, 0.5),
(133, @mineralId, 7, 500, 45000000, 0.5),
(134, @mineralId, 7, 500, 45000000, 0.5),
(135, @mineralId, 7, 500, 45000000, 0.5),
(136, @mineralId, 7, 500, 45000000, 0.5),
(137, @mineralId, 7, 500, 45000000, 0.5),
(138, @mineralId, 7, 500, 45000000, 0.5),
(139, @mineralId, 7, 500, 45000000, 0.5),
(140, @mineralId, 7, 500, 45000000, 0.5)
*/

GO

---- Add geoscanner charges

-- Directional charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_deepriton_direction')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_deepriton_direction', 1000, 2048, 395530, '#mineral=$deepriton', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_direction_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_deepriton_direction'
END

-- Tile charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_deepriton_tile')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_deepriton_tile', 1000, 2048, 133386, '#mineral=$deepriton #type=n1', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_tile_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_deepriton_tile'
END

GO

---- Add deep mining charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- Deepriton mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deepriton')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deepriton', 1000, 2147485696, @categoryFlags, '#mineral=$epriton', '', 0, 0.5, 1, 1, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#mineral=$epriton', enabled = 0, hidden = 1, categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deepriton'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deepriton_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deepriton_pr', 1, 2147485696, @categoryFlags, '#mineral=$epriton', '', 0, 0.5, 0.5, 1, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#mineral=$epriton', enabled = 0, hidden = 1, categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deepriton_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deepriton_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deepriton_cprg', 1, 1024, @categoryFlags, '', '', 0, 0.01, 0.1, 1, 100, 'calibration_program_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1, categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deepriton_pr'
END

GO

---- Assign beams to ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deepriton')
SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'medium_laser')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

GO

---- DHDT

-- Geoscan document definition

DECLARE @scanDocumentId INT

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_geoscan_document_dhdt')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_geoscan_document_dhdt', 1, 2048, 1685, '', '', 1, 0.1, 0.1, 0, 100, 'def_geoscan_document_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_geoscan_document_dhdt'
END

SET @scanDocumentId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_geoscan_document_dhdt')

-- Ore definition

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_liquid')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_dhdt')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_dhdt', 1, 2048, @categoryFlags, '', '', 1, 2.5E-05, 0.02, 0, 100, 'def_dhdt_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_dhdt'
END

-- Ore type

DECLARE @oreDefinitionId INT

SET @oreDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_dhdt')

IF NOT EXISTS (SELECT 1 FROM minerals WHERE name = 'dhdt')
BEGIN
	INSERT INTO minerals (idx, name, definition, amount, extractionType, enablereffectrequired, note, geoscandocument) VALUES
	(19, 'dhdt', @oreDefinitionId, 450, 1, 0, 'dhdt ore', @scanDocumentId)
END

-- Ore config

DECLARE @mineralId INT

SET @mineralId = (SELECT TOP 1 idx FROM minerals WHERE name = 'dhdt')

DELETE FROM mineralconfigs WHERE materialtype = @mineralId

/*
INSERT INTO mineralconfigs (zoneid, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold) VALUES
(0, @mineralId, 3, 125, 5000000, 0.5),
(1, @mineralId, 3, 125, 45000000, 0.5),
(3, @mineralId, 3, 125, 45000000, 0.5),
(4, @mineralId, 3, 125, 45000000, 0.5),
(5, @mineralId, 3, 125, 45000000, 0.5),
(6, @mineralId, 3, 125, 45000000, 0.5),
(7, @mineralId, 3, 125, 45000000, 0.5),
(8, @mineralId, 3, 125, 5000000, 0.5),
(9, @mineralId, 3, 125, 45000000, 0.5),
(10, @mineralId, 3, 125, 45000000, 0.5),
(11, @mineralId, 3, 125, 45000000, 0.5)
(100, @mineralId, 7, 500, 45000000, 0.5),
(101, @mineralId, 7, 500, 45000000, 0.5),
(102, @mineralId, 7, 500, 45000000, 0.5),
(103, @mineralId, 7, 500, 45000000, 0.5),
(104, @mineralId, 7, 500, 45000000, 0.5),
(105, @mineralId, 7, 500, 45000000, 0.5),
(106, @mineralId, 7, 500, 45000000, 0.5),
(107, @mineralId, 7, 500, 45000000, 0.5),
(108, @mineralId, 7, 500, 45000000, 0.5),
(109, @mineralId, 7, 500, 45000000, 0.5),
(110, @mineralId, 7, 500, 45000000, 0.5),
(111, @mineralId, 7, 500, 45000000, 0.5),
(112, @mineralId, 7, 500, 45000000, 0.5),
(113, @mineralId, 7, 500, 45000000, 0.5),
(114, @mineralId, 7, 500, 45000000, 0.5),
(115, @mineralId, 7, 500, 45000000, 0.5),
(116, @mineralId, 7, 500, 45000000, 0.5),
(117, @mineralId, 7, 500, 45000000, 0.5),
(118, @mineralId, 7, 500, 45000000, 0.5),
(119, @mineralId, 7, 500, 45000000, 0.5),
(120, @mineralId, 7, 500, 45000000, 0.5),
(121, @mineralId, 7, 500, 45000000, 0.5),
(122, @mineralId, 7, 500, 45000000, 0.5),
(123, @mineralId, 7, 500, 45000000, 0.5),
(124, @mineralId, 7, 500, 45000000, 0.5),
(125, @mineralId, 7, 500, 45000000, 0.5),
(126, @mineralId, 7, 500, 45000000, 0.5),
(127, @mineralId, 7, 500, 45000000, 0.5),
(128, @mineralId, 7, 500, 45000000, 0.5),
(129, @mineralId, 7, 500, 45000000, 0.5),
(130, @mineralId, 7, 500, 45000000, 0.5),
(131, @mineralId, 7, 500, 45000000, 0.5),
(132, @mineralId, 7, 500, 45000000, 0.5),
(133, @mineralId, 7, 500, 45000000, 0.5),
(134, @mineralId, 7, 500, 45000000, 0.5),
(135, @mineralId, 7, 500, 45000000, 0.5),
(136, @mineralId, 7, 500, 45000000, 0.5),
(137, @mineralId, 7, 500, 45000000, 0.5),
(138, @mineralId, 7, 500, 45000000, 0.5),
(139, @mineralId, 7, 500, 45000000, 0.5),
(140, @mineralId, 7, 500, 45000000, 0.5)
*/

GO

---- Add geoscanner charges

-- Directional charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_dhdt_direction')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_dhdt_direction', 1000, 2048, 395530, '#mineral=$dhdt', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_direction_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_dhdt_direction'
END

-- Tile charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_probe_dhdt_tile')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_probe_dhdt_tile', 1000, 2048, 133386, '#mineral=$dhdt #type=n1', '', 0, 0.5, 0.1, 1, 100, 'def_ammo_mining_probe_tile_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_probe_dhdt_tile'
END

GO

---- Add deep mining charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- DHDT mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_dhdt')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_dhdt', 1000, 2147485696, @categoryFlags, '#mineral=$dhdt', '', 0, 0.5, 1, 1, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_dhdt'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_dhdt_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_dhdt_pr', 1, 2147485696, @categoryFlags, '#mineral=$dhdt', '', 0, 0.5, 0.5, 1, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_dhdt_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_dhdt_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_dhdt_cprg', 1, 1024, @categoryFlags, '', '', 0, 0.01, 0.1, 1, 100, 'calibration_program_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags, enabled = 0, hidden = 1 WHERE definitionname = 'def_ammo_mining_dhdt_cprg'
END

GO

---- Assign beams to ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_dhdt')
SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'medium_laser')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

GO

---- Add deep mining charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- Deep imentium mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_imentium', 1000, 2147485696, @categoryFlags, '#mineral=$imentium', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_imentium'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_imentium_pr', 1, 2147485696, @categoryFlags, '#mineral=$imentium', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_imentium_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_imentium_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep stermonit mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_stermonit', 1000, 2147485696, @categoryFlags, '#mineral=$stermonit', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_stermonit'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_stermonit_pr', 1, 2147485696, @categoryFlags, '#mineral=$stermonit', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_stermonit_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_stermonit_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep silgium mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_silgium', 1000, 2147485696, @categoryFlags, '#mineral=$silgium', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_silgium'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_silgium_pr', 1, 2147485696, @categoryFlags, '#mineral=$silgium', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_silgium_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_silgium_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep gammaterial mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_gammaterial', 1000, 2147485696, @categoryFlags, '#mineral=$gammaterial', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_gammaterial'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_gammaterial_pr', 1, 2147485696, @categoryFlags, '#mineral=$gammaterial', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_gammaterial_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_gammaterial_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep fluxore mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_fluxore', 1000, 2147485696, @categoryFlags, '#mineral=$fluxore', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_fluxore'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_fluxore_pr', 1, 2147485696, @categoryFlags, '#mineral=$fluxore', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_fluxore_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_fluxore_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

GO

---- Assign beams to new ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'medium_laser')

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

GO

---- Adding chassis bonuses

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @sourceExtension INT
DECLARE @targetExtension INT

SET @sourceExtension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_heavyarmored_unit_piloting')
SET @targetExtension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_head')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus source WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_chassis')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_leg')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_head_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_chassis_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_chassis_pr')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_leg_pr')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_leg_pr')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @targetDefinition)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, note, targetpropertyID, effectenhancer)
	(SELECT @targetDefinition, extension, bonus, note, targetpropertyID, effectenhancer FROM chassisbonus WHERE definition = @sourceDefinition)
END

UPDATE chassisbonus SET extension = @targetExtension WHERE definition = @targetDefinition AND extension = @sourceExtension

GO

---- Setting up modifiers

DECLARE @sourceCategory INT
DECLARE @targetCategory INT

SET @sourceCategory = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_medium_drillers')
SET @targetCategory = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @targetCategory
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield)
(SELECT @targetCategory, basefield, modifierfield FROM modulepropertymodifiers WHERE categoryflags = @sourceCategory)

GO

---- Set up enabler extensions
-- extensive mining 5
-- intensive mining 5

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

DECLARE @t1_large_driller INT
DECLARE @t2_large_driller INT
DECLARE @t3_large_driller INT

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

SET @t1_large_driller = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
SET @t2_large_driller = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
SET @t3_large_driller = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 600),
(@definition, @t1_large_driller, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_large_driller, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_large_driller, 1)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600),
(@definition, @t1_large_driller, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_large_driller, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_large_driller, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

-- Robots --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @plasteosine, 10000),
(@definition, @alligior, 9000),
(@definition, @espitium, 9000),
(@definition, @flux, 2400)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @plasteosine, 10000),
(@definition, @alligior, 9000),
(@definition, @espitium, 9000),
(@definition, @flux, 2400),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 160)

-- Ammo --

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @polynucleit, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @polynucleit, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @phlobotil, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @phlobotil, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @polynitrocol, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @polynitrocol, 180)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @bryochite, 90),
(@definition, @statichnol, 90),
(@definition, @isopropentol, 90),
(@definition, @metachropin, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @bryochite, 90),
(@definition, @statichnol, 90),
(@definition, @isopropentol, 90),
(@definition, @metachropin, 90)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @bryochite, 135),
(@definition, @hydrobenol, 135)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @bryochite, 135),
(@definition, @hydrobenol, 135)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial_cprg')
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
DECLARE @titan INT
DECLARE @stermonit INT
DECLARE @silgium INT
DECLARE @imentium INT
DECLARE @flux INT
DECLARE @gammaterial INT
DECLARE @group INT
DECLARE @tempTable TABLE (parentdefinition INT, childdefinition INT, groupID INT, x INT, y INT, enablerextensionid INT)

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')
SET @titan = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan')
SET @stermonit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit')
SET @silgium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium')
SET @imentium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium')
SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore')
SET @gammaterial = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'indy')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(0, @robot, @group, 5, 10, NULL),
(@robot, @t1, @group, 6, 11, NULL),
(@t1, @t2, @group, 7, 11, NULL),
(@t2, @t3, @group, 8, 11, NULL),
(@t3, @t4, @group, 9, 11, NULL),
(@t1, @titan, @group, 6, 12, NULL),
(@t2, @stermonit, @group, 7, 12, NULL),
(@t2, @silgium, @group, 7, 13, NULL),
(@t2, @imentium, @group, 7, 14, NULL),
(@t3, @flux, @group, 8, 12, NULL),
(@t4, @gammaterial, @group, 9, 12, NULL)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 108000),
(@definition, @industrial, 108000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 34300),
(@definition, @industrial, 34300)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 51200),
(@definition, @industrial, 51200)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 72900),
(@definition, @industrial, 72900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 50000),
(@definition, @industrial, 100000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_titan')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 51450),
(@definition, @industrial, 102900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_stermonit')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 76800),
(@definition, @industrial, 153600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_silgium')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 76800),
(@definition, @industrial, 153600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_imentium')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 76800),
(@definition, @industrial, 153600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_fluxore')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 109350),
(@definition, @industrial, 218700)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_gammaterial')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 150000),
(@definition, @industrial, 300000)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_large_driller')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_large_driller_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_large_driller')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_large_driller_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_large_driller')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_large_driller_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_terramotus_bot')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_terramotus_bot_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_titan')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_titan_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_stermonit')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_stermonit_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_silgium')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_silgium_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_imentium')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_imentium_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_fluxore')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_fluxore_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_gammaterial')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_gammaterial_pr')

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

-- Paint bots

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#D65617')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#106CB5')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#106CB5')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#396C43')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#396C43')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#FFBC00')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#FFBC00')
END

GO