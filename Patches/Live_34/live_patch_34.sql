
USE perpetuumsa
GO

EXEC dbo.indexesMaintenance

GO

USE perpetuumsa
GO

---- Boost black bots to proposed values

-- Add specialized head slots

UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_reward1'

-- Boost chassis bonuses

DECLARE @definition INT
DECLARE @field INT

-- Gropho

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_chassis_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_medium_missile_modifier')

UPDATE chassisbonus SET bonus = 0.02 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_leg_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

UPDATE chassisbonus SET bonus = 0.05 WHERE definition = @definition AND targetpropertyID = @field

-- Mesmer

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_chassis_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_medium_railgun_modifier')

UPDATE chassisbonus SET bonus = 0.02 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_leg_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

UPDATE chassisbonus SET bonus = 0.05 WHERE definition = @definition AND targetpropertyID = @field

-- Seth

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_chassis_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_medium_laser_modifier')

UPDATE chassisbonus SET bonus = 0.02 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

UPDATE chassisbonus SET bonus = 5 WHERE definition = @definition AND targetpropertyID = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_leg_reward1')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

UPDATE chassisbonus SET bonus = 0.05 WHERE definition = @definition AND targetpropertyID = @field

GO

---- Half the NIC prices for black bots and t4+

---- Add Spark Teleport Devices and other items into Syndicate shop ----

DECLARE @definition INT
DECLARE @itemshop_preset INT
SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'daoden_preset')


SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_sensor_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_sensor_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_webber')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_webber')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_eccm')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_eccm')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_small_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_medium_core_booster')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_tracking_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_70_tracking_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_small_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 2500, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 2500, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_medium_armor_repairer')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_small_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 2500, NULL, NULL, 375000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 2500, icscoin = NULL, asicoin = NULL, credit = 375000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_medium_shield_generator')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_mining_probe_module')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_mining_probe_module')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_damage_mod_projectile')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_damage_mod_projectile')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_72_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_maneuvering_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 250000000, 10000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 250000000, unicoin = 10000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_71_maneuvering_upgrade')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_autocannon')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_laser')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 5000, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 5000, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_railgun')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 5000, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 5000, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_rocket_launcher')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_missile_launcher')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 5000, NULL, NULL, 750000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 5000, icscoin = NULL, asicoin = NULL, credit = 750000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_driller')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_driller')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_harvester')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_harvester')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
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
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 500000000, 25000, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = NULL, credit = 500000000, unicoin = 25000  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, 50000, NULL, NULL, 2500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = 50000, icscoin = NULL, asicoin = NULL, credit = 2500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, 50000, 2500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = NULL, asicoin = 50000, credit = 2500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_reward1_bot')

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, 50000, NULL, 2500000000, NULL, NULL, 0, NULL)
END
ELSE
BEGIN
	UPDATE itemshop SET tmcoin = NULL, icscoin = 50000, asicoin = NULL, credit = 2500000000, unicoin = NULL  WHERE targetdefinition = @definition AND presetid = @itemshop_preset
END

GO

---- Increase assignment rewards for Daoden

-- Rollback previous changes

UPDATE missionlocations SET agentid = 2 WHERE zoneid = 2

-- Increase Payout

UPDATE zones SET zonetype = 2 WHERE name = 'zone_ASI'

GO

---- Make it generate Uni tokens instead of TM

-- Done in the code. Have to rework it in future

GO

---- Increase spawn chances for breaches

GO

---- Add more fields to Daoden

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 125000000 WHERE zoneid = 2 AND materialtype = 1

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 1257, totalamountpernode = 125000000 WHERE zoneid = 2 AND materialtype = 2

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 125000000 WHERE zoneid = 2 AND materialtype = 3

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 125000000 WHERE zoneid = 2 AND materialtype = 4

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 125000000 WHERE zoneid = 2 AND materialtype = 5

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 85000000 WHERE zoneid = 2 AND materialtype = 6

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 500, totalamountpernode = 85000000 WHERE zoneid = 2 AND materialtype = 12

GO

---- Add components to new stuff

DECLARE @definition INT
DECLARE @component INT

-- Spectator

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Assault Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Assault Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Assault Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 15)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 15 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Tactical Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Tactical Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Tactical Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 15)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 15 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Industrial Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Industrial Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Industrial Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 15)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 15 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Support Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Support Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Support Remote Controller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 15)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 15 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_adaptive_alloy')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_adaptive_alloy')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 20)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 20 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Adaptive alloy

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_adaptive_alloy')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 15)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 15 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 30)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 30 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 45)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 45 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Dreadnought module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 60)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 60 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 180)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 180 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Excavator module

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 60)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 60 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 180)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 180 WHERE definition = @definition AND componentdefinition = @component
END

-- T2 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_large_driller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

-- T3 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_large_driller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

-- T4 Large Driller

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_large_driller')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 60)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 60 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 180)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 180 WHERE definition = @definition AND componentdefinition = @component
END

-- Terramotus

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 80)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 80 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 120)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 120 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 160)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 160 WHERE definition = @definition AND componentdefinition = @component
END

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 9000)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 9000 WHERE definition = @definition AND componentdefinition = @component
END

-- Terramotus prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_bot_pr')

SET @component = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal')

IF NOT EXISTS (SELECT 1 FROM components WHERE definition = @definition AND componentdefinition = @component)
BEGIN
	INSERT INTO components (definition, componentdefinition, componentamount) VALUES
	(@definition, @component, 9000)
END
ELSE
BEGIN
	UPDATE components SET componentamount = 9000 WHERE definition = @definition AND componentdefinition = @component
END

GO

---- Noxes incorrectly show tier when equipped

-- doesn't reproduce on test

GO

---- Large shields unaffected by reactor skills

DECLARE @categoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_large_shield_generators')

DELETE FROM aggregatemodifiers WHERE categoryflag = @categoryFlag

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield)
SELECT categoryflags, basefield, modifierfield FROM modulepropertymodifiers WHERE categoryflags = @categoryFlag

GO

---- Add more interference to spectators

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_head')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

UPDATE aggregatevalues SET value = 4 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

UPDATE aggregatevalues SET value = 10 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

UPDATE aggregatevalues SET value = 75 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

UPDATE aggregatevalues SET value = 340 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_head_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

UPDATE aggregatevalues SET value = 75 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

UPDATE aggregatevalues SET value = 340 WHERE definition = @definition AND field = @field

GO

---- Reconfigure facilities on Daoden

UPDATE entities SET definition = 1976, ename = 'dao_hakk_research' WHERE eid = 6749017929507170927
UPDATE entities SET definition = 1978, ename = 'dao_hakk_prototyper' WHERE eid = 6754023730784211370
UPDATE entities SET definition = 1972, ename = 'dao_hakk_mill' WHERE eid = 5638333303536245776
UPDATE entities SET definition = 1969, ename = 'dao_hakk_repair' WHERE eid = 5361718015214396991
UPDATE entities SET definition = 1966, ename = 'dao_hakk_reprocessor' WHERE eid = 7687403582260236039
UPDATE entities SET definition = 1964, ename = 'dao_hakk_refinery' WHERE eid = 6945016322404155049

UPDATE entities SET definition = 1963, ename = 'dao_dari_refinery' WHERE eid = 5120323525790820591
UPDATE entities SET definition = 1966, ename = 'dao_dari_reprocessor' WHERE eid = 7492824509451463731
UPDATE entities SET definition = 1969, ename = 'dao_dari_repair' WHERE eid = 5716466594085145081
UPDATE entities SET definition = 1975, ename = 'dao_dari_research' WHERE eid = 5874356087296516571
UPDATE entities SET definition = 1979, ename = 'dao_dari_prototyper' WHERE eid = 5053974845760081807
UPDATE entities SET definition = 1972, ename = 'dao_dari_mill' WHERE eid = 4786779398194527626

UPDATE entities SET definition = 1970, ename = 'dao_matsu_repair' WHERE eid = 4873402740791174086
UPDATE entities SET definition = 1975, ename = 'dao_matsu_research' WHERE eid = 7282044178021300031
UPDATE entities SET definition = 1978, ename = 'dao_matsu_prototyper' WHERE eid = 7329132555395171395
UPDATE entities SET definition = 1972, ename = 'dao_matsu_mill' WHERE eid = 7272037670394012085
UPDATE entities SET definition = 1963, ename = 'dao_matsu_refinery' WHERE eid = 8308184383095193902
UPDATE entities SET definition = 1967, ename = 'dao_matsu_reprocessor' WHERE eid = 7423051161637132034

UPDATE entities SET definition = 1963, ename = 'dao_main_refinery' WHERE eid = 5423
UPDATE entities SET definition = 1966, ename = 'dao_main_reprocessor' WHERE eid = 5424
UPDATE entities SET definition = 1972, ename = 'dao_main_mill' WHERE eid = 5426
UPDATE entities SET definition = 1969, ename = 'dao_main_repair' WHERE eid = 5425
UPDATE entities SET definition = 1978, ename = 'dao_main_prototyper' WHERE eid = 9045071191880104849
UPDATE entities SET definition = 1975, ename = 'dao_main_research' WHERE eid = 5428

GO

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

USE perpetuumsa;
GO

---- Increase enabler extensions level for Spectator

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 6)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 6 WHERE definition = @definition AND extensionid = @extension
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 3 WHERE definition = @definition AND extensionid = @extension
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 6)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 6 WHERE definition = @definition AND extensionid = @extension
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END
ELSE
BEGIN
	UPDATE enablerextensions SET extensionlevel = 3 WHERE definition = @definition AND extensionid = @extension
END

GO

---- Turm Spectator and Terramotus into mk1

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definitionname = 'def_terramotus_bot'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definitionname = 'def_spectator_bot'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL, options = NULL WHERE definitionname = 'def_spectator_bot_cprg'
UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL, options = NULL WHERE definitionname = 'def_terramotus_bot_cprg'

GO

-- Fix module property modifiers for excavators

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

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_harvesting_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_enhancer_harvesting_amount_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES (@categoryFlag, @baseField, @modifierField)

GO

-- Decrease masking penalty for excavator modules

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_excavator_module_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_excavator_stealth_strength_modifier')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

GO

-- Fix module property modifiers for dreadnoughts

DECLARE @definition INT
DECLARE @field INT

-- T1

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_dreadnought_stealth_strength_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T2P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -30)

-- T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T3P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -25)

-- T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

-- T4P

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_dreadnought_module_pr')

DELETE FROM aggregatevalues WHERE definition = @definition AND field = @field
INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -20)

GO

---- Add +4 flux fields to Daoden

UPDATE mineralconfigs SET maxnodes = 8 WHERE zoneid = 2 AND materialtype = 16

GO

---- Fix Server-Wide Boosters loot

DECLARE @npc INT
DECLARE @loot INT

-- Add T2 to Radamanthys
SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

DELETE FROM npcloot WHERE definition = @npc AND lootdefinition = @loot

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t2')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

-- Add T3 to Commendant main boss

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_sh70_mainboss')

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t1')

DELETE FROM npcloot WHERE definition = @npc AND lootdefinition = @loot

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t3')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

GO

---- Disable Santa

UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_santa_z8'

GO

---- Fix flux guardians on Daoden

DECLARE @zoneid INT
DECLARE @presenceid INT

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_ASI')

DELETE FROM npcreinforcements WHERE zoneId = @zoneid

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_1_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.1, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_2_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.2, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_3_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.3, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_4_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.4, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_5_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.5, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_6_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.6, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_7_nuimqol')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.7, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_8_pelistal')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.8, @presenceid, @zoneid)

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'flux_ore_npc_wave_9_thelodica')

INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
(1, 16, 0.9, @presenceid, @zoneid)

GO

---- Remove t0 ep boosters from Daoden syndishop and place them to observers

DECLARE @npc INT
DECLARE @loot INT

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

DELETE FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset

IF NOT EXISTS (SELECT 1 FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset)
BEGIN
	INSERT INTO itemshop (presetid, targetdefinition, targetamount, tmcoin, icscoin, asicoin, credit, unicoin, globallimit, purchasecount, standing) VALUES
	(@itemshop_preset, @definition, 1, NULL, NULL, NULL, 10000000, 500, null, 0, null)
END

--

SET @loot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_seth_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

