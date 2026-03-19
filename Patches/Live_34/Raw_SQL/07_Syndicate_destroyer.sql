
USE perpetuumsa;
GO

---- Create entity defaults for Ares

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_chassis', 1, 1024, @category, '#height=f2#slotFlags=4111,111,111,111,111,111', 1, 12, 72000, 1, 100, 'def_ares_chassis_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f2#slotFlags=4111,111,111,111,111,111', mass=72000  WHERE definitionname = 'def_ares_chassis'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_head', 1, 1024, @category, '#height=f0.2#slotFlags=4908,8,8,8,8', 1, 3, 3000, 1, 100, 'def_ares_head_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8', mass=3000  WHERE definitionname = 'def_ares_head'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_leg', 1, 1024, @category, '#height=f1.1#slotFlags=420,20,20,20,20', 1, 10, 12000, 1, 100, 'def_ares_leg_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f1.1#slotFlags=420,20,20,20,20', mass=12000  WHERE definitionname = 'def_ares_leg'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_robot_inventory_ares', 1, 4195328, @category, '#capacity=f31.5', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#capacity=f31.5', mass=0  WHERE definitionname = 'def_robot_inventory_ares'
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walkers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_bot', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_ares_bot_desc', 1, NULL, NULL)
END

GO

---- Create robot definitions and it's template and link them

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'ares_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('ares_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'ares')
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'ares_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_ares_bot')
END

GO

---- Set up aggregate fields for ares

DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4.5)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.27)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.27 WHERE definition = @definition AND field = @field
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1800)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 37)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 110)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 350)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11250)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7700)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 7700 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5500)
END
BEGIN
	UPDATE aggregatevalues SET value = 5500 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1200)
END
BEGIN
	UPDATE aggregatevalues SET value = 1200 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
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

---- Add enabler extensions for ares

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 4)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 10)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 8)
END

GO


---- Add chassis bonuses and link them with extensions and aggregate fields

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis
    
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_large_projectile_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.03, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'projectile_falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.05, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_combat_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.01, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.07, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.02, @field, 0)
END

GO

---------------------------

---- Create entity defaults for ares prototype

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_chassis_pr', 1, 1024, @category, '#height=f2#slotFlags=4111,111,111,111,111,111', 1, 12, 72000, 1, 100, 'def_ares_chassis_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f2#slotFlags=4111,111,111,111,111,111', mass=72000  WHERE definitionname = 'def_ares_chassis_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_head_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_head_pr', 1, 1024, @category, '#height=f0.2#slotFlags=4908,8,8,8,8', 1, 3, 3000, 1, 100, 'def_ares_head_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8', mass=3000  WHERE definitionname = 'def_ares_head_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walker_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_leg_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_leg_pr', 1, 1024, @category, '#height=f1.1#slotFlags=420,20,20,20,20', 1, 10, 12000, 1, 100, 'def_ares_leg_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#height=f1.1#slotFlags=420,20,20,20,20', mass=12000  WHERE definitionname = 'def_ares_leg_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_robot_inventory_ares', 1, 4195328, @category, '#capacity=f31.5', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#capacity=f31.5', mass=0  WHERE definitionname = 'def_robot_inventory_ares'
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_walkers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ares_bot_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ares_bot_pr', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo, ' #tier=$tierlevel_pr'), 1, 22.5, 0, 0, 100, 'def_ares_bot_pr_desc', 1, 2, 0)
END

GO

---- Create robot definitions and it's template and link them

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_pr')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_ares')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'ares_pr_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('ares_pr_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'ares prototype')
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'ares_pr_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_ares_bot_pr')
END

GO

---- Set up aggregate fields for ares
DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4.5)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.27)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.27 WHERE definition = @definition AND field = @field
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_head_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1800)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 37)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 110)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 350)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11250)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7700)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 7700 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5500)
END
BEGIN
	UPDATE aggregatevalues SET value = 5500 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1200)
END
BEGIN
	UPDATE aggregatevalues SET value = 1200 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
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

---- Add enabler extensions for ares prototype

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 4)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 10)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 8)
END

GO

---- Add chassis bonuses and link them with extensions and aggregate fields

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis
    
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_chassis_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_assault_unit_piloting')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_large_projectile_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.03, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'projectile_falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.05, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_combat_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.01, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_syndicate_combat_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, -0.07, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.02, @field, 0)
END

GO

---- Paint ares

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

GO
