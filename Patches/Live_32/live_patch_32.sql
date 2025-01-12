USE [perpetuumsa]
GO

PRINT N'00_Create_sp_to_revert_extensions.sql';

---- Create stored procedure to revert given extension for given ACCOUNT

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[extensionRevertV2]
	@accountId INT,
	@extensionToRemoveId INT
AS
BEGIN
SET NOCOUNT ON;
DECLARE @tExtId VARCHAR(20), @tCharId VARCHAR(20), @tNewLev VARCHAR(20), @tCurLev VARCHAR(20);

DECLARE  @characterId INT, @extensionId INT, @extensionLevel INT, @recId INT, @fee INT, @newLevel INT, @currentLevel INT;

DECLARE exSpent CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR
SELECT extensionid, extensionlevel, characterid, id FROM dbo.accountextensionspent WHERE  accountid=@accountId AND extensionid=@extensionToRemoveId ORDER BY eventtime;
OPEN exSpent;
FETCH NEXT FROM exSpent INTO @extensionId,@extensionLevel,@characterId,@recId;
WHILE (@@FETCH_STATUS =0)
BEGIN
	SET @tExtId = CAST(@extensionId AS VARCHAR(20));
	SET @tCharId = CAST(@characterId AS VARCHAR(20));
	
	-- degrade the current extension level
	IF (@extensionLevel = 1)
	BEGIN
	    --remove character extension entry
		DELETE dbo.characterextensions WHERE characterid=@characterId AND extensionid=@extensionId

		--pay back fee
		SELECT @fee=price FROM extensions WHERE extensionid=@extensionId;
		UPDATE characters SET credit=credit+@fee WHERE characterID=@characterId;
	END
	ELSE
    BEGIN
		
		IF EXISTS (SELECT 1 FROM dbo.characterextensions WHERE characterid=@characterId AND extensionid=@extensionId)
		BEGIN

			SET @newLevel = @extensionLevel-1;
			SET @tNewLev = CAST(@newLevel AS VARCHAR(20));
			SET @currentLevel= (select extensionLevel FROM dbo.characterextensions WHERE characterid=@characterId AND extensionid=@extensionId);
			SET @tCurLev = CAST(@currentLevel AS VARCHAR(20));

			IF (@currentLevel IS NOT NULL AND @currentLevel > @newLevel)
			BEGIN
				UPDATE dbo.characterextensions SET extensionlevel=@newLevel WHERE characterid=@characterId AND extensionid=@extensionId    
			END
			
		END
			
	end
	
	-- remove the spending record
	DELETE dbo.accountextensionspent WHERE id=@recId;

	FETCH NEXT FROM exSpent INTO @extensionId,@extensionLevel,@characterId,@recId;
END
CLOSE exSpent; DEALLOCATE exSpent;

END

GO

PRINT N'01_Scorchers.sql';

---- Create category flags for Scorchers

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_electric_weapons' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(853775, 'cf_electric_weapons', 'Electric weapons', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_scorchers'
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_scorchers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(17630991, 'cf_scorchers', 'Scorchers', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_scorchers'
END

GO

---- Add new aggregate fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'electric_damage')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('electric_damage', 1,'electric_damage_unit', 1, 0, 6, 0, 1, 1, 'Electric damage')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'electric_damage_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('electric_damage_modifier', 0,'electric_damage_modifier_unit', 100, -100, 6, 0, 1, 1, 'Electric damage modifier')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 0 WHERE name = 'electric_damage_modifier'
END

GO

---- Add new extensions

DECLARE @extensionsCategory INT
DECLARE @targetProperty INT

SET @targetProperty = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')
SET @extensionsCategory = (SELECT TOP 1 extensioncategoryid FROM extensioncategories WHERE categoryname = 'extcat_engineering')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_electric_damage')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetPropertyID, effectenhancer, hidden, freezelimit) VALUES
	(375, 'ext_electric_damage', @extensionsCategory, 9, 'attributeA', 0.1, 'Increases Scorcher electric damage', 405000, 1, 'ext_electric_damage_desc', @targetProperty, 0, 0, 7)
END
ELSE
BEGIN
	UPDATE extensions SET category = @extensionsCategory, targetPropertyID = @targetProperty WHERE extensionname = 'ext_electric_damage'
END

GO

---- Create entity defaults for Scorchers

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_scorchers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_elite2_cultist_scorcher', 1, 66256, @categoryFlag, '#moduleFlag=i490  #ammoCapacity=i0  #powergrid_usage=f200.00  #cpu_usage=f35.00  #cycle_time=f10.00  #energy_neutralized_amount=f300.00  #optimal_range=f25.00  #core_usage=f225.00  #falloff=f0.00  #tier=$tierlevel_t2+', 1, 1, 500, 0, 100, 'def_elite2_cultist_scorcher_desc', 1, 3, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET categoryflags = @categoryFlag, options='#moduleFlag=i490  #ammoCapacity=i0  #powergrid_usage=f200.00  #cpu_usage=f35.00  #cycle_time=f10.00  #energy_neutralized_amount=f300.00  #optimal_range=f25.00  #core_usage=f225.00  #falloff=f0.00  #tier=$tierlevel_t2+', mass=500, hidden = 0 WHERE definitionname = 'def_elite2_cultist_scorcher'
END

GO

---- Set up aggregate fields for Scorchers

DECLARE @definition INT
DECLARE @field INT

---- Core usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 225)
END

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Energy neutralized amount

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 250)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

---- Powergrid usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 200)
END

---- Energy dispersion

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

GO

---- Set up aggregate modifiers for Scorchers

DECLARE @destinationCategoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_scorchers')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_medium_energy_neutralizer_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage_energy_neutralizers_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_neutralizer_optimal_range_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_engineering_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

GO

---- Set up module property modifiers for Scorchers

DECLARE @destinationCategoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_scorchers')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_engineering_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_engineering_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'engineering_optimal_range_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_neutralizer_optimal_range_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_dispersion_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

GO

-- Assign beams to scorchers

DECLARE @moduleId INT
DECLARE @beamId INT

SET @beamId = (SELECT TOP 1 id FROM beams WHERE name = 'medium_e_nezt_beam')

-- standard

SET @moduleId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')

IF NOT EXISTS (SELECT 1 FROM beamassignment WHERE definition = @moduleId AND beam = @beamId)
BEGIN
	INSERT INTO beamassignment (definition, beam) VALUES (@moduleId, @beamId)
END

GO

PRINT N'02_NOX_modules.sql';

---- Create category flags for NOX Modules

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_nox_modules' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(2831, 'cf_nox_modules', 'NOX modules', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_nox_modules'
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_nox_shield_negators' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(68367, 'cf_nox_shield_negators', 'NOX shield negators', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_nox_shield_negators'
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_nox_repair_negators' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(133903, 'cf_nox_repair_negators', 'NOX repair negators', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_nox_repair_negators'
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_nox_teleport_negators' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(199439, 'cf_nox_teleport_negators', 'NOX teleport negators', 1, 0)
END
ELSE
BEGIN
	UPDATE categoryflags SET isunique = 0 WHERE name = 'cf_nox_teleport_negators'
END

GO

---- Add new aggregate fields

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_effect_radius')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_effect_radius', 1,'nox_effect_radius_unit', 10, 0, 6, 2, 1, NULL, 'NOX effect radius')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_effect_radius_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_effect_radius_modifier', 0,'nox_effect_radius_modifier_unit', 100, -100, 6, 2, 1, NULL, 'NOX effect radius modifier')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_effect_enhancer_radius_modifier', 0,'nox_effect_enhancer_radius_modifier_unit', 100, 0, 6, 2, 1, 1, 'NOX effect enhancer radius modifier')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_shield_absorbtion_modifier', 0,'nox_shield_absorbtion_modifier_unit', 100, -100, 6, 2, 1, 1, 'NOX shield negation effect')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 0 WHERE name = 'nox_shield_absorbtion_modifier'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier_enhancer')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_shield_absorbtion_modifier_enhancer', 0,'nox_shield_absorbtion_modifier_enhancer_unit', 100, -100, 6, 2, 1, 1, 'NOX shield negation effect enhancer')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'default_nox_effect_radius')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('default_nox_effect_radius', 1,'default_nox_effect_radius_unit', 1, 0, 6, 2, 1, 1, 'NOX shield negation effect enhancer')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_repair_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_repair_amount_modifier', 0,'nox_repair_amount_modifier_unit', 100, -100, 6, 2, 1, 1, 'NOX repair negation effect')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 0 WHERE name = 'nox_repair_amount_modifier'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_repair_amount_modifier_enhancer')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_repair_amount_modifier_enhancer', 0,'nox_repair_amount_modifier_enhancer_unit', 100, -100, 6, 2, 1, 1, 'NOX repair negation effect enhancer')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 0 WHERE name = 'nox_repair_amount_modifier_enhancer'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'default_nox_effect_radius')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('default_nox_effect_radius', 1,'default_nox_effect_radius_unit', 1, 0, 6, 2, 1, 1, 'NOX shield negation effect enhancer')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'nox_teleport_negation')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('nox_teleport_negation', 1,'nox_teleport_negation_unit', 1, 0, 6, 2, 1, 1, 'NOX teleport negation effect')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'nox_teleport_negation'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'ppm_pelistal_plasma_consumption')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('ppm_pelistal_plasma_consumption', 1,'ppm_pelistal_plasma_consumption_unit', 1, 0, 6, 2, 1, 1, 'Plasma-powered module pelistal plasma consumption')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'ppm_pelistal_plasma_consumption'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'ppm_nuimqol_plasma_consumption')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('ppm_nuimqol_plasma_consumption', 1,'ppm_nuimqol_plasma_consumption_unit', 1, 0, 6, 2, 1, 1, 'Plasma-powered module nuimqol plasma consumption')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'ppm_nuimqol_plasma_consumption'
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'ppm_thelodica_plasma_consumption')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('ppm_thelodica_plasma_consumption', 1,'ppm_thelodica_plasma_consumption_unit', 1, 0, 6, 2, 1, 1, 'Plasma-powered module thelodica plasma consumption')
END
ELSE
BEGIN
	UPDATE aggregatefields SET formula = 1 WHERE name = 'ppm_thelodica_plasma_consumption'
END

GO

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_nox_effect_shield_negation')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_nox_effect_shield_negation', 47, 1, 'Nox effect shield negation')
END
ELSE
BEGIN
	UPDATE effectcategories SET maxlevel = 1 WHERE name = 'effcat_nox_effect_shield_negation'
END

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_nox_effect_repair_negation')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_nox_effect_repair_negation', 48, 1, 'Nox effect repair negation')
END
ELSE
BEGIN
	UPDATE effectcategories SET maxlevel = 1 WHERE name = 'effcat_nox_effect_repair_negation'
END

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_nox_effect_teleport_negation')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_nox_effect_teleport_negation', 49, 1, 'Nox effect teleport negation')
END
ELSE
BEGIN
	UPDATE effectcategories SET maxlevel = 1 WHERE name = 'effcat_nox_effect_teleport_negation'
END

GO

---- Add new effects

DECLARE @effectCategory BIGINT

SET @effectCategory = 140737488355328

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'nox_effect_shield_negation')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'nox_effect_shield_negation', 'nox_effect_shield_negation_desc', 'NOX shield negation effect', 1, 10, 0, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET effectcategory = @effectCategory, duration = 0 WHERE name = 'nox_effect_shield_negation'
END

SET @effectCategory = 281474976710656

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'nox_effect_repair_negation')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'nox_effect_repair_negation', 'nox_effect_repair_negation_desc', 'NOX repair negation effect', 1, 10, 0, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET effectcategory = @effectCategory, duration = 0 WHERE name = 'nox_effect_repair_negation'
END

SET @effectCategory = 562949953421312

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'nox_effect_teleport_negation')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'nox_effect_teleport_negation', 'nox_effect_teleport_negation_desc', 'NOX teleport negation effect', 1, 10, 0, 1, 0)
END
ELSE
BEGIN
	UPDATE effects SET effectcategory = @effectCategory, duration = 0 WHERE name = 'nox_effect_teleport_negation'
END

---- Add new extensions category

IF NOT EXISTS (SELECT 1 FROM extensioncategories WHERE categoryname = 'extcat_nox_management')
BEGIN
	INSERT INTO extensioncategories (extensioncategoryid, categoryname, hidden) VALUES
	(7, 'extcat_nox_management', 0)
END

GO

---- Add new extensions

DECLARE @extensionsCategory INT
DECLARE @targetProperty INT

SET @extensionsCategory = (SELECT TOP 1 extensioncategoryid FROM extensioncategories WHERE categoryname = 'extcat_nox_management')

SET @targetProperty = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_nox_management_basic')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetPropertyID, effectenhancer, hidden, freezelimit) VALUES
	(376, 'ext_nox_management_basic', @extensionsCategory, 2, 'attributeA', 0.1, 'Increases NOX modules radius', 20000, 1, 'ext_nox_management_basic_desc', @targetProperty, 1, 0, 7)
END

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_nox_management_advanced')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetPropertyID, effectenhancer, hidden, freezelimit) VALUES
	(377, 'ext_nox_management_advanced', @extensionsCategory, 5, 'attributeA', 0.2, 'Increases NOX modules radius', 125000, 1, 'ext_nox_management_advanced_desc', @targetProperty, 0, 0, 7)
END

SET @targetProperty = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier_enhancer')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_nox_shield_negation')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetPropertyID, effectenhancer, hidden, freezelimit) VALUES
	(378, 'ext_nox_shield_negation', @extensionsCategory, 5, 'attributeA', -0.05, 'Increases NOX shield negation effect', 125000, 1, 'ext_nox_shield_negation_desc', @targetProperty, 1, 0, 7)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.05 WHERE extensionname = 'ext_nox_shield_negation'
END

SET @targetProperty = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier_enhancer')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_nox_repair_negation')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetPropertyID, effectenhancer, hidden, freezelimit) VALUES
	(379, 'ext_nox_repair_negation', @extensionsCategory, 5, 'attributeA', -0.05, 'Increases NOX repair negation effect', 125000, 1, 'ext_nox_repair_negation_desc', @targetProperty, 1, 0, 7)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.05 WHERE extensionname = 'ext_nox_repair_negation'
END