--

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_mesmer_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

--

SET @npc = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_daoden_gropho_advanced_observer')

IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @npc AND lootdefinition = @loot)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@npc, @loot, 1, 1, 0, 0, 1)
END

GO

---- Add extra head slot for Hydra

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4908,8,8,8,8,8' WHERE definitionname = 'def_hydra_bot_head'

GO

USE perpetuumsa;
GO

---- Create entity defaults for Beholder

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_chassis', 1, 1024, @category, '#slotFlags=4653 #height=f0.90 #decay=n125', 1, 12, 9600, 1, 100, 'def_beholder_chassis_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4653 #height=f0.90 #decay=n125', mass=9600  WHERE definitionname = 'def_beholder_chassis'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_head', 1, 1024, @category, '#slotFlags=4848,8,8,8,8 #height=f0.10', 1, 3, 300, 1, 100, 'def_beholder_head_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8 #height=f0.10', mass=300  WHERE definitionname = 'def_beholder_head'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_leg', 1, 1024, @category, '#slotFlags=420,20,20,20,20 #height=f0.30', 1, 10, 2700, 1, 100, 'def_beholder_leg_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20 #height=f0.30', mass=2700  WHERE definitionname = 'def_beholder_leg'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_robot_inventory_beholder')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_robot_inventory_beholder', 1, 4195328, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#capacity=f120.0', mass=0  WHERE definitionname = 'def_robot_inventory_beholder'
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_beholder')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_combat_command_robots')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_bot', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 123, 0, 0, 100, 'def_beholder_bot_desc', 1, NULL, NULL)
END

GO

---- Create robot definitions and it's template and link them

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_beholder')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'beholder_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('beholder_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'Beholder')
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'beholder_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_beholder_bot')
END

GO

---- Set up aggregate fields for Beholder

DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.2)
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 340)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1550)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3000)
END
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 400)
END
BEGIN
	UPDATE aggregatevalues SET value = 400 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 11)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

GO

---- Add enabler extensions for Beholder

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 1)
END

GO

---- Add chassis bonuses and link them with extensions and aggregate fields

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis
    
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

-- Head (whyyyy)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.03, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'massiveness')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 1, @field, 0)
END

-- Leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

GO

---------------------------

---- Create entity defaults for Beholder prototype

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_chassis_pr', 1, 1024, @category, '#slotFlags=4653 #height=f0.90 #decay=n125', 1, 12, 9000, 1, 100, 'def_beholder_chassis_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4653 #height=f0.90 #decay=n125', mass=9000  WHERE definitionname = 'def_beholder_chassis_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_head_pr', 1, 1024, @category, '#slotFlags=4848,8,8,8,8 #height=f0.10', 1, 3, 250, 1, 100, 'def_beholder_head_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8 #height=f0.10', mass=250  WHERE definitionname = 'def_beholder_head_pr'
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mech_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_leg_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_leg_pr', 1, 1024, @category, '#slotFlags=420,20,20,20,20 #height=f0.30', 1, 10, 2400, 1, 100, 'def_beholder_leg_pr_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20 #height=f0.30', mass=2400  WHERE definitionname = 'def_beholder_leg_pr'
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_beholder')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_combat_command_robots')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_bot_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_bot_pr', 1, 0, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 123, 0, 0, 100, 'def_beholder_bot_desc', 1, 2, NULL)
END

GO

---- Create robot definitions and it's template and link them

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_pr')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg_pr')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_beholder')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'beholder_pr_empty')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('beholder_pr_empty', CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X')), 'Beholder prototype')
END

DECLARE @template INT

SET @template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'beholder_pr_empty')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @robot AND templateid = @template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@robot, @template, 0, 0, 'def_beholder_bot_pr')
END

GO

---- Set up aggregate fields for Beholder

DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.2)
END

-- Head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 340)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1550)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3000)
END
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 400)
END
BEGIN
	UPDATE aggregatevalues SET value = 400 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 5 WHERE definition = @definition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

GO

---- Add enabler extensions for Beholder

DECLARE @definition INT
DECLARE @extension INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 3)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

IF NOT EXISTS (SELECT 1 FROM enablerextensions WHERE definition = @definition AND extensionid = @extension)
BEGIN
	INSERT INTO enablerextensions (definition, extensionid, extensionlevel) VALUES
	(@definition, @extension, 1)
END

GO

---- Add chassis bonuses and link them with extensions and aggregate fields

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis
    
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 3, @field, 0)
END

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

-- Head (whyyyy)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_command_robotics')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.03, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'massiveness')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 1, @field, 0)
END

-- Leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_leg_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field)
BEGIN
	INSERT INTO chassisbonus (definition, extension, bonus, targetpropertyID, effectenhancer) VALUES
	(@definition, @extension, 0.01, @field, 0)
END

GO

---- Position in tech tree ----

DECLARE @beholder INT
DECLARE @tacticalRcmT1 INT

DECLARE @group INT

SET @beholder = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')
SET @tacticalRcmT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common2')

DELETE FROM techtree WHERE childdefinition = @beholder

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
(@tacticalRcmT1, @beholder, @group, 2, 24, NULL)

GO

---- Create CT for Beholder

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_mech_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_beholder_bot_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_beholder_bot_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, NULL, NULL)
END

-- set base ct efficiency

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

GO

---- Production and prorotyping cost in materials, modules and components ----

DECLARE @definition INT

DECLARE @titanium INT
DECLARE @cryoperine INT
DECLARE @axicoline INT
DECLARE @plasteosine INT
DECLARE @flux INT

DECLARE @biotichrin INT
DECLARE @polynitrocol INT
DECLARE @polynucleit INT
DECLARE @phlobotil INT

DECLARE @bryochite INT
DECLARE @alligior INT
DECLARE @espitium INT
DECLARE @hydrobenol INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT
DECLARE @pelistal_expert_components INT
DECLARE @nuimqol_expert_components INT
DECLARE @thelodica_expert_components INT

DECLARE @gamma_syndicate_shards INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol')
SET @axicoline = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicoline')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')

SET @biotichrin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_biotichrin')
SET @polynitrocol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynitrocol')
SET @polynucleit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynucleit')
SET @phlobotil = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_phlobotil')

SET @alligior = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_alligior')
SET @hydrobenol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hydrobenol')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite

SET @common_basic_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
SET @common_advanced_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
SET @common_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

SET @pelistal_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')
SET @nuimqol_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')
SET @thelodica_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')

SET @gamma_syndicate_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')

-- Beholder --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @biotichrin, 1250),
(@definition, @phlobotil, 750),
(@definition, @polynucleit, 750),
(@definition, @polynitrocol, 750),
(@definition, @titanium, 3750),
(@definition, @plasteosine, 500),
(@definition, @cryoperine, 875),
(@definition, @hydrobenol, 750),
(@definition, @espitium, 2500),
(@definition, @alligior, 1250),
(@definition, @bryochite, 10000),
(@definition, @flux, 125),
(@definition, @gamma_syndicate_shards, 50),
(@definition, @common_expert_components, 45),
(@definition, @pelistal_expert_components, 45),
(@definition, @nuimqol_expert_components, 45),
(@definition, @thelodica_expert_components, 45)

-- Beholder Prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @biotichrin, 1250),
(@definition, @phlobotil, 750),
(@definition, @polynucleit, 750),
(@definition, @polynitrocol, 750),
(@definition, @titanium, 3750),
(@definition, @plasteosine, 500),
(@definition, @cryoperine, 875),
(@definition, @hydrobenol, 750),
(@definition, @espitium, 2500),
(@definition, @alligior, 1250),
(@definition, @bryochite, 10000),
(@definition, @flux, 125),
(@definition, @gamma_syndicate_shards, 50),
(@definition, @common_expert_components, 45),
(@definition, @pelistal_expert_components, 45),
(@definition, @nuimqol_expert_components, 45),
(@definition, @thelodica_expert_components, 45)

GO

---- Research levels ----

DECLARE @definition INT
DECLARE @calibration INT

-- Beholder prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

GO

----Research cost ----

DECLARE @definition INT
DECLARE @common INT
DECLARE @hightech INT
DECLARE @pelistal INT
DECLARE @nuimqol INT
DECLARE @thelodica INT

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')
SET @pelistal = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'pelistal')
SET @nuimqol = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'nuimqol')
SET @thelodica = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'thelodica')

-- Beholder

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000),
(@definition, @hightech, 75000)

GO

---- Link items and their prototypes----

DECLARE @item int
DECLARE @prototype int

-- Beholder

SET @item = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_beholder_bot')
SET @prototype = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname LIKE 'def_beholder_bot_pr')

DELETE FROM prototypes WHERE definition = @item AND prototype = @prototype

INSERT INTO prototypes (definition, prototype) VALUES (@item, @prototype)

GO

---- Paint Beholder

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

GO

USE perpetuumsa;
GO

---- Create category flags for field maskers

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_masker_capsule' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(3736, 'cf_mobile_field_masker_capsule', 'Mobile field masker capsule', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_masker' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(524920, 'cf_mobile_field_masker', 'Mobile field masker', 0, 0)
END

GO

---- Create entity defaults for field maskers

DECLARE @definition INT
DECLARE @categoryFlags INT

-- Field masker

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_masker')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_masker', 1, 12583936, @categoryFlags, '#size=n2', '', 1, 1, 1, 0, 100, 'def_mobile_field_masker_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#size=n2', descriptiontoken = 'def_mobile_field_masker_desc', attributeflags = 12583936 WHERE definitionname = 'def_mobile_field_masker'
END

-- Field masker capsule

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker')

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_masker_capsule')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker_capsule')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_masker_capsule', 1, 25167872, @categoryFlags, CONCAT('#target=n', @definition), '', 1, 5, 50000, 0, 100, 'def_mobile_field_masker_capsule_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#target=n', @definition), descriptiontoken = 'def_mobile_field_masker_capsule_desc', attributeflags = 25167872 WHERE definitionname = 'def_mobile_field_masker_capsule'
END

GO

---- Place field masker capsule on markets

DECLARE @definition INT
DECLARE @category INT
DECLARE @price FLOAT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker_capsule')
SET @category = (SELECT categoryflags FROM dbo.entitydefaults WHERE definition=@definition)
SET @price = 5000000

INSERT dbo.marketitems (marketeid, submittereid, itemdefinition, duration, isSell, price, quantity, isvendoritem) 
SELECT marketeid, vendoreid, @definition, 0, 1, @price, -1, 1 FROM dbo.vendors WHERE marketEID NOT IN (SELECT eid FROM getLiveGammaMarkets())

GO

---- Set up aggregate fields for field maskers

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker')

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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker_capsule')

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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END

GO

---- Add field masker effect

DECLARE @effectCategory BIGINT

SET @effectCategory = 17716740096

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_field_stealth')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_field_stealth', 'effect_field_stealth_desc', 'Field stealth effect', 1, 100, 1, 3, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 0 WHERE name = 'effect_field_stealth'
END

GO

---- Add definition configs

DECLARE @definition INT
DECLARE @targetdefinition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker_capsule')
SET @targetdefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_masker')

DELETE FROM definitionconfig WHERE definition = @definition
DELETE FROM definitionconfig WHERE definition = @targetdefinition

INSERT INTO definitionconfig (definition, targetdefinition, emitradius) VALUES
(@targetdefinition, NULL, 100)

INSERT INTO definitionconfig (definition, targetdefinition) VALUES
(@definition, @targetdefinition)

GO

USE perpetuumsa;
GO

---- Remove t0 ep boosters from Daoden I said!

DECLARE @npc INT
DECLARE @loot INT

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

DELETE FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset

GO

---- Fix ep boosters description

UPDATE entitydefaults SET descriptiontoken = 'def_server_wide_ep_booster_desc' WHERE definitionname in (
	'def_server_wide_ep_booster_t0',
	'def_server_wide_ep_booster_t1',
	'def_server_wide_ep_booster_t2',
	'def_server_wide_ep_booster_t3')
	
GO

-- Fix mass-harvestig ammo production duration and decalibtarion

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mass_harvesting_ammo')

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

---- Set up aggregate fields for Beholder

DECLARE @definition INT
DECLARE @field INT

-- Head

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')

