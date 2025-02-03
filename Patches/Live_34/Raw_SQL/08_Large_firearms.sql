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