---- Create entity defaults for NOX modules

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_nox_shield_negators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_shield_negator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_elite2_cultist_nox_shield_negator', 1, 1052948, @categoryFlag, '#moduleFlag=i8 #plasmaDefinition=icca #plasmaConsumption=i3e8  #tier=$tierlevel_t2+', 1, 0.2, 50, 0, 100, 'def_elite2_cultist_nox_shield_negator_desc', 1, 3, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i8 #plasmaDefinition=icca #plasmaConsumption=i3e8  #tier=$tierlevel_t1' WHERE definitionname = 'def_elite2_cultist_nox_shield_negator'
END

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_nox_repair_negators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_repair_negator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_elite2_cultist_nox_repair_negator', 1, 1052948, @categoryFlag, '#moduleFlag=i8 #plasmaDefinition=icc9 #plasmaConsumption=i3e8 #tier=$tierlevel_t2+', 1, 0.2, 50, 0, 100, 'def_elite2_cultist_nox_repair_negator_desc', 1, 3, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i8 #plasmaDefinition=icc9 #plasmaConsumption=i3e8  #tier=$tierlevel_t1' WHERE definitionname = 'def_elite2_cultist_nox_repair_negator'
END

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_nox_teleport_negators')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_teleport_negator')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_elite2_cultist_nox_teleport_negator', 1, 1052948, @categoryFlag, '#moduleFlag=i8 #plasmaDefinition=icc8 #plasmaConsumption=i3e8 #tier=$tierlevel_t2+', 1, 0.2, 50, 0, 100, 'def_elite2_cultist_nox_teleport_negator_desc', 1, 3, 2)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#moduleFlag=i8 #plasmaDefinition=icc8 #plasmaConsumption=i3e8  #tier=$tierlevel_t1' WHERE definitionname = 'def_elite2_cultist_nox_teleport_negator'
END

GO

---- Set up aggregate fields for NOX modules

DECLARE @definition INT
DECLARE @field INT

-- NOX shield negator

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_shield_negator')

---- Core usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Powergrid usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Default NOX effect radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'default_nox_effect_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

---- NOX shield absorbtion modifier

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @definition AND field = @field
END

---- Thelodica plasma consumption

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ppm_thelodica_plasma_consumption')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1000 WHERE definition = @definition AND field = @field
END

-- NOX repair negator

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_repair_negator')

---- Core usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Powergrid usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Default NOX effect radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'default_nox_effect_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

---- NOX repair amount modifier

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @definition AND field = @field
END

---- Nuimqol plasma consumption

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ppm_nuimqol_plasma_consumption')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1000 WHERE definition = @definition AND field = @field
END

-- NOX teleport negator

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_teleport_negator')

---- Core usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Powergrid usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Default NOX effect radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'default_nox_effect_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

---- NOX teleport negation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_teleport_negation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @definition AND field = @field
END

---- Pelistal plasma consumption

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ppm_pelistal_plasma_consumption')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1000 WHERE definition = @definition AND field = @field
END

GO

---- Set up aggregate modifiers for NOX modules

DECLARE @destinationCategoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

-- NOX modules radius

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_modules')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- NOX shield

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_shield_negators')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier_enhancer')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- NOX repair

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_repair_negators')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier_enhancer')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- NOX teleport

GO

---- Set up module property modifiers for NOX modules

DECLARE @destinationCategoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

-- NOX modules

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_modules')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- NOX shield

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_shield_negators')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier_enhancer')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- NOX repair

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_nox_repair_negators')

DELETE FROM modulepropertymodifiers WHERE categoryflags = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier_enhancer')

INSERT INTO modulepropertymodifiers (categoryflags, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

GO

PRINT N'03_Cultist_Preachers.sql';

---- Tellesis

-- Create and fill Cultists

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT

-- Create Cultist Preacher Ictus

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_cultist_preacher_ictus', 1, 1024, 1167, '', 'Ictus, Scorchers, Shield, NOX Teleport', 1, 0, 0, 0, 100, 'def_npc_cultist_preacher_ictus_desc', 1, NULL, NULL)
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 4.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 450)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_neutralizer_optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

GO

---- Create Ictus Preacher template

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT
DECLARE @shield INT
DECLARE @shield_hardener INT
DECLARE @scorcher INT
DECLARE @recharger INT
DECLARE @range_extender INT
DECLARE @sensor_booster INT
DECLARE @aux_accu INT
DECLARE @nox_module INT
DECLARE @lwf INT
DECLARE @targetDefinition INT

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')
SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ictus_mk2_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ictus_head_mk2')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ictus_chassis_mk2')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ictus_leg_mk2')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_ewmech_indy_runner_mk2')
SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
SET @scorcher = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @range_extender = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tracking_upgrade')
SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @aux_accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
SET @nox_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_teleport_negator')
SET @lwf = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Cultist_Preacher_Ictus')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Cultist_Preacher_Ictus', CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]'), 'Cultist Preacher Ictus')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]')
	WHERE name = 'Cultist_Preacher_Ictus'
END

DECLARE @templateId INT

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Cultist_Preacher_Ictus')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 2, NULL, NULL, 1500, 'def_npc_cultist_preacher_ictus')

-- Create Cultist Preacher Zenith

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_cultist_preacher_zenith', 1, 1024, 1167, '', 'Ictus, Scorchers, Shield, NOX Shield', 1, 0, 0, 0, 100, 'def_npc_cultist_preacher_zenith_desc', 1, NULL, NULL)
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 4.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 450)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_neutralizer_optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_shield_absorbtion_modifier_enhancer')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.45)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.45 WHERE definition = @targetDefinition AND field = @field
END

GO

---- Create Zenith Preacher template

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT
DECLARE @shield INT
DECLARE @shield_hardener INT
DECLARE @scorcher INT
DECLARE @recharger INT
DECLARE @range_extender INT
DECLARE @sensor_booster INT
DECLARE @aux_accu INT
DECLARE @nox_module INT
DECLARE @lwf INT
DECLARE @targetDefinition INT

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')
SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_zenith_mk2_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_zenith_head_mk2')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_zenith_chassis_mk2')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_zenith_leg_mk2')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_ewmech_indy_runner_mk2')
SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
SET @scorcher = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @range_extender = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tracking_upgrade')
SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @aux_accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
SET @nox_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_shield_negator')
SET @lwf = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Cultist_Preacher_Zenith')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Cultist_Preacher_Zenith', CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]'), 'Cultist Preacher Zenith')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]')
	WHERE name = 'Cultist_Preacher_Zenith'
END

DECLARE @templateId INT

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Cultist_Preacher_Zenith')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 2, NULL, NULL, 1500, 'def_npc_cultist_preacher_zenith')

-- Create Cultist Preacher Vagabond

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_cultist_preacher_vagabond', 1, 1024, 1167, '', 'Vagabond, Scorchers, Shield, NOX Repair', 1, 0, 0, 0, 100, 'def_npc_cultist_preacher_vagabond_desc', 1, NULL, NULL)
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max_bonus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 10 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 4.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 450)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'energy_neutralizer_optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 200 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_repair_amount_modifier_enhancer')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.45)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.45 WHERE definition = @targetDefinition AND field = @field
END

GO

---- Create Vagabond Preacher template

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT
DECLARE @shield INT
DECLARE @shield_hardener INT
DECLARE @scorcher INT
DECLARE @recharger INT
DECLARE @range_extender INT
DECLARE @sensor_booster INT
DECLARE @aux_accu INT
DECLARE @nox_module INT
DECLARE @lwf INT
DECLARE @targetDefinition INT

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')
SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vagabond_mk2_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vagabond_head_mk2')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vagabond_chassis_mk2')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vagabond_leg_mk2')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_ewmech_indy_runner_mk2')
SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
SET @scorcher = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @range_extender = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tracking_upgrade')
SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @aux_accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
SET @nox_module = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_repair_negator')
SET @lwf = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_mass_reductor')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Cultist_Preacher_Vagabond')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Cultist_Preacher_Vagabond', CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]'), 'Cultist Preacher Vagabond')
END
ELSE
BEGIN
	UPDATE robottemplates SET description = CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@sensor_booster, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@nox_module, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@range_extender, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@scorcher, 'X'),
		'|slot=i2]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@aux_accu, 'X'),
		'|slot=i2]|m3=[|definition=i',
		FORMAT(@lwf, 'X'),
		'|slot=i4]]'),
		note = 'Cultist Preacher Vagabond'
	WHERE name = 'Cultist_Preacher_Vagabond'
END

DECLARE @templateId INT

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Cultist_Preacher_Vagabond')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 2, NULL, NULL, 1500, 'def_npc_cultist_preacher_vagabond')

GO

-- Create Cultist Zealot Mesmer

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT
DECLARE @templateId INT

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_zealot_mesmer', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_zealot_mesmer_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_mesmer_heavydps_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_mesmer_heavydps_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Acolyte Vagabond

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_acolyte_vagabond', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_acolyte_vagabond_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_vagabond_heavyew_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_vagabond_heavyew_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Zealot Seth

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_zealot_seth', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_zealot_seth_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_seth_heavydps_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_seth_heavydps_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Acolyte Zenith

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_acolyte_zenith', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_acolyte_zenith_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_zenith_heavyew_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_zenith_heavyew_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Zealot Gropho

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_zealot_gropho', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_zealot_gropho_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_gropho_heavydps_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gropho_heavydps_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Acolyte Ictus

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_acolyte_ictus', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_acolyte_ictus_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_ictus_heavyew_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_ictus_heavyew_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note)
SELECT @targetDefinition, templateId, raceid, missionlevel, missionleveloverride, killep, note FROM robottemplaterelation WHERE definition = @sourceDefinition

-- Create Cultist Martyr Termis

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype)
	SELECT 'def_npc_cultist_martyr_termis', quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, 'def_npc_cultist_martyr_termis_desc', purchasable, tiertype FROM entitydefaults WHERE definitionname = 'def_npc_termis_basic_rank5'
END

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_basic_rank5')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

INSERT INTO aggregatevalues
SELECT @targetDefinition, field, value FROM aggregatevalues where definition = @sourceDefinition

GO

-- Create template for Cultist Martyr Termis

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT
DECLARE @shield INT
DECLARE @shield_hardener INT
DECLARE @energy_transferer INT
DECLARE @recharger INT
DECLARE @targetDefinition INT
DECLARE @templateId INT

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')
SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_mk2_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_head_mk2')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_chassis_mk2')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_leg_mk2')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_sequer_mk2')
SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
SET @energy_transferer = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Cultist_Martyr_Termis')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Cultist_Martyr_Termis', CONCAT(
		'#robot=i',
		FORMAT(@robot, 'X'),
		'#head=i',
		FORMAT(@head, 'X'),
		'#chassis=i',
		FORMAT(@chassis, 'X'),
		'#leg=i',
		FORMAT(@leg, 'X'),
		'#container=i',
		FORMAT(@inventory, 'X'),
		'#headModules=[|m0=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i5]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i3]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i5]]'), 'Cultist Martyr Termis')
END
		
SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Cultist_Martyr_Termis')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 2, NULL, NULL, 1500, 'def_npc_cultist_martyr_termis')

GO

-- Add Cultist Preachers roamers

IF NOT EXISTS (SELECT 1 FROM npcinterzonegroup WHERE name = 'alpha3_cultist_preachers_izgroup')
BEGIN
	INSERT INTO npcinterzonegroup (name, respawnTime, respawnNoiseFactor) VALUES
	('alpha3_cultist_preachers_izgroup', 259200, 0.15)
END

DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT
DECLARE @templateid INT
DECLARE @flockid INT
DECLARE @izgroupid INT

SET @izgroupid = (SELECT TOP 1 id FROM npcinterzonegroup WHERE name = 'alpha3_cultist_preachers_izgroup')

-- Tellesis

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ICS_pve')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_cultists_z6' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_cultists_z6', 10, 10, 2038, 2038, 'Tellesis Cultists', @spawnid, 1, 1, 7200, 8, 0, 0, 1, 0, 7200, 1, 1, 1, @izgroupid, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, presencetype = 8 WHERE name = 'roamer_cultists_z6'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_cultists_z6')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z6_cultist_preacher_ictus', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z6_cultist_preacher_zenith', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z6_cultist_preacher_vagabond', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'tellesis cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

---- Reinforcements

-- Vagabond wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z6_wave_0', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_mesmer_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_mesmer_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_seth_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_seth_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_gropho_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_gropho_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Vagabond wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z6_wave_1', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_mesmer_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_mesmer_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_seth_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_seth_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_gropho_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_gropho_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Vagabond wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z6_wave_2', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z6_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_mesmer_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_mesmer_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_seth_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_seth_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_zealot_gropho_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_zealot_gropho_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Zenith wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z6_wave_0', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_vagabond_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_vagabond_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_zenith_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_zenith_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_ictus_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_ictus_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Zenith wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z6_wave_1', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_vagabond_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_vagabond_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_zenith_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_zenith_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_ictus_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_ictus_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Zenith wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z6_wave_2', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z6_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_vagabond_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_vagabond_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_zenith_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_zenith_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_acolyte_ictus_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_acolyte_ictus_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Ictus wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z6_wave_0', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_martyr_termis_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_martyr_termis_wave_0', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Ictus wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z6_wave_1', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_martyr_termis_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_martyr_termis_wave_1', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Ictus wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z6_wave_2', 0, 0, 0, 0, 'Tellesis Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z6_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z6_cultist_martyr_termis_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z6_cultist_martyr_termis_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'tellesis cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Shinjalar

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ASI_pve')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_cultists_z7' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_cultists_z7', 10, 10, 2038, 2038, 'Shinjalar Cultists', @spawnid, 1, 1, 7200, 8, 0, 0, 1, 0, 7200, 1, 1, 1, @izgroupid, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, presencetype = 8 WHERE name = 'roamer_cultists_z7'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_cultists_z7')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_ictus')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z7_cultist_preacher_ictus', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z7_cultist_preacher_zenith', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z7_cultist_preacher_vagabond', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'shinjalar cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

---- Reinforcements

-- Vagabond wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z7_wave_0', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_mesmer_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_mesmer_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_seth_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_seth_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_gropho_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_gropho_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Vagabond wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z7_wave_1', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_mesmer_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_mesmer_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_seth_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_seth_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_gropho_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_gropho_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Vagabond wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z7_wave_2', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z7_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_mesmer_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_mesmer_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_seth_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_seth_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_zealot_gropho_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_zealot_gropho_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Zenith wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z7_wave_0', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_vagabond_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_vagabond_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_zenith_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_zenith_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_ictus_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_ictus_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Zenith wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z7_wave_1', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_vagabond_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_vagabond_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_zenith_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_zenith_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_ictus_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_ictus_wave_1', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Zenith wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z7_wave_2', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z7_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_vagabond_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_vagabond_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_zenith_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_zenith_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_acolyte_ictus_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_acolyte_ictus_wave_2', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Ictus wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z7_wave_0', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_martyr_termis_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_martyr_termis_wave_0', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Ictus wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z7_wave_1', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_martyr_termis_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_martyr_termis_wave_1', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Ictus wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z7_wave_2', 0, 0, 0, 0, 'Shinjalar Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z7_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z7_cultist_martyr_termis_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z7_cultist_martyr_termis_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'shinjalar cultists', 0.5, 1, 1, 2, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Attalica

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_ICS')

