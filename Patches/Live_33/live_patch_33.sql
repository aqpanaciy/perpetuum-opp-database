USE [perpetuumsa]
GO

CREATE PROCEDURE dbo.indexesMaintenance
AS
BEGIN

	SET NOCOUNT ON

	CREATE TABLE #Fragmentation 
	(
		TableName NVARCHAR(200),
		IndexName NVARCHAR(200),
		FragmentationAmount DECIMAL(18,4)
	)

	-- Load all of the fragmented tables
	INSERT INTO #Fragmentation (TableName, IndexName, FragmentationAmount)
		SELECT  DISTINCT 
			TableName = S.name + '.' + tbl.[name],
			IndexName = ind.name,
			FragmentationAmount = MAX(mn.avg_fragmentation_in_percent)
		FROM sys.dm_db_index_physical_stats(NULL, NULL, NULL, NULL, NULL) AS mn
			INNER JOIN sys.tables tbl ON tbl.[object_id] = mn.[object_id]
			INNER JOIN sys.indexes ind ON ind.[object_id] = mn.[object_id]
			INNER JOIN sys.schemas S ON tbl.schema_id = S.schema_id
		WHERE [database_id] = DB_ID() AND
			mn.avg_fragmentation_in_percent > 5 AND
			ind.type_desc <> 'NONCLUSTERED COLUMNSTORE' AND
			ind.name IS NOT NULL
		GROUP BY S.name + '.' + tbl.[name], ind.name
		ORDER BY MAX(mn.avg_fragmentation_in_percent) DESC

	DECLARE @tableName NVARCHAR(200)
	DECLARE @indexName NVARCHAR(200)
	DECLARE @fragmentationAmount DECIMAL(18,4)
	DECLARE @sql VARCHAR(1000)

	DECLARE curse CURSOR FAST_FORWARD READ_ONLY FOR
		SELECT TableName, IndexName, FragmentationAmount FROM #Fragmentation

	OPEN curse

	FETCH NEXT FROM curse INTO @tableName, @indexName, @fragmentationAmount

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = 'ALTER INDEX ' + @IndexName + ' ON ' + @TableName + CASE WHEN @FragmentationAmount > 30 THEN ' REBUILD' ELSE ' REORGANIZE' END

		PRINT @sql
		EXEC(@sql)

		FETCH NEXT FROM curse INTO @tableName, @indexName, @fragmentationAmount
	END

	CLOSE curse
	DEALLOCATE curse

	DROP TABLE #Fragmentation

END

GO

PRINT N'00_Perform_index_maintenance.sql';

EXEC dbo.indexesMaintenance

GO

PRINT N'01_Add_new_ores.sql';

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

PRINT N'02_Daoden.sql';

-- Reenabling, repositioning Daoden and making it PvP

UPDATE zones SET enabled = 1, active = 1, protected = 0, raceid = 1, x = -20000, y = -1000 WHERE name = 'zone_ASI'

GO

---- Add relics

DECLARE @sourceZoneId INT
DECLARE @destinationZoneId INT

SET @sourceZoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z117')
SET @destinationZoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')
  
DELETE FROM relicspawninfo WHERE zoneid = @destinationZoneId

INSERT INTO relicspawninfo (relictypeid, zoneid, rate, x, y)
SELECT relictypeid, @destinationZoneId, rate, x, y FROM relicspawninfo WHERE zoneid = @sourceZoneId

DELETE FROM reliczoneconfig WHERE zoneid = @destinationZoneId

INSERT INTO reliczoneconfig (zoneid, maxspawn, respawnrate)
SELECT @destinationZoneId, maxspawn, respawnrate FROM reliczoneconfig WHERE zoneid = @sourceZoneId

GO

---- Fill syndicate market

IF NOT EXISTS (SELECT 1 FROM itemshoppresets WHERE name = 'daoden_preset')
BEGIN
	INSERT INTO itemshoppresets (name, note) VALUES ('daoden_preset', 'Daoden preset')
END

DECLARE @sourcePresetId INT
DECLARE @destinationPresetId INT

SET @sourcePresetId = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'asi_preset_pve')
SET @destinationPresetId = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')

DECLARE @locationEid INT

SET @locationEid = (SELECT TOP 1 eid FROM entities WHERE ename = 'def_base_item_shop_megacorp_ASI_base_ASI')

UPDATE itemshoplocations SET presetid = @destinationPresetId WHERE locationeid = @locationEid

SET @locationEid = (SELECT TOP 1 eid FROM entities WHERE ename = 'def_base_item_shop_megacorp_ASI_asi_outpost_s_03')

UPDATE itemshoplocations SET presetid = @destinationPresetId WHERE locationeid = @locationEid

SET @locationEid = (SELECT TOP 1 eid FROM entities WHERE ename = 'def_base_item_shop_megacorp_ASI_asi_outpost_w_01')

UPDATE itemshoplocations SET presetid = @destinationPresetId WHERE locationeid = @locationEid

SET @locationEid = (SELECT TOP 1 eid FROM entities WHERE ename = 'def_base_item_shop_megacorp_ASI_asi_outpost_i_02')

UPDATE itemshoplocations SET presetid = @destinationPresetId WHERE locationeid = @locationEid

DELETE FROM itemshop WHERE presetid = @destinationPresetId

INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing)
SELECT @destinationPresetId, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing FROM itemshop its
INNER JOIN entitydefaults ed ON  its.targetdefinition = ed.definition
WHERE presetid = @sourcePresetId AND ed.categoryflags != 328859

GO

---- Set up missions for daoden

DECLARE @zoneid INT

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

UPDATE missionlocations SET maxmissionlevel = 7 WHERE zoneid = @zoneid

UPDATE missions SET listable = 0 WHERE name = 'mission_asi_gen_tutorial_exp3_01'
UPDATE missions SET listable = 0 WHERE name = 'mission_asi_gen_tutorial_exp3_02'
UPDATE missions SET listable = 0 WHERE name = 'mission_asi_gen_tutorial_exp3_03'
UPDATE missions SET listable = 0 WHERE name = 'mission_asi_gen_tutorial_exp3_04'
UPDATE missions SET listable = 0 WHERE name = 'mission_asi_gen_tutorial_exp3_05'

GO

-- Disable existing spawns

UPDATE p
SET p.enabled = 0
FROM npcpresence p 
INNER JOIN zones z 
ON p.spawnid = z.spawnid
WHERE z.name IN ('zone_ASI') AND p.enabled = 1 AND p.izgroupid IS NULL

GO

---- Add rare resources

DECLARE @sourceZoneId INT
DECLARE @destinationZoneId INT
DECLARE @mineralId INT

SET @sourceZoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_TM_pve')
SET @destinationZoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM mineralconfigs WHERE zoneid = @destinationZoneId

INSERT INTO mineralconfigs (zoneid, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold)
(SELECT @destinationZoneId, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold FROM mineralconfigs WHERE zoneid = @sourceZoneId)

SET @sourceZoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ICS_A_real')

SET @mineralId = (SELECT TOP 1 idx FROM minerals WHERE name = 'epriton')

INSERT INTO mineralconfigs (zoneid, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold)
(SELECT @destinationZoneId, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold FROM mineralconfigs WHERE zoneid = @sourceZoneId AND materialtype = @mineralId)

SET @mineralId = (SELECT TOP 1 idx FROM minerals WHERE name = 'fluxore')

INSERT INTO mineralconfigs (zoneid, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold)
(SELECT @destinationZoneId, materialtype, maxnodes, maxtilespernode, totalamountpernode, minthreshold FROM mineralconfigs WHERE zoneid = @sourceZoneId AND materialtype = @mineralId)

GO

---- Reconfigure plants

DECLARE @rulesetid INT

SET @rulesetid = (SELECT TOP 1 plantruleset FROM zones WHERE name = 'zone_ASI')

DELETE FROM plantrules WHERE rulesetid = @rulesetid

INSERT INTO plantrules (plantrule, rulesetid, note) VALUES
('bonsai.txt', @rulesetid, 'decor'),
('bush_a.txt', @rulesetid, 'decor'),
('bush_b.txt', @rulesetid, 'decor'),
('coppertree.txt', @rulesetid, 'decor'),
('devrinol.txt', @rulesetid, 'decor'),
('electroplant_wild.txt', @rulesetid, 'harvestable'),
('grass_a.txt', @rulesetid, 'decor'),
('grass_b.txt', @rulesetid, 'decor'),
('irontree_wild.txt', @rulesetid, 'harvestable'),
('nanowheat.txt', @rulesetid, 'decor'),
('pinetree.txt', @rulesetid, 'decor'),
('poffeteg.txt', @rulesetid, 'decor'),
('quag.txt', @rulesetid, 'decor'),
('rango.txt', @rulesetid, 'decor'),
('reed.txt', @rulesetid, 'decor'),
('rustbush_wild.txt', @rulesetid, 'harvestable'),
('slimeroot_wild.txt', @rulesetid, 'harvestable'),
('titanplant.txt', @rulesetid, 'decor'),
('wall.txt', @rulesetid, 'decor')

GO

-- Reconfigure teleports

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'teleport_column_asi_chotassia_to_teleport_column_asipve_1'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'teleport_column_asipve_1_to_teleport_column_asi_chotassia'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'teleport_column_asi_ruydado_Z_to_teleport_column_icspve_3'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'teleport_column_icspve_3_to_teleport_column_asi_ruydado_Z'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'tp_zone_7_8_to_tp_zone_2_10'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'tp_zone_2_10_to_tp_zone_7_8'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'teleport_column_asi_matsu_Z_to_tp_zone_6_8'

UPDATE teleportdescriptions SET active = 0, listable = 0 WHERE description = 'tp_zone_6_8_to_teleport_column_asi_matsu_Z'

UPDATE zoneentities SET enabled = 0 WHERE synckey IN (
'asi_sangutal_Z',
'asi_matsu_Z',
'asi_ruydado_Z',
'asi_golpagany_Z',
'asi_darishoto_a',
'asi_chotassia_b',
'asitutorialpunchbag',
'asi_chotassia',
'asi_hakkabor',
'asi_matsu',
'tpc_awvufzo',
'tpc_prkykye',
'tpc_ovyfjtv'
)

GO

PRINT N'03_Populate_Daoden.sql';

---- Nuimqol

-- Create and fill new npc

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @gamma_syndicate_shards INT
DECLARE @gamma_nuimqol_shards INT

SET @gamma_syndicate_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')
SET @gamma_nuimqol_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_nuimqol')

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_kain_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_kain_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_arbalest_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_arbalest_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_shield_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_cameleon_shield_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_cameleon_shield_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_shield_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_shield_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_shield_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_sequer_basic_lindy', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_sequer_basic_lindy_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_riveler_basic_lindy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_riveler_basic_lindy', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_riveler_basic_lindy_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_riveler_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_riveler_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_riveler_basic_lindy')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_laird_basic_lindy', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_laird_basic_lindy_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_laird_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_laird_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_mesmer_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_mesmer_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_kain_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_kain_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_vagabond_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_vagabond_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_vagabond_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_vagabond_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_cameleon_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_cameleon_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_yagel_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_yagel_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_mesmer_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_mesmer_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_yagel_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_yagel_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_arbalest_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_arbalest_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_argano_basic_lindy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_argano_basic_lindy', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_argano_basic_lindy_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_argano_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_argano_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_argano_basic_lindy')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_arbalest_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_arbalest_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_arbalest_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_cameleon_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_cameleon_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_sequer_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_sequer_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_yagel_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_yagel_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_hermes_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_hermes_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_hermes_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_hermes_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_hermes_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_hermes_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_mesmer_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_mesmer_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_kain_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_kain_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_kain_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_vagabond_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_vagabond_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_vagabond_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_vagabond_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_nuimqol_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

GO

-- Add roamers for daoden

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N01_z2', 10, 10, 2038, 2038, 'daoden roamers 1', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N01_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N01_z2_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N01_z2_kain_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N01_z2_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N01_z2_arbalest_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N01_z2_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N01_z2_cameleon_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N02_z2', 10, 10, 2038, 2038, 'daoden roamers 2', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_mesmer_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_mesmer_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_kain_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_kain_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_vagabond_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_cameleon_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N02_z2_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N02_z2_yagel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N03_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N03_z2', 10, 10, 2038, 2038, 'daoden roamers 3', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N03_z2'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N03_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N03_z2_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N03_z2_arbalest_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N03_z2_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N03_z2_vagabond_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N03_z2_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N03_z2_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N04_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N04_z2', 10, 10, 2038, 2038, 'daoden roamers 4', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N04_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N04_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N04_z2_mesmer_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N04_z2_mesmer_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N04_z2_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N04_z2_yagel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N04_z2_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N04_z2_arbalest_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 5

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N05_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N05_z2', 10, 10, 2038, 2038, 'daoden roamers 5', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N05_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N05_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N05_z2_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N05_z2_kain_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N05_z2_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N05_z2_vagabond_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N05_z2_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N05_z2_cameleon_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N05_z2_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N05_z2_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 6

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N06_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N06_z2', 10, 10, 2038, 2038, 'daoden roamers 6', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N06_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N06_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N06_z2_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N06_z2_yagel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N06_z2_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N06_z2_arbalest_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N06_z2_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N06_z2_cameleon_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N06_z2_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N06_z2_kain_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 7

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N07_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N07_z2', 10, 10, 2038, 2038, 'daoden roamers 7', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N07_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N07_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N07_z2_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N07_z2_yagel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N07_z2_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N07_z2_cameleon_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N07_z2_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N07_z2_arbalest_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 8

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N08_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N08_z2', 10, 10, 2038, 2038, 'daoden roamers 8', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N08_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N08_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N08_z2_mesmer_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N08_z2_mesmer_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N08_z2_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N08_z2_kain_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N08_z2_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N08_z2_cameleon_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N08_z2_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N08_z2_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 9

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_N09_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_N09_z2', 10, 10, 2038, 2038, 'daoden roamers 9', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_N09_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_N09_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N09_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N09_z2_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N09_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N09_z2_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N09_z2_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N09_z2_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N09_z2_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N09_z2_arbalest_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_N09_z2_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_N09_z2_yagel_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- courier 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_N01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_N01_z2', 10, 10, 2038, 2038, 'daoden courier 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_N01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_N01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_arbalest_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_N01_z2_def_npc_daoden_arbalest_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_N01_z2_def_npc_daoden_arbalest_advanced_courier', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_cameleon_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_N01_z2_def_npc_daoden_cameleon_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_N01_z2_def_npc_daoden_cameleon_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_N01_z2_def_npc_daoden_sequer_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_N01_z2_def_npc_daoden_sequer_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET flockmembercount = 1 WHERE name = 'courier_N01_z2_def_npc_daoden_sequer_advanced_courier'
END