UPDATE aggregatevalues SET value = 155 WHERE definition = @definition AND field = @field

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')

UPDATE aggregatevalues SET value = 155 WHERE definition = @definition AND field = @field

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

GO

---- Fix volume for Spectators

UPDATE entitydefaults SET volume = 23 WHERE definitionname in (
	'def_spectator_bot_pr',
	'def_spectator_bot')
	
GO

---- Increase bandwidth to medium and large terminals for 25%

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

GO

---- Remove dev_dhdt

UPDATE entitydefaults SET enabled = 0 WHERE definitionname = 'def_dhdt'

GO

---- Decrease energy fields but increase energy in them by 1/3

DECLARE @zoneid INT
DECLARE @mineralid INT

SET @mineralid = (SELECT TOP 1 idx FROM minerals WHERE name = 'energymineral')

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z106')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z107')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z108')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z109')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z111')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z112')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z113')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z115')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z116')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z117')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z118')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z120')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z121')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z122')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z123')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z124')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z125')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z126')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z127')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z128')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z129')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z130')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z132')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z133')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z134')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z135')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z136')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z137')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z138')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z139')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z140')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

GO

---- Fix ghost bases

DELETE FROM entities WHERE eid = 8672957799981290018
DELETE FROM entities WHERE eid = 7135039852722197766
DELETE FROM entities WHERE eid = 5606203623296356816

DELETE FROM entities WHERE eid = 4614988393035807463
DELETE FROM entities WHERE eid = 8107379312386187517
DELETE FROM entities WHERE eid = 7974584861862392349
DELETE FROM entities WHERE eid = 8901489937581974613
DELETE FROM entities WHERE eid = 8394791714481758393

DELETE FROM entities WHERE eid = 7946028597290312044

----

DELETE FROM entities WHERE eid = 4822305416562049174

DELETE FROM entities WHERE eid = 4911644923930124201

DELETE FROM entities WHERE eid = 5230550472600805402

DELETE FROM entities WHERE eid = 8113007424844366194
DELETE FROM entities WHERE eid = 9150636073543254054
DELETE FROM entities WHERE eid = 5333350848329355092

----

GO

---- Fix Beholder hit surface

DECLARE @definition INT
DECLARE @field INT

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

UPDATE aggregatevalues SET value = 5 WHERE definition = @definition AND field = @field

GO

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

USE perpetuumsa
GO

---- Re-enable existing stuff

DECLARE @categoryFlafs BIGINT

SET @categoryFlafs = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_single_projectile')

UPDATE categoryFlags SET hidden = 0 WHERE value = @categoryFlafs
UPDATE entitydefaults SET enabled = 1 WHERE categoryflags = @categoryFlafs

SET @categoryFlafs = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_projectile_ammo')

UPDATE categoryFlags SET hidden = 0 WHERE value = @categoryFlafs
UPDATE entitydefaults SET enabled = 1 WHERE categoryflags = @categoryFlafs

GO

---- Create categories for Hell and RAVEN ammo

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_hell_cannon_ammo' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(16974602, 'cf_hell_cannon_ammo', 'Hell cannon ammo', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_raven_cannon_ammo' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(33751818, 'cf_raven_cannon_ammo', 'RAVEN cannon ammo', 0, 0)
END

GO

---- Rename and reconfigure large ammo into hell cannon ammo

DECLARE @categoryFlags BIGINT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannon_ammo')

UPDATE entitydefaults
SET
	definitionname = 'def_ammo_hell_cannon_a',
	descriptiontoken = 'def_ammo_hell_cannon_a_desc',
	options = '
	#damageChemical=f0.00
	#damageKinetic=f72.00
	#damageExplosive=f36.00
	#damageThermal=f0.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	categoryflags = @categoryFlags
WHERE definitionname = 'def_ammo_large_projectile_a'

--

UPDATE entitydefaults
SET
	definitionname = 'def_ammo_hell_cannon_b',
	descriptiontoken = 'def_ammo_hell_cannon_b_desc',
	options = '
	#damageChemical=f0.00
	#damageKinetic=f24.00
	#damageExplosive=f24.00
	#damageThermal=f60.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0',
	categoryflags = @categoryFlags
WHERE definitionname = 'def_ammo_large_projectile_b'

--

UPDATE entitydefaults
SET
	definitionname = 'def_ammo_hell_cannon_c',
	descriptiontoken = 'def_ammo_hell_cannon_c_desc',
	options = '
	#damageChemical=f0.00
	#damageKinetic=f36.00
	#damageExplosive=f72.00
	#damageThermal=f0.00
	#damageToxic=f18.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0
	#bullettime=f35.0',
	categoryflags = @categoryFlags
WHERE definitionname = 'def_ammo_large_projectile_c'

--

UPDATE entitydefaults
SET
	definitionname = 'def_ammo_hell_cannon_d',
	descriptiontoken = 'def_ammo_hell_cannon_d_desc',
	options = '
	#damageChemical=f24.00
	#damageKinetic=f24.00
	#damageExplosive=f8.00
	#damageThermal=f0.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0
	#bullettime=f35.0',
	categoryflags = @categoryFlags
WHERE definitionname = 'def_ammo_large_projectile_d'

GO

---- Create RAVEN ammo

DECLARE @categoryFlags BIGINT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannon_ammo')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_a', 1000, 133120, @categoryFlags, '
	#damageChemical=f0.00
	#damageKinetic=f96.00
	#damageExplosive=f48.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0', '', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_a_desc', 1, NULL, NULL)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_b', 1000, 133120, @categoryFlags, '
	#damageChemical=f0.00
	#damageKinetic=f32.00
	#damageExplosive=f32.00
	#damageThermal=f80.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0', '', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_b_desc', 1, NULL, NULL)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_c', 1000, 133120, @categoryFlags, '
	#damageChemical=f0.00
	#damageKinetic=f48.00
	#damageExplosive=f96.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0', '', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_c_desc', 1, NULL, NULL)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_ammo_raven_cannon_d', 1000, 133120, @categoryFlags, '
	#damageChemical=f48.00
	#damageKinetic=f48.00
	#damageExplosive=f48.00
	#damageThermal=f0.00
	#damageToxic=f24.00
	#optimalRangeModifier=f1.00
	#explosion_radius=f0 #bullettime=f35.0', '', 1, 2, 0.4, 0, 100, 'def_ammo_raven_cannon_d_desc', 1, NULL, NULL)
END

GO


---- Create categories for Hell and RAVEN cannons

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_hell_cannons' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(1112463771407, 'cf_hell_cannons', 'Hell cannons', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_raven_cannons' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(2211975399183, 'cf_raven_cannons', 'RAVEN cannons', 0, 0)
END

GO

---- Rename and reconfigure existing weapons

DECLARE @categoryFlags BIGINT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_hell_cannons')

UPDATE entitydefaults
SET
	definitionname = 'def_standard_hell_cannon',
	descriptiontoken = 'def_standard_hell_cannon_desc',
	options = '
	#moduleFlag=i111
	#ammoCapacity=i2d
	#powergrid_usage=f195.00
	#cpu_usage=f55.00
	#accuracy=f44.00
	#cycle_time=f8.00
	#optimal_range=f15.00
	#damage_modifier=f2.2
	#falloff=f20.00
	#core_usage=f2.00
	#ammoType=L103030a
	#tier=$tierlevel_t1',
	mass = 1100,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_standard_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named1_hell_cannon',
	descriptiontoken = 'def_named1_hell_cannon_desc',
	options = '
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
	#tier=$tierlevel_t2',
	mass = 990,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named1_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named2_hell_cannon',
	descriptiontoken = 'def_named2_hell_cannon_desc',
	options = '
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
	#tier=$tierlevel_t3',
	mass = 1100,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named2_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named3_hell_cannon',
	descriptiontoken = 'def_named3_hell_cannon_desc',
	options = '
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
	#tier=$tierlevel_t4',
	mass = 1320,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named3_large_autocannon'

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_raven_cannons')

UPDATE entitydefaults
SET
	definitionname = 'def_standard_raven_cannon',
	descriptiontoken = 'def_standard_raven_cannon_desc',
	options = '
	#moduleFlag=i111
	#ammoCapacity=if
	#powergrid_usage=f300.00
	#cpu_usage=f70.00
	#accuracy=f18.00
	#cycle_time=f46.00
	#optimal_range=f38.00
	#damage_modifier=f1.65
	#falloff=f40.00
	#core_usage=f2.00
	#ammoType=L203030A
	#tier=$tierlevel_t1',
	mass = 1400,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_longrange_standard_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named1_raven_cannon',
	descriptiontoken = 'def_named1_raven_cannon_desc',
	options = '
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
	#tier=$tierlevel_t2',
	mass = 1260,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named1_longrange_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named2_raven_cannon',
	descriptiontoken = 'def_named2_raven_cannon_desc',
	options = '
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
	#tier=$tierlevel_t3',
	mass = 1400,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named2_longrange_large_autocannon'

--

UPDATE entitydefaults
SET
	definitionname = 'def_named3_raven_cannon',
	descriptiontoken = 'def_named3_raven_cannon_desc',
	options = '
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
	#tier=$tierlevel_t4',
	mass = 1680,
	categoryflags = @categoryFlags
WHERE definitionname = 'def_named3_longrange_large_autocannon'

GO

---- Set aggregate values for ammo

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')

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

---- Set aggregate values for guns

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_hell_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 55)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 195)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_hell_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 49.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 175.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_hell_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 60.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 214.5)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_hell_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 66)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 234)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_raven_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 70)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 300)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_raven_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 63)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 270)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_raven_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 77)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 330)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_raven_cannon')

DELETE FROM aggregatevalues WHERE definition = @definition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 84)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 360)

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

INSERT INTO aggregatevalues (definition, field, value) VALUES
(@definition, @field, 2)

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

---- Assign modifiers

DECLARE @categoryflags BIGINT
DECLARE @base INT
DECLARE @modifier INT

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_single_projectile')

DELETE FROM aggregatemodifiers WHERE categoryflag = @categoryflags

-- Accuracy

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- Core usage

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage_weapon_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- Cpu usage large

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_large_projectile_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- Cpu usage

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_weapons_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- Cycle time

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'projectile_cycle_time_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_cycle_time_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'weapon_cycle_time_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- damage

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_large_projectile_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_projectile_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_turret_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- falloff

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'projectile_falloff_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_fallof_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- optimal

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'projectile_optimal_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_optimal_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- powergrid

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_large_projectile_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

--

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_weapons_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

GO

---- Assign  module property modifiers

DECLARE @categoryflags BIGINT
DECLARE @base INT
DECLARE @modifier INT

SET @categoryflags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_large_single_projectile')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @categoryflags

-- Cpu usage large

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_large_projectile_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- damage

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_large_projectile_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

-- powergrid

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_large_projectile_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@categoryflags, @base, @modifier)

GO

---- Add new beams

IF NOT EXISTS (SELECT 1 FROM beams WHERE name = 'large_mg')
BEGIN
	INSERT INTO beams (name, cycletime, startdelay, description) VALUES
	('large_mg', 0, 0, NULL)
END

IF NOT EXISTS (SELECT 1 FROM beams WHERE name = 'large_ac')
BEGIN
	INSERT INTO beams (name, cycletime, startdelay, description) VALUES
	('large_ac', 0, 0, NULL)
END

GO

---- Assign beams

DECLARE @definition INT
DECLARE @beam INT

SET @beam = (SELECT TOP 1 id FROM beams WHERE name = 'large_mg')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_a')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_b')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_c')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_hell_cannon_d')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @beam = (SELECT TOP 1 id FROM beams WHERE name = 'large_ac')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_a')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_b')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_c')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_raven_cannon_d')

DELETE FROM beamassignment WHERE definition = @definition
INSERT INTO beamassignment (definition, beam) VALUES
(@definition, @beam)

GO

---- Enable large projectiles extension

UPDATE extensions SET active = 1 WHERE extensionname = 'ext_large_projectile_turret'

GO

----Research cost ----
/*
DECLARE @definition INT
DECLARE @common INT
DECLARE @hightech INT
DECLARE @pelistal INT
DECLARE @nuimqol INT
DECLARE @thelodica INT

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')
SET @pelistal = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'pelistal')
SET @nuimqol = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'nuimqol')
SET @thelodica = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'thelodica')

-- ares

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_bot')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000),
(@definition, @hightech, 75000)

GO
*/