--- roamers 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'roamer_cultists_z1' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('roamer_cultists_z1', 10, 10, 2038, 2038, 'Attalica Cultists', @spawnid, 1, 1, 7200, 8, 0, 0, 1, 0, 7200, 1, 1, 1, @izgroupid, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, presencetype = 8 WHERE name = 'roamer_cultists_z1'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'roamer_cultists_z1')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_ictus')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z1_cultist_preacher_ictus', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z1_cultist_preacher_zenith', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('roamer_cultists_z1_cultist_preacher_vagabond', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'attalica cultists', 0.9, 1, 1, 2, 0)
END

--

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcbossinfo WHERE flockid = @flockid)
BEGIN
	INSERT INTO npcbossinfo (flockid, respawnNoiseFactor, lootSplitFlag, outpostEID, stabilityPts, overrideRelations, customDeathMessage, customAggressMessage, riftConfigId, isAnnounced) VALUES
	(@flockId, 0.15, 1, NULL, NULL, 0, '....Gooodssssss....blessssssing.....usssssss.....', '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....', NULL, 1)
END

---- Reinforcements

-- Vagabond wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z1_wave_0', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_mesmer_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_mesmer_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_seth_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_seth_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_gropho_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_gropho_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Vagabond wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z1_wave_1', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_mesmer_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_mesmer_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_seth_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_seth_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_gropho_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_gropho_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Vagabond wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_vagabond_z1_wave_2', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_vagabond_z1_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_mesmer_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_mesmer_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_seth_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_seth_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_zealot_gropho_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_zealot_gropho_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Zenith wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z1_wave_0', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_vagabond_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_vagabond_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_zenith_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_zenith_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_ictus_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_ictus_wave_0', @presenceid, 1, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Zenith wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z1_wave_1', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_vagabond_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_vagabond_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_zenith_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_zenith_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_ictus_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_ictus_wave_1', @presenceid, 2, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Zenith wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_zenith_z1_wave_2', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_zenith_z1_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_vagabond_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_vagabond_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_zenith_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_zenith_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_acolyte_ictus_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_acolyte_ictus_wave_2', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

-- Ictus wave 0

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_0' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z1_wave_0', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 0', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_0')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_martyr_termis_wave_0')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_martyr_termis_wave_0', @presenceid, 3, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.25, @presenceid, NULL)
END

-- Ictus wave 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_1' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z1_wave_1', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 1', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_martyr_termis_wave_1')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_martyr_termis_wave_1', @presenceid, 6, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.5, @presenceid, NULL)
END

/*
-- Ictus wave 2

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_2' AND spawnid = 10)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('reinforce_cultists_preacher_ictus_z1_wave_2', 0, 0, 0, 0, 'Attalica Cultists Reinforcement Wave 2', 10, 1, 0, 0, 9, NULL, NULL, NULL, NULL, NULL, 1, 0, 1, NULL, NULL)
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'reinforce_cultists_preacher_ictus_z1_wave_2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'reinforce_cultists_z1_cultist_martyr_termis_wave_2')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('reinforce_cultists_z1_cultist_martyr_termis_wave_2', @presenceid, 9, @definition, 0, 0, 0, 10, 0, 1, 55, 'attalica cultists', 0.5, 1, 1, 1, 0)
END

SET @flockid = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM npcreinforcements WHERE presenceId = @presenceid AND targetId = @flockid)
BEGIN
	INSERT INTO npcreinforcements (reinforcementType, targetId, threshold, presenceId, zoneId) VALUES
	(2, @flockid, 0.75, @presenceid, NULL)
END
*/

GO

---- Adding loot

DECLARE @lootDefinition INT
DECLARE @targetDefinition INT

-- Mesmer Zealot

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_mesmer')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_thrm_armor_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_damage_mod_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_thrm_armor_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_damage_mod_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_railgun_d')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1125, 1, 0, 0, 921)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 240, 1, 0, 1, 160)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_nuimqol')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 960, 1, 0, 1, 640)

-- Vagabond Acolyte

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_vagabond')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_longrange_medium_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_dampener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_longrange_medium_railgun')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_dampener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_railgun_b')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_nuimqol')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Seth Zealot

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_seth')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_damage_mod_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_damage_mod_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_lasercrystal_d')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1005, 1, 0, 0, 821)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 240, 1, 0, 1, 160)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_thelodica')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 960, 1, 0, 1, 640)

-- Zenith Acolyte

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_zenith')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_dampener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_laser')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_dampener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_lasercrystal_a')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_thelodica')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Gropho Zealot

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_zealot_gropho')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_kin_armor_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_missile_launcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_damage_mod_missile')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_kin_armor_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_missile_launcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_damage_mod_missile')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_missile_d')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 965, 1, 0, 0, 788)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 240, 1, 0, 1, 160)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_pelistal')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 960, 1, 0, 1, 640)

-- Ictus Acolyte

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_acolyte_ictus')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_neutralizer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_missile_launcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_neutralizer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_webber')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_jammer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_missile_launcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_vampire')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_missile_d')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 100, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_pelistal')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Termis Martyr

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_martyr_termis')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1),
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 296, 1, 0, 0, 242)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Zenith Preacher

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_shield_negator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_thelodica_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_thelodica')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Vagabond Preacher

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_repair_negator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_nuimqol_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_nuimqol')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

-- Ictus Preacher

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

DELETE FROM npcloot WHERE definition = @targetDefinition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_nox_teleport_negator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.35, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_artifact_a_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tracking_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_mass_reductor')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_pelistal_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 335, 1, 0, 0, 274)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_pelistal')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
(@targetDefinition, @lootDefinition, 768, 1, 0, 1, 512)

GO

PRINT N'04_Fixes_and_rebalance.sql';

---- Disable Spectator minibosses

UPDATE npcpresence SET enabled = 0 WHERE name IN ('spectator_01_z7', 'spectator_01_z1', 'spectator_01_z6')

GO

---- Fix Drones craft COST

DECLARE @definition INT
DECLARE @gamma_nuimqol_shards INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_nuimqol_combat_drone_unit')
SET @gamma_nuimqol_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_nuimqol')

UPDATE components SET componentamount = 1 WHERE definition = @definition AND componentdefinition = @gamma_nuimqol_shards

GO

---- Speeding up the destroyers

UPDATE entitydefaults SET mass = 78000 WHERE definitionname IN ('def_onyx_bot_chassis', 'def_hydra_bot_chassis', 'def_felos_bot_chassis')
UPDATE entitydefaults SET mass = 18000 WHERE definitionname IN ('def_onyx_bot_leg', 'def_hydra_bot_leg', 'def_felos_bot_leg')

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hydra_bot_leg')
UPDATE aggregatevalues SET value = 1.7 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_felos_bot_leg')
UPDATE aggregatevalues SET value = 1.87 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_onyx_bot_leg')
UPDATE aggregatevalues SET value = 1.7 WHERE definition = @definition AND field = @field

GO

---- Fixes for drones description

UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named1_nuimqol_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named1_nuimqol_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named1_pelistal_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named1_pelistal_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named1_thelodica_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named1_thelodica_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named2_nuimqol_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named2_nuimqol_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named2_pelistal_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named2_pelistal_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named2_thelodica_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named2_thelodica_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named3_nuimqol_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_nuimqol_combat_drone_desc' WHERE definitionname = 'def_named3_nuimqol_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named3_pelistal_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_pelistal_combat_drone_desc' WHERE definitionname = 'def_named3_pelistal_combat_drone_unit'

UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named3_thelodica_combat_drone'
UPDATE entitydefaults SET descriptiontoken = 'def_standart_thelodica_combat_drone_desc' WHERE definitionname = 'def_named3_thelodica_combat_drone_unit'

GO

PRINT N'05_camouflage.sql';

USE [perpetuumsa]
GO

--------------------------------------
-- Maroon Dark paint
--
-- Date Modified:
--      2024/03/26 - Initial commit
--------------------------------------

PRINT N'INSERT def_paint_maroon_dark DEFINITION';
INSERT INTO [dbo].[entitydefaults]
    ([definitionname],
     [quantity],
     [attributeflags],
     [categoryflags],
     [options],
     [note],
     [enabled],
     [volume],
     [mass],
     [hidden],
     [health],
     [descriptiontoken],
     [purchasable],
     [tiertype],
     [tierlevel])
VALUES
    ('def_paint_maroon_dark',1,2052,132251,'','Paint',1,0.000001,0.000001,0,100,'def_paint_maroon_dark_desc',1,NULL,NULL);

PRINT N'INSERT INTO definitionconfig TO CONFIGURE COLOR OF PAINT';
DECLARE	@paintDef int;
SET @paintDef = (SELECT TOP 1 definition from entitydefaults where definitionname='def_paint_maroon_dark');

INSERT INTO [dbo].[definitionconfig]
    ([definition],[tint],[note])
VALUES
    (@paintDef,'#330101','Paint Color');

PRINT N'INSERT SYNDICATE SHOP ORDERS';
DECLARE @alphaTM  int;
DECLARE @alphaASI int;
DECLARE @alphaICS int;

DECLARE @betaTM   int;
DECLARE @betaASI  int;
DECLARE @betaICS  int;

SET @alphaTM  = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'tm_preset_pve');
SET @alphaASI = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'asi_preset_pve');
SET @alphaICS = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'ics_preset_pve');

SET @betaTM   = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'tm_preset_pvp');
SET @betaASI  = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'asi_preset_pvp');
SET @betaICS  = (SELECT TOP 1 id FROM itemshoppresets WHERE name LIKE 'ics_preset_pvp');

DECLARE @price int;
SET @price = 3000000;

INSERT INTO [dbo].[itemshop]
    ([presetid],
     [targetdefinition],
     [targetamount],
     [tmcoin],
     [icscoin],
     [asicoin],
     [credit],
     [unicoin],
     [globallimit],
     [purchasecount],
     [standing])
VALUES
    (@alphaTM,  @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL),
    (@alphaASI, @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL),
    (@alphaICS, @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL),
	(@betaTM,   @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL),
	(@betaASI,  @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL),
	(@betaICS,  @paintDef, 1, NULL, NULL, NULL, @price, NULL, NULL, 0, NULL);
GO

PRINT N'06_Post_testing_changes_step1.sql';

---- Add new boss settings

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
ALTER TABLE dbo.npcbossinfo ADD
	isServerWideAnnouncement bit NULL,
	isNoRadioDelay bit NULL
GO
ALTER TABLE dbo.npcbossinfo SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

---- Fill new boss settings

DECLARE @flockId INTEGER

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_ictus')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '....Gooodssssss....blessssssing.....usssssss.....',
	customAggressMessage = '....Sssssslaaaaay.....hhhhumansssss....Worshhhhhhip.....Goooodsssssss....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_zenith')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '...Deathssss........pleasuresssss...Goooodsssssss.......',
	customAggressMessage = '....Sssssslay....Ssssssslaaaaaaay....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z1_cultist_preacher_vagabond')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '....Prrrraaaaayssssssse......',
	customAggressMessage = '.....Masssssacre....in the name offff.....Gooooodssss....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_ictus')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '...Sssssacrifice......ourselvesssss.....',
	customAggressMessage = '.....Sssssacrifice....humanssssss.....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_zenith')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '.....Resssstoooooore.....bodiessss......',
	customAggressMessage = '....Ssssssummon.....forcessssss....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z7_cultist_preacher_vagabond')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '...Retreeeeeat....to issssslandsssss....',
	customAggressMessage = '.....Assssseeeemble....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_ictus')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '....Witnessssss...uuussssss....',
	customAggressMessage = '....Dessssintergaaaate....'
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_zenith')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '',
	customAggressMessage = ''
WHERE flockId = @flockId

SET @flockId = (SELECT TOP 1 id FROM npcflock WHERE name = 'roamer_cultists_z6_cultist_preacher_vagabond')
UPDATE npcbossinfo SET
	isServerWideAnnouncement = 1,
	isNoRadioDelay = 1,
	customDeathMessage = '.....Lossssst....powersssss.....',
	customAggressMessage = '.....Sssssstrike......with Ssssscorchersssss.....'
WHERE flockId = @flockId

GO

---- Add T2+ items to Josef, Bonnie and Commandant loot

DECLARE @definition INT
DECLARE @lootDefinition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_Zone71_WilliamHBonnie')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_maneuvering_upgrade')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_medium_shield_generator')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_mining_probe_module')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_71_small_shield_generator')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_Zone72_One_Eye_Josef')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_small_armor_repairer')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_medium_armor_repairer')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_damage_mod_projectile')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_72_mass_reductor')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_sh70_mainboss')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_armor_repairer')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_armor_repairer')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_shield_generator')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_shield_generator')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_sensor_booster')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_webber')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_eccm')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_small_core_booster')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_medium_core_booster')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet2_70_tracking_upgrade')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.1, 0, 0, 1)
END

GO

---- Adding T4+ to gamma pitbosses loot

DECLARE @definition INT
DECLARE @lootDefinition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_apollo_syndicate_syn_pitboss')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_autocannon')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_autocannon')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_autocannon')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_driller')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_driller')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_harvester')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_harvester')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_felos_nuimqol_pitboss')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_railgun')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_railgun')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_railgun')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_onyx_thelodica_pitboss')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_longrange_medium_laser')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_medium_laser')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_small_laser')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_gamma_hydra_pelistal_pitboss')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_missile_launcher')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elitet4_gamma_rocket_launcher')
IF NOT EXISTS (SELECT 1 FROM npcloot WHERE definition = @definition AND lootdefinition = @lootDefinition)
BEGIN
	INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity) VALUES
	(@definition, @lootDefinition, 1, 0.05, 0, 0, 1)
END

GO

---- Increase PBS bandwidth

DECLARE @entityDef INT
DECLARE @capsuleDef INT
DECLARE @protoDef INT

SET @entityDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_small')
SET @capsuleDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_small_capsule')
SET @protoDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_small_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 15000 WHERE definition IN (@entityDef, @capsuleDef, @protoDef)

SET @entityDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium')
SET @capsuleDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule')
SET @protoDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 30000 WHERE definition IN (@entityDef, @capsuleDef, @protoDef)

SET @entityDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large')
SET @capsuleDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule')
SET @protoDef = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 54000 WHERE definition IN (@entityDef, @capsuleDef, @protoDef)

GO

---- Nerf scorchers

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_elite2_cultist_scorcher')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage')

UPDATE aggregatevalues SET value = 125 WHERE definition = @definition AND field = @field

GO

---- Fix Doom Beamers shards

DECLARE @titanium INT
DECLARE @polynucleit INT
DECLARE @espitium INT
DECLARE @bryochite INT
DECLARE @flux INT
DECLARE @gamma_thelodica_shards INT
DECLARE @definition INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @polynucleit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynucleit')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite
SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')
SET @gamma_thelodica_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_thelodica')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_thelodica_combat_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2000),
(@definition, @polynucleit, 4000),
(@definition, @espitium, 200),
(@definition, @bryochite, 100),
(@definition, @flux, 20),
(@definition, @gamma_thelodica_shards, 1)

