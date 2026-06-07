DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_argano_main_support_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_locust_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM definitionconfig WHERE definition = @definition)
BEGIN
	INSERT INTO definitionconfig (definition, tint) VALUES (@definition, '#1a2315')
END

GO