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