GO

PRINT N'08_Spectator_Revamp.sql';

---- Nerf Spectator base stats

DECLARE @definition INT
DECLARE @field INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_head')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

UPDATE aggregatevalues SET value = 8000 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

UPDATE aggregatevalues SET value = 8000 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

UPDATE aggregatevalues SET value = 9 WHERE definition = @definition AND field = @field

GO

---- Nerf Spectator chassis bonuses

DECLARE @definition INT
DECLARE @extension INT
DECLARE @field INT

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_chassis')

SET @extension = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_glider_specialist')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation_modifier')

DELETE FROM chassisbonus WHERE definition = @definition AND extension = @extension AND targetpropertyID = @field

GO

---- Create category flags for extra remote controllers

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_tactical_remote_controllers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(17564687, 'cf_tactical_remote_controllers', 'Tactical remote controllers', 0, 1)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_assault_remote_controllers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(34341903, 'cf_assault_remote_controllers', 'Assault remote controllers', 0, 1)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_industrial_remote_controllers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(51119119, 'cf_industrial_remote_controllers', 'Industrial remote controllers', 0, 1)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_support_remote_controllers' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(67896335, 'cf_support_remote_controllers', 'Support remote controllers', 0, 1)
END

GO

---- Create category flags for extra rcu as ammo

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_attack_drones_units' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(201226, 'cf_attack_drones_units', 'Attack drones units', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_assault_drones_units' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(266762, 'cf_assault_drones_units', 'Assault drones units', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_industrial_drones_units' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(332298, 'cf_industrial_drones_units', 'Industrial drones units', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_support_drones_units' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(397834, 'cf_support_drones_units', 'Support drones units', 0, 0)
END

---- Create category flags for extra rcu as zone object

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_assault_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4498, 'cf_assault_drones', 'Assault drones', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_industrial_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4754, 'cf_industrial_drones', 'Industrial drones', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_support_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(5010, 'cf_support_drones', 'Support drones', 0, 0)
END

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_attack_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(5266, 'cf_attack_drones', 'Attack drones', 0, 0)
END

GO

---- Rename existing remote controllers

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_remote_controllers')

UPDATE entitydefaults SET
	definitionname = 'def_standard_assault_remote_controller',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i3  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t1'
WHERE definitionname = 'def_standart_remote_controller'

UPDATE entitydefaults SET
	definitionname = 'def_standard_assault_remote_controller_cprg'
WHERE definitionname = 'def_standart_remote_controller_cprg'

--

UPDATE entitydefaults SET
	definitionname = 'def_named1_assault_remote_controller',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i3  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2'
WHERE definitionname = 'def_named1_remote_controller'

UPDATE entitydefaults SET
	definitionname = 'def_named1_assault_remote_controller_pr',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i3  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2_pr'
WHERE definitionname = 'def_named1_remote_controller_pr'

UPDATE entitydefaults SET
	definitionname = 'def_named1_assault_remote_controller_cprg'
WHERE definitionname = 'def_named1_remote_controller_cprg'

--

UPDATE entitydefaults SET
	definitionname = 'def_named2_assault_remote_controller',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i4  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3'
WHERE definitionname = 'def_named2_remote_controller'

UPDATE entitydefaults SET
	definitionname = 'def_named2_assault_remote_controller_pr',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i4  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3_pr'
WHERE definitionname = 'def_named2_remote_controller_pr'

UPDATE entitydefaults SET
	definitionname = 'def_named2_assault_remote_controller_cprg'
WHERE definitionname = 'def_named2_remote_controller_cprg'

--

UPDATE entitydefaults SET
	definitionname = 'def_named3_assault_remote_controller',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i5  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4'
WHERE definitionname = 'def_named3_remote_controller'

UPDATE entitydefaults SET
	definitionname = 'def_named3_assault_remote_controller_pr',
	descriptiontoken = 'def_standard_assault_remote_controller_desc',
	categoryflags = @categoryFlag,
	options = '#moduleFlag=i888  #ammoCapacity=i5  #ammoType=L4120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4_pr'
WHERE definitionname = 'def_named3_remote_controller_pr'

UPDATE entitydefaults SET
	definitionname = 'def_named3_assault_remote_controller_cprg'
WHERE definitionname = 'def_named3_remote_controller_cprg'

GO

---- Create extra remote controllers

-- Tactical

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_tactical_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_tactical_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i3  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t1', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 1)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_tactical_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i3  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_tactical_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i3  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2_pr', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 2)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_tactical_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i4  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_tactical_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i4  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3_pr', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 3)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_tactical_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i5  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 4)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_tactical_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=i848  #ammoCapacity=i5  #ammoType=L3120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4_pr', 1, 1, 1, 0, 100, 'def_standard_tactical_remote_controller_desc', 1, 1, 4)
END

--

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_electronics_equipment_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_tactical_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t1', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_tactical_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t2', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_tactical_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t3', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_tactical_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t4', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

-- Industrial

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_industrial_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i3  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t1', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 1)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_industrial_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i3  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_industrial_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i3  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2_pr', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 2)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_industrial_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i4  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_industrial_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i4  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3_pr', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 3)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_industrial_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i5  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 4)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_industrial_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iA08  #ammoCapacity=i5  #ammoType=L5120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4_pr', 1, 1, 1, 0, 100, 'def_standard_industrial_remote_controller_desc', 1, 1, 4)
END

--

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_electronics_equipment_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_industrial_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t1', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_industrial_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t2', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_industrial_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t3', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_industrial_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t4', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

-- Support

DECLARE @categoryFlag INT

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_support_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i3  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t1', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 1)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_support_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i3  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_support_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i3  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t2_pr', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 2)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_support_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i4  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_support_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i4  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t3_pr', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 3)
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_support_remote_controller', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i5  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 4)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_support_remote_controller_pr', 1, 2359320, @categoryFlag, '#moduleFlag=iC08  #ammoCapacity=i5  #ammoType=L6120a  #powergrid_usage=f0.00  #cpu_usage=f0.00  #tier=$tierlevel_t4_pr', 1, 1, 1, 0, 100, 'def_standard_support_remote_controller_desc', 1, 1, 4)
END

--

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_electronics_equipment_calibration_programs')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_standard_support_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t1', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named1_support_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t2', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 2)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named2_support_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t3', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 3)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_named3_support_remote_controller_cprg', 1, 1024, @categoryFlag, '#tier=$tierlevel_t4', 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 4)
END

GO

---- Create entity defaults for Syndicate Assault Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_head', 1, 1024, @category, '#height=f0.2#slotFlags=48,8,8,8,8', 1, 3, 1000, 1, 100, 'def_syndicate_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_chassis', 1, 1024, @category, '#height=f1.1#slotFlags=44d1,4d1,d1', 1, 13, 30000, 1, 100, 'def_syndicate_assault_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_leg', 1, 1024, @category, '#height=f1.15#slotFlags=420,20,20,20,20', 1, 7, 4000, 1, 100, 'def_syndicate_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_syndicate_assault_drone_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate assault drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_syndicate_assault_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate assault drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_longrange_standard_medium_autocannon')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_projectile_rewa')

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'syndicate_assault_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i96]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i96]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i96]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('syndicate_assault_drone', @description, 'Syndicate assault drone')
END

GO

---- Link Syndicate assault drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'syndicate_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'Syndicate assault drone')
END

GO

---- Set up aggregate fields for Syndicate assault drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3520)
END

---- Damage chemical

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Damage explosive

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

---- Damage thermal

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

---- Damage toxic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 8000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 18)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 22)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 28)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

GO

---- Set up aggregate fields for Syndicate assault drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 370)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 405)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3520)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3080)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1200)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 22)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.847)
END

GO

---- Create entity defaults for nuimqol Assault Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_head', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.15', 1, 3, 1000, 1, 100, 'def_nuimqol_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_chassis', 1, 1024, @category, '#height=f1.1#slotFlags=420,20,20,20', 1, 13, 25000, 1, 100, 'def_nuimqol_assault_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_leg', 1, 1024, @category, '#slotFlags=420  #height=f0.9', 1, 7, 4000, 1, 100, 'def_nuimqol_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_nuimqol_assault_drone_desc', 1, NULL, NULL)
END

GO

---- Create nuimqol assault drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_nuimqol_assault_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create nuimqol assault drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_longrange_standard_medium_railgun')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_railgun_d')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'nuimqol_assault_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('nuimqol_assault_drone', @description, 'nuimqol assault drone')
END

GO

---- Link nuimqol assault drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'nuimqol_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'nuimqol assault drone')
END

GO

---- Set up aggregate fields for nuimqol assault drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2880)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 48)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 14)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 29)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7.5)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

GO

---- Set up aggregate fields for nuimqol assault drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 365)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 33)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 405)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2880)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3300)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1075)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.13)
END

GO

---- Create entity defaults for thelodica Assault Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_head', 1, 1024, @category, '#height=f0.1#slotFlags=48,8,8,8,8,8', 1, 3, 1000, 1, 100, 'def_thelodica_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_chassis', 1, 1024, @category, '#height=f0.75#slotFlags=44d1,4d1,d1', 1, 13, 25000, 1, 100, 'def_thelodica_assault_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_leg', 1, 1024, @category, '#height=f0.95#slotFlags=420,20,20,20', 1, 7, 4000, 1, 100, 'def_thelodica_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_thelodica_assault_drone_desc', 1, NULL, NULL)
END

GO

---- Create thelodica assault drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_thelodica_assault_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create thelodica assault drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_longrange_standard_medium_laser')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_medium_lasercrystal_d')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'thelodica_assault_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('thelodica_assault_drone', @description, 'thelodica assault drone')
END

GO

---- Link thelodica assault drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'thelodica_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'thelodica assault drone')
END

GO

---- Set up aggregate fields for thelodica assault drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3200)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 48)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

GO

---- Set up aggregate fields for thelodica assault drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 315)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 35)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 405)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3200)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3440)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1375)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.95)
END

GO

---- Create entity defaults for pelistal Assault Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_head', 1, 1024, @category, '#height=f0.2#slotFlags=48,8,8,8', 1, 3, 1000, 1, 100, 'def_pelistal_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_chassis', 1, 1024, @category, '#height=f0.8#slotFlags=44d0,4d0,d2,d2,492', 1, 13, 22000, 1, 100, 'def_pelistal_assault_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_leg', 1, 1024, @category, '#slotFlags=420,20,20,20  #height=f1.15', 1, 7, 4000, 1, 100, 'def_pelistal_assault_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_pelistal_assault_drone_desc', 1, NULL, NULL)
END

GO

---- Create pelistal assault drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_pelistal_assault_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create pelistal assault drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_missile_launcher')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_longrange_missile_d')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'pelistal_assault_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i4|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]|m3=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i5|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('pelistal_assault_drone', @description, 'pelistal assault drone')
END

GO

---- Link pelistal assault drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'pelistal_assault_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'pelistal assault drone')
END

GO

---- Set up aggregate fields for pelistal assault drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3200)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 14000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'explosion_radius')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 13)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

GO

---- Set up aggregate fields for pelistal assault drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 418)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 34)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 405)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_chassis')

---- Missile miss

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'missile_miss')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3200)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2600)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 720)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1125)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1.95)
END

GO

---- Create entity defaults for Syndicate attack Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_head', 1, 1024, @category, '#height=f0.01#slotFlags=48,8,8,8', 1, 3, 300, 1, 100, 'def_syndicate_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_chassis', 1, 1024, @category, '#height=f0.45#slotFlags=4451,6d1,451,6d1', 1, 8, 8400, 1, 100, 'def_syndicate_attack_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_leg', 1, 1024, @category, '#height=f0.35#slotFlags=420,20,20', 1, 3, 1700, 1, 100, 'def_syndicate_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_syndicate_attack_drone_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate attack drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_syndicate_attack_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate attack drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_autocannon')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_rewa')

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'syndicate_attack_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=ic8]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=ic8]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=ic8]|m3=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i4|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=ic8]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('syndicate_attack_drone', @description, 'Syndicate attack drone')
END

GO

---- Link Syndicate attack drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'syndicate_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'Syndicate attack drone')
END

GO

---- Set up aggregate fields for Syndicate attack drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 996)
END

---- Damage chemical

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Damage explosive

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Damage thermal

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Damage toxic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_toxic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3200)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 6)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7.5)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12.5)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

GO

---- Set up aggregate fields for Syndicate attack drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 19)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 130)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 280)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 125)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 105)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 996)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 240)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4.5)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.083)
END

GO

---- Create entity defaults for nuimqol attack Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_head', 1, 1024, @category, '#height=f0.01#slotFlags=48,8,8', 1, 3, 300, 1, 100, 'def_nuimqol_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_chassis', 1, 1024, @category, '#height=f0.45#slotFlags=4451,6d1,451,6d3', 1, 13, 7100, 1, 100, 'def_nuimqol_attack_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_leg', 1, 1024, @category, '#height=f0.35#slotFlags=420,20,20,20', 1, 7, 1700, 1, 100, 'def_nuimqol_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_nuimqol_attack_drone_desc', 1, NULL, NULL)
END

GO

---- Create nuimqol attack drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_nuimqol_attack_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create nuimqol attack drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_railgun')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_railgun_d')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'nuimqol_attack_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]|m3=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i4|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i32]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('nuimqol_attack_drone', @description, 'nuimqol attack drone')
END

GO

---- Link nuimqol attack drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'nuimqol_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'nuimqol attack drone')
END

GO

---- Set up aggregate fields for nuimqol attack drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 816)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 24)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0.5)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

GO

---- Set up aggregate fields for nuimqol attack drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 17)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 280)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 816)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.527)
END

GO

---- Create entity defaults for thelodica attack Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_head', 1, 1024, @category, '#height=f0.01#slotFlags=48,8,8', 1, 3, 300, 1, 100, 'def_thelodica_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_chassis', 1, 1024, @category, '#height=f0.3#slotFlags=4451,6d1,451,6d3', 1, 13, 7100, 1, 100, 'def_thelodica_attack_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_leg', 1, 1024, @category, '#height=f0.3#slotFlags=420,20,20,20', 1, 7, 1700, 1, 100, 'def_thelodica_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_thelodica_attack_drone_desc', 1, NULL, NULL)
END

GO

---- Create thelodica attack drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_thelodica_attack_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create thelodica attack drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_laser')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_lasercrystal_d')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'thelodica_attack_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]|m3=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i4|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i78]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('thelodica_attack_drone', @description, 'thelodica attack drone')
END

GO

---- Link thelodica attack drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'thelodica_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'thelodica attack drone')
END

GO

---- Set up aggregate fields for thelodica attack drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 912)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 24)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'accuracy')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

---- Falloff

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

GO

---- Set up aggregate fields for thelodica attack drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 19)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 280)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 912)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 360)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.222)
END

GO