--- courier 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_N02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_N02_z2', 10, 10, 2038, 2038, 'daoden courier 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_N02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_N02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_yagel_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_N02_z2_def_npc_daoden_yagel_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_N02_z2_def_npc_daoden_yagel_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_hermes_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_N02_z2_def_npc_daoden_hermes_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_N02_z2_def_npc_daoden_hermes_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

-- observer 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_N01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_N01_z2', 10, 10, 2038, 2038, 'daoden observer 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_N01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_N01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_N01_z2_def_npc_daoden_mesmer_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_N01_z2_def_npc_daoden_mesmer_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_N01_z2_def_npc_daoden_kain_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_N01_z2_def_npc_daoden_kain_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_N01_z2_def_npc_daoden_vagabond_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_N01_z2_def_npc_daoden_vagabond_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

-- observer 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_N02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_N02_z2', 10, 10, 2038, 2038, 'daoden observer 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_N02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_N02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_kain_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_N02_z2_def_npc_daoden_kain_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_N02_z2_def_npc_daoden_kain_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_vagabond_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_N02_z2_def_npc_daoden_vagabond_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_N02_z2_def_npc_daoden_vagabond_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

GO

---- Telodica

-- Create and fill new npc

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @gamma_syndicate_shards INT
DECLARE @gamma_thelodica_shards INT

SET @gamma_syndicate_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')
SET @gamma_thelodica_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_thelodica')

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_artemis_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_artemis_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_baphomet_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_baphomet_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_shield_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_intakt_shield_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_intakt_shield_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_shield_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_shield_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_shield_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_sequer_basic_lindy', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_sequer_basic_lindy_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_seth_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_seth_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_seth_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_artemis_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_artemis_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_zenith_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_zenith_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_zenith_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_zenith_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_intakt_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_intakt_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_prometheus_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_prometheus_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_seth_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_seth_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_seth_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_seth_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_prometheus_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_prometheus_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_baphomet_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_baphomet_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_baphomet_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_baphomet_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_baphomet_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_intakt_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_intakt_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_intakt_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_prometheus_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_prometheus_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_prometheus_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_seth_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_seth_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_seth_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_seth_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_artemis_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_artemis_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_artemis_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_zenith_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_zenith_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_zenith_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_zenith_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_thelodica_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

GO

-- Add roamers for Shinjalar

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T01_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 1', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T01_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T01_z2_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T01_z2_artemis_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T01_z2_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T01_z2_baphomet_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T01_z2_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T01_z2_intakt_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T02_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 2', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_seth_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_seth_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_artemis_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_artemis_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_zenith_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_intakt_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T02_z2_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T02_z2_prometheus_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T03_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T03_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 3', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T03_z2'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T03_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T03_z2_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T03_z2_baphomet_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T03_z2_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T03_z2_zenith_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T03_z2_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T03_z2_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T04_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T04_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 4', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T04_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T04_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T04_z2_seth_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T04_z2_seth_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T04_z2_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T04_z2_prometheus_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T04_z2_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T04_z2_baphomet_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 5

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T05_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T05_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 5', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T05_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T05_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T05_z2_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T05_z2_artemis_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T05_z2_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T05_z2_zenith_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T05_z2_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T05_z2_intakt_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T05_z2_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T05_z2_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 6

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T06_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T06_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 6', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T06_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T06_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T06_z2_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T06_z2_prometheus_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T06_z2_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T06_z2_baphomet_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T06_z2_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T06_z2_intakt_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T06_z2_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T06_z2_artemis_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 7

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T07_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T07_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 7', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T07_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T07_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T07_z2_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T07_z2_prometheus_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T07_z2_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T07_z2_intakt_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T07_z2_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T07_z2_baphomet_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 8

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T08_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T08_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 8', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T08_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T08_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T08_z2_seth_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T08_z2_seth_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T08_z2_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T08_z2_artemis_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T08_z2_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T08_z2_intakt_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T08_z2_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T08_z2_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 9

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_T09_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_T09_z2', 10, 10, 2038, 2038, 'Shinjalar roamers 9', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_T09_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_T09_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T09_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T09_z2_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T09_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T09_z2_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T09_z2_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T09_z2_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T09_z2_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T09_z2_baphomet_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_T09_z2_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_T09_z2_prometheus_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- courier 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_T01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_T01_z2', 10, 10, 2038, 2038, 'Shinjalar courier 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_T01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_T01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_baphomet_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_T01_z2_def_npc_daoden_baphomet_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_T01_z2_def_npc_daoden_baphomet_advanced_courier', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_intakt_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_T01_z2_def_npc_daoden_intakt_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_T01_z2_def_npc_daoden_intakt_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_T01_z2_def_npc_daoden_sequer_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_T01_z2_def_npc_daoden_sequer_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET flockmembercount = 1 WHERE name = 'courier_T01_z2_def_npc_daoden_sequer_advanced_courier'
END

--- courier 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_T02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_T02_z2', 10, 10, 2038, 2038, 'Shinjalar courier 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_T02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_T02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_prometheus_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_T02_z2_def_npc_daoden_prometheus_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_T02_z2_def_npc_daoden_prometheus_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_hermes_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_T02_z2_def_npc_daoden_hermes_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_T02_z2_def_npc_daoden_hermes_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

-- observer 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_T01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_T01_z2', 10, 10, 2038, 2038, 'Shinjalar observer 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_T01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_T01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_T01_z2_def_npc_daoden_seth_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_T01_z2_def_npc_daoden_seth_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_T01_z2_def_npc_daoden_artemis_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_T01_z2_def_npc_daoden_artemis_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_T01_z2_def_npc_daoden_zenith_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_T01_z2_def_npc_daoden_zenith_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

-- observer 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_T02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_T02_z2', 10, 10, 2038, 2038, 'Shinjalar observer 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_T02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_T02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_artemis_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_T02_z2_def_npc_daoden_artemis_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_T02_z2_def_npc_daoden_artemis_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_zenith_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_T02_z2_def_npc_daoden_zenith_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_T02_z2_def_npc_daoden_zenith_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

GO

---- Attalica

-- Create and fill new npc

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @gamma_syndicate_shards INT
DECLARE @gamma_pelistal_shards INT

SET @gamma_syndicate_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')
SET @gamma_pelistal_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_pelistal')

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_tyrannos_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_tyrannos_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_waspish_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_waspish_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_shield_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_troiar_shield_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_troiar_shield_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_shield_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_shield_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_shield_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_gropho_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_gropho_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_mesmer_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_gropho_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_tank_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_tyrannos_tank_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_tyrannos_tank_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_tank_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_tank_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_tank_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_ictus_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_ictus_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_ictus_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_ictus_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_armor_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_troiar_armor_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_troiar_armor_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_armor_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_armor_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_armor_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_castel_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_castel_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_dps_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_gropho_dps_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_gropho_dps_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_gropho_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_gropho_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_dps_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_castel_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_castel_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_speed_l3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_waspish_speed_l3', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_waspish_speed_l3_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_speed_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_speed_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_speed_l3')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_waspish_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_waspish_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_waspish_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_troiar_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_troiar_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_troiar_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_advanced_courier')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_castel_advanced_courier', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_castel_advanced_courier_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_advanced_courier'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_castel_advanced_courier')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_advanced_courier')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_gropho_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_gropho_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_gropho_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_gropho_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_tyrannos_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_tyrannos_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_tyrannos_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_advanced_observer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_daoden_ictus_advanced_observer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_daoden_ictus_advanced_observer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_ictus_advanced_observer'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_ictus_advanced_observer')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_advanced_observer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4)) AND nl.lootdefinition != @gamma_syndicate_shards AND nl.lootdefinition != @gamma_pelistal_shards

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

GO

-- Add roamers for daoden

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P01_z2', 10, 10, 2038, 2038, 'daoden roamers 1', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P01_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P01_z2_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P01_z2_tyrannos_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P01_z2_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P01_z2_waspish_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P01_z2_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P01_z2_troiar_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P02_z2', 10, 10, 2038, 2038, 'daoden roamers 2', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_gropho_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_gropho_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_tyrannos_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_tyrannos_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_ictus_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_troiar_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P02_z2_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P02_z2_castel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P03_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P03_z2', 10, 10, 2038, 2038, 'daoden roamers 3', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P03_z2'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P03_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P03_z2_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P03_z2_waspish_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P03_z2_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P03_z2_ictus_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P03_z2_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P03_z2_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P04_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P04_z2', 10, 10, 2038, 2038, 'daoden roamers 4', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P04_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P04_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P04_z2_gropho_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P04_z2_gropho_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P04_z2_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P04_z2_castel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P04_z2_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P04_z2_waspish_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 5

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P05_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P05_z2', 10, 10, 2038, 2038, 'daoden roamers 5', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P05_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P05_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P05_z2_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P05_z2_tyrannos_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P05_z2_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P05_z2_ictus_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P05_z2_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P05_z2_troiar_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P05_z2_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P05_z2_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 6

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P06_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P06_z2', 10, 10, 2038, 2038, 'daoden roamers 6', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P06_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P06_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P06_z2_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P06_z2_castel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P06_z2_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P06_z2_waspish_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P06_z2_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P06_z2_troiar_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P06_z2_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P06_z2_tyrannos_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 7

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P07_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P07_z2', 10, 10, 2038, 2038, 'daoden roamers 7', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P07_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P07_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P07_z2_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P07_z2_castel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P07_z2_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P07_z2_troiar_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P07_z2_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P07_z2_waspish_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 8

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P08_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P08_z2', 10, 10, 2038, 2038, 'daoden roamers 8', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P08_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P08_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P08_z2_gropho_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P08_z2_gropho_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P08_z2_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P08_z2_tyrannos_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P08_z2_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P08_z2_troiar_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P08_z2_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P08_z2_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- roamers 9

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_P09_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_P09_z2', 10, 10, 2038, 2038, 'daoden roamers 9', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_P09_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_P09_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P09_z2_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P09_z2_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P09_z2_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P09_z2_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P09_z2_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P09_z2_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P09_z2_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P09_z2_waspish_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_P09_z2_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_P09_z2_castel_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--- courier 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_P01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_P01_z2', 10, 10, 2038, 2038, 'daoden courier 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_P01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_P01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_waspish_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_P01_z2_def_npc_daoden_waspish_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_P01_z2_def_npc_daoden_waspish_advanced_courier', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_troiar_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_P01_z2_def_npc_daoden_troiar_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_P01_z2_def_npc_daoden_troiar_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_sequer_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_P01_z2_def_npc_daoden_sequer_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_P01_z2_def_npc_daoden_sequer_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET flockmembercount = 1 WHERE name = 'courier_P01_z2_def_npc_daoden_sequer_advanced_courier'
END

--- courier 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'courier_P02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('courier_P02_z2', 10, 10, 2038, 2038, 'daoden courier 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'courier_P02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'courier_P02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_castel_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_P02_z2_def_npc_daoden_castel_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_P02_z2_def_npc_daoden_castel_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_hermes_advanced_courier')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'courier_P02_z2_def_npc_daoden_hermes_advanced_courier')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('courier_P02_z2_def_npc_daoden_hermes_advanced_courier', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 1, 0)
END

-- observer 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_P01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_P01_z2', 10, 10, 2038, 2038, 'daoden observer 1', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_P01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_P01_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_P01_z2_def_npc_daoden_gropho_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_P01_z2_def_npc_daoden_gropho_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_P01_z2_def_npc_daoden_tyrannos_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_P01_z2_def_npc_daoden_tyrannos_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_P01_z2_def_npc_daoden_ictus_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_P01_z2_def_npc_daoden_ictus_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

-- observer 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_P02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_P02_z2', 10, 10, 2038, 2038, 'daoden observer 2', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_P02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_P02_z2')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_tyrannos_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_P02_z2_def_npc_daoden_tyrannos_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_P02_z2_def_npc_daoden_tyrannos_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_ictus_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_P02_z2_def_npc_daoden_ictus_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_P02_z2_def_npc_daoden_ictus_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END

GO

PRINT N'04_Gods_Bless.sql';

-- Add effect

DECLARE @effectCatName BIGINT
SET @effectCatName = (SELECT TOP 1 flag FROM effectcategories WHERE name = 'effcat_zone_effects')

DECLARE @effectName AS VARCHAR(100) = 'effect_gods_bless';

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = @effectName)
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCatName, 0, @effectName, @effectName+'_desc', 'Gods Bless effect', 1, 0, 1, 1, 0)
END

DECLARE @effectId INT;

SET @effectId = (SELECT TOP 1 id FROM effects WHERE name = @effectName)

DECLARE @zoneId INT

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM zoneeffects WHERE zoneid = @zoneId;

INSERT INTO zoneeffects (zoneid, effectid) VALUES
(@zoneId, @effectId)

GO

PRINT N'05_Syndicate_Forces.sql';

DECLARE @targetDefinition INT
DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_forces_echelon_main_combat_bot', 1, 1024, 1167, '#faction=SSyndicate', 'Echelon, Armor, Machine Guns', 1, 0, 0, 0, 100, 'def_syndicate_forces_echelon_main_combat_bot_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SSyndicate' WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot'
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -0.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -0.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -10 WHERE definition = @targetDefinition AND field = @field
END

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT

DECLARE @sensor_booster INT
DECLARE @s_demob INT
DECLARE @firearm_tuning INT
DECLARE @medium_mg INT
DECLARE @mg_ammo INT
DECLARE @medium_armor_rep INT
DECLARE @medium_injector INT
DECLARE @injector_charges INT
DECLARE @uni_plate INT
DECLARE @med_plate INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_echelon_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_mech')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
SET @s_demob = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_webber')
SET @firearm_tuning = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_damage_mod_projectile')
SET @medium_mg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_autocannon')
SET @mg_ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_rewa')
SET @medium_armor_rep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
SET @medium_injector = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_booster')
SET @injector_charges = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_corebooster_ammo')
SET @uni_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
SET @med_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Echelon_Main_Combat')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Echelon_Main_Combat', CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@s_demob, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@firearm_tuning, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@firearm_tuning, 'X'),
		'|slot=i5]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@medium_mg, 'X'),
		'|slot=i1|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m1=[|definition=i',
		FORMAT(@medium_mg, 'X'),
		'|slot=i2|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m2=[|definition=i',
		FORMAT(@medium_mg, 'X'),
		'|slot=i3|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m3=[|definition=i',
		FORMAT(@medium_mg, 'X'),
		'|slot=i4|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]]#legModules=[|m0=[|definition=i',
		FORMAT(@medium_armor_rep, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@medium_injector, 'X'),
		'|slot=i2|ammoDefinition=i',
		FORMAT(@injector_charges, 'X'),
		'|ammoQuantity=i8]|m2=[|definition=i',
		FORMAT(@uni_plate, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@uni_plate, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@med_plate, 'X'),
		'|slot=i5]]'), 'Syndicate Forces Main Combat Echelon')
