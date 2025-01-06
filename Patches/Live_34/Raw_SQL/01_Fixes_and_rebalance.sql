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