---- Create entity defaults for pelistal attack Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_head', 1, 1024, @category, '#height=f0.01#slotFlags=48,8,8,8', 1, 3, 300, 1, 100, 'def_pelistal_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_chassis', 1, 1024, @category, '#height=f0.25#slotFlags=452,d2,52,d3', 1, 13, 6840, 1, 100, 'def_pelistal_attack_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_leg', 1, 1024, @category, '#height=f0.5#slotFlags=420,20,20', 1, 7, 1700, 1, 100, 'def_pelistal_attack_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_pelistal_attack_drone_desc', 1, NULL, NULL)
END

GO

---- Create pelistal attack drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_pelistal_attack_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create pelistal attack drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @ammo INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_rocket_launcher')
SET @ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_rocket_b')

-- T1

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'pelistal_attack_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]|m2=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i3|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]|m3=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i4|ammoDefinition=i', FORMAT(@ammo, 'X'), '|ammoQuantity=i14]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('pelistal_attack_drone', @description, 'pelistal attack drone')
END

GO

---- Link pelistal attack drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'pelistal_attack_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'pelistal attack drone')
END

GO

---- Set up aggregate fields for pelistal attack drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 912)
END

---- Damage kinetic

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 40)
END

---- Weapon cycle

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END

---- Accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'explosion_radius')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4.5)
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 18)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

GO

---- Set up aggregate fields for pelistal attack drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 204)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 18)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 15)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 280)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_chassis')

---- Missile miss

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'missile_miss')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 912)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 270)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 140)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.222)
END

GO

---- Create entity defaults for industrial Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_head', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.10', 1, 3, 225, 1, 100, 'def_mining_industrial_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_chassis', 1, 1024, @category, '#slotFlags=46d3,6d3  #height=f2.00  #decay=n500', 1, 8, 6250, 1, 100, 'def_mining_industrial_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_leg', 1, 1024, @category, '#slotFlags=420  #height=f1.50', 1, 3, 1875, 1, 100, 'def_mining_industrial_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_mining_industrial_drone_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate industrial drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone'), ' #turretType=$IndustrialDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_mining_industrial_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create industrial drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_industrial_turret_driller')

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'mining_industrial_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('mining_industrial_drone', @description, 'Mining industrial drone')
END

GO

---- Link mining industrial drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'mining_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'Mining industrial drone')
END

GO

---- Set up aggregate fields for Mining industrial drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

GO

---- Set up aggregate fields for Mining industrial drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 175)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 840)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 360)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.75)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.05)
END

GO

---- Create entity defaults for industrial Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_head', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.10', 1, 3, 225, 1, 100, 'def_harvesting_industrial_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_chassis', 1, 1024, @category, '#slotFlags=46d3,6d3  #height=f2.00  #decay=n500', 1, 8, 6250, 1, 100, 'def_harvesting_industrial_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_leg', 1, 1024, @category, '#slotFlags=420  #height=f1.50', 1, 3, 1875, 1, 100, 'def_harvesting_industrial_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_harvesting_industrial_drone_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate industrial drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone'), ' #turretType=$IndustrialDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_harvesting_industrial_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create industrial drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_industrial_turret_harvester')

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'harvesting_industrial_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('harvesting_industrial_drone', @description, 'harvesting industrial drone')
END

GO

---- Link harvesting industrial drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'harvesting_industrial_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'harvesting industrial drone')
END

GO

---- Set up aggregate fields for harvesting industrial drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

GO

---- Set up aggregate fields for harvesting industrial drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 175)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 840)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 360)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.75)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.05)
END

GO

---- Create entity defaults for repair support Drones

DECLARE @category INT

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_head')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_head')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_head', 1, 1024, @category, '#slotFlags=48,8,8,8  #height=f0.10', 1, 3, 225, 1, 100, 'def_repair_support_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_chassis')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_chassis')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_chassis', 1, 1024, @category, '#slotFlags=46d3,6d3  #height=f2.00  #decay=n500', 1, 8, 6250, 1, 100, 'def_repair_support_drone_chassis_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_leg')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_leg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_leg', 1, 1024, @category, '#slotFlags=420  #height=f1.50', 1, 3, 1875, 1, 100, 'def_repair_support_drone_desc', 0, NULL, NULL)
END

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_robot_inventory')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_inventory')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_inventory', 1, 4195336, @category, '#capacity=f120.0', 1, 0, 0, 0, 100, 'def_robot_inventory_desc', 0, NULL, NULL)
END

DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_inventory')

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_drones')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone', 1, 1024, @category, CONCAT('#head=n', @head, '  #chassis=n', @chassis, '  #leg=n', @leg, '  #inventory=n', @cargo), 1, 22.5, 0, 0, 100, 'def_repair_support_drone_desc', 1, NULL, NULL)
END

GO

---- Create Syndicate support drones ammo 

DECLARE @categoryFlag INT
DECLARE @options VARCHAR(MAX)

SET @categoryFlag = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_drones_units')

SET @options = CONCAT('#turretId=i', (SELECT TOP 1 FORMAT(definition, 'X') FROM entitydefaults WHERE definitionname = 'def_repair_support_drone'), ' #turretType=$CombatDrone')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_unit', 10, 2048, @categoryFlag, @options, 1, 2.5, 1, 0, 100, 'def_repair_support_drone_unit_desc', 1, NULL, NULL)
END

GO

---- Create support drones templates

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @cargo INT
DECLARE @gunDefinitionId INT
DECLARE @description VARCHAR(MAX)

SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_leg')
SET @cargo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_inventory')
SET @gunDefinitionId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'repair_support_drone')
BEGIN
	SET @description = CONCAT('#robot=i', FORMAT(@robot, 'X'), '#head=i', FORMAT(@head, 'X'), '#chassis=i', FORMAT(@chassis, 'X'), '#leg=i', FORMAT(@leg, 'X'), '#container=i', FORMAT(@cargo, 'X'), '#chassisModules=[|m0=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i1]|m1=[|definition=i', FORMAT(@gunDefinitionId, 'X'), '|slot=i2]]')

	INSERT INTO robottemplates (name, description, note) VALUES
	('repair_support_drone', @description, 'repair support drone')
END

GO

---- Link repair support drone with it's template

DECLARE @turret_def INT
DECLARE @turret_template INT

SET @turret_def = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone')
SET @turret_template = (SELECT TOP 1 id FROM robottemplates WHERE name = 'repair_support_drone')

IF NOT EXISTS (SELECT 1 FROM robottemplaterelation WHERE definition = @turret_def AND templateid = @turret_template)
BEGIN
	INSERT INTO robottemplaterelation (definition, templateid, itemscoresum, raceid, note) VALUES
	(@turret_def, @turret_template, 0, 0, 'repair support drone')
END

GO

---- Set up aggregate fields for repair support drones as ammo

DECLARE @definition INT
DECLARE @field INT

---- Bandwidth usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5)
END

---- Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END

---- Repair amount

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20000)
END

GO

---- Set up aggregate fields for repair support drones

DECLARE @definition INT
DECLARE @field INT

--head

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_head')

---- CPU max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 175)
END

---- Locked targets max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locked_targets_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Locking range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END

---- Locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 12500)
END

---- Sensor strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'sensor_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Blob emission

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3)
END

---- Blob emission radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10)
END

---- Blob level low

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_low')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Blob level high

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

---- Detection strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 80)
END

---- Stealth strength

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END

-- chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_chassis')

---- Ammo reload time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'ammo_reload_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 840)
END

---- Core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 360)
END

---- Core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 120)
END

---- Powergrid max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END

---- Resists

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_chemical')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_explosive')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_kinetic')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

--

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'resist_thermal')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 45)
END

---- Signature radius

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4)
END

---- Reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'reactor_radiation')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 2.75)
END

---- Mine detection range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'mine_detection_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7)
END

-- leg

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_leg')

---- Slope

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'slope')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 56)
END

---- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3.05)
END

GO

---- Set up aggregate fields for extra remote controllers

DECLARE @definition INT
DECLARE @field INT

-- Tactical

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 150 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 85 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 77)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 77 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 75 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 68)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 68 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 83)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 83 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

-- Industrial

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 150 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 85 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 77)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 77 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 75 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 68)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 68 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 83)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 83 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

-- Support

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 150)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 150 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 85 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 77)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 77 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 100)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 100 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 75 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 68)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 68 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 83)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 83 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 90)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 90 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

GO

---- Add extra head slots for heavy mechs

UPDATE entitydefaults SET options = '#height=f0.15#slotFlags=4848,8,8,8,8,8' WHERE definitionname = 'def_mesmer_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_reward1'
UPDATE entitydefaults SET options = '#height=f0.01#slotFlags=4848,8,8,8,8,8,8' WHERE definitionname = 'def_seth_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_reward1'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4848,8,8,8,8,8,8' WHERE definitionname = 'def_gropho_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_reward1'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8  #height=f0.20  #max_locked_targets=f1  #max_targeting_range=f21.0  #sensor_strength=f100  #cpu=f450' WHERE definitionname = 'def_riveler_head'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8,8  #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_riveler_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8 #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_riveler_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8  #height=f0.20  #max_locked_targets=f1  #max_targeting_range=f21.0  #sensor_strength=f100  #cpu=f450' WHERE definitionname = 'def_symbiont_head'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8,8  #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_symbiont_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8 #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_symbiont_head_pr'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4848,8,8,8,8,8' WHERE definitionname = 'def_legatus_head'
UPDATE entitydefaults SET options = '#slotFlags=4C08,8,8,8  #height=f0.20' WHERE definitionname = 'def_metis_head'
UPDATE entitydefaults SET options = '#slotFlags=4888,8,8,8,8,8  #height=f0.10', mass=3000  WHERE definitionname = 'def_spectator_head'
UPDATE entitydefaults SET options = '#slotFlags=4888,8,8,8,8,8  #height=f0.10', mass=3000  WHERE definitionname = 'def_spectator_head_pr'

GO

---- Add new effect category

IF NOT EXISTS (SELECT 1 FROM effectcategories WHERE name = 'effcat_drone_amplification')
BEGIN
	INSERT INTO effectcategories (name, flag, maxlevel, note) VALUES
	('effcat_drone_amplification', 50, 1, 'Drone amplification')
END

GO

---- Add new effects

DECLARE @effectCategory BIGINT

SET @effectCategory = 562949953421312

IF NOT EXISTS (SELECT 1 FROM effects WHERE name = 'effect_drone_amplification')
BEGIN
	INSERT INTO effects (effectcategory, duration, name, description, note, isaura, auraradius, ispositive, display, saveable) VALUES
	(@effectCategory, 0, 'effect_drone_amplification', 'effect_drone_amplification_desc', 'Drone amplification effect', 0, 0, 1, 0, 0)
END

GO

---- Add new aggregate fields for drones

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_damage_modifier', 0,'drone_amplification_damage_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification damage bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_damage_modifier_modifier', 1,'drone_amplification_damage_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification damage bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_locking_time_modifier', 2,'drone_amplification_locking_time_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification locking time bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_locking_time_modifier_modifier', 1,'drone_amplification_locking_time_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification locking time bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_cycle_time_modifier', 2,'drone_amplification_cycle_time_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification cycle time bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_cycle_time_modifier_modifier', 1,'drone_amplification_cycle_time_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification cycle time bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_armor_max_modifier', 0,'drone_amplification_armor_max_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification armor max bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_armor_max_modifier_modifier', 1,'drone_amplification_armor_max_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification armor max bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_mining_amount_modifier', 0,'drone_amplification_mining_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification mining amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_mining_amount_modifier_modifier', 1,'drone_amplification_mining_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification mining amount bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_harvesting_amount_modifier', 0,'drone_amplification_harvesting_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification harvesting amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_harvesting_amount_modifier_modifier', 1,'drone_amplification_harvesting_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification harvesting amount bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_remote_repair_amount_modifier', 0,'drone_amplification_remote_repair_amount_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification remote repair amount bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_remote_repair_amount_modifier_modifier', 1,'drone_amplification_remote_repair_amount_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification remote repair amount bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_remote_repair_cycle_time_modifier', 2,'drone_amplification_remote_repair_cycle_time_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification remote repair cycle time bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_remote_repair_cycle_time_modifier_modifier', 1,'drone_amplification_remote_repair_cycle_time_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification remote repair cycle time bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_core_max_modifier', 0,'drone_amplification_core_max_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification core max bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_core_max_modifier_modifier', 1,'drone_amplification_core_max_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone amplification core max bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_core_recharge_time_modifier', 0,'drone_amplification_core_recharge_time_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification core recharge time bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_core_recharge_time_modifier_modifier', 1,'drone_amplification_core_recharge_time_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification core max bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_long_range_modifier', 0,'drone_amplification_long_range_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification long range bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_long_range_modifier_modifier', 1,'drone_amplification_long_range_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification long range bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_accuracy_modifier', 0,'drone_amplification_accuracy_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification accuracy bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_accuracy_modifier_modifier', 1,'drone_amplification_accuracy_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone amplification accuracy bonus extender')
END

GO

---- Link base value with modifier via category flag

DECLARE @category INT
DECLARE @base INT
DECLARE @modifier INT

-- assault remote controllers

-- damage

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- cycle

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- long range

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Accuracy

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- tactical remote controllers

-- damage

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_tactical_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- cycle

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- long range

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Accuracy

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- industrial remote controllers

-- mining amount

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- harvesting amount

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- support remote controllers

-- remote repair amount

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- remote repair cycle

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- all remote controllers

-- locking time

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_controllers')

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Armor max

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Core max

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Core recharge time

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

GO

---- Add new extensions category

IF NOT EXISTS (SELECT 1 FROM extensioncategories WHERE categoryname = 'extcat_drones_operations')
BEGIN
	INSERT INTO extensioncategories (extensioncategoryid, categoryname, hidden) VALUES
	(11, 'extcat_drones_operations', 0)
END

GO

---- Add new extensions

DECLARE @extensionsCategory INT
DECLARE @field INT