USE [perpetuumsa]
GO

----------------------------------------
-- Turret stats
-- Reintroduced cycle time modifier
-- Date Modified: 2023/06/27
----------------------------------------

PRINT N'Define all stats and modifiers by tech and turret type';
DROP TABLE IF EXISTS #STATS_BY_TECH;
CREATE TABLE #STATS_BY_TECH(
	tech INT,
	fieldName NVARCHAR(100),
	modValue FLOAT
);
INSERT INTO #STATS_BY_TECH (tech, fieldName, modValue) VALUES
(1, 'resist_thermal', 180),
(1, 'resist_kinetic', 180),
(1, 'resist_explosive', 180),
(1, 'resist_chemical', 180),

(2, 'resist_thermal', 240),
(2, 'resist_kinetic', 240),
(2, 'resist_explosive', 240),
(2, 'resist_chemical', 240),

(3, 'resist_thermal', 300),
(3, 'resist_kinetic', 300),
(3, 'resist_explosive', 300),
(3, 'resist_chemical', 300),

(1, 'signature_radius', 12),
(2, 'signature_radius', 18),
(3, 'signature_radius', 30),

(1, 'armor_max', 45000),
(2, 'armor_max', 67500),
(3, 'armor_max', 75000),

(1, 'sensor_strength', 160),
(2, 'sensor_strength', 180),
(3, 'sensor_strength', 200),

(1, 'detection_strength', 125),
(2, 'detection_strength', 125),
(3, 'detection_strength', 125),

(1, 'stealth_strength', 80),
(2, 'stealth_strength', 80),
(3, 'stealth_strength', 80),

(1, 'locking_range_modifier', 1.35),
(2, 'locking_range_modifier', 1.425),
(3, 'locking_range_modifier', 1.50),

(1,'damage_modifier', 0.4),
(2,'damage_modifier', 0.6),
(3,'damage_modifier', 1.0),

(1,'cycle_time', 0.6),
(2,'cycle_time', 0.7),
(3,'cycle_time', 1.0),

(1,'energy_neutralized_amount_modifier', 0.5),
(2,'energy_neutralized_amount_modifier', 0.7),
(3,'energy_neutralized_amount_modifier', 1.0),

(1,'ecm_strength_modifier', 0.85),
(2,'ecm_strength_modifier', 0.9),
(3,'ecm_strength_modifier', 1.0),

(1,'ew_optimal_range_modifier',0.85),
(2,'ew_optimal_range_modifier',0.9),
(3,'ew_optimal_range_modifier',1.0),

(1,'optimal_range_modifier',1.0),
(2,'optimal_range_modifier',1.0),
(3,'optimal_range_modifier',1.0),

(1,'falloff_modifier',1.6),
(2,'falloff_modifier',1.8),
(3,'falloff_modifier',2.0),

(1,'missile_falloff_modifier',1.6),
(2,'missile_falloff_modifier',1.8),
(3,'missile_falloff_modifier',2.0),

(1,'turret_fallof_modifier',1.6),
(2,'turret_fallof_modifier',1.8),
(3,'turret_fallof_modifier',2.0),

(1,'core_max',2500),
(2,'core_max',2500),
(3,'core_max',2500),

-- EW turrets 

(4, 'resist_thermal', 180),
(4, 'resist_kinetic', 180),
(4, 'resist_explosive', 180),
(4, 'resist_chemical', 180),

(5, 'resist_thermal', 240),
(5, 'resist_kinetic', 240),
(5, 'resist_explosive', 240),
(5, 'resist_chemical', 240),

(6, 'resist_thermal', 300),
(6, 'resist_kinetic', 300),
(6, 'resist_explosive', 300),
(6, 'resist_chemical', 300),

(4, 'signature_radius', 12),
(5, 'signature_radius', 18),
(6, 'signature_radius', 30),

(4, 'armor_max', 45000),
(5, 'armor_max', 67500),
(6, 'armor_max', 75000),

(4, 'sensor_strength', 160),
(5, 'sensor_strength', 180),
(6, 'sensor_strength', 200),

(4, 'detection_strength', 135),
(5, 'detection_strength', 135),
(6, 'detection_strength', 135),

(4, 'stealth_strength', 80),
(5, 'stealth_strength', 80),
(6, 'stealth_strength', 80),

(4, 'locking_range_modifier', 1.35),
(5, 'locking_range_modifier', 1.425),
(6, 'locking_range_modifier', 1.50),

(4,'damage_modifier', 0.4),
(5,'damage_modifier', 0.6),
(6,'damage_modifier', 1.0),

(4,'cycle_time', 1.0),
(5,'cycle_time', 1.0),
(6,'cycle_time', 1.0),

(4,'energy_neutralized_amount_modifier', 0.5),
(5,'energy_neutralized_amount_modifier', 0.7),
(6,'energy_neutralized_amount_modifier', 1.0),

(4,'ecm_strength_modifier', 0.85),
(5,'ecm_strength_modifier', 0.9),
(6,'ecm_strength_modifier', 1.0),

(4,'ew_optimal_range_modifier',0.85),
(5,'ew_optimal_range_modifier',0.9),
(6,'ew_optimal_range_modifier',1.0),

(4,'optimal_range_modifier',0.85),
(5,'optimal_range_modifier',0.9),
(6,'optimal_range_modifier',1.0),

(4,'falloff_modifier',1.6),
(5,'falloff_modifier',1.8),
(6,'falloff_modifier',2.0),

(4,'missile_falloff_modifier',1.6),
(5,'missile_falloff_modifier',1.8),
(6,'missile_falloff_modifier',2.0),

(4,'turret_fallof_modifier',1.6),
(5,'turret_fallof_modifier',1.8),
(6,'turret_fallof_modifier',2.0),

(4,'core_max',2500),
(5,'core_max',2500),
(6,'core_max',2500);

DROP TABLE IF EXISTS #TURRETNAME_BY_TECH;
CREATE TABLE #TURRETNAME_BY_TECH(
	defName VARCHAR(100),
	tech INT 
);
INSERT INTO #TURRETNAME_BY_TECH (defName, tech) VALUES
('def_pbs_turret_ew_large', 6),
('def_pbs_turret_ew_medium', 5),
('def_pbs_turret_ew_small', 4),

('def_pbs_turret_laser_large', 3),
('def_pbs_turret_laser_medium', 2),
('def_pbs_turret_laser_small', 1),

('def_pbs_turret_missile_large', 3),
('def_pbs_turret_missile_medium', 2),
('def_pbs_turret_missile_small', 1),

('def_pbs_turret_rail_large', 3),
('def_pbs_turret_rail_medium', 2),
('def_pbs_turret_rail_small', 1);



DROP TABLE IF EXISTS #TURRET_STATS;
CREATE TABLE #TURRET_STATS(
	defName VARCHAR(100),
	fieldName NVARCHAR(100),
	modValue FLOAT
);
INSERT INTO #TURRET_STATS (defName, fieldName, modValue)
SELECT t.defName, s.fieldName, s.modValue
FROM #STATS_BY_TECH s
JOIN #TURRETNAME_BY_TECH t ON t.tech=s.tech;

INSERT INTO #TURRET_STATS (defName, fieldName, modValue)
SELECT t.defName+'_capsule', s.fieldName, s.modValue
FROM #STATS_BY_TECH s
JOIN #TURRETNAME_BY_TECH t ON t.tech=s.tech;


PRINT N'Merge all turret stats';
MERGE [dbo].[aggregatevalues] v USING #TURRET_STATS s
ON v.definition = (SELECT TOP 1 definition FROM entitydefaults WHERE s.defName=definitionname collate SQL_Latin1_General_CP1_CI_AS) AND
v.field = (SELECT TOP 1 id FROM aggregatefields WHERE name=s.fieldName collate SQL_Latin1_General_CP1_CI_AS)
WHEN MATCHED
    THEN UPDATE SET
		v.value=s.modValue
WHEN NOT MATCHED
    THEN INSERT (definition, field, value) VALUES
	((SELECT TOP 1 definition FROM entitydefaults WHERE s.defName=definitionname collate SQL_Latin1_General_CP1_CI_AS),
	(SELECT TOP 1 id FROM aggregatefields WHERE name=s.fieldName collate SQL_Latin1_General_CP1_CI_AS),
	s.modValue);


DROP TABLE IF EXISTS #STATS_BY_TECH;
DROP TABLE IF EXISTS #TURRET_STATS;
DROP TABLE IF EXISTS #TURRETNAME_BY_TECH;
PRINT N'Turret stats modified';
GO

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

USE perpetuumsa;
GO

---- Fix large firearms CT tier

UPDATE entitydefaults SET tierlevel = 2 WHERE definitionname = 'def_named1_raven_cannon_cprg'
UPDATE entitydefaults SET tierlevel = 3 WHERE definitionname = 'def_named2_raven_cannon_cprg'
UPDATE entitydefaults SET tierlevel = 4 WHERE definitionname = 'def_named3_raven_cannon_cprg'

UPDATE entitydefaults SET tierlevel = 2 WHERE definitionname = 'def_named1_hell_cannon_cprg'
UPDATE entitydefaults SET tierlevel = 3 WHERE definitionname = 'def_named2_hell_cannon_cprg'
UPDATE entitydefaults SET tierlevel = 4 WHERE definitionname = 'def_named3_hell_cannon_cprg'

GO

---- Set up aggregate fields for ares
DECLARE @definition INT
DECLARE @field INT

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg_pr')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.83)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.83 WHERE definition = @definition AND field = @field
END

-- Legs

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ares_leg')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.83)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.83 WHERE definition = @definition AND field = @field
END

GO

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

USE perpetuumsa;
GO

---- Create category flags for field reactor stabilizer

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_reactor_stabilizer_capsule' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4248, 'cf_mobile_field_reactor_stabilizer_capsule', 'Mobile field reactor stabilizer capsule', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_mobile_field_reactor_stabilizer' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(655992, 'cf_mobile_field_reactor_stabilizer', 'Mobile field reactor stabilizer', 0, 0)
END

GO

---- Create entity defaults for field reactor stabilizer

DECLARE @definition INT
DECLARE @categoryFlags INT

-- Field stabilizer

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_reactor_stabilizer')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_reactor_stabilizer', 1, 12583936, @categoryFlags, '#size=n2', '', 1, 1, 1, 0, 100, 'def_mobile_field_reactor_stabilizer_desc', 0, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#size=n2', descriptiontoken = 'def_mobile_field_reactor_stabilizer_desc', attributeflags = 12583936 WHERE definitionname = 'def_mobile_field_reactor_stabilizer'
END

-- Field reactor stabilizer capsule

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer')

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mobile_field_reactor_stabilizer_capsule')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer_capsule')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mobile_field_reactor_stabilizer_capsule', 1, 25167872, @categoryFlags, CONCAT('#target=n', @definition), '', 1, 5, 50000, 0, 100, 'def_mobile_field_reactor_stabilizer_capsule_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = CONCAT('#target=n', @definition), descriptiontoken = 'def_mobile_field_reactor_stabilizer_capsule_desc', attributeflags = 25167872 WHERE definitionname = 'def_mobile_field_reactor_stabilizer_capsule'
END

GO

---- Place field reactor stabilizer capsule on markets

DECLARE @definition INT
DECLARE @category INT
DECLARE @price FLOAT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer_capsule')
SET @category = (SELECT categoryflags FROM dbo.entitydefaults WHERE definition=@definition)
SET @price = 5000000

INSERT dbo.marketitems (marketeid, submittereid, itemdefinition, duration, isSell, price, quantity, isvendoritem) 
SELECT marketeid, vendoreid, @definition, 0, 1, @price, -1, 1 FROM dbo.vendors WHERE marketEID NOT IN (SELECT eid FROM getLiveGammaMarkets())

GO

---- Set up aggregate fields for field eccm

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -50)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_reactor_radiation_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer_capsule')

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
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, -50)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'effect_field_reactor_radiation_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.5)
END

GO

---- Add field reactor stabilizer effect

DECLARE @effectCategory BIGINT