END

DECLARE @templateId INT

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Echelon_Main_Combat')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 15, 'def_npc_daoden_echelon_main_combat')


--- squad 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'syndicate_N01_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('syndicate_N01_z2', 510, 1025, 895, 1405, 'daoden syndicate forces 1', @spawnid, 1, 1, 900, 5, NULL, 720, 1270, 500, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 510, topy = 1025, bottomx = 895, bottomy = 1405, randomcenterx = 720, randomcentery = 1270, randomradius = 500, roamingrespawnseconds = 900
	WHERE name = 'syndicate_N01_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'syndicate_N01_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'syndicate_N01_z2_echelon_main_combat')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('syndicate_N01_z2_echelon_main_combat', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 900 WHERE name = 'syndicate_N01_z2_echelon_main_combat'
END
	
--- squad 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'syndicate_N02_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('syndicate_N02_z2', 510, 1025, 895, 1405, 'daoden syndicate forces 2', @spawnid, 1, 1, 900, 5, NULL, 720, 1270, 500, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 510, topy = 1025, bottomx = 895, bottomy = 1405, randomcenterx = 720, randomcentery = 1270, randomradius = 500, roamingrespawnseconds = 900
	WHERE name = 'syndicate_N02_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'syndicate_N02_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'syndicate_N02_z2_echelon_main_combat')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('syndicate_N02_z2_echelon_main_combat', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 900 WHERE name = 'syndicate_N02_z2_echelon_main_combat'
END

--- squad 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'syndicate_N03_z2' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('syndicate_N03_z2', 510, 1025, 895, 1405, 'daoden syndicate forces 3', @spawnid, 1, 1, 900, 5, NULL, 720, 1270, 500, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 510, topy = 1025, bottomx = 895, bottomy = 1405, randomcenterx = 720, randomcentery = 1270, randomradius = 500, roamingrespawnseconds = 900
	WHERE name = 'syndicate_N03_z2'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'syndicate_N03_z2')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_echelon_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'syndicate_N03_z2_echelon_main_combat')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('syndicate_N03_z2_echelon_main_combat', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'daoden npc', 0.9, 1, 1, 2, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 900 WHERE name = 'syndicate_N03_z2_echelon_main_combat'
END

GO

---- Mark drones as Syndicate

UPDATE entitydefaults SET options = '#head=n8647  #chassis=n8648  #leg=n8649  #inventory=n8650 #faction=sSyndicate' WHERE definitionname = 'def_harvesting_industrial_drone'
UPDATE entitydefaults SET options = '#head=n8641  #chassis=n8642  #leg=n8643  #inventory=n8644 #faction=sSyndicate' WHERE definitionname = 'def_mining_industrial_drone'
UPDATE entitydefaults SET options = '#head=n8599  #chassis=n8600  #leg=n8601  #inventory=n8602 #faction=sSyndicate' WHERE definitionname = 'def_nuimqol_assault_drone'
UPDATE entitydefaults SET options = '#head=n8623  #chassis=n8624  #leg=n8625  #inventory=n8626 #faction=sSyndicate' WHERE definitionname = 'def_nuimqol_attack_drone'
UPDATE entitydefaults SET options = '#head=n8611  #chassis=n8612  #leg=n8613  #inventory=n8614 #faction=sSyndicate' WHERE definitionname = 'def_pelistal_assault_drone'
UPDATE entitydefaults SET options = '#head=n8635  #chassis=n8636  #leg=n8637  #inventory=n8638 #faction=sSyndicate' WHERE definitionname = 'def_pelistal_attack_drone'
UPDATE entitydefaults SET options = '#head=n8653  #chassis=n8654  #leg=n8655  #inventory=n8656 #faction=sSyndicate' WHERE definitionname = 'def_repair_support_drone'
UPDATE entitydefaults SET options = '#head=n8593  #chassis=n8594  #leg=n8595  #inventory=n8596 #faction=sSyndicate' WHERE definitionname = 'def_syndicate_assault_drone'
UPDATE entitydefaults SET options = '#head=n8617  #chassis=n8618  #leg=n8619  #inventory=n8620 #faction=sSyndicate' WHERE definitionname = 'def_syndicate_attack_drone'
UPDATE entitydefaults SET options = '#head=n8605  #chassis=n8606  #leg=n8607  #inventory=n8608 #faction=sSyndicate' WHERE definitionname = 'def_thelodica_assault_drone'
UPDATE entitydefaults SET options = '#head=n8629  #chassis=n8630  #leg=n8631  #inventory=n8632 #faction=sSyndicate' WHERE definitionname = 'def_thelodica_attack_drone'

GO

PRINT N'06_Anomaly_entrance.sql';

---- Create Daoden entrance

DECLARE @zoneId INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @destinationGroupId INT
DECLARE @flockId INT
DECLARE @riftConfigId INT
DECLARE @artifactType INT

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_TM_pve')

-- Create and fill gatekeeper definition

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_gatekeeper_locust_lvl1')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_gatekeeper_locust_lvl1', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_gatekeeper_locust_lvl1_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_locust_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_locust_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gatekeeper_locust_lvl1')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

DELETE FROM npcloot WHERE definition = @targetDefinition

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, nl.lootdefinition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults ed ON nl.lootdefinition = ed.definition
WHERE nl.definition = @sourceDefinition AND (ed.tierlevel IS NULL OR (ed.tierlevel != 4))

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
SELECT @targetDefinition, t3.definition, nl.quantity, nl.probability, nl.repackaged, nl.dontdamage, nl.minquantity FROM npcloot nl
INNER JOIN entitydefaults t4 ON nl.lootdefinition = t4.definition
INNER JOIN entitydefaults t3 ON t4.categoryflags = t3.categoryflags
WHERE nl.definition = @sourceDefinition
AND t4.tiertype = 1 and  t4.tierlevel = 4 and t3.tiertype = 1 and t3.tierlevel = 3

---- Create gatekeepers

-- Hershfield

-- Create gatekeepers presence

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('hershfield_to_daoden_gatekeepers_lvl1', 0, 0, 0, 0, 'Hershfield gatekeepers', 10, 1, 0, 0, 2, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 0, topy = 0, bottomx = 0, bottomy = 0 WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1')

-- Create Gatekeeper flock

DELETE FROM npcflock WHERE presenceid = @presenceid

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gatekeeper_locust_lvl1')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('hershfield_to_daoden_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1', @presenceid, 1, @definition, 0, 0, 0, 5, 0, 1, 15, 'gatekeeper', 0.5, 1, 1, 2, 1)
END
ELSE
BEGIN
	UPDATE npcflock SET spawnoriginX = 0, spawnoriginY = 0 WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1'
END

-- Add rift config

DELETE FROM riftconfigs WHERE name = 'daoden_z2_entry'

INSERT INTO riftconfigs (name, destinationGroupId, lifespanSeconds, maxUses, categoryExclusionGroupId) VALUES
('daoden_z2_entry', 201, 1800, NULL, NULL)

-- Add rift destinations

SET @destinationGroupId = (SELECT TOP 1 destinationGroupId FROM riftconfigs WHERE name = 'daoden_z2_entry')

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM riftdestinations WHERE groupId = @destinationGroupId AND zoneId = @zoneId

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

-- Add boss info

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'hershfield_to_daoden_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1')

SET @riftConfigId = (SELECT TOP 1 id FROM riftconfigs WHERE name = 'daoden_z2_entry')

INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced, isServerWideAnnouncement, isNoRadioDelay) VALUES
(@flockId, 0.15, 0, NULL, NULL, 0, '...Hold...the...door...', 'Network security breach. Initiating extermination protocol', @riftConfigId, 0, NULL, NULL)

-- Create artifact type

IF NOT EXISTS (SELECT 1 FROM artifacttypes WHERE name = 'gateway_hershfield_to_daoden_lvl1')
BEGIN
	INSERT INTO artifacttypes (name, goalrange, npcpresenceid, persistent, minimumloot, dynamic)
	VALUES ('gateway_hershfield_to_daoden_lvl1', 10, @presenceId, 1, 0, 0)
END

-- Create artifact spawn info

SET @artifactType = (SELECT TOP 1 id FROM artifacttypes WHERE name = 'gateway_hershfield_to_daoden_lvl1')

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_TM_pve')

DELETE FROM artifactspawninfo WHERE artifacttype = @artifactType

INSERT INTO artifactspawninfo (artifacttype, zoneid, rate) VALUES
(@artifactType, @zoneId, 99)

-- Daoden

-- Create gatekeepers presence

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'daoden_to_alpha_gatekeepers_lvl1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('daoden_to_alpha_gatekeepers_lvl1', 0, 0, 0, 0, 'Daoden gatekeepers', 10, 1, 0, 0, 2, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 0, topy = 0, bottomx = 0, bottomy = 0 WHERE name = 'daoden_to_alpha_gatekeepers_lvl1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'daoden_to_alpha_gatekeepers_lvl1')

-- Create Gatekeeper flock

DELETE FROM npcflock WHERE presenceid = @presenceid

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gatekeeper_locust_lvl1')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'daoden_to_alpha_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('daoden_to_alpha_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1', @presenceid, 1, @definition, 0, 0, 0, 5, 0, 1, 15, 'gatekeeper', 0.5, 1, 1, 2, 1)
END
ELSE
BEGIN
	UPDATE npcflock SET spawnoriginX = 0, spawnoriginY = 0 WHERE name = 'daoden_to_alpha_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1'
END

-- Add rift config

DELETE FROM riftconfigs WHERE name = 'daoden_z2_exit'

INSERT INTO riftconfigs (name, destinationGroupId, lifespanSeconds, maxUses, categoryExclusionGroupId) VALUES
('daoden_z2_exit', 200, 1800, NULL, NULL)

-- Add rift destinations

SET @destinationGroupId = (SELECT TOP 1 destinationGroupId FROM riftconfigs WHERE name = 'daoden_z2_exit')

DELETE FROM riftdestinations WHERE groupId = @destinationGroupId

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_TM')

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ICS')

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ICS_pve')

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI_pve')

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_TM_pve')

INSERT INTO riftdestinations (groupId, zoneId, x, y, weight) VALUES
(@destinationGroupId, @zoneId, NULL, NULL, 1)

-- Add boss info

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'daoden_to_alpha_gatekeepers_lvl1_def_npc_gatekeeper_locust_lvl1')

SET @riftConfigId = (SELECT TOP 1 id FROM riftconfigs WHERE name = 'daoden_z2_exit')

INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced, isServerWideAnnouncement, isNoRadioDelay) VALUES
(@flockId, 0.15, 0, NULL, NULL, 0, '...Hold...the...door...', 'Network security breach. Initiating extermination protocol', @riftConfigId, 0, NULL, NULL)

-- Create artifact type

IF NOT EXISTS (SELECT 1 FROM artifacttypes WHERE name = 'gateway_daoden_to_alpha_lvl1')
BEGIN
	INSERT INTO artifacttypes (name, goalrange, npcpresenceid, persistent, minimumloot, dynamic)
	VALUES ('gateway_daoden_to_alpha_lvl1', 10, @presenceId, 1, 0, 0)
END

-- Create artifact spawn info

SET @artifactType = (SELECT TOP 1 id FROM artifacttypes WHERE name = 'gateway_daoden_to_alpha_lvl1')

SET @zoneId = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM artifactspawninfo WHERE artifacttype = @artifactType

INSERT INTO artifactspawninfo (artifacttype, zoneid, rate) VALUES
(@artifactType, @zoneId, 99)

GO

PRINT N'07_Syndicate_shop.sql';

---- Spark Teleport Devices ----
DECLARE @categoryFlags INT
DECLARE @options VARCHAR(MAX)
DECLARE @baseeid INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_spark_teleport_devices')

SET @baseeid = (SELECT TOP 1 eid FROM entities WHERE ename = 'base_ASI')
SET @options = CONCAT('#baseId=n', @baseeid)

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_spark_teleport_device_daoden')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) 
	VALUES ( 'def_spark_teleport_device_daoden', 1, 2052, @categoryFlags, @options, '', 1, 2, 50000, 0, 100, 'def_spark_teleport_device_daoden_desc', 1, 0, 0);
END

GO

---- Add Daoden as spark teleport location ----

DECLARE @basedefinition INT
DECLARE @baseeid INT

SET @basedefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_public_docking_base_thelodica')

SET @baseeid = (SELECT TOP 1 eid FROM entities WHERE ename = 'base_ASI')

IF NOT EXISTS (SELECT 1 FROM charactersparkteleports WHERE characterid = 0 AND baseeid = @baseeid AND basedefinition = @basedefinition)
BEGIN
	INSERT INTO [charactersparkteleports] (characterid, baseeid, basedefinition, zoneid, x, y) VALUES
	(0, @baseeid, @basedefinition, 2, 721.5, 1271.5)
END

GO

---- Enable black bots and reward items

UPDATE entitydefaults SET enabled = 1, hidden = 0 WHERE definitionname in (
'def_gropho_reward1_bot',
'def_mesmer_reward1_bot',
'def_purgatory_mass_reductor_reward',
'def_seth_reward1_bot',
'def_tux_shield_hardener_reward'
)

GO

---- Add Spark Teleport Devices and other items into Syndicate shop ----

DECLARE @definition INT
DECLARE @itemshop_preset INT
SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spark_teleport_device_daoden')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 5000000, 300, null, 0, null)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_sensor_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_sensor_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_webber')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_webber')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_eccm')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_eccm')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_tracking_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_tracking_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_mining_probe_module')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_mining_probe_module')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_damage_mod_projectile')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_damage_mod_projectile')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_maneuvering_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_maneuvering_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_rocket_launcher')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_missile_launcher')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 1500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 1500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_driller')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_driller')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_harvester')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_harvester')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_purgatory_mass_reductor_reward')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_tux_shield_hardener_reward')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 1000000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 20000, NULL, NULL, 5000000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 20000, icscoin = NULL, asicoin = NULL, credit = 5000000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 50000, 5000000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 20000, credit = 5000000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 50000, NULL, 5000000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 20000, asicoin = NULL, credit = 5000000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

GO

PRINT N'08_Adaptive_Alloys.sql';