SET @extensionsCategory = (SELECT TOP 1 extensioncategoryid FROM extensioncategories WHERE categoryname = 'extcat_drones_operations')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_damage')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(380, 'ext_drone_amplification_damage', @extensionsCategory, 6, 'attributeA', 0.085, '', 180000, 1, 'ext_drone_amplification_damage_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.085 WHERE extensionname = 'ext_drone_amplification_damage'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_locking_time')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(381, 'ext_drone_amplification_locking_time', @extensionsCategory, 2, 'attributeA', -0.07, '', 20000, 1, 'ext_drone_amplification_locking_time_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.07 WHERE extensionname = 'ext_drone_amplification_locking_time'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_cycle_time')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(382, 'ext_drone_amplification_cycle_time', @extensionsCategory, 4, 'attributeA', -0.05, '', 80000, 1, 'ext_drone_amplification_cycle_time_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.05 WHERE extensionname = 'ext_drone_amplification_cycle_time'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_armor_max')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(383, 'ext_drone_amplification_armor_max', @extensionsCategory, 3, 'attributeA', 0.05, '', 45000, 1, 'ext_drone_amplification_armor_max_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.05 WHERE extensionname = 'ext_drone_amplification_armor_max'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_mining_amount')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(384, 'ext_drone_amplification_mining_amount', @extensionsCategory, 6, 'attributeA', 0.05, '', 180000, 1, 'ext_drone_amplification_mining_amount_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.05 WHERE extensionname = 'ext_drone_amplification_mining_amount'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_harvesting_amount')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(385, 'ext_drone_amplification_harvesting_amount', @extensionsCategory, 6, 'attributeA', 0.05, '', 180000, 1, 'ext_drone_amplification_harvesting_amount_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.05 WHERE extensionname = 'ext_drone_amplification_harvesting_amount'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_remote_repair_amount')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(386, 'ext_drone_amplification_remote_repair_amount', @extensionsCategory, 6, 'attributeA', 0.02, '', 180000, 1, 'ext_drone_amplification_remote_repair_amount_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.02 WHERE extensionname = 'ext_drone_amplification_remote_repair_amount'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_remote_repair_cycle_time')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(387, 'ext_drone_amplification_remote_repair_cycle_time', @extensionsCategory, 1, 'attributeA', -0.05, '', 5000, 1, 'ext_drone_amplification_remote_repair_cycle_time_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.05 WHERE extensionname = 'ext_drone_amplification_remote_repair_cycle_time'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_core_max')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(388, 'ext_drone_amplification_core_max', @extensionsCategory, 5, 'attributeA', 0.03, '', 125000, 1, 'ext_drone_amplification_core_max_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.03 WHERE extensionname = 'ext_drone_amplification_core_max'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_core_recharge_time')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(389, 'ext_drone_amplification_core_recharge_time', @extensionsCategory, 5, 'attributeA', -0.03, '', 125000, 1, 'ext_drone_amplification_core_recharge_time_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.03 WHERE extensionname = 'ext_drone_amplification_core_recharge_time'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_long_range')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(390, 'ext_drone_amplification_long_range', @extensionsCategory, 3, 'attributeA', 0.03, '', 45000, 1, 'ext_drone_amplification_long_range_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.03 WHERE extensionname = 'ext_drone_amplification_long_range'
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_accuracy')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(391, 'ext_drone_amplification_accuracy', @extensionsCategory, 3, 'attributeA', -0.03, '', 45000, 1, 'ext_drone_amplification_accuracy_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.03 WHERE extensionname = 'ext_drone_amplification_accuracy'
END

GO

---- Set up additional aggregate fields for remote controllers

DECLARE @definition INT
DECLARE @field INT

---- Tactical

---- Drone amplification damage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification long range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Assault

---- Drone amplification damage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_damage_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_cycle_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification long range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_long_range_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification accuracy

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_accuracy_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Industrial

---- Drone amplification locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification mining amount

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_mining_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification harvesting amount

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_harvesting_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Support

---- Drone amplification locking time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_locking_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_armor_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification remote repair amount

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_amount_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification remote repair cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_remote_repair_cycle_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification core recharge time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_core_recharge_time_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

GO

---- Revert obsolete extensions

DECLARE @extensionId INT
DECLARE @accountId INT

DECLARE procAccounts CURSOR LOCAL FORWARD_ONLY FAST_FORWARD FOR
SELECT accountID FROM accounts WHERE DATEDIFF(MONTH, lastloggedin, GETDATE()) < 4

OPEN procAccounts

FETCH NEXT FROM procAccounts INTO @accountId

WHILE @@FETCH_STATUS = 0
BEGIN
	-- Sentry turrets experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_sentry_turrets_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	-- Mining turrets experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_mining_turrets_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	-- Harvesting turrets experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_harvesting_turrets_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	-- Pelistal combat drones experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_pelistal_combat_drones_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	-- Nuimqol combat drones experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_nuimqol_combat_drones_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	-- Thelodica combat drones experience
	SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_thelodica_combat_drones_experience')
	EXEC dbo.extensionRevertV2 @accountID, @extensionId
	
	FETCH NEXT FROM procAccounts INTO @accountId
END

CLOSE procAccounts

DEALLOCATE procAccounts

---- Disable obsolete extensions

-- Sentry turrets experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_sentry_turrets_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

-- Mining turrets experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_mining_turrets_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

-- Harvesting turrets experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_harvesting_turrets_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

-- Pelistal combat drones experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_pelistal_combat_drones_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

-- Nuimqol combat drones experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_nuimqol_combat_drones_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

-- Thelodica combat drones experience

SET @extensionId = (SELECT TOP 1 extensionid FROM extensions WHERE extensionname = 'ext_thelodica_combat_drones_experience')

UPDATE extensions SET active = 0, hidden = 1 WHERE extensionid = @extensionId

GO

---- Hide obsolete categories

UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_mining_turret_units'
UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_harvesting_turret_units'
UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_nuimqol_combat_drones_units'
UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_pelistal_combat_drones_units'
UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_sentry_turret_units'
UPDATE categoryFlags SET hidden = 1 WHERE name = 'cf_thelodica_combat_drones_units'

GO

/*
cf_remote_controlled_turrets
cf_sentry_turret_units
cf_mining_turret_units
cf_harvesting_turret_units
cf_remote_controlled_combat_drones
cf_pelistal_combat_drones_units
cf_nuimqol_combat_drones_units
cf_thelodica_combat_drones_units

cf_combat_drones_units
cf_assault_drones_units
cf_industrial_drones_units
cf_support_drones_units
*/

PRINT N'09_Post_testing_changes_step2.sql';

---- Set up aggregate fields for drones

DECLARE @definition INT
DECLARE @field INT

---- Support drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

---- Harvesting industrial drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

---- Mining industrial drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1440)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1440 WHERE definition = @definition AND field = @field
END

---- Pelistal attack drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1368)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1368 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1368)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1368 WHERE definition = @definition AND field = @field
END

---- Thelodica attack drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1368)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1368 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1368)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1368 WHERE definition = @definition AND field = @field
END

---- Nuimqol attack drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1200 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1200)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1200 WHERE definition = @definition AND field = @field
END

---- Syndicate attack drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1500 WHERE definition = @definition AND field = @field
END

---- Pelistal assault drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

---- Thelodica assault drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4000 WHERE definition = @definition AND field = @field
END

---- Nuimqol assault drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3600)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3600 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 3600)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3600 WHERE definition = @definition AND field = @field
END

---- Syndicate assault drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_chassis')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4400)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4400 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

---- Armor max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 4400)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 4400 WHERE definition = @definition AND field = @field
END

GO

---- Add extra head slots for heavy mechs

UPDATE entitydefaults SET options = '#height=f0.15#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_mesmer_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8  #height=f0.15  #max_locked_targets=f3.00  #max_targeting_range=f35.00  #sensor_strength=f100.00  #cpu=f375.00' WHERE definitionname = 'def_mesmer_head_reward1'
UPDATE entitydefaults SET options = '#height=f0.01#slotFlags=4848,8,8,8,8,8,8' WHERE definitionname = 'def_seth_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8  #height=f0.01  #max_locked_targets=f3.00  #max_targeting_range=f37.50  #sensor_strength=f100.00  #cpu=f325.00' WHERE definitionname = 'def_seth_head_reward1'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4848,8,8,8,8,8,8' WHERE definitionname = 'def_gropho_head'
UPDATE entitydefaults SET options = '#slotFlags=4848,8,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8  #height=f0.20  #max_locked_targets=f3.00  #max_targeting_range=f32.50  #sensor_strength=f100.00  #cpu=f475.00' WHERE definitionname = 'def_gropho_head_reward1'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8  #height=f0.20  #max_locked_targets=f1  #max_targeting_range=f21.0  #sensor_strength=f100  #cpu=f450' WHERE definitionname = 'def_riveler_head'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8,8  #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_riveler_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8 #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_riveler_head_pr'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8  #height=f0.20  #max_locked_targets=f1  #max_targeting_range=f21.0  #sensor_strength=f100  #cpu=f450' WHERE definitionname = 'def_symbiont_head'
UPDATE entitydefaults SET options = '#slotFlags=4A08,8,8,8,8,8  #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_symbiont_head_mk2'
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8 #height=f0.20  #max_locked_targets=f1.00  #max_targeting_range=f21.00  #sensor_strength=f100.00  #cpu=f450.00' WHERE definitionname = 'def_symbiont_head_pr'
UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=4848,8,8,8,8,8' WHERE definitionname = 'def_legatus_head'
UPDATE entitydefaults SET options = '#slotFlags=4C08,8,8,8  #height=f0.20' WHERE definitionname = 'def_metis_head'
UPDATE entitydefaults SET options = '#slotFlags=4888,8,8,8,8,8  #height=f0.10', mass=3000  WHERE definitionname = 'def_spectator_head'
UPDATE entitydefaults SET options = '#slotFlags=4888,8,8,8,8,8  #height=f0.10', mass=3000  WHERE definitionname = 'def_spectator_head_pr'

GO

---- Rebalance Preachers

DECLARE @definition INT
DECLARE @field INT

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

UPDATE aggregatevalues SET value = 16 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

UPDATE aggregatevalues SET value = 8 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

UPDATE aggregatevalues SET value = 50 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

UPDATE aggregatevalues SET value = 16 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

UPDATE aggregatevalues SET value = 8 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

UPDATE aggregatevalues SET value = 50 WHERE definition = @definition AND field = @field

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

UPDATE aggregatevalues SET value = 16 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

UPDATE aggregatevalues SET value = 8 WHERE definition = @definition AND field = @field

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'nox_effect_enhancer_radius_modifier')

UPDATE aggregatevalues SET value = 50 WHERE definition = @definition AND field = @field

GO

GO

PRINT N'10_Post_testing_changes_step3.sql';

---- Craft

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_ammo_rcu_calibration_programs')

---- Create CT for assault drones

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_assault_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_assault_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_assault_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_assault_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

---- Create CT for attack drones

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_attack_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_nuimqol_attack_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_thelodica_attack_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_pelistal_attack_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

---- Create CT for industrial drones

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_mining_industrial_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_harvesting_industrial_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

---- Create CT for support drones

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit_cprg')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_repair_support_drone_unit_cprg', 1, 1024, @categoryFlags, NULL, NULL, 1, 0.01, 0.1, 0, 100, 'calibration_program_desc', 0, 1, 1)
END

GO

-- Set base CT efficiency

DECLARE @definition INT

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit_cprg')

DELETE FROM calibrationdefaults WHERE definition = @definition

INSERT INTO calibrationdefaults (definition, materialefficiency, timeefficiency) VALUES
(@definition, 50, 50)

GO

---- Set up decalibration and production time

DECLARE @categoryFlags BIGINT

----

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_tactical_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

--

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_remote_controllers')

IF NOT EXISTS (SELECT 1 FROM productiondecalibration WHERE categoryflag = @categoryFlags)
BEGIN
	INSERT INTO productiondecalibration (categoryflag, distorsionmin, distorsionmax, decrease) values
	(@categoryflags, 0.003, 0.005, 1)
END

IF NOT EXISTS (SELECT 1 FROM productionduration WHERE category = @categoryFlags)
BEGIN
	INSERT INTO productionduration (category, durationmodifier) values
	(@categoryFlags, 2)
END

----

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_assault_drones_units')

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

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_attack_drones_units')

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

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_industrial_drones_units')

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

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_support_drones_units')

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
DECLARE @gamma_pelistal_shards INT
DECLARE @gamma_nuimqol_shards INT
DECLARE @gamma_thelodica_shards INT

DECLARE @assault_remote_controller_t1 INT
DECLARE @assault_remote_controller_t2 INT
DECLARE @assault_remote_controller_t3 INT

DECLARE @tactical_remote_controller_t1 INT
DECLARE @tactical_remote_controller_t2 INT
DECLARE @tactical_remote_controller_t3 INT

DECLARE @industrial_remote_controller_t1 INT
DECLARE @industrial_remote_controller_t2 INT
DECLARE @industrial_remote_controller_t3 INT

DECLARE @support_remote_controller_t1 INT
DECLARE @support_remote_controller_t2 INT
DECLARE @support_remote_controller_t3 INT

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
SET @gamma_pelistal_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_pelistal')
SET @gamma_nuimqol_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_nuimqol')
SET @gamma_thelodica_shards = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_material_boss_gamma_syndicate')

SET @assault_remote_controller_t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')
SET @assault_remote_controller_t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')
SET @assault_remote_controller_t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

SET @tactical_remote_controller_t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @tactical_remote_controller_t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')
SET @tactical_remote_controller_t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

SET @industrial_remote_controller_t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @industrial_remote_controller_t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')
SET @industrial_remote_controller_t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

SET @support_remote_controller_t1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @support_remote_controller_t2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')
SET @support_remote_controller_t3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @phlobotil, 1000),
(@definition, @polynucleit, 1000),
(@definition, @polynitrocol, 1000),
(@definition, @axicoline, 1000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50),
(@definition, @flux, 10)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2000),
(@definition, @polynitrocol, 4000),
(@definition, @espitium, 200),
(@definition, @bryochite, 100),
(@definition, @flux, 20),
(@definition, @gamma_nuimqol_shards, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2000),
(@definition, @polynucleit, 4000),
(@definition, @espitium, 200),
(@definition, @bryochite, 100),
(@definition, @flux, 20),
(@definition, @gamma_thelodica_shards, 1)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 2000),
(@definition, @phlobotil, 4000),
(@definition, @espitium, 200),
(@definition, @bryochite, 100),
(@definition, @flux, 20),
(@definition, @gamma_pelistal_shards, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 500),
(@definition, @phlobotil, 500),
(@definition, @polynucleit, 500),
(@definition, @polynitrocol, 500),
(@definition, @axicoline, 500),
(@definition, @espitium, 50),
(@definition, @bryochite, 25)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @polynitrocol, 2000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @polynucleit, 2000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @phlobotil, 2000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @axicoline, 1000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @axicoline, 1000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 1000),
(@definition, @axicoline, 1000),
(@definition, @espitium, 100),
(@definition, @bryochite, 50)

----

-- Assault remote controller T1 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50)

-- Remote controller T2 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @assault_remote_controller_t1, 1)

-- Remote controller T2 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @assault_remote_controller_t1, 1),
(@definition, @common_basic_components, 30)

-- Remote controller T3 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @assault_remote_controller_t2, 1)

-- Remote controller T3 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @assault_remote_controller_t2, 1),
(@definition, @common_basic_components, 20),
(@definition, @common_advanced_components, 20)

-- Remote controller T4 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @assault_remote_controller_t3, 1)