SET @effectCategory = 9007199254740992

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_field_reactor_stabilizer')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_field_reactor_stabilizer', 'effect_field_reactor_stabilizer_desc', 'Field Reactor Stabilizer effect', 1, 30, 1, 3, 0)
END
ELSE
BEGIN
	UPDATE effects SET duration = 0 WHERE name = 'effect_field_reactor_stabilizer'
END

GO

---- Add definition configs

DECLARE @definition INT
DECLARE @targetdefinition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer_capsule')
SET @targetdefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mobile_field_reactor_stabilizer')

DELETE FROM definitionconfig WHERE definition = @definition
DELETE FROM definitionconfig WHERE definition = @targetdefinition

INSERT INTO definitionconfig (definition, targetdefinition, emitradius) VALUES
(@targetdefinition, NULL, 30)

INSERT INTO definitionconfig (definition, targetdefinition) VALUES
(@definition, @targetdefinition)

GO

USE perpetuumsa
GO

---- turn pre-created account 'devours@internet.ru' into admin account

UPDATE accounts SET accLevel = 14 WHERE email = 'devours@internet.ru'

GO

---- turn pre-created character with the nick 'Dat Nick' into DEV Ours

UPDATE characters SET corporationeid = 495, allianceeid = 2401, nick = 'DEV Ours' WHERE nick = 'Dat Nick'

GO

USE perpetuumsa
GO

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4353, 'cf_drones', 'Drones', 1, 0)
END

UPDATE categoryflags SET value = 69889, hidden = 1, isunique = 0 WHERE name = 'cf_assault_drones'
UPDATE categoryflags SET value = 135425, hidden = 1, isunique = 0 WHERE name = 'cf_industrial_drones'
UPDATE categoryflags SET value = 200961, hidden = 1, isunique = 0 WHERE name = 'cf_support_drones'
UPDATE categoryflags SET value = 266497, hidden = 1, isunique = 0 WHERE name = 'cf_attack_drones'

UPDATE entitydefaults SET categoryflags = 69889 WHERE categoryflags = 4498
UPDATE entitydefaults SET categoryflags = 135425 WHERE categoryflags = 4754
UPDATE entitydefaults SET categoryflags = 200961 WHERE categoryflags = 5010
UPDATE entitydefaults SET categoryflags = 266497 WHERE categoryflags = 5266

GO

USE perpetuumsa;
GO

---- Slow down the spectator

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_leg')

UPDATE aggregatevalues SET value = 1.53 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_leg_pr')

UPDATE aggregatevalues SET value = 1.53 WHERE definition = @definition AND field = @field

GO

---- Set allowed bots for dreadnoughts

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named1_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named1_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named2_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named2_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named3_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named3_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t1#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_standard_dreadnought_module'

GO

---- Set allowed bots for excavators

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_excavator_module'

GO

---- Set allowed bots for assault remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a #powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=4209c,20e4' WHERE definitionname = 'def_named1_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named1_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=4209c,20e4' WHERE definitionname = 'def_named2_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named2_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=4209c,20e4' WHERE definitionname = 'def_named3_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named3_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=4209c,20e4' WHERE definitionname = 'def_standard_assault_remote_controller'

GO

---- Set allowed bots for tactical remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named1_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named1_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named2_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named2_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named3_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named3_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00  #cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_standard_tactical_remote_controller'

GO

---- Set allowed bots for industrial remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=4beb,bec' WHERE definitionname = 'def_named1_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named1_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=4beb,bec' WHERE definitionname = 'def_named2_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named2_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=4beb,bec' WHERE definitionname = 'def_named3_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named3_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=4beb,bec' WHERE definitionname = 'def_standard_industrial_remote_controller'

GO

---- Set allowed bots for support remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=415a8' WHERE definitionname = 'def_standard_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=415a8' WHERE definitionname = 'def_named1_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=415a8' WHERE definitionname = 'def_named1_support_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=415a8' WHERE definitionname = 'def_named2_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=415a8' WHERE definitionname = 'def_named2_support_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=415a8' WHERE definitionname = 'def_named3_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=415a8' WHERE definitionname = 'def_named3_support_remote_controller_pr'

GO

---- Set allowed bots for large drillers

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_large_driller'

GO

---- Set allowed bots for large harvesters

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_large_harvester'

GO

---- Turn slots into normal

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_ares_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_ares_head_pr'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_felos_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8,8' WHERE definitionname = 'def_hydra_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_onyx_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_terramotus_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_terramotus_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.10' WHERE definitionname = 'def_spectator_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.10' WHERE definitionname = 'def_spectator_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8 #height=f0.10' WHERE definitionname = 'def_beholder_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8 #height=f0.10' WHERE definitionname = 'def_beholder_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.15#max_locked_targets=f3.00#max_targeting_range=f35.00#sensor_strength=f100.00#cpu=f375.00' WHERE definitionname = 'def_mesmer_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.15#max_locked_targets=f3.00#max_targeting_range=f35.00#sensor_strength=f100.00#cpu=f375.00' WHERE definitionname = 'def_mesmer_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f475.00' WHERE definitionname = 'def_gropho_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f475.00' WHERE definitionname = 'def_gropho_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.01#max_locked_targets=f3.00#max_targeting_range=f37.50#sensor_strength=f100.00#cpu=f325.00' WHERE definitionname = 'def_seth_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.01#max_locked_targets=f3.00#max_targeting_range=f37.50#sensor_strength=f100.00#cpu=f325.00' WHERE definitionname = 'def_seth_head_reward1'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8,8' WHERE definitionname = 'def_legatus_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.20#max_locked_targets=f1.00#max_targeting_range=f21.00#sensor_strength=f100.00#cpu=f450.00' WHERE definitionname = 'def_riveler_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.20#max_locked_targets=f1.00#max_targeting_range=f21.00#sensor_strength=f100.00#cpu=f450.00' WHERE definitionname = 'def_symbiont_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8#height=f0.20' WHERE definitionname = 'def_metis_head'

UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg'

UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg_pr'

GO

USE perpetuumsa;
GO

---- Alter add isAnnouncement to the sap table
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
ALTER TABLE dbo.intrusionsites ADD
	isAnnounced bit NOT NULL CONSTRAINT DF_intrusionsites_isAnnounced DEFAULT 0
GO
ALTER TABLE dbo.intrusionsites SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Add Syndicate Intel channel and assign Announcer there

DECLARE @chanName AS VARCHAR(100) = 'Syndicate Intel';

IF NOT EXISTS (SELECT TOP 1 name FROM channels WHERE name=@chanName)
BEGIN
	PRINT N'INSERT INTO channels '+@chanName;
	INSERT INTO channels (name, password, topic, type) VALUES
	(@chanName, NULL, '', 1);
END
ELSE
BEGIN
	PRINT N'UPDATE channels '+@chanName;
	UPDATE channels SET
		password=NULL,
		topic='',
		type=1
	WHERE name=@chanName;
END

DECLARE @oppChar AS INT = (SELECT TOP 1 characterID FROM characters WHERE nick='[OPP] Announcer');
DECLARE @chanID AS INT = (SELECT TOP 1 id FROM channels WHERE name=@chanName);

DELETE FROM channelmembers WHERE channelid=@chanID AND memberid=@oppChar;
INSERT INTO channelmembers (channelid, memberid, role) VALUES
(@chanID, @oppChar, 2);

GO

USE perpetuumsa
GO

---- Create and fill technical character
DELETE FROM characters WHERE nick = 'Discord'

INSERT INTO characters (
	accountId,
	rootEID,
	nick,
	moodMessage,
	creation,
	lastLogOut,
	lastUsed,
	credit,
	inUse,
	totalMinsOnline,
	activeChassis,
	active,
	deletedAt,
	baseEID,
	defaultcorporationEID,
	majorID,
	raceID,
	schoolID,
	sparkID,
	lastdocked, docked, lastteleported, zoneID, nickcorrected, offensivenick, positionX, positionY, homeBaseEID, blockTrades, globalMute, avatar, note, corporationeid, allianceeid, [language], LastRespec) VALUES
(
	3156,
	8702057415139945528,
	'Discord',
	NULL,
	GETDATE(),
	NULL,
	NULL,
	0,
	0,
	0,
	8669878442849126445,
	1,
	NULL,
	142,
	499,
	5,
	1,
	2,
	5, NULL, 1, NULL, NULL, 0, 0, NULL, NULL, 961, 0, 0, NULL, 'OPP Discord Integration Character', 47423, NULL, 0, NULL)
	
GO

DECLARE @characterId INT

SET @characterId = (SELECT TOP 1 characterID FROM characters WHERE nick = 'Discord')

DELETE FROM corporationmembers WHERE corporationEID = 666 and memberid = @characterId

INSERT INTO corporationmembers (corporationEID, memberid, role) VALUES
(47423, @characterId, 4194303)

GO

USE perpetuumsa;
GO

---- Add DiscordId to channels
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
	DiscordId VARCHAR(128) NULL
GO
ALTER TABLE dbo.channels SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create Bug reports channel
DELETE FROM channels WHERE name = 'Bug reports'

INSERT INTO channels (name, password, topic, type, isForcedJoin, DiscordId) VALUES
('Bug reports', NULL, 'Bug reports channel - describe the bug experienced in the game right here', 1, NULL, NULL)

GO

---- Fill DiscordId for Help
UPDATE channels SET DiscordId = '361257957226446848' WHERE name = 'regchannel_help'
UPDATE channels SET DiscordId = '361257930688954378' WHERE name = 'General chat'
UPDATE channels SET DiscordId = '406330729912336387' WHERE name = 'Bug reports'

GO

USE perpetuumsa;
GO

---- Reduce Terramotus interference radius

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head_pr')

UPDATE aggregatevalues SET value = 35 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_terramotus_head')

UPDATE aggregatevalues SET value = 35 WHERE definition = @definition AND field = @field

GO

---- Fix mass harvesting charges production duration

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mass_harvesting_ammo')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryFlags, 0.001, 0.0015, 0.3)
END
ELSE
BEGIN
	UPDATE productiondecalibration SET distorsionmin = 0.001, distorsionmax = 0.0015, decrease = 0.3 WHERE categoryflag = @categoryFlags
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 0.2)
END
ELSE
BEGIN
	UPDATE productionduration SET durationmodifier = 0.2 WHERE category = @categoryFlags
END

GO

---- Halve reload time for Beholders and Spectators

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')

UPDATE aggregatevalues SET value = 5000 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis_pr')

UPDATE aggregatevalues SET value = 5000 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis')

UPDATE aggregatevalues SET value = 5000 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis_pr')

UPDATE aggregatevalues SET value = 5000 WHERE definition = @definition AND field = @field

GO

USE perpetuumsa;
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
('electroplant_hi.txt', @rulesetid, 'harvestable'),
('grass_a.txt', @rulesetid, 'decor'),
('grass_b.txt', @rulesetid, 'decor'),
('irontree_hi.txt', @rulesetid, 'harvestable'),
('nanowheat.txt', @rulesetid, 'decor'),
('pinetree.txt', @rulesetid, 'decor'),
('poffeteg.txt', @rulesetid, 'decor'),
('quag.txt', @rulesetid, 'decor'),
('rango.txt', @rulesetid, 'decor'),
('reed.txt', @rulesetid, 'decor'),
('rustbush_hi.txt', @rulesetid, 'harvestable'),
('slimeroot_hi.txt', @rulesetid, 'harvestable'),
('titanplant.txt', @rulesetid, 'decor'),
('wall.txt', @rulesetid, 'decor')

GO

USE perpetuumsa;
GO

---- Create and fill raw material prices table

-- Drop existing objects if they exist
IF OBJECT_ID('dbo.raw_material_prices', 'U') IS NOT NULL DROP TABLE raw_material_prices;
GO

CREATE TABLE raw_material_prices (
    material_name VARCHAR(100) PRIMARY KEY,
    price_nic DECIMAL(18, 2) NOT NULL
);
GO