---- Add new category for Adaptive Alloys ----

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_adaptive_alloys')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(100925711, 'cf_adaptive_alloys', 'Adaptive alloys', 0, 1)
END

GO

---- Add adaptive alloys

DECLARE @categoryFlags INT

-- T1 Adaptive alloy

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_adaptive_alloy', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t1', '', 1, 1.5, 500, 0, 100, 'def_adaptive_alloy_desc', 1, 1, 1)
END

-- T1 Adaptive alloy CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_armor_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_adaptive_alloy_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 Adaptive alloy

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_adaptive_alloy', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t2', '', 1, 1.5, 460, 0, 100, 'def_adaptive_alloy_desc', 1, 1, 2)
END

-- T2 Adaptive alloy prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_adaptive_alloy_pr', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t2_pr', '', 1, 1.5, 330, 0, 100, 'def_adaptive_alloy_desc', 1, 2, 2)
END

-- T2 Adaptive alloy CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_armor_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_adaptive_alloy_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 Adaptive alloy

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_adaptive_alloy', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t3', '', 1, 1.5, 500, 0, 100, 'def_adaptive_alloy_desc', 1, 1, 3)
END

-- T3 Adaptive alloy prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_adaptive_alloy_pr', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t3_pr', '', 1, 1.5, 371.4, 0, 100, 'def_adaptive_alloy_desc', 1, 2, 3)
END

-- T3 Adaptive alloy CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_armor_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_adaptive_alloy_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 Adaptive alloy

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_adaptive_alloy', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t4', '', 1, 1.5, 500, 0, 100, 'def_adaptive_alloy_desc', 1, 1, 4)
END

-- T4 Adaptive alloy prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_adaptive_alloy_pr', 1, 524292, @categoryFlags, '#moduleFlag=i20  #tier=$tierlevel_t4_pr', '', 1, 1.5, 371.4, 0, 100, 'def_adaptive_alloy_desc', 1, 2, 4)
END

-- T4 Adaptive alloy CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_armor_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_adaptive_alloy_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Create new aggregate field

IF NOT EXISTS (SELECT TOP 1 name FROM aggregatefields WHERE name = 'adaptive_resist_points')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('adaptive_resist_points', 1, 'adaptive_resist_points_unit', 1, 0, 2, 0, 1, NULL, NULL)
END

GO

---- Set up aggregate fields for Adaptive alloys

DECLARE @definition INT
DECLARE @field INT

-- T1 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 38)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END

-- T2 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END

-- T2 Adaptive alloy prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 33)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END

-- T3 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 40)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- T3 Adaptive alloy prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3363)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END

-- T4 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 43)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 14)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- T4 Adaptive alloy prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 41)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 13)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'adaptive_resist_points')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 105)
END

GO

---- Add effect

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_adaptive_alloy')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(8, 0, 'effect_adaptive_alloy', 'effect_adaptive_alloy_desc', 'Adaptive alloy', 0, 0, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 0 WHERE name = 'effect_adaptive_alloy'
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

DECLARE @metachropin INT
DECLARE @prilumium INT

DECLARE @statichnol INT
DECLARE @chollonin INT

DECLARE @isopropentol INT
DECLARE @vitricyl INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1_adaptive_alloy INT
DECLARE @t2_adaptive_alloy INT
DECLARE @t3_adaptive_alloy INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol') -- axicoline Y U NO cryoperine

SET @alligior = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_alligior')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite

SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite

SET @metachropin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_metachropin')
SET @prilumium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_prilumium')

SET @statichnol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_statichnol')
SET @chollonin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_chollonin')

SET @isopropentol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_isopropentol')
SET @vitricyl = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vitricyl')

SET @common_basic_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
SET @common_advanced_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
SET @common_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

SET @t1_adaptive_alloy = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
SET @t2_adaptive_alloy = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')
SET @t3_adaptive_alloy = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 500),
(@definition, @cryoperine, 200),
(@definition, @metachropin, 65),
(@definition, @prilumium, 25),
(@definition, @statichnol, 65),
(@definition, @chollonin, 25),
(@definition, @isopropentol, 65),
(@definition, @vitricyl, 25)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 500),
(@definition, @cryoperine, 200),
(@definition, @metachropin, 65),
(@definition, @prilumium, 25),
(@definition, @statichnol, 65),
(@definition, @chollonin, 25),
(@definition, @isopropentol, 65),
(@definition, @vitricyl, 25),
(@definition, @t1_adaptive_alloy, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 250),
(@definition, @cryoperine, 100),
(@definition, @metachropin, 65),
(@definition, @prilumium, 25),
(@definition, @statichnol, 65),
(@definition, @chollonin, 25),
(@definition, @isopropentol, 65),
(@definition, @vitricyl, 25),
(@definition, @alligior, 250),
(@definition, @espitium, 100),
(@definition, @t2_adaptive_alloy, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 2500),
(@definition, @cryoperine, 100),
(@definition, @metachropin, 125),
(@definition, @prilumium, 50),
(@definition, @statichnol, 125),
(@definition, @chollonin, 50),
(@definition, @isopropentol, 125),
(@definition, @vitricyl, 50),
(@definition, @alligior, 500),
(@definition, @espitium, 200),
(@definition, @t3_adaptive_alloy, 1)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 500),
(@definition, @cryoperine, 200),
(@definition, @metachropin, 65),
(@definition, @prilumium, 25),
(@definition, @statichnol, 65),
(@definition, @chollonin, 25),
(@definition, @isopropentol, 65),
(@definition, @vitricyl, 25),
(@definition, @t1_adaptive_alloy, 1),
(@definition, @common_basic_components, 30)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 250),
(@definition, @cryoperine, 100),
(@definition, @metachropin, 65),
(@definition, @prilumium, 25),
(@definition, @statichnol, 65),
(@definition, @chollonin, 25),
(@definition, @isopropentol, 65),
(@definition, @vitricyl, 25),
(@definition, @alligior, 250),
(@definition, @espitium, 100),
(@definition, @t2_adaptive_alloy, 1),
(@definition, @common_basic_components, 20),
(@definition, @common_advanced_components, 20)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @plasteosine, 2500),
(@definition, @cryoperine, 100),
(@definition, @metachropin, 125),
(@definition, @prilumium, 50),
(@definition, @statichnol, 125),
(@definition, @chollonin, 50),
(@definition, @isopropentol, 125),
(@definition, @vitricyl, 50),
(@definition, @alligior, 500),
(@definition, @espitium, 200),
(@definition, @t3_adaptive_alloy, 1),
(@definition, @common_basic_components, 15),
(@definition, @common_advanced_components, 30),
(@definition, @common_expert_components, 45)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 3, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 4, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

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

DECLARE @parent INT
DECLARE @t1 INT
DECLARE @t2 INT
DECLARE @t3 INT
DECLARE @t4 INT
DECLARE @group INT
DECLARE @tempTable TABLE (parentdefinition INT, childdefinition INT, groupID INT, x INT, y INT, enablerextensionid INT)

SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_chm_armor_hardener')
SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common1')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @t1, @group, 4, 12, NULL),
(@t1, @t2, @group, 5, 12, NULL),
(@t2, @t3, @group, 6, 12, NULL),
(@t3, @t4, @group, 7, 12, NULL)

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

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 129600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 205800)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 76800)
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 153600)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_adaptive_alloy')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_adaptive_alloy_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_adaptive_alloy')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_adaptive_alloy_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_adaptive_alloy')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_adaptive_alloy_pr')

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

PRINT N'09_Dreadnought_modules.sql';

---- Create new categories for siege modules

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_robot_enhancements')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(3087, 'cf_robot_enhancements', 'Robot enhancements', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_dreadnought_modules')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(68623, 'cf_dreadnought_modules', 'Dreadnought modules', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_robot_enhancements_calibration_programs')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(590870, 'cf_robot_enhancements_calibration_programs', 'Robot enhancements CT', 0, 0)
END

GO

---- Add dreadnought modules

DECLARE @categoryFlags INT

-- T1 dreadnought module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_dreadnought_module', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t1', '', 1, 2.5, 2000, 0, 100, 'def_dreadnought_module_desc', 1, 1, 1)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t1', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_standard_dreadnought_module'
END

-- T1 dreadnought module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_dreadnought_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 dreadnought module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_dreadnought_module', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t2', '', 1, 2.5, 1500, 0, 100, 'def_dreadnought_module_desc', 1, 1, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t2', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named1_dreadnought_module'
END

-- T2 dreadnought module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_dreadnought_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t2_pr', '', 1, 2.5, 1250, 0, 100, 'def_dreadnought_module_desc', 1, 2, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#ammoCapacity=i2d#tier=$tierlevel_t2_pr', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named1_dreadnought_module_pr'
END

-- T2 dreadnought module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_dreadnought_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 dreadnought module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_dreadnought_module', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t3', '', 1, 2.5, 1500, 0, 100, 'def_dreadnought_module_desc', 1, 1, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t3', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named2_dreadnought_module'
END

-- T3 dreadnought module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_dreadnought_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t3_pr', '', 1, 2.5, 1250, 0, 100, 'def_dreadnought_module_desc', 1, 2, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t3_pr', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named2_dreadnought_module_pr'
END

-- T3 dreadnought module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_dreadnought_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 dreadnought module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_dreadnought_module', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t4', '', 1, 2.5, 1500, 0, 100, 'def_dreadnought_module_desc', 1, 1, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t4', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named3_dreadnought_module'
END

-- T3 dreadnought module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_dreadnought_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=i908#tier=$tierlevel_t4_pr', '', 1, 2.5, 1250, 0, 100, 'def_dreadnought_module_desc', 1, 2, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i908#tier=$tierlevel_t4_pr', descriptiontoken = 'def_dreadnought_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named3_dreadnought_module_pr'
END

-- T3 dreadnought module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_dreadnought_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Set up aggregate fields for dreadnought module

DECLARE @definition INT
DECLARE @field INT

-- T1 dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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


-- T2 dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T2 dreadnought module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T3 dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T3 dreadnought module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T4 dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T4 dreadnought module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_robot_enhancements')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_robot_enhancements', 51, 1, 'Robot enhancements')
END

GO

---- Add new effects

DECLARE @effectCategory BIGINT

SET @effectCategory = 1125899906842624 -- 2^50

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_dreadnought')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 180500, 'effect_dreadnought', 'effect_dreadnought_desc', 'Dreadnought effect', 0, 0, 1, 3, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 180500 WHERE name = 'effect_dreadnought'
END

GO

-- Add dreadnought effect fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_weapon_cycle_time_modifier', 0, 'effect_dreadnought_weapon_cycle_time_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_weapon_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_weapon_cycle_time_modifier', 0, 'effect_dreadnought_enhancer_weapon_cycle_time_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_optimal_range_modifier', 0, 'effect_dreadnought_optimal_range_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_optimal_range_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_optimal_range_modifier', 0, 'effect_dreadnought_enhancer_optimal_range_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

/*
IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_mining_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_mining_amount_modifier', 0, 'effect_dreadnought_enhancer_mining_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_harvesting_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_harvesting_amount_modifier', 0, 'effect_dreadnought_enhancer_harvesting_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_mining_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_mining_cycle_time_modifier', 0, 'effect_dreadnought_enhancer_mining_cycle_time_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_harvesting_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_harvesting_cycle_time_modifier', 0, 'effect_dreadnought_enhancer_harvesting_cycle_time_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END
*/

----

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_weapon_damage_modifier', 0, 'effect_dreadnought_weapon_damage_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_weapon_damage_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_weapon_damage_modifier', 0, 'effect_dreadnought_enhancer_weapon_damage_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_speed_max_modifier', 0, 'effect_dreadnought_speed_max_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_speed_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_speed_max_modifier', 0, 'effect_dreadnought_enhancer_speed_max_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_detection_strength_modifier', 1, 'effect_dreadnought_detection_strength_modifier_unit', 1, 0, 3, 2, 1, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1, measurementmultiplier = 1, measurementoffset = 0, category = 3, digits = 2, moreisbetter = 1, usedinconfig = 1, note = NULL
	WHERE name = 'effect_dreadnought_detection_strength_modifier'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_detection_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_detection_strength_modifier', 0, 'effect_dreadnought_enhancer_detection_strength_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_stealth_strength_modifier', 1, 'effect_dreadnought_stealth_strength_modifier_unit', 1, 0, 3, 2, 1, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1, measurementmultiplier = 1, measurementoffset = 0, category = 3, digits = 2, moreisbetter = 1, usedinconfig = 1, note = NULL
	WHERE name = 'effect_dreadnought_stealth_strength_modifier'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_stealth_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_stealth_strength_modifier', 1, 'effect_dreadnought_enhancer_stealth_strength_modifier_unit', 1, 0, 3, 2, 1, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1, measurementmultiplier = 1, measurementoffset = 0, category = 3, digits = 2, moreisbetter = 1, usedinconfig = 1, note = NULL
	WHERE name = 'effect_dreadnought_enhancer_stealth_strength_modifier'
END

GO

-- Set up aggregate values for dreadnought modules

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.9)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.9)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.6)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.9)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.7)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.8)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.7)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.5)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
--INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.01)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -90)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.5)

GO

-- Set up module property modifiers

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag

/*
SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_speed_max_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_speed_max_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)
*/

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_detection_strength_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_detection_strength_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_stealth_strength_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_damage_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_weapon_damage_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_optimal_range_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_optimal_range_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_weapon_cycle_time_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_weapon_cycle_time_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO

-- Add slots to combat destroyers

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8' WHERE definitionname = 'def_onyx_bot_head'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8' WHERE definitionname = 'def_hydra_bot_head'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8' WHERE definitionname = 'def_felos_bot_head'

GO

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_robot_reactor_overheat')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_robot_reactor_overheat', 52, 1, 'Robot reactor overheat')
END

GO

---- Add new effects for overheating

DECLARE @effectCategory BIGINT

SET @effectCategory = 2251799813685248 -- 2^51

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_overheat_buildup_low')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_overheat_buildup_low', 'effect_overheat_buildup_low_desc', 'Overheat buildup low', 0, 0, 0, 3, 0)
END
ELSE
BEGIN
	 UPDATE effects SET effectcategory = @effectCategory WHERE name = 'effect_overheat_buildup_low'
END

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_overheat_buildup_medium')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_overheat_buildup_medium', 'effect_overheat_buildup_medium_desc', 'Overheat buildup medium', 0, 0, 0, 3, 0)
END
ELSE
BEGIN
	 UPDATE effects SET effectcategory = @effectCategory WHERE name = 'effect_overheat_buildup_medium'