-- Remote controller T4 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @assault_remote_controller_t3, 1),
(@definition, @common_basic_components, 15),
(@definition, @common_advanced_components, 30),
(@definition, @common_expert_components, 45)

----

-- Tactical remote controller T1 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50)

-- Remote controller T2 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @tactical_remote_controller_t1, 1)

-- Remote controller T2 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @tactical_remote_controller_t1, 1),
(@definition, @common_basic_components, 30)

-- Remote controller T3 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @tactical_remote_controller_t2, 1)

-- Remote controller T3 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @tactical_remote_controller_t2, 1),
(@definition, @common_basic_components, 20),
(@definition, @common_advanced_components, 20)

-- Remote controller T4 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @tactical_remote_controller_t3, 1)

-- Remote controller T4 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @tactical_remote_controller_t3, 1),
(@definition, @common_basic_components, 15),
(@definition, @common_advanced_components, 30),
(@definition, @common_expert_components, 45)

----

-- Industrial remote controller T1 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50)

-- Remote controller T2 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @industrial_remote_controller_t1, 1)

-- Remote controller T2 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @industrial_remote_controller_t1, 1),
(@definition, @common_basic_components, 30)

-- Remote controller T3 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @industrial_remote_controller_t2, 1)

-- Remote controller T3 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @industrial_remote_controller_t2, 1),
(@definition, @common_basic_components, 20),
(@definition, @common_advanced_components, 20)

-- Remote controller T4 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @industrial_remote_controller_t3, 1)

-- Remote controller T4 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @industrial_remote_controller_t3, 1),
(@definition, @common_basic_components, 15),
(@definition, @common_advanced_components, 30),
(@definition, @common_expert_components, 45)

----

-- Support remote controller T1 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50)

-- Remote controller T2 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @support_remote_controller_t1, 1)

-- Remote controller T2 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 50),
(@definition, @support_remote_controller_t1, 1),
(@definition, @common_basic_components, 30)

-- Remote controller T3 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @support_remote_controller_t2, 1)

-- Remote controller T3 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 175),
(@definition, @hydrobenol, 50),
(@definition, @support_remote_controller_t2, 1),
(@definition, @common_basic_components, 20),
(@definition, @common_advanced_components, 20)

-- Remote controller T4 --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @support_remote_controller_t3, 1)

-- Remote controller T4 prototype --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

DELETE FROM components WHERE definition = @definition

INSERT INTO components (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 50),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @bryochite, 50),
(@definition, @support_remote_controller_t3, 1),
(@definition, @common_basic_components, 15),
(@definition, @common_advanced_components, 30),
(@definition, @common_expert_components, 45)

GO

---- Research levels ----

DECLARE @definition INT
DECLARE @calibration INT

----

-- Assault Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

-- Assault Remote controller T2 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

-- Assault Remote controller T3 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

-- Assault Remote controller T4 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

--

-- Tactical Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

-- Tactical Remote controller T2 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

-- Tactical Remote controller T3 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

-- Tactical Remote controller T4 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

--

-- Industrial Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

-- Industrial Remote controller T2 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

-- Industrial Remote controller T3 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

-- Industrial Remote controller T4 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

--

-- Support Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

-- Support Remote controller T2 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 6, @calibration, 1)

-- Support Remote controller T3 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO itemresearchlevels (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 7, @calibration, 1)

-- Support Remote controller T4 prototype

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 8, @calibration, 1)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')
SET @calibration = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit_cprg')

DELETE FROM itemresearchlevels WHERE definition = @definition AND calibrationprogram = @calibration

INSERT INTO [itemresearchlevels] (definition, researchlevel, calibrationprogram, enabled) VALUES
(@definition, 5, @calibration, 1)

GO

----Research cost ----

DECLARE @definition INT
DECLARE @common INT
DECLARE @hightech INT
DECLARE @pelistal INT
DECLARE @nuimqol INT
DECLARE @thelodica INT
DECLARE @industrial INT

SET @common = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'common')
SET @hightech = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'hitech')
SET @pelistal = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'pelistal')
SET @nuimqol = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'nuimqol')
SET @thelodica = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'thelodica')
SET @industrial = (SELECT TOP 1 id FROM techtreepointtypes WHERE name = 'industrial')

-- Spectator

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 256000),
(@definition, @nuimqol, 100000),
(@definition, @thelodica, 100000),
(@definition, @pelistal, 100000)

-- Assault Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 25000)

-- Assault Remote controller T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 50000)

-- Assault Remote controller T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

-- Assault Remote controller T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 100000),
(@definition, @hightech, 50000)

-- Tactical Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 25000)

-- Tactical Remote controller T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 50000)

-- Tactical Remote controller T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

-- Tactical Remote controller T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 100000),
(@definition, @hightech, 50000)

-- Industrial Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 25000)

-- Industrial Remote controller T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 50000)

-- Industrial Remote controller T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

-- Industrial Remote controller T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 100000),
(@definition, @hightech, 50000)

-- Support Remote controller T1

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 25000)

-- Support Remote controller T2

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 50000)

-- Support Remote controller T3

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 75000)

-- Support Remote controller T4

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @common, 100000),
(@definition, @hightech, 50000)

-- Assault drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @common, 75000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @nuimqol, 75000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @thelodica, 75000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @pelistal, 75000)

-- Attack drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @common, 50000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @nuimqol, 50000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @thelodica, 50000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @pelistal, 50000)

-- Industrial drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @industrial, 50000)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @industrial, 50000)

-- Support drones

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

DELETE FROM techtreenodeprices WHERE definition = @definition

INSERT INTO [techtreenodeprices] (definition, pointtype, amount) VALUES
(@definition, @hightech, 40000),
(@definition, @industrial, 50000)

GO

---- Revert and reimburse Research

DECLARE @temp TABLE (definition INT, owner BIGINT)

INSERT INTO @temp (definition, owner) (

SELECT ed.definition, unl.owner FROM entitydefaults ed
LEFT JOIN techtreeunlockednodes unl
ON ed.definition = unl.definition
WHERE ed.definitionname in (
	'def_named3_thelodica_combat_drone_unit',
	'def_named2_thelodica_combat_drone_unit',
	'def_named1_thelodica_combat_drone_unit',
	'def_standart_thelodica_combat_drone_unit',
	'def_named3_nuimqol_combat_drone_unit',
	'def_named2_nuimqol_combat_drone_unit',
	'def_named1_nuimqol_combat_drone_unit',
	'def_standart_nuimqol_combat_drone_unit',
	'def_named3_pelistal_combat_drone_unit',
	'def_named2_pelistal_combat_drone_unit',
	'def_named1_pelistal_combat_drone_unit',
	'def_standart_pelistal_combat_drone_unit',
	'def_named3_harvesting_turret_unit',
	'def_named2_harvesting_turret_unit',
	'def_named1_harvesting_turret_unit',
	'def_standart_harvesting_turret_unit',
	'def_named3_mining_turret_unit',
	'def_named2_mining_turret_unit',
	'def_named1_mining_turret_unit',
	'def_standart_mining_turret_unit',
	'def_named3_sentry_turret_unit',
	'def_named2_sentry_turret_unit',
	'def_named1_sentry_turret_unit',
	'def_standart_sentry_turret_unit',
	'def_named3_assault_remote_controller',
	'def_named2_assault_remote_controller',
	'def_named1_assault_remote_controller',
	'def_standard_assault_remote_controller',
	'def_spectator_bot'
))

DECLARE @currentDefinition INT
DECLARE @currentOwner BIGINT

DECLARE curse CURSOR LOCAL FAST_FORWARD READ_ONLY FOR
	SELECT definition, owner FROM @temp

OPEN curse

FETCH NEXT FROM curse INTO @currentDefinition, @currentOwner

WHILE @@FETCH_STATUS = 0
BEGIN
	UPDATE tp
	SET tp.amount = tp.amount + np.amount
	FROM techtreepoints tp
	LEFT JOIN techtreenodeprices np
	ON tp.pointtype = np.pointtype
	WHERE tp.owner = @currentOwner
	AND np.definition = @currentDefinition

	DELETE FROM techtreeunlockednodes
	WHERE definition = @currentDefinition
	AND owner = @currentOwner

	FETCH NEXT FROM curse INTO @currentDefinition, @currentOwner
END

CLOSE curse

DEALLOCATE curse

---- Position in tech tree ----

DECLARE @parent INT
DECLARE @spectator INT
DECLARE @pupeteerT1 INT
DECLARE @pupeteerT2 INT
DECLARE @pupeteerT3 INT
DECLARE @pupeteerT4 INT
DECLARE @miningTurretT1 INT
DECLARE @miningTurretT2 INT
DECLARE @miningTurretT3 INT
DECLARE @miningTurretT4 INT
DECLARE @harvestingTurretT1 INT
DECLARE @harvestingTurretT2 INT
DECLARE @harvestingTurretT3 INT
DECLARE @harvestingTurretT4 INT
DECLARE @sentryTurretT1 INT
DECLARE @sentryTurretT2 INT
DECLARE @sentryTurretT3 INT
DECLARE @sentryTurretT4 INT
DECLARE @pelistalDroneT1 INT
DECLARE @pelistalDroneT2 INT
DECLARE @pelistalDroneT3 INT
DECLARE @pelistalDroneT4 INT
DECLARE @nuimqolDroneT1 INT
DECLARE @nuimqolDroneT2 INT
DECLARE @nuimqolDroneT3 INT
DECLARE @nuimqolDroneT4 INT
DECLARE @thelodicaDroneT1 INT
DECLARE @thelodicaDroneT2 INT
DECLARE @thelodicaDroneT3 INT
DECLARE @thelodicaDroneT4 INT

DECLARE @assaultRcmT1 INT
DECLARE @assaultRcmT2 INT
DECLARE @assaultRcmT3 INT
DECLARE @assaultRcmT4 INT

DECLARE @tacticalRcmT1 INT
DECLARE @tacticalRcmT2 INT
DECLARE @tacticalRcmT3 INT
DECLARE @tacticalRcmT4 INT

DECLARE @industrialRcmT1 INT
DECLARE @industrialRcmT2 INT
DECLARE @industrialRcmT3 INT
DECLARE @industrialRcmT4 INT

DECLARE @supportRcmT1 INT
DECLARE @supportRcmT2 INT
DECLARE @supportRcmT3 INT
DECLARE @supportRcmT4 INT

DECLARE @syndicateAssaultDrone INT
DECLARE @nuimqolAssaultDrone INT
DECLARE @thelodicaAssaultDrone INT
DECLARE @pelistalAssaultDrone INT

DECLARE @syndicateAttackDrone INT
DECLARE @nuimqolAttackDrone INT
DECLARE @thelodicaAttackDrone INT
DECLARE @pelistalAttackDrone INT

DECLARE @miningIndustrialDrone INT
DECLARE @harvestingIndustrialDrone INT

DECLARE @repairSupportDrone INT

DECLARE @group INT

SET @parent = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_cpu_upgrade')
SET @spectator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_bot')
SET @pupeteerT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_remote_controller')
SET @pupeteerT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_controller')
SET @pupeteerT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_controller')
SET @pupeteerT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_controller')
SET @miningTurretT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_mining_turret_unit')
SET @miningTurretT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_mining_turret_unit')
SET @miningTurretT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_mining_turret_unit')
SET @miningTurretT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_mining_turret_unit')
SET @harvestingTurretT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_harvesting_turret_unit')
SET @harvestingTurretT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_harvesting_turret_unit')
SET @harvestingTurretT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_harvesting_turret_unit')
SET @harvestingTurretT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_harvesting_turret_unit')
SET @sentryTurretT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_sentry_turret_unit')
SET @sentryTurretT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sentry_turret_unit')
SET @sentryTurretT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_sentry_turret_unit')
SET @sentryTurretT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sentry_turret_unit')
SET @pelistalDroneT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_pelistal_combat_drone_unit')
SET @pelistalDroneT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_pelistal_combat_drone_unit')
SET @pelistalDroneT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_pelistal_combat_drone_unit')
SET @pelistalDroneT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_pelistal_combat_drone_unit')
SET @nuimqolDroneT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_nuimqol_combat_drone_unit')
SET @nuimqolDroneT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_nuimqol_combat_drone_unit')
SET @nuimqolDroneT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_nuimqol_combat_drone_unit')
SET @nuimqolDroneT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_nuimqol_combat_drone_unit')
SET @thelodicaDroneT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_thelodica_combat_drone_unit')
SET @thelodicaDroneT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_thelodica_combat_drone_unit')
SET @thelodicaDroneT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_thelodica_combat_drone_unit')
SET @thelodicaDroneT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_thelodica_combat_drone_unit')

SET @assaultRcmT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')
SET @assaultRcmT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')
SET @assaultRcmT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')
SET @assaultRcmT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

SET @tacticalRcmT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @tacticalRcmT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')
SET @tacticalRcmT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')
SET @tacticalRcmT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

SET @industrialRcmT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @industrialRcmT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')
SET @industrialRcmT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')
SET @industrialRcmT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

SET @supportRcmT1 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @supportRcmT2 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')
SET @supportRcmT3 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')
SET @supportRcmT4 = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

SET @syndicateAssaultDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')
SET @nuimqolAssaultDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')
SET @thelodicaAssaultDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')
SET @pelistalAssaultDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

SET @syndicateAttackDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')
SET @nuimqolAttackDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')
SET @thelodicaAttackDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')
SET @pelistalAttackDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

SET @miningIndustrialDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')
SET @harvestingIndustrialDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

SET @repairSupportDrone = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit')

SET @group = (SELECT TOP 1 id FROM [techtreegroups] WHERE name = 'common2')

DELETE FROM techtree WHERE childdefinition IN (@spectator,@pupeteerT1,@pupeteerT2,@pupeteerT3,@pupeteerT4,@miningTurretT1,@miningTurretT2,@miningTurretT3,@miningTurretT4,
@harvestingTurretT1,@harvestingTurretT2,@harvestingTurretT3,@harvestingTurretT4,@sentryTurretT1,@sentryTurretT2,@sentryTurretT3,@sentryTurretT4,
@pelistalDroneT1,@pelistalDroneT2,@pelistalDroneT3,@pelistalDroneT4,@nuimqolDroneT1,@nuimqolDroneT2,@nuimqolDroneT3,@nuimqolDroneT4,
@thelodicaDroneT1,@thelodicaDroneT2,@thelodicaDroneT3,@thelodicaDroneT4,
@assaultRcmT1, @assaultRcmT2, @assaultRcmT3, @assaultRcmT4, @tacticalRcmT1, @tacticalRcmT2, @tacticalRcmT3, @tacticalRcmT4,
@industrialRcmT1, @industrialRcmT2, @industrialRcmT3, @industrialRcmT4, @supportRcmT1, @supportRcmT2, @supportRcmT3, @supportRcmT4,
@syndicateAssaultDrone, @nuimqolAssaultDrone, @thelodicaAssaultDrone, @pelistalAssaultDrone, @syndicateAttackDrone, @nuimqolAttackDrone, @thelodicaAttackDrone,
@pelistalAttackDrone, @miningIndustrialDrone, @harvestingIndustrialDrone, @repairSupportDrone)

