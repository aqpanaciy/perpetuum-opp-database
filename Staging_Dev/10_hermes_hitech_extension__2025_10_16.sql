USE [perpetuumsa]
GO

--------------------------------------
-- ENABLE HIGH TECH EXT. INFO
--         FOR HERMES 
--
-- Date Modified:
-- 2025/10/16	- Initial release
--------------------------------------

DECLARE @def_hermes INT;
DECLARE @id_ext_hitech INT;
DECLARE @level_min INT = 1;

SET @def_hermes = (SELECT TOP (1) [definition] FROM [entitydefaults] WHERE [definitionname] = 'def_hermes_bot');
SET @id_ext_hitech = (SELECT TOP (1) [extensionid] FROM [extensions] WHERE [extensionname] = 'ext_high_tech_specialist');

IF EXISTS (SELECT * FROM [enablerextensions] WHERE [definition] = @def_hermes AND [extensionid] = @id_ext_hitech)
BEGIN
    UPDATE [enablerextensions]
        SET [extensionlevel] = @level_min 
        WHERE [definition] = @def_hermes AND [extensionid] = @id_ext_hitech;
    PRINT N'Update level for hermes extension';
END
ELSE
BEGIN
    INSERT INTO [enablerextensions]
               ([definition]
               ,[extensionid]
               ,[extensionlevel])
         VALUES
               (@def_hermes
               ,@id_ext_hitech
               ,@level_min);
    PRINT N'Insert new hermes extension';
END

GO