-- Insert material prices
INSERT INTO raw_material_prices (material_name, price_nic) VALUES
('def_titan', 3.00),
('def_crude', 0.5),
('def_silgium', 4.00),
('def_liquizit', 1.00),
('def_epriton', 4.00),
('def_triandlus', 3.00),
('def_stermonit', 4.00),
('def_imentium', 4.00),
('def_helioptris', 4.00),
('def_prismocitae', 3.00),
('def_electroplant_fruit', 10),
('def_gammaterial', 250),
('def_fluxore', 150.00),
('def_robotshard_common_basic', 700.00),
('def_robotshard_common_advanced', 600.00),
('def_robotshard_common_expert', 5000.00),
('def_robotshard_nuimqol_basic', 700.00),
('def_robotshard_nuimqol_advanced', 600.00),
('def_robotshard_nuimqol_expert', 1300.00),
('def_robotshard_thelodica_basic', 700.00),
('def_robotshard_thelodica_advanced', 600.00),
('def_robotshard_thelodica_expert', 1300.00),
('def_robotshard_pelistal_basic', 700.00),
('def_robotshard_pelistal_advanced', 600.00),
('def_robotshard_pelistal_expert', 1300.00);
GO

---- Create view that shows all the production tree

-- Drop and create view
IF OBJECT_ID('dbo.production_data', 'V') IS NOT NULL DROP VIEW production_data;
GO

CREATE VIEW production_data AS
SELECT 
    ed.definitionname AS product,
    ced.definitionname AS components,
    c.componentamount AS amount
FROM components c
INNER JOIN entitydefaults ed ON c.definition = ed.definition
INNER JOIN entitydefaults ced ON c.componentdefinition = ced.definition
WHERE ed.purchasable = 1 AND ed.enabled = 1 AND ed.hidden = 0;-- AND (ed.tiertype IS NULL OR ed.tiertype = 1);-- AND ed.attributeflags & CONVERT(BIGINT, 2147483648) = 0;
GO

---- Create view that shows production cost assuming 50% efficiency of all the facilities

CREATE OR ALTER VIEW v_all_production_costs AS
WITH all_items AS (
    SELECT product AS item FROM production_data
    UNION
    SELECT components AS item FROM production_data
),
recursive_materials AS (
    SELECT 
        base.item,
        pd.components AS raw_material,
        CAST(pd.amount * 2.0 AS FLOAT) AS quantity
    FROM all_items base
    JOIN production_data pd ON pd.product = base.item

    UNION ALL

    SELECT
        rm.item,
        pd.components AS raw_material,
        rm.quantity * pd.amount * 2.0 AS quantity
    FROM recursive_materials rm
    JOIN production_data pd ON rm.raw_material = pd.product
),
aggregated_costs AS (
    SELECT
        rm.item AS product,
        rm.raw_material,
        SUM(rm.quantity) AS total_quantity
    FROM recursive_materials rm
    GROUP BY rm.item, rm.raw_material
),
computed_costs AS (
    SELECT
        ac.product,
        SUM(COALESCE(ac.total_quantity * rmp.price_nic, 0)) AS production_cost_nic
    FROM aggregated_costs ac
    LEFT JOIN raw_material_prices rmp ON ac.raw_material = rmp.material_name
    GROUP BY ac.product
),
raw_resources AS (
    SELECT 
        material_name AS product,
        price_nic AS production_cost_nic
    FROM raw_material_prices
    WHERE NOT EXISTS (
        SELECT 1 FROM production_data WHERE product = material_name
    )
),
final_costs AS (
    SELECT * FROM computed_costs
    UNION
    SELECT * FROM raw_resources
)
SELECT 
    product,
    ROUND(production_cost_nic, 2) AS production_cost_nic
FROM final_costs;

GO

---- Create and fill market orders condifuration that will be used to renew sell orders

IF OBJECT_ID('dbo.market_orders_configuration', 'U') IS NOT NULL DROP TABLE market_orders_configuration;
GO

CREATE TABLE market_orders_configuration (
    definitionname VARCHAR(100) NOT NULL,
    amount INT NOT NULL
);
GO

-- Insert items and amount
INSERT INTO market_orders_configuration (definitionname, amount) VALUES
('def_kain_bot', 5),
('def_artemis_bot', 5),
('def_tyrannos_bot', 5),
('def_echelon_bot', 5),
('def_named3_medium_laser', 20),
('def_named3_medium_autocannon', 20),
('def_named3_missile_launcher', 20),
('def_named3_medium_railgun', 20),
('def_named3_longrange_medium_railgun', 20),
('def_named3_longrange_medium_laser', 20),
('def_named3_longrange_medium_autocannon', 20)

GO

---- Create view that shows required raw materials

-- Drop existing view if it exists
IF OBJECT_ID('dbo.v_required_raw_materials', 'V') IS NOT NULL
    DROP VIEW dbo.v_required_raw_materials;
GO

-- Create the view
CREATE VIEW dbo.v_required_raw_materials AS
WITH RecursiveBreakdown AS (
    -- Base case: direct components
    SELECT 
        moc.definitionname AS product,
        pd.components AS component,
        pd.amount * moc.amount * 2 AS total_amount  -- 50% efficiency adjustment
    FROM dbo.market_orders_configuration moc
    JOIN dbo.production_data pd ON moc.definitionname = pd.product

    UNION ALL

    -- Recursive case: break down intermediate components
    SELECT 
        rb.product,
        pd.components AS component,
        rb.total_amount * pd.amount * 2 AS total_amount
    FROM RecursiveBreakdown rb
    JOIN dbo.production_data pd ON rb.component = pd.product
)

-- Final aggregation: only raw materials (not further craftable)
SELECT 
    rb.component AS raw_material,
    SUM(rb.total_amount) AS total_quantity
FROM RecursiveBreakdown rb
LEFT JOIN dbo.production_data pd ON rb.component = pd.product
WHERE pd.product IS NULL
GROUP BY rb.component;

GO

---- Add isAutoOrder into marketitems

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
ALTER TABLE dbo.marketitems ADD
	isAutoOrder bit NULL
GO
ALTER TABLE dbo.marketitems SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create stored procedure that will refresh autoorders

CREATE OR ALTER PROCEDURE usp_RefreshAutoMarketOrders
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 2: Fetch market and vendor EIDs
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;

        SELECT @marketeid = eid 
        FROM entities 
        WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

        SELECT @vendoreid = vendorEID 
        FROM dbo.vendors 
        WHERE marketEID = @marketeid;

        -- Step 3: Insert new auto-orders
        INSERT INTO marketitems (marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder)
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,     -- Note: double-check if this should be used as duration or another field
            0 AS isSell,
            1 AS duration,   -- ← You may want to fix this mapping: @vendoreid seems misplaced
            pc.production_cost_nic,
            moc.amount,
            1 AS isvendoritem,
            1 AS isAutoorder
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product;

		-- Final selection: only include components that are not themselves products (i.e., raw materials)
		INSERT INTO marketitems (marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoOrder)
			SELECT @marketeid, ed.definition, @vendoreid,  0, 0, apc.production_cost_nic, total_quantity, 1, 1 FROM v_required_raw_materials rrm
			INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
			INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product

    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO

USE perpetuumsa;
GO

---- Add or update items and amounts

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_named3_medium_armor_plate', 40),
('def_named3_medium_armor_repairer', 20),
('def_named3_thrm_armor_hardener', 30),
('def_named3_chm_armor_hardener', 30),
('def_named3_kin_armor_hardener', 30),
('def_named3_exp_armor_hardener', 30),
('def_named3_medium_shield_generator', 15),
('def_named3_shield_hardener', 30),
('def_named3_core_recharger', 30),
('def_named3_sensor_booster', 40),
('def_named3_eccm', 40),
('def_named3_medium_driller', 20),
('def_named3_mining_upgrade', 30),
('def_named3_powergrid_upgrades', 30),
('def_named3_cpu_upgrade', 30),
('def_named3_mining_probe_module', 5),
('def_named3_medium_harvester', 20),
('def_named3_medium_core_battery', 30),
('def_named3_medium_core_booster', 20),
('def_named3_damage_mod_railgun', 10),
('def_named3_damage_mod_missile', 10),
('def_named3_damage_mod_laser', 10),
('def_named3_damage_mod_projectile', 10),
('def_named3_tracking_upgrade', 40),
('def_named3_resistant_plating', 20),
('def_named3_mass_reductor', 40),
('def_named3_maneuvering_upgrade', 10),
('def_named3_detection_modul', 20),
('def_named3_stealth_modul', 30),
('def_named3_kinetic_kers', 20),
('def_named3_thermal_kers', 20),
('def_named3_explosive_kers', 20),
('def_named3_weapon_stabilizer', 40),
('def_named3_ew_resist', 40),
('def_named3_adaptive_alloy', 20),
('def_termis_bot', 5),
('def_gargoyle_bot', 5)

MERGE market_orders_configuration AS Target
USING (SELECT definitionname, amount FROM @tempTable) AS Source
ON (Target.definitionname = Source.definitionname)
WHEN MATCHED THEN
    UPDATE SET 
		Target.amount = Source.amount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definitionname, amount)
    VALUES (Source.definitionname, Source.amount);

GO

USE perpetuumsa;
GO