INSERT INTO [techtree] (parentdefinition, childdefinition, groupID, x, y, enablerextensionid) VALUES
	(@parent, @assaultRcmT1, @group, 1, 20, NULL),
	(@assaultRcmT1, @assaultRcmT2, @group, 2, 20, NULL),
	(@assaultRcmT2, @assaultRcmT3, @group, 3, 20, NULL),
	(@assaultRcmT3, @assaultRcmT4, @group, 4, 20, NULL),
	
	(@assaultRcmT1, @spectator, @group, 2, 19, NULL),
	
	(@assaultRcmT1, @syndicateAssaultDrone, @group, 2, 21, NULL),
	(@syndicateAssaultDrone, @nuimqolAssaultDrone, @group, 3, 22, NULL),
	(@syndicateAssaultDrone, @thelodicaAssaultDrone, @group, 3, 23, NULL),
	(@syndicateAssaultDrone, @pelistalAssaultDrone, @group, 3, 24, NULL),
	
	(@parent, @tacticalRcmT1, @group, 1, 25, NULL),
	(@tacticalRcmT1, @tacticalRcmT2, @group, 2, 25, NULL),
	(@tacticalRcmT2, @tacticalRcmT3, @group, 3, 25, NULL),
	(@tacticalRcmT3, @tacticalRcmT4, @group, 4, 25, NULL),
	
	(@tacticalRcmT1, @syndicateAttackDrone, @group, 2, 26, NULL),
	(@syndicateAttackDrone, @nuimqolAttackDrone, @group, 3, 27, NULL),
	(@syndicateAttackDrone, @thelodicaAttackDrone, @group, 3, 28, NULL),
	(@syndicateAttackDrone, @pelistalAttackDrone, @group, 3, 29, NULL),
	
	(@parent, @industrialRcmT1, @group, 1, 30, NULL),
	(@industrialRcmT1, @industrialRcmT2, @group, 2, 30, NULL),
	(@industrialRcmT2, @industrialRcmT3, @group, 3, 30, NULL),
	(@industrialRcmT3, @industrialRcmT4, @group, 4, 30, NULL),
	
	(@industrialRcmT1, @miningIndustrialDrone, @group, 2, 31, NULL),
	(@industrialRcmT1, @harvestingIndustrialDrone, @group, 2, 32, NULL),
	
	(@parent, @supportRcmT1, @group, 1, 33, NULL),
	(@supportRcmT1, @supportRcmT2, @group, 2, 33, NULL),
	(@supportRcmT2, @supportRcmT3, @group, 3, 33, NULL),
	(@supportRcmT3, @supportRcmT4, @group, 4, 33, NULL),
	
	(@supportRcmT1, @repairSupportDrone, @group, 2, 34, NULL)

GO

---- Nerf Preachers Scorchers

DECLARE @targetDefinition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'electric_damage_modifier')

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_vagabond')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

--

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_zenith')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

--

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_cultist_preacher_ictus')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

GO

---- Increase drones extensions complexity

UPDATE extensions SET rank = 9, price = 405000 WHERE extensionname = 'ext_drone_amplification_damage'
UPDATE extensions SET rank = 5, price = 125000 WHERE extensionname = 'ext_drone_amplification_locking_time'
UPDATE extensions SET rank = 7, price = 245000 WHERE extensionname = 'ext_drone_amplification_cycle_time'
UPDATE extensions SET rank = 6, price = 180000 WHERE extensionname = 'ext_drone_amplification_armor_max'
UPDATE extensions SET rank = 9, price = 405000 WHERE extensionname = 'ext_drone_amplification_mining_amount'
UPDATE extensions SET rank = 9, price = 405000 WHERE extensionname = 'ext_drone_amplification_harvesting_amount'
UPDATE extensions SET rank = 9, price = 405000 WHERE extensionname = 'ext_drone_amplification_remote_repair_amount'
UPDATE extensions SET rank = 4, price = 80000 WHERE extensionname = 'ext_drone_amplification_remote_repair_cycle_time'
UPDATE extensions SET rank = 8, price = 320000 WHERE extensionname = 'ext_drone_amplification_core_max'
UPDATE extensions SET rank = 8, price = 320000 WHERE extensionname = 'ext_drone_amplification_core_recharge_time'
UPDATE extensions SET rank = 6, price = 180000 WHERE extensionname = 'ext_drone_amplification_long_range'
UPDATE extensions SET rank = 6, price = 180000 WHERE extensionname = 'ext_drone_amplification_accuracy'

GO

---- Add new aggregate fields for drones

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_speed_max_modifier', 0,'drone_amplification_speed_max_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone max speed bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_speed_max_modifier_modifier', 1,'drone_amplification_speed_max_modifier_modifier_unit', 100, 0, 6, 0, 1, 1, 'Drone max speed bonus extender')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_reactor_radiation_modifier', 0,'drone_amplification_reactor_radiation_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone reactor stability bonus')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('drone_amplification_reactor_radiation_modifier_modifier', 1,'drone_amplification_reactor_radiation_modifier_modifier_unit', 100, 0, 6, 0, 0, 1, 'Drone reactor stability bonus extender')
END

GO

---- Link base value with modifier via category flag

DECLARE @category INT
DECLARE @base INT
DECLARE @modifier INT

-- all remote controllers

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_controllers')

-- Speed max

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Reactor stability

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

GO

---- Add new extensions

DECLARE @extensionsCategory INT
DECLARE @field INT

SET @extensionsCategory = (SELECT TOP 1 extensioncategoryid FROM extensioncategories WHERE categoryname = 'extcat_drones_operations')

-- Speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_speed_max')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(392, 'ext_drone_amplification_speed_max', @extensionsCategory, 6, 'attributeA', 0.05, '', 180000, 1, 'ext_drone_amplification_speed_max_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = 0.05 WHERE extensionname = 'ext_drone_amplification_speed_max'
END

-- Reactor stability

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_drone_amplification_reactor_radiation')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(393, 'ext_drone_amplification_reactor_radiation', @extensionsCategory, 9, 'attributeA', -0.03, '', 405000, 1, 'ext_drone_amplification_reactor_radiation_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.03 WHERE extensionname = 'ext_drone_amplification_reactor_radiation'
END

GO

---- Set up additional aggregate fields for remote controllers

DECLARE @definition INT
DECLARE @field INT

---- Tactical

---- Drone amplification speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Assault

---- Drone amplification speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Industrial

---- Drone amplification speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Support

---- Drone amplification speed max

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_speed_max_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

---- Drone amplification reactor radiation

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'drone_amplification_reactor_radiation_modifier')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 1)
END

GO

---- Set up aggregate fields for remote controllers

DECLARE @definition INT
DECLARE @field INT

-- Assault

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 250)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 250 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 225)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 225 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 214)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 214 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 270)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 270 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 257)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 257 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 285)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 285 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 271)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 271 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_assault_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 57)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 57 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 64)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 64 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 70 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

-- Tactical

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 125)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 125 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 113)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 113 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 107)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 107 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 129)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 129 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 143)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 143 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 136)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 136 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_tactical_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 57)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 57 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 64)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 64 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 70 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

-- Industrial

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 125)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 125 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 113)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 113 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 107)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 107 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 129)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 129 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 143)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 143 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 136)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 136 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_industrial_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 57)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 57 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 64)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 64 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 70 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

-- Support

---- CPU usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 125)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 125 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 113)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 113 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 107)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 107 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 129)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 129 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 143)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 143 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 136)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 136 WHERE definition = @definition AND field = @field
END

---- Reactor usage

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_support_remote_controller')
SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 65)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 65 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 60)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 60 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 57)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 57 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 64)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 64 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 70)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 70 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 67)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 67 WHERE definition = @definition AND field = @field
END

GO

---- Add missing aggregate fields to new prototypes

DECLARE @definition INT
DECLARE @field INT

-- Tactical

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

-- Industrial

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

-- Support

---- Max bandwidth

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_bandwidth_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 0)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0 WHERE definition = @definition AND field = @field
END

---- Accumulator usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_usage')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 135)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 135 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 165)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 165 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 180)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 180 WHERE definition = @definition AND field = @field
END

---- Cycle time

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cycle_time')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 10000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 7500)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2500 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 5000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2000 WHERE definition = @definition AND field = @field
END

---- Optimal range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 20 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

---- Rcu Lifetime

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_lifetime')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 300000)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 300000 WHERE definition = @definition AND field = @field
END

---- Drones operational range

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'remote_control_operational_range')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 30)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 30 WHERE definition = @definition AND field = @field
END

GO

---- Add new aggregate fields for RCM

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('cpu_usage_remote_controller_modifier', 0,'cpu_usage_remote_controller_modifier_unit', 100, -100, 1, 0, 0, 1, 'RCM CPU usage')
END

IF NOT EXISTS (SELECT 1 FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')
BEGIN
	INSERT INTO aggregatefields (name, formula, measurementunit, measurementmultiplier, measurementoffset, category, digits, moreisbetter, usedinconfig, note) VALUES
	('powergrid_usage_remote_controller_modifier', 0,'powergrid_usage_remote_controller_modifier_unit', 100, -100, 1, 0, 0, 1, 'RCM Powergrid usage')
END

GO

---- Add new extensions to manage CPU and Powergrid usage

DECLARE @extensionsCategory INT
DECLARE @field INT

SET @extensionsCategory = (SELECT TOP 1 extensioncategoryid FROM extensioncategories WHERE categoryname = 'extcat_remote_command')

-- CPU usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_rcm_cpu_upgrade')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(394, 'ext_rcm_cpu_upgrade', @extensionsCategory, 4, 'attributeD', -0.03, 'attributeB', 80000, 1, 'ext_rcm_cpu_upgrade_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.03 WHERE extensionname = 'ext_rcm_cpu_upgrade'
END

-- Powergrid usage

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

IF NOT EXISTS (SELECT 1 FROM extensions WHERE extensionname = 'ext_rcm_powergrid_upgrade')
BEGIN
	INSERT INTO extensions (extensionid, extensionname, category, rank, learningattributeprimary, bonus, note, price, active, description, targetpropertyID, effectenhancer, hidden, freezelimit) VALUES
	(395, 'ext_rcm_powergrid_upgrade', @extensionsCategory, 4, 'attributeD', -0.03, 'attributeB', 80000, 1, 'ext_rcm_powergrid_upgrade_desc', @field, 0, 0, 4)
END
ELSE
BEGIN
	UPDATE extensions SET bonus = -0.03 WHERE extensionname = 'ext_drone_amplification_reactor_radiation'
END

---- Set up aggregate modifiers for remote controllers

DECLARE @destinationCategoryFlag INT
DECLARE @baseField INT
DECLARE @modifierField INT

-- Assault

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_assault_remote_controllers')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- Tactical

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_tactical_remote_controllers')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- Industrial

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_industrial_remote_controllers')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

-- Support

SET @destinationCategoryFlag = (SELECT TOP 1 value FROM categoryflags WHERE name = 'cf_support_remote_controllers')

DELETE FROM aggregatemodifiers WHERE categoryflag = @destinationCategoryFlag

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

SET @baseField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifierField = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

INSERT INTO aggregatemodifiers (categoryflag, basefield, modifierfield) VALUES
(@destinationCategoryFlag, @baseField, @modifierField)

GO

---- Link base value with modifier via category flag

DECLARE @category INT
DECLARE @base INT
DECLARE @modifier INT

-- all remote controllers

SET @category = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_remote_controllers')

-- CPU usage

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_usage_remote_controller_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

-- Reactor stability

SET @base = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage')
SET @modifier = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_usage_remote_controller_modifier')

IF NOT EXISTS (SELECT 1 FROM [modulepropertymodifiers] WHERE categoryflags = @category AND baseField = @base AND modifierField = @modifier)
BEGIN
	INSERT INTO [modulepropertymodifiers] (categoryflags, baseField, modifierField) VALUES
	(@category, @base, @modifier)
END

GO

---- Stop running Production

UPDATE productionlines SET runningproductionid = NULL

DELETE FROM runningproduction

GO

---- Replace old stuff with new analogue

DECLARE @sourceDefinition INT
DECLARE @targetDefinition INT

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_sentry_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sentry_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_sentry_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sentry_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_mining_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_mining_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_mining_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_mining_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_harvesting_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_harvesting_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_harvesting_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_harvesting_turret_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_pelistal_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_pelistal_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_pelistal_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_pelistal_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_nuimqol_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_nuimqol_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_nuimqol_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_nuimqol_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standart_thelodica_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_thelodica_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_thelodica_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

--

SET @sourceDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_thelodica_combat_drone_unit')
SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit')

UPDATE entities SET definition = @targetDefinition WHERE definition = @sourceDefinition

GO

PRINT N'11_Final_changes.sql';

UPDATE npcpresence SET roamingrespawnseconds = 10800, dynamiclifetime = 10800 WHERE name IN (
'roamer_cultists_z6',
'roamer_cultists_z7',
'roamer_cultists_z1')

UPDATE nf SET nf.respawnseconds = 10800 FROM npcflock nf INNER JOIN npcpresence np ON np.id = nf.presenceid
WHERE np.name IN (
'roamer_cultists_z6',
'roamer_cultists_z7',
'roamer_cultists_z1')

UPDATE npcinterzonegroup SET respawnTime = 10800 WHERE NAME = 'alpha3_cultist_preachers_izgroup'

GO

PRINT N'12_32p1_Fix_RCM.sql';

DECLARE @prototypeId INT
DECLARE @itemId INT

-- T2

-- Assault

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_assault_remote_controller_pr')

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Industrial

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_industrial_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Support

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_support_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Tactical

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_tactical_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- T3

-- Assault

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_assault_remote_controller_pr')

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Industrial

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_industrial_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Support

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_support_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Tactical

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_tactical_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- T4

-- Assault

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_assault_remote_controller_pr')

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Industrial

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_industrial_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Support

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_support_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

-- Tactical

SET @prototypeId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller_pr')
SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_tactical_remote_controller')

DELETE FROM prototypes WHERE definition = @itemId OR prototype = @prototypeId
INSERT INTO prototypes (definition, prototype) VALUES (@itemId, @prototypeId)

UPDATE entitydefaults SET tiertype = 2 WHERE definition = @prototypeId

GO

-- Remove tiers from ammo CT

DECLARE @itemId INT

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_assault_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_attack_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mining_industrial_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_harvesting_industrial_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_repair_support_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_assault_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_nuimqol_attack_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_assault_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pelistal_attack_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_assault_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

--

SET @itemId = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_thelodica_attack_drone_unit_cprg')

UPDATE entitydefaults SET tiertype = NULL, tierlevel = NULL WHERE definition = @itemId

GO

PRINT N'Completed';