END

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_overheat_buildup_high')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_overheat_buildup_high', 'effect_overheat_buildup_high_desc', 'Overheat buildup high', 0, 0, 0, 3, 0)
END
ELSE
BEGIN
	 UPDATE effects SET effectcategory = @effectCategory WHERE name = 'effect_overheat_buildup_high'
END

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_overheat_buildup_critical')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_overheat_buildup_critical', 'effect_overheat_buildup_critical_desc', 'Overheat buildup critical', 0, 0, 0, 3, 0)
END
ELSE
BEGIN
	 UPDATE effects SET effectcategory = @effectCategory WHERE name = 'effect_overheat_buildup_critical'
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

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1_dreadnought_module INT
DECLARE @t2_dreadnought_module INT
DECLARE @t3_dreadnought_module INT

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

SET @t1_dreadnought_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
SET @t2_dreadnought_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')
SET @t3_dreadnought_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 600),
(@definition, @t1_dreadnought_module, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_dreadnought_module, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_dreadnought_module, 1)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600),
(@definition, @t1_dreadnought_module, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_dreadnought_module, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_dreadnought_module, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_cprg')
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

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common2')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(0, @t1, @group, 6, 20, NULL),
(@t1, @t2, @group, 7, 20, NULL),
(@t2, @t3, @group, 8, 20, NULL),
(@t3, @t4, @group, 9, 20, NULL)

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

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 34300),
(@definition, @hightech, 34300)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 51200),
(@definition, @hightech, 51200)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 72900),
(@definition, @hightech, 72900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 150000)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_dreadnought_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_dreadnought_module_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_dreadnought_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_dreadnought_module_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_dreadnought_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_dreadnought_module_pr')

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

PRINT N'10_Riveler_rebalance.sql';

-- Small QoL for riveler mk2 pilots would be increase the range of the base locking range, add an additional amount of targets they can lock (to account for the drones) and buff the range on t4+ miners.

USE perpetuumsa

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_head_mk2')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

UPDATE aggregatevalues SET value = 44 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_driller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field

GO

PRINT N'11_Add_more Cultists_to_Alpha3.sql';

-- Add roamers for Tellesis

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ICS_pve')

--- roamers 10

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_10_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_10_z6', 10, 10, 2038, 2038, 'Tellesis roamers 10', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_10_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_10_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z6_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z6_kain_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z6_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z6_arbalest_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z6_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z6_cameleon_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 11

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_11_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_11_z6', 10, 10, 2038, 2038, 'Tellesis roamers 11', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_11_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_11_z6')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_mesmer_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_mesmer_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_mesmer_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_kain_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_kain_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_vagabond_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_cameleon_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z6_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z6_yagel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 12

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_12_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_12_z6', 10, 10, 2038, 2038, 'Tellesis roamers 12', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_12_z6'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_12_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z6_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z6_arbalest_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z6_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z6_vagabond_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z6_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z6_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 13

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_13_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_13_z6', 10, 10, 2038, 2038, 'Tellesis roamers 13', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_13_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_13_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_mesmer_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z6_mesmer_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z6_mesmer_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z6_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z6_yagel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z6_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z6_arbalest_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 14

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_14_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_14_z6', 10, 10, 2038, 2038, 'Tellesis roamers 14', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_14_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_14_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z6_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z6_kain_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_vagabond_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z6_vagabond_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z6_vagabond_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z6_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z6_cameleon_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z6_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z6_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 15

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_15_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_15_z6', 10, 10, 2038, 2038, 'Tellesis roamers 15', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_15_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_15_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z6_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z6_yagel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z6_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z6_arbalest_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z6_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z6_cameleon_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z6_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z6_kain_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 16

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_16_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_16_z6', 10, 10, 2038, 2038, 'Tellesis roamers 16', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_16_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_16_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z6_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z6_yagel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z6_cameleon_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z6_cameleon_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z6_arbalest_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z6_arbalest_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 17

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_17_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_17_z6', 10, 10, 2038, 2038, 'Tellesis roamers 17', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_17_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_17_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_mesmer_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z6_mesmer_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z6_mesmer_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z6_kain_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z6_kain_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_cameleon_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z6_cameleon_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z6_cameleon_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z6_yagel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z6_yagel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--- roamers 18

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_18_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_18_z6', 10, 10, 2038, 2038, 'Tellesis roamers 18', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_18_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_18_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z6_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z6_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z6_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z6_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z6_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z6_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_arbalest_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z6_arbalest_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z6_arbalest_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_yagel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z6_yagel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z6_yagel_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

-- observer 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_03_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_03_z6', 10, 10, 2038, 2038, 'Tellesis observer 3', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_03_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_03_z6')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_mesmer_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z6_def_npc_tellesis_mesmer_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z6_def_npc_tellesis_mesmer_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z6_def_npc_tellesis_kain_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z6_def_npc_tellesis_kain_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_vagabond_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z6_def_npc_tellesis_vagabond_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z6_def_npc_tellesis_vagabond_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

-- observer 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_04_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_04_z6', 10, 10, 2038, 2038, 'Tellesis observer 4', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_04_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_04_z6')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_kain_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z6_def_npc_tellesis_kain_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z6_def_npc_tellesis_kain_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_vagabond_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z6_def_npc_tellesis_vagabond_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z6_def_npc_tellesis_vagabond_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'tellesis npc', 0.9, 1, 1, 2, 0)
END

GO

-- Add roamers for Shinjalar

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI_pve')

--- roamers 10

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_10_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_10_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 10', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_10_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_10_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z7_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z7_artemis_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z7_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z7_baphomet_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z7_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z7_intakt_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 11

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_11_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_11_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 11', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_11_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_11_z7')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_seth_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_seth_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_seth_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_artemis_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_artemis_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_zenith_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_intakt_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z7_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z7_prometheus_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 12

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_12_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_12_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 12', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_12_z7'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_12_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z7_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z7_baphomet_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z7_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z7_zenith_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z7_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z7_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 13

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_13_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_13_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 13', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_13_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_13_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_seth_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z7_seth_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z7_seth_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z7_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z7_prometheus_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z7_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z7_baphomet_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 14

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_14_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_14_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 14', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_14_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_14_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z7_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z7_artemis_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_zenith_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z7_zenith_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z7_zenith_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z7_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z7_intakt_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z7_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z7_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 15

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_15_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_15_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 15', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_15_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_15_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z7_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z7_prometheus_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z7_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z7_baphomet_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z7_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z7_intakt_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z7_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z7_artemis_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 16

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_16_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_16_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 16', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_16_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_16_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z7_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z7_prometheus_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z7_intakt_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z7_intakt_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z7_baphomet_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z7_baphomet_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 17

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_17_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_17_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 17', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_17_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_17_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_seth_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z7_seth_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z7_seth_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z7_artemis_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z7_artemis_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_intakt_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z7_intakt_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z7_intakt_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z7_prometheus_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z7_prometheus_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--- roamers 18

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_18_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_18_z7', 10, 10, 2038, 2038, 'Shinjalar roamers 18', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_18_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_18_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z7_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z7_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z7_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z7_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z7_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z7_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_baphomet_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z7_baphomet_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z7_baphomet_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_prometheus_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z7_prometheus_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z7_prometheus_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

-- observer 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_03_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_03_z7', 10, 10, 2038, 2038, 'Shinjalar observer 3', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_03_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_03_z7')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_seth_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z7_def_npc_shinjalar_seth_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z7_def_npc_shinjalar_seth_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z7_def_npc_shinjalar_artemis_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z7_def_npc_shinjalar_artemis_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_zenith_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z7_def_npc_shinjalar_zenith_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z7_def_npc_shinjalar_zenith_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

-- observer 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_04_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_04_z7', 10, 10, 2038, 2038, 'Shinjalar observer 4', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_04_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_04_z7')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_artemis_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z7_def_npc_shinjalar_artemis_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z7_def_npc_shinjalar_artemis_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_zenith_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z7_def_npc_shinjalar_zenith_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z7_def_npc_shinjalar_zenith_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'shinjalar npc', 0.9, 1, 1, 2, 0)
END

GO

-- Add roamers for attalica

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ICS')

--- roamers 10

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_10_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_10_z1', 10, 10, 2038, 2038, 'attalica roamers 10', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_10_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_10_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z1_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z1_tyrannos_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z1_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z1_waspish_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_10_z1_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_10_z1_troiar_shield_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 11

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_11_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_11_z1', 10, 10, 2038, 2038, 'attalica roamers 11', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_11_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_11_z1')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_sequer_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_riveler_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_riveler_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_riveler_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_laird_basic_lindy', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_gropho_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_gropho_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_gropho_tank_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_tank_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_tyrannos_tank_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_tyrannos_tank_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_ictus_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_troiar_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_11_z1_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_11_z1_castel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 12

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_12_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_12_z1', 10, 10, 2038, 2038, 'attalica roamers 12', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_12_z1'
END


SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_12_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z1_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z1_waspish_dps_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z1_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z1_ictus_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_12_z1_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_12_z1_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 13

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_13_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_13_z1', 10, 10, 2038, 2038, 'attalica roamers 13', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_13_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_13_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_gropho_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z1_gropho_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z1_gropho_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z1_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z1_castel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_13_z1_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_13_z1_waspish_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 14

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_14_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_14_z1', 10, 10, 2038, 2038, 'attalica roamers 14', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_14_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_14_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z1_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z1_tyrannos_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_ictus_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z1_ictus_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z1_ictus_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z1_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z1_troiar_armor_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_14_z1_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_14_z1_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 15

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_15_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_15_z1', 10, 10, 2038, 2038, 'attalica roamers 15', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_15_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_15_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z1_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z1_castel_speed_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z1_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z1_waspish_speed_l3', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z1_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z1_troiar_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_15_z1_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_15_z1_tyrannos_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 16

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_16_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_16_z1', 10, 10, 2038, 2038, 'attalica roamers 16', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_16_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_16_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z1_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z1_castel_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_shield_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z1_troiar_shield_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z1_troiar_shield_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_16_z1_waspish_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_16_z1_waspish_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 17

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_17_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_17_z1', 10, 10, 2038, 2038, 'attalica roamers 17', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_17_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_17_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_gropho_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z1_gropho_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z1_gropho_dps_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z1_tyrannos_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z1_tyrannos_dps_l3', @presenceid, 5, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_troiar_armor_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z1_troiar_armor_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z1_troiar_armor_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_dps_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_17_z1_castel_dps_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_17_z1_castel_dps_l3', @presenceid, 3, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--- roamers 18

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_18_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_18_z1', 10, 10, 2038, 2038, 'attalica roamers 18', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_18_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_18_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_sequer_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z1_sequer_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z1_sequer_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_laird_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z1_laird_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z1_laird_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_argano_basic_lindy')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z1_argano_basic_lindy')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z1_argano_basic_lindy', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_waspish_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z1_waspish_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z1_waspish_speed_l3', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_castel_speed_l3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_18_z1_castel_speed_l3')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_18_z1_castel_speed_l3', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

-- observer 3

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_03_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_03_z1', 10, 10, 2038, 2038, 'attalica observer 3', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_03_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_03_z1')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_gropho_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z1_def_npc_attalica_gropho_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z1_def_npc_attalica_gropho_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z1_def_npc_attalica_tyrannos_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z1_def_npc_attalica_tyrannos_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_ictus_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_03_z1_def_npc_attalica_ictus_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_03_z1_def_npc_attalica_ictus_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

-- observer 4

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'observer_04_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('observer_04_z1', 10, 10, 2038, 2038, 'attalica observer 4', @spawnid, 1, 1, 18000, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1 WHERE name = 'observer_04_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'observer_04_z1')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_tyrannos_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z1_def_npc_attalica_tyrannos_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z1_def_npc_attalica_tyrannos_advanced_observer', @presenceid, 2, @definition, 0, 0, 0, 10, 18000, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_ictus_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'observer_04_z1_def_npc_attalica_ictus_advanced_observer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('observer_04_z1_def_npc_attalica_ictus_advanced_observer', @presenceid, 1, @definition, 0, 0, 0, 10, 18000, 0, 50, 'attalica npc', 0.9, 1, 1, 2, 0)
END

GO

PRINT N'12_Fixes.sql';

-- Remove extra head slot from Seth mk1

UPDATE entitydefaults SET options = '#height=f0.01#slotFlags=48,8,8,8,8,8' WHERE definitionname = 'def_seth_head'

GO

-- Add production duration for landmine detectors

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_landmine_detectors')

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlag)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) VALUES
	(@categoryFlag, 1)
END

GO

-- Fix health for t3 landmine detectors

UPDATE entitydefaults SET health = 100 WHERE definitionname = 'def_named2_landmine_detector'
UPDATE entities SET health = 100 WHERE health > 100

GO

-- Fix Spectator missile hit chance

DECLARE @field INT
DECLARE @definition INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'missile_miss')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES
	(@definition, @field, 0.9)
END ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES
	(@definition, @field, 0.9)
END ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @definition AND field = @field
END

GO

PRINT N'13_Liquid_deep_charges.sql';

---- Add deep mining charges

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

-- Deep liquizit mining charge

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_liquizit', 1000, 2147485696, @categoryFlags, '#mineral=$liquizit', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_liquizit'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_liquizit_pr', 1, 2147485696, @categoryFlags, '#mineral=$liquizit', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_liquizit_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_liquizit_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep hdt mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_crude', 1000, 2147485696, @categoryFlags, '#mineral=$crude', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_crude'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_crude_pr', 1, 2147485696, @categoryFlags, '#mineral=$crude', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_crude_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_crude_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

-- Deep epriton mining charge

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_epriton', 1000, 2147485696, @categoryFlags, '#mineral=$epriton', '', 1, 0.5, 1, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_epriton'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_epriton_pr', 1, 2147485696, @categoryFlags, '#mineral=$epriton', '', 1, 0.5, 0.5, 0, 100, 'def_ammo_mining_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlags WHERE definitionname = 'def_ammo_mining_deep_epriton_pr'
END

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_ammo_mining_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_mining_deep_epriton_cprg', 1, 1024, @categoryFlags, '', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 1, NULL, NULL)
END

---- Assign beams to new ammo

DECLARE @ammoDefinition INT
DECLARE @beamDefinition INT

SET @beamDefinition = (SELECT TOP 1 id FROM beams WHERE name = 'medium_laser')

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

SET @ammoDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_pr')

DELETE FROM beamassignment WHERE definition = @ammoDefinition
INSERT INTO beamassignment (definition, beam) VALUES (@ammoDefinition, @beamDefinition)

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

