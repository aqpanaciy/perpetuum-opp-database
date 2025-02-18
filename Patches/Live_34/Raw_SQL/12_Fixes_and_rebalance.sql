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