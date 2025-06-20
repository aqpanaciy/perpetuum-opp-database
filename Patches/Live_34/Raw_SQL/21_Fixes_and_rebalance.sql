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