DECLARE @t1_large_driller INT
DECLARE @t2_large_driller INT
DECLARE @t3_large_driller INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @axicoline = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicoline')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Ammo --

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 225),
(@definition, @axicoline, 225)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_pr')
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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton_cprg')
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

DECLARE @t1 INT
DECLARE @t2 INT
DECLARE @t3 INT
DECLARE @liquizit INT
DECLARE @crude INT
DECLARE @epriton INT
DECLARE @group INT
DECLARE @tempTable TABLE (parentdefinition INT, childdefinition INT, groupID INT, x INT, y INT, enablerextensionid INT)

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')
SET @liquizit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit')
SET @crude = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude')
SET @epriton = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'indy')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@t1, @crude, @group, 6, 13, NULL),
(@t2, @liquizit, @group, 7, 15, NULL),
(@t3, @epriton, @group, 8, 13, NULL)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_crude')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 51450),
(@definition, @industrial, 102900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_liquizit')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 76800),
(@definition, @industrial, 153600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_mining_deep_epriton')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 109350),
(@definition, @industrial, 218700)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_liquizit')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_liquizit_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_crude')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_crude_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_epriton')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_ammo_mining_deep_epriton_pr')

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

PRINT N'14_Enabler_Extensions.sql';

DECLARE @extension INT
DECLARE @definition INT

-- Terramotus

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')

DELETE FROM enablerextensions WHERE definition = @definition

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 4)

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_indy_role_specialist')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_industry_specialist')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 10)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')

DELETE FROM enablerextensions WHERE definition = @definition

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 4)

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_indy_role_specialist')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_industry_specialist')

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 10)

-- Large drillers

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_miner')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_large_driller')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller_pr')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller_pr')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller_pr')

DELETE FROM enablerextensions WHERE definition = @definition

INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
(@definition, @extension, 8)

GO

PRINT N'15_Blob_emission_for_Dreadnoughts.sql';

-- Add dreadnought effect fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_blob_emission_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_blob_emission_modifier', 0, 'effect_dreadnought_blob_emission_modifier_unit', 100, -100, 3, 2, 0, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_blob_emission_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_dreadnought_enhancer_blob_emission_modifier', 0, 'effect_dreadnought_enhancer_blob_emission_modifier_unit', 100, -100, 3, 2, 0, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 0, measurementmultiplier = 100, measurementoffset = -100, category = 3, digits = 2, moreisbetter = 0, usedinconfig = 1, note = NULL
	WHERE name = 'effect_dreadnought_enhancer_blob_emission_modifier'
END

GO

-- Set up aggregate values for dreadnought modules

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_blob_emission_modifier')

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.9)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.9)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.8)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.8)

GO

-- Set up module property modifiers

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')
SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_blob_emission_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_enhancer_blob_emission_modifier')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag AND basefield = @baseField AND modifierfield = @modifierField

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO

PRINT N'16_Excavator_module.sql';

---- Create new categories for siege modules

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_excavator_modules')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(134159, 'cf_excavator_modules', 'Excavator modules', 0, 0)
END

GO

---- Add excavator modules

DECLARE @categoryFlags INT

-- T1 excavator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_excavator_module', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t1', '', 1, 2.5, 2000, 0, 100, 'def_excavator_module_desc', 1, 1, 1)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t1', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_standard_excavator_module'
END

-- T1 excavator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_excavator_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 excavator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_excavator_module', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t2', '', 1, 2.5, 1500, 0, 100, 'def_excavator_module_desc', 1, 1, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t2', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named1_excavator_module'
END

-- T2 excavator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_excavator_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t2_pr', '', 1, 2.5, 1250, 0, 100, 'def_excavator_module_desc', 1, 2, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#ammoCapacity=i2d#tier=$tierlevel_t2_pr', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named1_excavator_module_pr'
END

-- T2 excavator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_excavator_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 excavator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_excavator_module', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t3', '', 1, 2.5, 1500, 0, 100, 'def_excavator_module_desc', 1, 1, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t3', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named2_excavator_module'
END

-- T3 excavator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_excavator_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t3_pr', '', 1, 2.5, 1250, 0, 100, 'def_excavator_module_desc', 1, 2, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t3_pr', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named2_excavator_module_pr'
END

-- T3 excavator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_excavator_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 excavator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_excavator_module', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t4', '', 1, 2.5, 1500, 0, 100, 'def_excavator_module_desc', 1, 1, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t4', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named3_excavator_module'
END

-- T3 excavator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_excavator_module_pr', 1, 131344, @categoryFlags, '#moduleFlag=iA08#tier=$tierlevel_t4_pr', '', 1, 2.5, 1250, 0, 100, 'def_excavator_module_desc', 1, 2, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=iA08#tier=$tierlevel_t4_pr', descriptiontoken = 'def_excavator_module_desc', attributeflags = 131344 WHERE definitionname = 'def_named3_excavator_module_pr'
END

-- T3 excavator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_robot_enhancements_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_excavator_module_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Set up aggregate fields for excavator module

DECLARE @definition INT
DECLARE @field INT

-- T1 excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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


-- T2 excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T2 excavator module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T3 excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T3 excavator module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T4 excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

-- T4 excavator module prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180000)
END
ELSE
BEGIN
	UPDATE  aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field
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

---- Add new effects

DECLARE @effectCategory BIGINT

SET @effectCategory = 1125899906842624 -- 2^50

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_excavator')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_excavator', 'effect_excavator_desc', 'Excavator effect', 1, 30, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 0 WHERE name = 'effect_excavator'
END

GO

-- Add excavator effect fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_mining_amount_modifier', 0, 'effect_excavator_mining_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_enhancer_mining_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_enhancer_mining_amount_modifier', 0, 'effect_excavator_enhancer_mining_amount_modifier_unit', 100, -100, 6, 2, 1, 1, NULL)
END

----

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_stealth_strength_modifier', 1, 'effect_excavator_stealth_strength_modifier_unit', 1, 0, 3, 2, 1, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1, measurementmultiplier = 1, measurementoffset = 0, category = 3, digits = 2, moreisbetter = 1, usedinconfig = 1, note = NULL
	WHERE name = 'effect_excavator_stealth_strength_modifier'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'effect_excavator_enhancer_stealth_strength_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note)
	VALUES ('effect_excavator_enhancer_stealth_strength_modifier', 1, 'effect_excavator_enhancer_stealth_strength_modifier_unit', 1, 0, 3, 2, 1, 1, NULL)
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1, measurementmultiplier = 1, measurementoffset = 0, category = 3, digits = 2, moreisbetter = 1, usedinconfig = 1, note = NULL
	WHERE name = 'effect_excavator_enhancer_stealth_strength_modifier'
END

GO

-- Set up aggregate values for excavator modules

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.3)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.4)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -60)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_mining_amount_modifier')

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

GO

-- Add slots to indy destroyers

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4A08,8,8,8,8' WHERE definitionname = 'def_terramotus_head'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4A08,8,8,8,8' WHERE definitionname = 'def_terramotus_head_pr'

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

DECLARE @t1_excavator_module INT
DECLARE @t2_excavator_module INT
DECLARE @t3_excavator_module INT

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

SET @t1_excavator_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
SET @t2_excavator_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')
SET @t3_excavator_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 600),
(@definition, @t1_excavator_module, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_excavator_module, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_excavator_module, 1)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 1600),
(@definition, @t1_excavator_module, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 400),
(@definition, @espitium, 400),
(@definition, @t2_excavator_module, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2400),
(@definition, @cryoperine, 800),
(@definition, @bryochite, 2400),
(@definition, @espitium, 800),
(@definition, @t3_excavator_module, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_cprg')
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

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')
SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common2')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(0, @t1, @group, 6, 21, NULL),
(@t1, @t2, @group, 7, 21, NULL),
(@t2, @t3, @group, 8, 21, NULL),
(@t3, @t4, @group, 9, 21, NULL)

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

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 34300),
(@definition, @hightech, 34300)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 51200),
(@definition, @hightech, 51200)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 72900),
(@definition, @hightech, 72900)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 150000)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_excavator_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_excavator_module_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_excavator_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_excavator_module_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_excavator_module')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_excavator_module_pr')

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

PRINT N'17_Forced_channels.sql';

---- Add new column ----

BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.channels ADD
	isForcedJoin bit NULL
GO
ALTER TABLE dbo.channels SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

---- Fill it for General chat ----

UPDATE channels SET isForcedJoin = 1 WHERE name = 'General chat' and type = 1

GO

PRINT N'18_News.sql';

INSERT INTO news (title, body, ntime, type, language) VALUES (
'Urgent: Mission Briefing on Daoden',
'To: All Syndicate Agents


Agents,


We are facing a critical situation that requires your immediate attention and expertise.

As you know, the island of Daoden vanished from the Nia teleport network several years ago, cutting off all contact and energy flow. Until recently, it had remained lost, with no explanation. However, Daoden has reappeared. Strangely, it is not connected to the teleport network, raising significant concerns about what might be happening on the island.

Simultaneously, our teleportation infrastructure on Herschfield has been breached. Initial investigations suggest that these breaches could serve as a pathway to Daoden. To complicate matters further, a group of Niani, known as the Niani Cultists, have become increasingly aggressive, invading several key islands. Their intentions remain unclear, but we suspect they may be involved in Daoden''s return.

We have dispatched scouting teams to Daoden to assess the situation and attempt to regain control, but their progress has been slow, and intelligence is limited. We need your help.


Your Mission:

- Deploy immediately to Herschfield and investigate the breaches in the teleport network.

- Secure access to Daoden and report on any anomalies you encounter.

- Assist in re-establishing Syndicate control over Daoden and ensure the stability of the energy flow.

- Be on high alert for any interaction with the Niani Cultists. Approach with caution—they may be more dangerous than we currently understand.


This mission is of the utmost priority. Daoden holds critical resources that the Syndicate cannot afford to lose. Your skills, determination, and commitment are crucial to the success of this operation.


Prepare for immediate departure.


For the Syndicate,

Command Directorate',
GETUTCDATE(),
5,
0)

GO

PRINT N'19_After_Release_fixes.sql';

UPDATE channels SET isForcedJoin = 0 WHERE name = 'General chat'
UPDATE channels SET isForcedJoin = 1 WHERE name = 'regchannel_help'

GO

---------------------------

DECLARE @definition INT
DECLARE @calibration INT
DECLARE @tempTable TABLE (definition INT, researchlevel INT, calibrationprogram INT, enabled BIT)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 3, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 4, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

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

--------------------------------

---- Create CT for Terramotus

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_walker_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_terramotus_bot_cprg', 1, 1024, @categoryFlags, '', NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

GO

---------------------------------

DECLARE @definition INT
DECLARE @calibration INT
DECLARE @tempTable TABLE (definition INT, researchlevel INT, calibrationprogram INT, enabled BIT)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

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

PRINT N'20_Command_Translators.sql';

---- Create new categories for remote command translators

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_remote_command_translators')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(84673551, 'cf_remote_command_translators', 'Remote command translators', 0, 0)
END

GO

---- Add new aggregate fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_damage_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_damage_modifier', 0,'drone_remote_command_translation_damage_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation damage bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_damage_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_damage_modifier_modifier', 1,'drone_remote_command_translation_damage_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation damage bonus extender')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_damage_modifier_modifier'
END

--

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_armor_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_armor_max_modifier', 0,'drone_remote_command_translation_armor_max_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation armor max bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_armor_max_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_armor_max_modifier_modifier', 1,'drone_remote_command_translation_armor_max_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation armor max bonus extender')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_armor_max_modifier_modifier'
END

--

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_mining_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_mining_amount_modifier', 0,'drone_remote_command_translation_mining_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation mining amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_mining_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_mining_amount_modifier_modifier', 1,'drone_remote_command_translation_mining_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation mining amount bonus extender')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_mining_amount_modifier_modifier'
END

--

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_harvesting_amount_modifier', 0,'drone_remote_command_translation_harvesting_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation harvesting amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_harvesting_amount_modifier_modifier', 1,'drone_remote_command_translation_harvesting_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation harvesting amount bonus extender')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier_modifier'
END

--

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_remote_repair_amount_modifier', 0,'drone_remote_command_translation_remote_repair_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation remote repair amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_remote_repair_amount_modifier_modifier', 1,'drone_remote_command_translation_remote_repair_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone remote command translation remote repair amount bonus extender')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier_modifier'
END

--

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_retreat')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_retreat', 1,'drone_remote_command_translation_retreat_unit', 1, 0, 6, 0, 1, 1, 'Drone remote command translation retreat')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_retreat'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_remote_command_translation_retreat_confirmation')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_remote_command_translation_retreat_confirmation', 1,'drone_remote_command_translation_retreat_confirmation_unit', 1, 0, 6, 0, 1, 1, 'Drone remote command translation retreat confirmation')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'drone_remote_command_translation_retreat_confirmation'
END

GO

---- Add remote command translators

DECLARE @categoryFlags INT

-- T1 remote command translator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_remote_command_translator', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t1#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 2000, 0, 100, 'def_remote_command_translator_desc', 1, 1, 1)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t1#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_standard_remote_command_translator'
END

-- T1 remote command translator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_module_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_remote_command_translator_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t1', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

-- T2 remote command translator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_remote_command_translator', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t2#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1500, 0, 100, 'def_remote_command_translator_desc', 1, 1, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t2#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named1_remote_command_translator'
END

-- T2 remote command translator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_remote_command_translator_pr', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t2_pr#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1250, 0, 100, 'def_remote_command_translator_desc', 1, 2, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#ammoCapacity=i2d#tier=$tierlevel_t2_pr#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named1_remote_command_translator_pr'
END

-- T2 remote command translator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_module_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_remote_command_translator_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t2', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

-- T3 remote command translator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_remote_command_translator', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t3#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1500, 0, 100, 'def_remote_command_translator_desc', 1, 1, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t3#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named2_remote_command_translator'
END

-- T3 remote command translator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_remote_command_translator_pr', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t3_pr#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1250, 0, 100, 'def_remote_command_translator_desc', 1, 2, 3)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t3_pr#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named2_remote_command_translator_pr'
END

-- T3 remote command translator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_module_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_remote_command_translator_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t3', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

-- T4 remote command translator module

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_remote_command_translator', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t4#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1500, 0, 100, 'def_remote_command_translator_desc', 1, 1, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t4#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named3_remote_command_translator'
END