---- Create statistics table for plasma

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
CREATE TABLE dbo.plasma_gathered
	(
	gathered_on date NOT NULL,
	plasma_type varchar(100) NOT NULL,
	quantity BIGINT NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.plasma_gathered SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create statistics table for resources

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
CREATE TABLE dbo.resources_gathered
	(
	gathered_on date NOT NULL,
	resource_name varchar(100) NOT NULL,
	quantity BIGINT NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.resources_gathered SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create table for auto prices

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
CREATE TABLE dbo.resource_market_prices
	(
	calculated_on date NOT NULL,
	resource_name varchar(100) NOT NULL,
	unit_price decimal(18, 2) NOT NULL
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.resource_market_prices SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create sp to register plasma statistics

CREATE PROCEDURE sp_RecordPlasmaGathered
    @gathered_on DATE,
    @plasma_type VARCHAR(50),
    @quantity BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE plasma_gathered AS target
    USING (SELECT @gathered_on AS gathered_on, @plasma_type AS plasma_type) AS source
    ON target.gathered_on = source.gathered_on AND target.plasma_type = source.plasma_type
    WHEN MATCHED THEN
        UPDATE SET quantity = quantity + @quantity
    WHEN NOT MATCHED THEN
        INSERT (gathered_on, plasma_type, quantity)
        VALUES (@gathered_on, @plasma_type, @quantity);
END;

GO

---- Create sp to register resources statistics

CREATE PROCEDURE sp_RecordResourceGathered
    @gathered_on DATE,
    @resource_name VARCHAR(100),
    @quantity BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE resources_gathered AS target
    USING (SELECT @gathered_on AS gathered_on, @resource_name AS resource_name) AS source
    ON target.gathered_on = source.gathered_on AND target.resource_name = source.resource_name
    WHEN MATCHED THEN
        UPDATE SET quantity = quantity + @quantity
    WHEN NOT MATCHED THEN
        INSERT (gathered_on, resource_name, quantity)
        VALUES (@gathered_on, @resource_name, @quantity);
END;

GO

---- Create sp to recalculate resource prices

CREATE OR ALTER PROCEDURE recalculate_raw_material_prices
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATE = CAST(GETDATE() AS DATE);
    DECLARE @week_start DATE = DATEADD(DAY, -DATEPART(WEEKDAY, @today) + 2, @today); -- Monday
    DECLARE @startDate DATE = DATEADD(DAY, -7, @today);

    -- Total NIC value from plasma gathered
    DECLARE @total_plasma_nic DECIMAL(18,2);
    SELECT @total_plasma_nic = 
        ISNULL(SUM(CASE 
            WHEN plasma_type COLLATE DATABASE_DEFAULT = 'def_common_reactor_plasma' THEN quantity * 242
            WHEN plasma_type COLLATE DATABASE_DEFAULT IN (
                'def_pelistal_reactor_plasma',
                'def_thelodica_reactor_plasma',
                'def_nuimqol_reactor_plasma'
            ) THEN quantity * 330
            ELSE 0 END), 0)
    FROM plasma_gathered
    WHERE gathered_on >= @startDate;

    -- Total resources gathered
    DECLARE @total_resources BIGINT;
    SELECT @total_resources = SUM(quantity)
    FROM resources_gathered
    WHERE gathered_on >= @startDate;

    -- Step 1: Compute new prices
    IF OBJECT_ID('tempdb..#new_prices') IS NOT NULL DROP TABLE #new_prices;
    CREATE TABLE #new_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        new_price_nic DECIMAL(18,2)
    );

    INSERT INTO #new_prices(resource_name, new_price_nic)
    SELECT 
        rg.resource_name COLLATE DATABASE_DEFAULT,
        ROUND(
            CASE 
                WHEN @total_resources = 0 THEN 0
                ELSE (@total_plasma_nic * 1.0 * SUM(rg.quantity) / @total_resources)
            END, 2
        )
    FROM resources_gathered rg
    WHERE gathered_on >= @startDate
    GROUP BY rg.resource_name;

    -- Step 2: Get fallback base prices
    IF OBJECT_ID('tempdb..#fallback_prices') IS NOT NULL DROP TABLE #fallback_prices;
    CREATE TABLE #fallback_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #fallback_prices(resource_name, unit_price)
    SELECT 
        rmp.material_name COLLATE DATABASE_DEFAULT,
        rmp.price_nic
    FROM raw_material_prices rmp
    WHERE NOT EXISTS (
        SELECT 1 FROM #new_prices np
        WHERE np.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT
    );

    -- Step 3: Combine new and fallback prices
    IF OBJECT_ID('tempdb..#merged_prices') IS NOT NULL DROP TABLE #merged_prices;
    CREATE TABLE #merged_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #merged_prices(resource_name, unit_price)
    SELECT resource_name, new_price_nic FROM #new_prices
    UNION ALL
    SELECT resource_name, unit_price FROM #fallback_prices;

    -- Step 4: Clamp against raw_material_prices base values
    IF OBJECT_ID('tempdb..#clamped_prices') IS NOT NULL DROP TABLE #clamped_prices;
    CREATE TABLE #clamped_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #clamped_prices(resource_name, unit_price)
    SELECT 
        mp.resource_name,
        CASE 
            WHEN mp.unit_price > rmp.price_nic * 2 THEN rmp.price_nic * 2
            WHEN mp.unit_price < rmp.price_nic * 0.5 THEN rmp.price_nic * 0.5
            ELSE mp.unit_price
        END
    FROM #merged_prices mp
    JOIN raw_material_prices rmp
        ON mp.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT;

    -- Step 5: Upsert to resource_market_prices
    MERGE INTO dbo.resource_market_prices AS target
    USING (
        SELECT resource_name, unit_price FROM #clamped_prices
    ) AS source
    ON target.calculated_on = @week_start
       AND target.resource_name COLLATE DATABASE_DEFAULT = source.resource_name COLLATE DATABASE_DEFAULT
    WHEN MATCHED THEN
        UPDATE SET unit_price = source.unit_price
    WHEN NOT MATCHED THEN
        INSERT (calculated_on, resource_name, unit_price)
        VALUES (@week_start, source.resource_name, source.unit_price);

    -- Step 6: Optional cleanup of old stats
    DELETE FROM plasma_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
    DELETE FROM resources_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
END;
GO

---- Alter calculation core to give more space for crafters by taking prototyping into account

---- Create view that shows production cost assuming 50% efficiency of all the facilities

CREATE OR ALTER VIEW v_all_production_costs AS
WITH all_items AS (
    SELECT product AS item FROM production_data
    UNION
    SELECT components AS item FROM production_data
),
recursive_materials AS (
    SELECT 
        base.item,
        pd.components AS raw_material,
        CAST(pd.amount * 2.1 AS FLOAT) AS quantity
    FROM all_items base
    JOIN production_data pd ON pd.product = base.item

    UNION ALL

    SELECT
        rm.item,
        pd.components AS raw_material,
        rm.quantity * pd.amount * 2.1 AS quantity
    FROM recursive_materials rm
    JOIN production_data pd ON rm.raw_material = pd.product
),
aggregated_costs AS (
    SELECT
        rm.item AS product,
        rm.raw_material,
        SUM(rm.quantity) AS total_quantity
    FROM recursive_materials rm
    GROUP BY rm.item, rm.raw_material
),
computed_costs AS (
    SELECT
        ac.product,
        SUM(
            ac.total_quantity * 
            COALESCE(
                rmp.unit_price,               -- preferred: current market price
                base.price_nic,               -- fallback: base price
                0
            )
        ) AS production_cost_nic
    FROM aggregated_costs ac
    LEFT JOIN (
        SELECT resource_name, unit_price
        FROM resource_market_prices
        WHERE calculated_on = (
            SELECT MAX(calculated_on) FROM resource_market_prices
        )
    ) rmp ON ac.raw_material COLLATE DATABASE_DEFAULT = rmp.resource_name COLLATE DATABASE_DEFAULT
    LEFT JOIN raw_material_prices base ON ac.raw_material COLLATE DATABASE_DEFAULT = base.material_name COLLATE DATABASE_DEFAULT
    GROUP BY ac.product
),
raw_resources AS (
    SELECT 
        rmp.material_name AS product,
        COALESCE(
            m.unit_price,
            rmp.price_nic
        ) AS production_cost_nic
    FROM raw_material_prices rmp
    LEFT JOIN (
        SELECT resource_name, unit_price
        FROM resource_market_prices
        WHERE calculated_on = (SELECT MAX(calculated_on) FROM resource_market_prices)
    ) m ON rmp.material_name COLLATE DATABASE_DEFAULT = m.resource_name COLLATE DATABASE_DEFAULT
    WHERE NOT EXISTS (
        SELECT 1 FROM production_data WHERE product = rmp.material_name
    )
),
final_costs AS (
    SELECT * FROM computed_costs
    UNION
    SELECT * FROM raw_resources
)
SELECT 
    product,
    ROUND(production_cost_nic, 2) AS production_cost_nic
FROM final_costs;

GO

-- Drop existing view if it exists
IF OBJECT_ID('dbo.v_required_raw_materials', 'V') IS NOT NULL
    DROP VIEW dbo.v_required_raw_materials;
GO

-- Create the view
CREATE VIEW dbo.v_required_raw_materials AS
WITH RecursiveBreakdown AS (
    -- Base case: direct components
    SELECT 
        moc.definitionname AS product,
        pd.components AS component,
        pd.amount * CAST(ROUND(moc.amount * 2.1, 0) AS INT) AS total_amount  -- 50% efficiency adjustment
    FROM dbo.market_orders_configuration moc
    JOIN dbo.production_data pd ON moc.definitionname = pd.product

    UNION ALL

    -- Recursive case: break down intermediate components
    SELECT 
        rb.product,
        pd.components AS component,
        rb.total_amount * CAST(ROUND(pd.amount * 2.1, 0) AS INT) AS total_amount
    FROM RecursiveBreakdown rb
    JOIN dbo.production_data pd ON rb.component = pd.product
)

-- Final aggregation: only raw materials (not further craftable)
SELECT 
    rb.component AS raw_material,
    SUM(rb.total_amount) AS total_quantity
FROM RecursiveBreakdown rb
LEFT JOIN dbo.production_data pd ON rb.component = pd.product
WHERE pd.product IS NULL
GROUP BY rb.component;

GO

---- Use both based and calculated values

CREATE OR ALTER VIEW v_all_production_costs AS
WITH all_items AS (
    SELECT product AS item FROM production_data
    UNION
    SELECT components AS item FROM production_data
),
recursive_materials AS (
    SELECT 
        base.item,
        pd.components AS raw_material,
        CAST(pd.amount * 2.1 AS FLOAT) AS quantity
    FROM all_items base
    JOIN production_data pd ON pd.product = base.item

    UNION ALL

    SELECT
        rm.item,
        pd.components AS raw_material,
        rm.quantity * pd.amount * 2.1 AS quantity
    FROM recursive_materials rm
    JOIN production_data pd ON rm.raw_material = pd.product
),
aggregated_costs AS (
    SELECT
        rm.item AS product,
        rm.raw_material,
        SUM(rm.quantity) AS total_quantity
    FROM recursive_materials rm
    GROUP BY rm.item, rm.raw_material
),
latest_market_prices AS (
    SELECT rmp.resource_name, rmp.unit_price
    FROM resource_market_prices rmp
    WHERE rmp.calculated_on = (SELECT MAX(calculated_on) FROM resource_market_prices)
),
computed_costs AS (
    SELECT
        ac.product,
        SUM(
            ac.total_quantity * 
            ISNULL(mp.unit_price, base.price_nic)
        ) AS production_cost_nic
    FROM aggregated_costs ac
    LEFT JOIN latest_market_prices mp 
        ON ac.raw_material COLLATE DATABASE_DEFAULT = mp.resource_name COLLATE DATABASE_DEFAULT
    LEFT JOIN raw_material_prices base 
        ON ac.raw_material COLLATE DATABASE_DEFAULT = base.material_name COLLATE DATABASE_DEFAULT
    GROUP BY ac.product
),
raw_resources AS (
    SELECT 
        rmp.material_name AS product,
        ISNULL(mp.unit_price, rmp.price_nic) AS production_cost_nic
    FROM raw_material_prices rmp
    LEFT JOIN latest_market_prices mp 
        ON rmp.material_name COLLATE DATABASE_DEFAULT = mp.resource_name COLLATE DATABASE_DEFAULT
    WHERE NOT EXISTS (
        SELECT 1 FROM production_data pd WHERE pd.product = rmp.material_name
    )
),
final_costs AS (
    SELECT * FROM computed_costs
    UNION
    SELECT * FROM raw_resources
)
SELECT 
    product,
    ROUND(production_cost_nic, 2) AS production_cost_nic
FROM final_costs;

GO

USE perpetuumsa;
GO

---- Add or update items and amounts

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_named3_medium_shield_generator', 35),
('def_named3_shield_hardener', 50),
('def_named3_core_recharger', 50),
('def_named3_sensor_booster', 80),
('def_named3_eccm', 50),
('def_named3_medium_core_battery', 50),
('def_named3_medium_core_booster', 40),
('def_named3_tracking_upgrade', 50),
('def_named3_mass_reductor', 60),
('def_named3_medium_energy_vampire', 40),
('def_named3_medium_energy_neutralizer', 40),
('def_named3_sensor_jammer', 30),
('def_named3_sensor_dampener', 30),
('def_named3_blob_emission_modulator', 20),
('def_named3_target_painter', 20),
('def_named3_longrange_webber', 40),
('def_named3_webber', 40),
('def_named3_reactor_sealing', 40),
('def_named3_energy_warfare_upgrade', 40),
('def_named3_ecm_booster', 40),
('def_named3_sensor_supressor_booster', 40),
('def_named3_landmine_detector', 40),
('def_vagabond_bot', 5),
('def_ictus_bot', 5),
('def_callisto_bot', 5),
('def_zenith_bot', 5)

MERGE market_orders_configuration AS Target
USING (SELECT definitionname, amount FROM @tempTable) AS Source
ON (Target.definitionname = Source.definitionname)
WHEN MATCHED THEN
    UPDATE SET 
		Target.amount = Source.amount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definitionname, amount)
    VALUES (Source.definitionname, Source.amount);

GO

USE [perpetuumsa]
GO

---- Fix v_required_raw_materials

/****** Object:  View [dbo].[v_required_raw_materials]    Script Date: 04.07.2025 18:57:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Create the view
CREATE OR ALTER VIEW [dbo].[v_required_raw_materials] AS
WITH RecursiveBreakdown AS (
    -- Base case: direct components
    SELECT 
        moc.definitionname AS product,
        pd.components AS component,
        pd.amount * CAST(ROUND(moc.amount * 2.1, 0) AS BIGINT) AS total_amount  -- 50% efficiency adjustment
    FROM dbo.market_orders_configuration moc
    JOIN dbo.production_data pd ON moc.definitionname = pd.product

    UNION ALL

    -- Recursive case: break down intermediate components
    SELECT 
        rb.product,
        pd.components AS component,
        rb.total_amount * CAST(ROUND(pd.amount * 2.1, 0) AS BIGINT) AS total_amount
    FROM RecursiveBreakdown rb
    JOIN dbo.production_data pd ON rb.component = pd.product
)

-- Final aggregation: only raw materials (not further craftable)
SELECT 
    rb.component AS raw_material,
    SUM(rb.total_amount) AS total_quantity
FROM RecursiveBreakdown rb
LEFT JOIN dbo.production_data pd ON rb.component = pd.product
WHERE pd.product IS NULL
GROUP BY rb.component;

GO




---- Fix usp_RefreshAutoMarketOrders

CREATE OR ALTER PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 2: Fetch market and vendor EIDs
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;

        SELECT @marketeid = eid 
        FROM entities 
        WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

        SELECT @vendoreid = vendorEID 
        FROM dbo.vendors 
        WHERE marketEID = @marketeid;

        -- Step 3: Insert product auto-orders (static config)
        INSERT INTO marketitems (
            marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
        )
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,
            0,
            1,
            pc.production_cost_nic,
            moc.amount,
            1,
            1
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product;

        -- Step 4: Insert raw material buy orders, split if quantity too large
        DECLARE @batch INT = 500000000;

        -- Use a cursor to handle splitting quantities
        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            rrm.total_quantity AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        DECLARE @itemdefinition INT;
        DECLARE @unit_price FLOAT;
        DECLARE @quantity BIGINT;
        DECLARE @remaining BIGINT;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
        PRINT(@quantity);
            SET @remaining = @quantity;

            WHILE @remaining > 0
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;

    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO

USE perpetuumsa;
GO

---- Create statistics table for plasma sold

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
CREATE TABLE dbo.plasma_sold
	(
	sold_on date NOT NULL,
	plasma_type varchar(100) NOT NULL,
	quantity BIGINT NOT NULL,
    income FLOAT
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.plasma_sold SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create sp to register plasma sold statistics

CREATE PROCEDURE sp_RecordPlasmaSold
    @sold_on DATE,
    @plasma_type VARCHAR(50),
    @quantity BIGINT,
    @income FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE plasma_sold AS target
    USING (SELECT @sold_on AS sold_on, @plasma_type AS plasma_type) AS source
    ON target.sold_on = source.sold_on AND target.plasma_type = source.plasma_type
    WHEN MATCHED THEN
        UPDATE SET quantity = quantity + @quantity, income = income + @income
    WHEN NOT MATCHED THEN
        INSERT (sold_on, plasma_type, quantity, income)
        VALUES (@sold_on, @plasma_type, @quantity, @income);
END;

GO

---- Create table function to calculate dynamic prices for a given island type

CREATE OR ALTER FUNCTION dbo.fn_CalculateDynamicPlasmaPrices (@island_type INT)
RETURNS TABLE
AS
RETURN
(
    WITH parameters AS (
        SELECT 
            MIN_PRICE = 
                CASE @island_type 
                    WHEN 1 THEN 25 
                    WHEN 2 THEN 125 
                    WHEN 3 THEN 200 
                    ELSE 0 
                END,
            MAX_PRICE = 
                CASE @island_type 
                    WHEN 1 THEN 150 
                    WHEN 2 THEN 250 
                    WHEN 3 THEN 275 
                    ELSE 0 
                END
    ),
    weights AS (
        SELECT * FROM (VALUES
            ('def_common_reactor_plasma', 1.0),
            ('def_thelodica_reactor_plasma', 1.35),
            ('def_pelistal_reactor_plasma', 1.35),
            ('def_nuimqol_reactor_plasma', 1.35)
        ) AS w(plasma_type, weight)
    ),
    gathered_cte AS (
        SELECT plasma_type, SUM(quantity) AS gathered
        FROM plasma_gathered
        WHERE gathered_on >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
        GROUP BY plasma_type
    ),
    sold_cte AS (
        SELECT plasma_type, SUM(quantity) AS sold
        FROM plasma_sold
        WHERE sold_on >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
        GROUP BY plasma_type
    )
    SELECT 
        w.plasma_type,
        g.gathered,
        s.sold,
        w.weight,
        CAST(
            (
                CASE 
                    WHEN ISNULL(g.gathered, 0) = 0 THEN p.MAX_PRICE
                    ELSE
                        p.MIN_PRICE + (p.MAX_PRICE - p.MIN_PRICE) * 
                        (
                            CASE 
                                WHEN CAST(ISNULL(s.sold, 0) AS FLOAT) / NULLIF(g.gathered, 1) > 1 THEN 0
                                ELSE 1.0 - (CAST(ISNULL(s.sold, 0) AS FLOAT) / NULLIF(g.gathered, 1))
                            END
                        )
                END
            ) * w.weight AS DECIMAL(10, 2)
        ) AS dynamic_price
    FROM weights w
    CROSS JOIN parameters p
    LEFT JOIN gathered_cte g ON g.plasma_type = w.plasma_type
    LEFT JOIN sold_cte s ON s.plasma_type = w.plasma_type
);

GO

---- Change auto orders placement so that it places plasma buy orders across all the islands

CREATE OR ALTER PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @batch INT = 500000000;
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;
        DECLARE @itemdefinition INT;
        DECLARE @unit_price FLOAT;
        DECLARE @quantity BIGINT;
        DECLARE @remaining BIGINT;

        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 1.1: Place plasma buy orders on alphas:

        DECLARE alpha_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 1
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(1) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN alpha_cursor;

        FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE alpha_cursor;
        DEALLOCATE alpha_cursor;

        -- Step 1.2: Place plasma buy orders on betas:

        DECLARE beta_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 0
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(2) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN beta_cursor;

        FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE beta_cursor;
        DEALLOCATE beta_cursor;

        -- Step 1.3: Place plasma buy orders on gammas:

        DECLARE gamma_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT eid FROM dbo.getLiveGammaDockingBases()
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(3) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN gamma_cursor;

        FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE gamma_cursor;
        DEALLOCATE gamma_cursor;

        -- Step 2: Fetch market and vendor EIDs
        
        SELECT @marketeid = eid 
        FROM entities 
        WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

        SELECT @vendoreid = vendorEID 
        FROM dbo.vendors 
        WHERE marketEID = @marketeid;

        -- Step 3: Insert product auto-orders (static config)
        INSERT INTO marketitems (
            marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
        )
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,
            0,
            1,
            pc.production_cost_nic,
            moc.amount,
            1,
            1
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product;

        -- Step 4: Insert raw material buy orders, split if quantity too large

        -- Use a cursor to handle splitting quantities
        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            rrm.total_quantity AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END
			
            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;

    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

---- Change raw resources price calculation to use dynamic plasma prices. Also set restrains to 50%-300%

CREATE OR ALTER   PROCEDURE [dbo].[recalculate_raw_material_prices]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATE = CAST(GETDATE() AS DATE);
    DECLARE @week_start DATE = DATEADD(DAY, -DATEPART(WEEKDAY, @today) + 2, @today); -- Monday
    DECLARE @startDate DATE = DATEADD(DAY, -7, @today);

    -- Total NIC value from plasma gathered
    DECLARE @total_plasma_nic DECIMAL(18,2);

    --
    DECLARE @avg_common_price DECIMAL(18, 2);
    DECLARE @avg_racial_price DECIMAL(18, 2);

    WITH combined_prices AS (
        SELECT 1 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(1)
        UNION ALL
        SELECT 2 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(2)
        UNION ALL
        SELECT 3 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(3)
    )
    SELECT
        @avg_common_price = AVG(CASE WHEN plasma_type = 'def_common_reactor_plasma' THEN dynamic_price END),
        @avg_racial_price = AVG(CASE 
            WHEN plasma_type IN (
                'def_thelodica_reactor_plasma', 
                'def_pelistal_reactor_plasma', 
                'def_nuimqol_reactor_plasma') 
            THEN dynamic_price END)
    FROM combined_prices;
    --


    SELECT @total_plasma_nic = 
        ISNULL(SUM(CASE 
            WHEN plasma_type COLLATE DATABASE_DEFAULT = 'def_common_reactor_plasma' THEN quantity * @avg_common_price
            WHEN plasma_type COLLATE DATABASE_DEFAULT IN (
                'def_pelistal_reactor_plasma',
                'def_thelodica_reactor_plasma',
                'def_nuimqol_reactor_plasma'
            ) THEN quantity * @avg_racial_price
            ELSE 0 END), 0)
    FROM plasma_gathered
    WHERE gathered_on >= @startDate;

    -- Total resources gathered
    DECLARE @total_resources BIGINT;
    SELECT @total_resources = SUM(quantity)
    FROM resources_gathered
    WHERE gathered_on >= @startDate;

    -- Step 1: Compute new prices
    IF OBJECT_ID('tempdb..#new_prices') IS NOT NULL DROP TABLE #new_prices;
    CREATE TABLE #new_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        new_price_nic DECIMAL(18,2)
    );

    INSERT INTO #new_prices(resource_name, new_price_nic)
    SELECT 
        rg.resource_name COLLATE DATABASE_DEFAULT,
        ROUND(
            CASE 
                WHEN @total_resources = 0 THEN 0
                ELSE (@total_plasma_nic * 1.0 * SUM(rg.quantity) / @total_resources)
            END, 2
        )
    FROM resources_gathered rg
    WHERE gathered_on >= @startDate
    GROUP BY rg.resource_name;

    -- Step 2: Get fallback base prices
    IF OBJECT_ID('tempdb..#fallback_prices') IS NOT NULL DROP TABLE #fallback_prices;
    CREATE TABLE #fallback_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #fallback_prices(resource_name, unit_price)
    SELECT 
        rmp.material_name COLLATE DATABASE_DEFAULT,
        rmp.price_nic
    FROM raw_material_prices rmp
    WHERE NOT EXISTS (
        SELECT 1 FROM #new_prices np
        WHERE np.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT
    );

    -- Step 3: Combine new and fallback prices
    IF OBJECT_ID('tempdb..#merged_prices') IS NOT NULL DROP TABLE #merged_prices;
    CREATE TABLE #merged_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #merged_prices(resource_name, unit_price)
    SELECT resource_name, new_price_nic FROM #new_prices
    UNION ALL
    SELECT resource_name, unit_price FROM #fallback_prices;

    -- Step 4: Clamp against raw_material_prices base values
    IF OBJECT_ID('tempdb..#clamped_prices') IS NOT NULL DROP TABLE #clamped_prices;
    CREATE TABLE #clamped_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #clamped_prices(resource_name, unit_price)
    SELECT 
        mp.resource_name,
        CASE 
            WHEN mp.unit_price > rmp.price_nic * 3 THEN rmp.price_nic * 3
            WHEN mp.unit_price < rmp.price_nic * 0.5 THEN rmp.price_nic * 0.5
            ELSE mp.unit_price
        END
    FROM #merged_prices mp
    JOIN raw_material_prices rmp
        ON mp.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT;

    -- Step 5: Upsert to resource_market_prices
    MERGE INTO dbo.resource_market_prices AS target
    USING (
        SELECT resource_name, unit_price FROM #clamped_prices
    ) AS source
    ON target.calculated_on = @week_start
       AND target.resource_name COLLATE DATABASE_DEFAULT = source.resource_name COLLATE DATABASE_DEFAULT
    WHEN MATCHED THEN
        UPDATE SET unit_price = source.unit_price
    WHEN NOT MATCHED THEN
        INSERT (calculated_on, resource_name, unit_price)
        VALUES (@week_start, source.resource_name, source.unit_price);

    -- Step 6: Optional cleanup of old stats
    DELETE FROM plasma_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
    DELETE FROM plasma_sold WHERE sold_on < DATEADD(DAY, -90, @today);
    DELETE FROM resources_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
END;
GO

---- Delete unlimited plasma buy orders

DELETE FROM marketitems WHERE isvendoritem = 1 AND itemdefinition IN (
    3271,
    3272,
    3273,
    3274
)
GO

USE perpetuumsa;
GO

---- Add or update items and amounts

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_riveler_bot', 3),
('def_symbiont_bot', 3),
('def_kain_mk2_bot', 1),
('def_tyrannos_mk2_bot', 1),
('def_artemis_mk2_bot', 1)

MERGE market_orders_configuration AS Target
USING (SELECT definitionname, amount FROM @tempTable) AS Source
ON (Target.definitionname = Source.definitionname)
WHEN MATCHED THEN
    UPDATE SET 
		Target.amount = Source.amount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definitionname, amount)
    VALUES (Source.definitionname, Source.amount);

GO
