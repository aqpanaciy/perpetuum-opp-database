
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