-- T4 remote command translator module prototype

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_remote_command_translator_pr', 1, 262420, @categoryFlags, '#moduleFlag=i410#tier=$tierlevel_t4_pr#ammoType=L7120a#ammoCapacity=i1', '', 1, 2.5, 1250, 0, 100, 'def_remote_command_translator_desc', 1, 2, 4)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i410#tier=$tierlevel_t4_pr#ammoType=L7120a#ammoCapacity=i1', descriptiontoken = 'def_remote_command_translator_desc', attributeflags = 262420 WHERE definitionname = 'def_named3_remote_command_translator_pr'
END

-- T4 remote command translator module CT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_module_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_remote_command_translator_cprg', 1, 1024, @categoryFlags, '#tier=$tierlevel_t4', '', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Create new categories for remote commands

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_remote_commands')
BEGIN
	INSERT INTO categoryFlags (value, name, note, hidden, isunique) VALUES
	(463370, 'cf_remote_commands', 'Remote commands', 0, 0)
END

GO

---- Add remote commands

DECLARE @categoryFlags INT

-- Attack remote commands

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_commands')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_basic_attack_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_basic_attack_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_attack_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_attack_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_basic_attack_remote_command'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_improved_attack_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_improved_attack_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_attack_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_attack_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_improved_attack_remote_command'
END

-- Defend remote command

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_basic_defend_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_basic_defend_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_defend_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_defend_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_basic_defend_remote_command'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_improved_defend_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_improved_defend_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_defend_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_defend_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_improved_defend_remote_command'
END

-- Gather remote command

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_basic_gather_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_basic_gather_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_gather_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_gather_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_basic_gather_remote_command'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_improved_gather_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_improved_gather_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_gather_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_gather_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_improved_gather_remote_command'
END

-- Support remote command

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_basic_support_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_basic_support_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_support_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_support_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_support_remote_command'
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_improved_support_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_improved_support_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_support_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_support_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_improved_support_remote_command'
END

-- Retreat remote command

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_commands')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_retreat_remote_command')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_retreat_remote_command', 1, 2147485696, @categoryFlags, '', '', 1, 0.01, 1, 0, 100, 'def_retreat_remote_command_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '', descriptiontoken = 'def_retreat_remote_command_desc', attributeflags = 2147485696 WHERE definitionname = 'def_retreat_remote_command'
END

GO

---- Set up aggregate fields for remote command translators

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_damage_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_armor_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_mining_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.025 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.075)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.075 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_retreat')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.001 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 9000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 9000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 9000)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 150000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 150000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 9 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 8 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 11 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 12 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 125)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 125 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 113)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 113 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 107)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 107 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 129)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 129 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 143)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 143 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 136)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 136 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 57)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 57 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 64)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 64 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 70 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

GO

---- Set up aggregate fields for remote commands

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_attack_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_damage_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.025 WHERE definition = @definition AND field = @field
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_attack_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_damage_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.05 WHERE definition = @definition AND field = @field
END

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_defend_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_armor_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.025 WHERE definition = @definition AND field = @field
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_defend_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_armor_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.05 WHERE definition = @definition AND field = @field
END

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_gather_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_mining_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.025 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.025 WHERE definition = @definition AND field = @field
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_gather_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_mining_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.05 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_harvesting_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.05 WHERE definition = @definition AND field = @field
END

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_support_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.025)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.025 WHERE definition = @definition AND field = @field
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_support_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_remote_repair_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.05 WHERE definition = @definition AND field = @field
END

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_retreat_remote_command')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_remote_command_translation_retreat_confirmation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.001)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.001 WHERE definition = @definition AND field = @field
END

GO

---- Reconfigure uniqueness of remote controllers

UPDATE categoryFlags SET isunique = 0 WHERE name = 'cf_remote_controllers'
UPDATE categoryFlags SET isunique = 1 WHERE name = 'cf_remote_command_translators'

GO

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_drone_remote_command_translation')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_drone_remote_command_translation', 53, 1, 'Drone remote command translation')
END

GO

---- Add new effects

DECLARE @effectCategory BIGINT

SET @effectCategory = 9007199254740992

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'remote_command_translation')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'remote_command_translation', 'remote_command_translation_desc', 'Remote command translation', 0, 0, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET effectcategory = @effectCategory, duration = 0, isaura = 0, auraradius = 0 WHERE name = 'remote_command_translation'
END

GO

---- Fix effect categories

UPDATE effects SET effectcategory = 70368744177664 WHERE name = 'effect_mine_detector'
UPDATE effects SET effectcategory = 140737488355328 WHERE name = 'nox_effect_shield_negation'
UPDATE effects SET effectcategory = 281474976710656 WHERE name = 'nox_effect_repair_negation'
UPDATE effects SET effectcategory = 562949953421312 WHERE name = 'nox_effect_teleport_negation'
UPDATE effects SET effectcategory = 1125899906842624 WHERE name = 'effect_drone_amplification'
UPDATE effects SET effectcategory = 2251799813685248 WHERE name = 'effect_dreadnought'
UPDATE effects SET effectcategory = 4503599627370496 WHERE name = 'effect_overheat_buildup_low'
UPDATE effects SET effectcategory = 4503599627370496 WHERE name = 'effect_overheat_buildup_medium'
UPDATE effects SET effectcategory = 4503599627370496 WHERE name = 'effect_overheat_buildup_high'
UPDATE effects SET effectcategory = 4503599627370496 WHERE name = 'effect_overheat_buildup_critical'
UPDATE effects SET effectcategory = 2251799813685248 WHERE name = 'effect_excavator'
UPDATE effects SET effectcategory = 9007199254740992 WHERE name = 'remote_command_translation'

GO

---- Set rcu ammo id for scooping

UPDATE entitydefaults SET options = '#head=n8593  #chassis=n8594  #leg=n8595  #inventory=n8596 #faction=sSyndicate #packedTurretId=i2196' WHERE definitionname = 'def_syndicate_assault_drone'
UPDATE entitydefaults SET options = '#head=n8599  #chassis=n8600  #leg=n8601  #inventory=n8602 #faction=sSyndicate #packedTurretId=i219c' WHERE definitionname = 'def_nuimqol_assault_drone'
UPDATE entitydefaults SET options = '#head=n8605  #chassis=n8606  #leg=n8607  #inventory=n8608 #faction=sSyndicate #packedTurretId=i21a2' WHERE definitionname = 'def_thelodica_assault_drone'
UPDATE entitydefaults SET options = '#head=n8611  #chassis=n8612  #leg=n8613  #inventory=n8614 #faction=sSyndicate #packedTurretId=i21a8' WHERE definitionname = 'def_pelistal_assault_drone'

UPDATE entitydefaults SET options = '#head=n8617  #chassis=n8618  #leg=n8619  #inventory=n8620 #faction=sSyndicate #packedTurretId=i21ae' WHERE definitionname = 'def_syndicate_attack_drone'
UPDATE entitydefaults SET options = '#head=n8623  #chassis=n8624  #leg=n8625  #inventory=n8626 #faction=sSyndicate #packedTurretId=i21b4' WHERE definitionname = 'def_nuimqol_attack_drone'
UPDATE entitydefaults SET options = '#head=n8629  #chassis=n8630  #leg=n8631  #inventory=n8632 #faction=sSyndicate #packedTurretId=i21ba' WHERE definitionname = 'def_thelodica_attack_drone'
UPDATE entitydefaults SET options = '#head=n8635  #chassis=n8636  #leg=n8637  #inventory=n8638 #faction=sSyndicate #packedTurretId=i21c0' WHERE definitionname = 'def_pelistal_attack_drone'

UPDATE entitydefaults SET options = '#head=n8641  #chassis=n8642  #leg=n8643  #inventory=n8644 #faction=sSyndicate #packedTurretId=i21c6' WHERE definitionname = 'def_mining_industrial_drone'

UPDATE entitydefaults SET options = '#head=n8647  #chassis=n8648  #leg=n8649  #inventory=n8650 #faction=sSyndicate #packedTurretId=i21cc' WHERE definitionname = 'def_harvesting_industrial_drone'

UPDATE entitydefaults SET options = '#head=n8653  #chassis=n8654  #leg=n8655  #inventory=n8656 #faction=sSyndicate #packedTurretId=i21d2' WHERE definitionname = 'def_repair_support_drone'

GO

---- Add cpu, reactor, bandwidth, lifetime and operational range modifier

DECLARE @categoryFlags INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')
DELETE FROM aggregatemodifiers WHERE categoryflag = @categoryFlags

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlags, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlags, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlags, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlags, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlags, @baseField, @modifierField)

GO

---- Production and prorotyping cost in materials, modules and components ----

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

DECLARE @t1_remote_command_translator INT
DECLARE @t2_remote_command_translator INT
DECLARE @t3_remote_command_translator INT

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

SET @t1_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @t2_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
SET @t3_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200),
(@definition, @t1_remote_command_translator, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 125),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @t2_remote_command_translator, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 400),
(@definition, @hydrobenol, 200),
(@definition, @bryochite, 200),
(@definition, @t3_remote_command_translator, 1)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200),
(@definition, @t1_remote_command_translator, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 125),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @t2_remote_command_translator, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 400),
(@definition, @hydrobenol, 200),
(@definition, @bryochite, 200),
(@definition, @t3_remote_command_translator, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_cprg')
INSERT INTO @tempTable (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_cprg')
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
DECLARE @parent INT
DECLARE @group INT
DECLARE @tempTable TABLE (parentdefinition INT, childdefinition INT, groupID INT, x INT, y INT, enablerextensionid INT)

SET @t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
SET @t3 = (SELECT TOP 1 definition definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')
SET @t4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')

SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_cpu_upgrade')

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common2')

INSERT INTO @tempTable (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@parent, @t1, @group, 1, 35, NULL),
(@t1, @t2, @group, 2, 35, NULL),
(@t2, @t3, @group, 3, 35, NULL),
(@t3, @t4, @group, 4, 35, NULL)

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

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 25000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 50000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')
INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 100000),
(@definition, @hightech, 50000)

GO

---- Link modules and their prototypes----

DECLARE @module int
DECLARE @prototype int
DECLARE @tempTable TABLE (definition INT, prototype INT)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_remote_command_translator')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named1_remote_command_translator_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_remote_command_translator')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named2_remote_command_translator_pr')

INSERT INTO @tempTable (definition, prototype) VALUES (@module, @prototype)

SET @module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_remote_command_translator')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_named3_remote_command_translator_pr')

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

---- Set up decalibration and production time

DECLARE @categoryFlags BIGINT

----

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_command_translators')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

GO

---- Add Improved Commands into Daoden Syndicate shop ----

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_attack_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000, 150, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_defend_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000, 150, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_gather_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000, 150, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_basic_support_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000, 150, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_retreat_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 1000000, 150, null, 0, null)
END

----

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_attack_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 5000000, 300, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_defend_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 5000000, 300, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_gather_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 5000000, 300, null, 0, null)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_improved_support_remote_command')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 5000000, 300, null, 0, null)
END

GO

PRINT N'21_Fixes_and_rebalances.sql';

---- Set up decalibration and production time

DECLARE @categoryFlags BIGINT

----

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_dreadnought_modules')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_excavator_modules')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_deep_mining_ammo')

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

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_drillers')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

GO

---- Fix adaptive alloys cpu and powergrid

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_adaptive_alloys')

DELETE FROM aggregatemodifiers WHERE categoryflag = @categoryFlag
DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_armor_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_armor_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)
INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO

---- Rebalance remote controllers

---- Set up aggregate fields for extra remote controllers

DECLARE @definition INT
DECLARE @field INT

-- Tactical

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

UPDATE aggregatevalues SET value = 1800000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

UPDATE aggregatevalues SET value = 240000 WHERE definition = @definition AND field = @field


---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

UPDATE aggregatevalues SET value = 54 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

UPDATE aggregatevalues SET value = 71 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

-- Industrial

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

UPDATE aggregatevalues SET value = 240000 WHERE definition = @definition AND field = @field

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

UPDATE aggregatevalues SET value = 54 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

UPDATE aggregatevalues SET value = 71 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

-- Support

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

UPDATE aggregatevalues SET value = 240000 WHERE definition = @definition AND field = @field

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

UPDATE aggregatevalues SET value = 63 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

UPDATE aggregatevalues SET value = 54 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

UPDATE aggregatevalues SET value = 71 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field

-- Assault

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

UPDATE aggregatevalues SET value = 180000 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

UPDATE aggregatevalues SET value = 240000 WHERE definition = @definition AND field = @field

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field

GO

---- Add extra head slot to Metis

UPDATE entitydefaults SET options = '#slotFlags=4C08,8,8,8,8  #height=f0.20' WHERE definitionname = 'def_metis_head'

GO

---- Getting rid of ghost bases attempt 1

EXEC dbo.deleteAllChildren 4865912697679673829
DELETE FROM entities WHERE eid = 4865912697679673829

GO

PRINT N'22_News.sql';

INSERT INTO news (title, body, ntime, type, language) VALUES (
'Syndicate Directive: Recover Lost Technologies',
'To: All Syndicate Agents


Agents,


The Syndicate urgently requires your assistance in securing vital lost technologies.

Our secret scientific laboratory on Daoden was pivotal in studying the Niani Cultists and their advanced command protocols, used to control and empower their followers. By partially deciphering these protocols, Syndicate researchers successfully developed a prototype system for drone commands.

Unfortunately, the Niani Cultists discovered the laboratory, launching an invasion that compromised the facility. While Syndicate forces managed to salvage basic versions of these commands, it is believed that improved command protocols and additional technologies remain hidden on Daoden.

Your mission is critical:

    Investigate Network Breaches on Hershfield by performing artifact scans.
    Eliminate the Gatekeeper to gain access to Daoden.
    Recover improved protocols and any other valuable technologies.

Time is of the essence. The Syndicate relies on your skills and determination to reclaim what has been lost.


For the Syndicate,

Command Directorate',
GETUTCDATE(),
5,
0)

GO

PRINT N'23_No_flux_for_drones.sql';

---- Remove flux from drones

DECLARE @definition INT
DECLARE @flux INT
DECLARE @gamma_syndicate_shards INT
DECLARE @gamma_pelistal_shards INT
DECLARE @gamma_nuimqol_shards INT
DECLARE @gamma_thelodica_shards INT

SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')
SET @gamma_syndicate_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')
SET @gamma_pelistal_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_pelistal')
SET @gamma_nuimqol_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_nuimqol')
SET @gamma_thelodica_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

DELETE FROM components WHERE definition = @definition AND componentdefinition = @flux
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_syndicate_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_pelistal_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards
DELETE FROM components WHERE definition = @definition AND componentdefinition = @gamma_thelodica_shards

GO

PRINT N'24_Server_EP_boost.sql';

---- New category for Server-wide EP boosts ----

