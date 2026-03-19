
USE perpetuumsa;
GO

---- Add or update items and amounts

DELETE FROM market_orders_configuration WHERE definitionname in ('def_kain_mk2_bot','def_tyrannos_mk2_bot','def_artemis_mk2_bot')

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_named3_medium_laser', 12),
('def_named3_medium_autocannon', 12),
('def_named3_missile_launcher', 12),
('def_named3_medium_railgun', 12),
('def_named3_longrange_medium_railgun', 12),
('def_named3_longrange_medium_laser', 12),
('def_named3_longrange_medium_autocannon', 12),
('def_named3_medium_armor_plate', 20),
('def_named3_medium_armor_repairer', 10),
('def_named3_thrm_armor_hardener', 10),
('def_named3_chm_armor_hardener', 10),
('def_named3_kin_armor_hardener', 10),
('def_named3_exp_armor_hardener', 10),
('def_named3_medium_shield_generator', 10),
('def_named3_shield_hardener', 20),
('def_named3_core_recharger', 20),
('def_named3_sensor_booster', 20),
('def_named3_eccm', 15),
('def_named3_medium_driller', 10),
('def_named3_mining_upgrade', 10),
('def_named3_powergrid_upgrades', 10),
('def_named3_cpu_upgrade', 10),
('def_named3_medium_harvester', 10),
('def_named3_medium_core_battery', 10),
('def_named3_medium_core_booster', 10),
('def_named3_tracking_upgrade', 10),
('def_named3_resistant_plating', 10),
('def_named3_mass_reductor', 10),
('def_named3_detection_modul', 10),
('def_named3_stealth_modul', 10),
('def_named3_kinetic_kers', 5),
('def_named3_thermal_kers', 5),
('def_named3_explosive_kers', 5),
('def_named3_weapon_stabilizer', 10),
('def_named3_ew_resist', 10),
('def_named3_adaptive_alloy', 10),
('def_named3_medium_energy_vampire', 10),
('def_named3_medium_energy_neutralizer', 10),
('def_named3_sensor_jammer', 10),
('def_named3_sensor_dampener', 10),
('def_named3_blob_emission_modulator', 10),
('def_named3_target_painter', 5),
('def_named3_longrange_webber', 10),
('def_named3_webber', 10),
('def_named3_reactor_sealing', 10),
('def_named3_energy_warfare_upgrade', 10),
('def_named3_ecm_booster', 10),
('def_named3_sensor_supressor_booster', 10),
('def_named3_landmine_detector', 10),
('def_beholder_bot', 3),
('def_terramotus_bot', 3),
('def_standard_tactical_remote_controller', 5),
('def_standard_remote_command_translator', 5),
('def_standard_large_driller', 3),
('def_standard_large_harvester', 3),
('def_standard_large_armor_plate', 5),
('def_standard_large_armor_repairer', 5),
('def_syndicate_attack_drone_unit', 10)

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