IF NOT EXISTS (SELECT 1 FROM categoryFlags WHERE name = 'cf_server_wide_ep_boosters')
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(394395, 'cf_server_wide_ep_boosters', 'Server-wide EP boosters', 0, 0)
END

GO

---- Add new aggregate fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'server_wide_ep_bonus')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('server_wide_ep_bonus', 1,'server_wide_ep_bonus_unit', 1, 0, 6, 0, 1, 1, 'Server-wide EP bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'server_wide_ep_bonus_duration')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('server_wide_ep_bonus_duration', 1,'server_wide_ep_bonus_duration_unit', 1, 0, 6, 0, 1, 1, 'Server-wide EP bonus duration')
END

---- Server-wide EP boost ----

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_server_wide_ep_boosters')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_server_wide_ep_booster_t0', 1, 2052, @categoryflags, '', '', 1, 0.1, 0.1, 0, 100, 'def_server_wide_ep_booster', 1, 1, 0); 
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_server_wide_ep_booster_t1', 1, 2052, @categoryflags, '', '', 1, 0.1, 0.1, 0, 100, 'def_server_wide_ep_booster', 1, 1, 1); 
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t2')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_server_wide_ep_booster_t2', 1, 2052, @categoryflags, '', '', 1, 0.1, 0.1, 0, 100, 'def_server_wide_ep_booster', 1, 1, 2); 
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_server_wide_ep_booster_t3', 1, 2052, @categoryflags, '', '', 1, 0.1, 0.1, 0, 100, 'def_server_wide_ep_booster', 1, 1, 3); 
END

GO

---- Set up aggregate fields for Server-wide EP boosters

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus_duration')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 24)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 168 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus_duration')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 72)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 72 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t2')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus_duration')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 120 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t3')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 15 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'server_wide_ep_bonus_duration')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 168)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 168 WHERE definition = @definition AND field = @field
END

GO

---- Add boosters to distribution sources

-- Add T0 into Daoden Syndicate shop ----


DECLARE @npc INT
DECLARE @loot INT

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 10000000, 500, null, 0, null)
END

-- Add T1 to destroyer bosses

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_onyx_mammoth_destro')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_onyx_thelodica_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_shinjalar_onyx_thelodica_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_attalica_hydra_pelistal_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_hydra_mammoth_destro')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_hydra_pelistal_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_felos_mammoth_destro')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_felos_nuimqol_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_tellesis_felos_nuimqol_pitboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

-- Add T2 to Radamanthys

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

-- Add T3 to Commendant main boss

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_sh70_mainboss')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

GO

PRINT N'25_Fixes_and_rebalances.sql';

---- Reallocate T0 server-wide ep boosters to Daoden

DECLARE @definition INT
DECLARE @itemshop_preset_old INT
DECLARE @itemshop_preset_new INT

SET @itemshop_preset_old = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')
SET @itemshop_preset_new = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

UPDATE itemshop SET presetid = @itemshop_preset_new WHERE targetdefinition = @definition AND presetid = @itemshop_preset_old

GO

---- Add cargo to advanced couriers so they finally stop crying about it's missing

UPDATE robottemplates
SET description = '#robot=iC8#head=i5B#chassis=i5C#leg=i5D#container=i146#headModules=[|m0=[|definition=i302|slot=i1]|m1=[|definition=i317|slot=i2]|m2=[|definition=i31A|slot=i3]|m3=[|definition=i31A|slot=i4]|m4=[|definition=i314|slot=i5]]#chassisModules=[|m0=[|definition=i341|slot=i1|ammoDefinition=i989|ammoQuantity=i32]|m1=[|definition=i341|slot=i2|ammoDefinition=i989|ammoQuantity=i32]|m2=[|definition=i2EA|slot=i3]]#legModules=[|m0=[|definition=i338|slot=i1|ammoDefinition=i298|ammoQuantity=iA]|m1=[|definition=i2D5|slot=i2]|m2=[|definition=i57C|slot=i3]]'
WHERE name = 'gamma_intakt_advanced'

UPDATE robottemplates
SET description = '#robot=i3AE#head=i3AB#chassis=i3AC#leg=i3AD#container=i146#headModules=[|m0=[|definition=i2DE|slot=i1]|m1=[|definition=i314|slot=i2]|m2=[|definition=i302|slot=i3]]#chassisModules=[|m0=[|definition=i2F3|slot=i1]|m1=[|definition=i2F3|slot=i2]|m2=[|definition=i356|slot=i3|ammoDefinition=i98F|ammoQuantity=i0]|m3=[|definition=i356|slot=i4|ammoDefinition=i98F|ammoQuantity=i0]|m4=[|definition=i2EA|slot=i5]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i332|slot=i2]|m2=[|definition=i57C|slot=i3]]'
WHERE name = 'gamma_troiar_advanced'

UPDATE robottemplates
SET description = '#robot=iC7#head=i58#chassis=i59#leg=i5A#container=i146#headModules=[|m0=[|definition=i314|slot=i1]|m1=[|definition=i31A|slot=i2]|m2=[|definition=i317|slot=i3]|m3=[|definition=i317|slot=i4]|m4=[|definition=i302|slot=i5]]#chassisModules=[|m0=[|definition=i35C|slot=i1|ammoDefinition=i980|ammoQuantity=i0]|m1=[|definition=i35C|slot=i2|ammoDefinition=i980|ammoQuantity=iA]|m2=[|definition=i2ED|slot=i3]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i2B7|slot=i2]|m2=[|definition=i57C|slot=i3]]'
WHERE name = 'gamma_cameleon_advanced'

GO

PRINT N'26_Santa.sql';

---- Create Santa, Deers and Elfs

DECLARE @robot INT
DECLARE @template INT
DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @speedModifier INT

SET @speedModifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max_modifier')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_yagel_dps_l3_deer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_hershfield_yagel_dps_l3_deer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_hershfield_yagel_dps_l3_deer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_dps_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_yagel_dps_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_yagel_dps_l3_deer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@targetDefinition, @speedModifier, 1.5)

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'christmas_deer')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('christmas_deer', '#robot=iC1#head=i46#chassis=i47#leg=i48#headModules=[|m0=[|definition=i302|slot=i1]|m1=[|definition=i39E|slot=i2]|m2=[|definition=i39E|slot=i3]]#chassisModules=[|m0=[|definition=i35C|slot=i1|ammoDefinition=iFA|ammoQuantity=i14]|m1=[|definition=i35C|slot=i2|ammoDefinition=iFA|ammoQuantity=i14]|m2=[|definition=i35C|slot=i3|ammoDefinition=iFA|ammoQuantity=i14]|m3=[|definition=i35C|slot=i4|ammoDefinition=iFA|ammoQuantity=i14]]#legModules=[|m0=[|definition=i2B7|slot=i1]|m1=[|definition=i338|slot=i2|ammoDefinition=i298|ammoQuantity=iA]|m2=[|definition=i2D2|slot=i3]|m3=[|definition=i2B7|slot=i4]]', 'Christmas Deer')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = '#robot=iC1#head=i46#chassis=i47#leg=i48#headModules=[|m0=[|definition=i302|slot=i1]|m1=[|definition=i39E|slot=i2]|m2=[|definition=i39E|slot=i3]]#chassisModules=[|m0=[|definition=i35C|slot=i1|ammoDefinition=iFA|ammoQuantity=i14]|m1=[|definition=i35C|slot=i2|ammoDefinition=iFA|ammoQuantity=i14]|m2=[|definition=i35C|slot=i3|ammoDefinition=iFA|ammoQuantity=i14]|m3=[|definition=i35C|slot=i4|ammoDefinition=iFA|ammoQuantity=i14]]#legModules=[|m0=[|definition=i2B7|slot=i1]|m1=[|definition=i338|slot=i2|ammoDefinition=i298|ammoQuantity=iA]|m2=[|definition=i2D2|slot=i3]|m3=[|definition=i2B7|slot=i4]]' WHERE name = 'christmas_deer'
END

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_yagel_dps_l3_deer')
SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'christmas_deer')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_npc_hershfield_yagel_dps_l3_deer')
END

DELETE FROM npcloot WHERE definition = @targetDefinition

--

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_sequer_basic_lindy_santa')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_hershfield_sequer_basic_lindy_santa', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_hershfield_sequer_basic_lindy_santa_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_sequer_basic_lindy')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_sequer_basic_lindy_santa')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @speedModifier

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'christmas_santa')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('christmas_santa', '#robot=i5CC#head=i5C8#chassis=i5C9#leg=i5CA#headModules=[|m0=[|definition=i2DE|slot=i1]|m1=[|definition=i2DE|slot=i2]|m2=[|definition=i2DE|slot=i3]|m3=[|definition=i2DE|slot=i4]]#chassisModules=[|m0=[|definition=i2EA|slot=i1]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i57C|slot=i2]|m2=[|definition=i32F|slot=i3]|m3=[|definition=i338|slot=i4|ammoDefinition=i298|ammoQuantity=iA]]', 'Christmas Santa')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = '#robot=i5CC#head=i5C8#chassis=i5C9#leg=i5CA#headModules=[|m0=[|definition=i2DE|slot=i1]|m1=[|definition=i2DE|slot=i2]|m2=[|definition=i2DE|slot=i3]|m3=[|definition=i2DE|slot=i4]]#chassisModules=[|m0=[|definition=i2EA|slot=i1]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i57C|slot=i2]|m2=[|definition=i32F|slot=i3]|m3=[|definition=i338|slot=i4|ammoDefinition=i298|ammoQuantity=iA]]' WHERE name = 'christmas_santa'
END

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_sequer_basic_lindy_santa')
SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'christmas_santa')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_npc_hershfield_sequer_basic_lindy_santa')
END

DELETE FROM npcloot WHERE definition = @targetDefinition

DECLARE @presents INT

SET @presents = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_anniversary_package')

INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@robot, @presents, 20, 1, 0, 0, 5)

--

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_cameleon_shield_l3_elf')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_hershfield_cameleon_shield_l3_elf', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_hershfield_cameleon_shield_l3_elf_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_shield_l3'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_cameleon_shield_l3')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_cameleon_shield_l3_elf')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@targetDefinition, @speedModifier, 1.5)

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'christmas_elf')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('christmas_elf', '#robot=iC7#head=i58#chassis=i59#leg=i5A#headModules=[|m0=[|definition=i31A|slot=i1]|m1=[|definition=i31A|slot=i2]|m2=[|definition=i317|slot=i3]|m3=[|definition=i317|slot=i4]|m4=[|definition=i302|slot=i5]]#chassisModules=[|m0=[|definition=i2EA|slot=i1]|m1=[|definition=i2EA|slot=i2]|m2=[|definition=i2EA|slot=i3]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i32F|slot=i2]|m2=[|definition=i2D2|slot=i3]]', 'Christmas Elf')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = '#robot=iC7#head=i58#chassis=i59#leg=i5A#headModules=[|m0=[|definition=i31A|slot=i1]|m1=[|definition=i31A|slot=i2]|m2=[|definition=i317|slot=i3]|m3=[|definition=i317|slot=i4]|m4=[|definition=i302|slot=i5]]#chassisModules=[|m0=[|definition=i2EA|slot=i1]|m1=[|definition=i2EA|slot=i2]|m2=[|definition=i2EA|slot=i3]]#legModules=[|m0=[|definition=i2D5|slot=i1]|m1=[|definition=i32F|slot=i2]|m2=[|definition=i2D2|slot=i3]]' WHERE name = 'christmas_elf'
END

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_cameleon_shield_l3_elf')
SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'christmas_elf')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_npc_hershfield_cameleon_shield_l3_elf')
END

DELETE FROM npcloot WHERE definition = @targetDefinition

GO

---- Put them on Hershfield

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT
DECLARE @flockId INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_TM_pve')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_santa_z8' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_santa_z8', 10, 10, 2038, 2038, 'Santa on Hershfield', @spawnid, 1, 1, 7200, 5, NULL, NULL, NULL, NULL, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, presencetype = 5 WHERE name = 'roamer_santa_z8'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_santa_z8')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_cameleon_shield_l3_elf')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_santa_z8_cameleon_shield_l3_elf')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_santa_z8_cameleon_shield_l3_elf', @presenceid, 4, @definition, 0, 0, 0, 10, 7200, 0, 50, 'Santa on Hershfield', 0.9, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_yagel_dps_l3_deer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_santa_z8_yagel_dps_l3_deer')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_santa_z8_yagel_dps_l3_deer', @presenceid, 8, @definition, 0, 0, 0, 10, 7200, 0, 50, 'Santa on Hershfield', 0.9, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_sequer_basic_lindy_santa')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_santa_z8_sequer_basic_lindy_santa')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_santa_z8_sequer_basic_lindy_santa', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'Santa on Hershfield', 0.9, 1, 1, 1, 0)
END

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_santa_z8_sequer_basic_lindy_santa')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, 'Were you any good, Children of Earth?', 'Ho-Ho-Ho, Network Crackers', NULL, 0)
END

GO

-- Paint bots

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_yagel_dps_l3_deer')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#fb6701')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_cameleon_shield_l3_elf')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#013301')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_hershfield_sequer_basic_lindy_santa')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#fb0101')
END

GO

---- Increase missions level for daoden

DECLARE @zoneid INT

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

UPDATE missionlocations SET maxmissionlevel = 8 WHERE zoneid = @zoneid

GO

PRINT N'27_News.sql';

INSERT INTO news (title, body, ntime, type, language) VALUES (
'Syndicate Warning: Intrusion detected!',
'To: All Syndicate Agents


Agents,


Our sensors detected possible intrusion.

Something managed to get out of one of those Network Breaches and now roaming on Herschfield.

Syndicate wants you to discover and eliminate all the possible threats, even if they don''t show any agression.

Once it''s done, stay alerted. Security Division thinks that this is not just a single accident.


For the Syndicate,

Command Directorate',
GETUTCDATE(),
5,
0)

GO

PRINT N'28_Fixes_and_rebalance.sql';

---- Fix Black Gropho price

DECLARE @definition INT
DECLARE @itemshop_preset INT
SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 50000, NULL, NULL, 5000000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 50000, icscoin = NULL, asicoin = NULL, credit = 5000000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

GO

---- Fix Martyrs EP reward

DECLARE @targetDefinition INT
DECLARE @templateId INT

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')
	
SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Cultist_Martyr_Termis')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 2, NULL, NULL, 150, 'def_npc_cultist_martyr_termis')

GO

---- Fix missions reward

UPDATE missionlocations SET agentid = 30 WHERE zoneid = 2

GO

PRINT N'Completed';