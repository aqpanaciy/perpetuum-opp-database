USE perpetuumsa;

GO

---- Remove t0 ep boosters from Daoden I said!

DECLARE @npc INT
DECLARE @loot INT

DECLARE @definition INT
DECLARE @itemshop_preset INT

SET @itemshop_preset = (SELECT TOP 1 id FROM itemshoppresets WHERE name = 'tm_preset_pve')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_server_wide_ep_booster_t0')

DELETE FROM itemshop WHERE targetdefinition = @definition AND presetid = @itemshop_preset

GO

---- Fix ep boosters description

UPDATE entitydefaults SET descriptiontoken = 'def_server_wide_ep_booster_desc' WHERE definitionname in (
	'def_server_wide_ep_booster_t0',
	'def_server_wide_ep_booster_t1',
	'def_server_wide_ep_booster_t2',
	'def_server_wide_ep_booster_t3')
	
GO

-- Fix mass-harvestig ammo production duration and decalibtarion

DECLARE @categoryFlags INT

SET @categoryFlags = (SELECT TOP 1 value FROM categoryFlags WHERE name = 'cf_mass_harvesting_ammo')

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

---- Set up aggregate fields for Beholder

DECLARE @definition INT
DECLARE @field INT

-- Head

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_level_high')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head')

UPDATE aggregatevalues SET value = 155 WHERE definition = @definition AND field = @field

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_head_pr')

UPDATE aggregatevalues SET value = 155 WHERE definition = @definition AND field = @field

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @definition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@definition, @field, 155)
END

GO

---- Fix volume for Spectators

UPDATE entitydefaults SET volume = 23 WHERE definitionname in (
	'def_spectator_bot_pr',
	'def_spectator_bot')
	
GO

---- Increase bandwidth to medium and large terminals for 25%

DECLARE @definition INT

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_medium_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 37500 WHERE definition = @definition

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_pbs_docking_base_large_capsule_pr')

UPDATE definitionconfig SET bandwidthcapacity = 67500 WHERE definition = @definition

GO

---- Remove dev_dhdt

UPDATE entitydefaults SET enabled = 0 WHERE definitionname = 'def_dhdt'

GO

---- Decrease energy fields but increase energy in them by 1/3

DECLARE @zoneid INT
DECLARE @mineralid INT

SET @mineralid = (SELECT TOP 1 idx FROM minerals WHERE name = 'energymineral')

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z106')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z107')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z108')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z109')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z111')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z112')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z113')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z115')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z116')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z117')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z118')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z120')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z121')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z122')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z123')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z124')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z125')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z126')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z127')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z128')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z129')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z130')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z132')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z133')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z134')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z135')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z136')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z137')

UPDATE mineralconfigs SET maxnodes = 7, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z138')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z139')

UPDATE mineralconfigs SET maxnodes = 8, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

--

SET @zoneid = (SELECT TOP 1 id FROM zones WHERE name = 'zone_gamma_z140')

UPDATE mineralconfigs SET maxnodes = 10, maxtilespernode = 300 WHERE zoneid = @zoneid AND materialtype = @mineralid

GO

---- Fix ghost bases

DELETE FROM entities WHERE eid = 8672957799981290018
DELETE FROM entities WHERE eid = 7135039852722197766
DELETE FROM entities WHERE eid = 5606203623296356816

DELETE FROM entities WHERE eid = 4614988393035807463
DELETE FROM entities WHERE eid = 8107379312386187517
DELETE FROM entities WHERE eid = 7974584861862392349
DELETE FROM entities WHERE eid = 8901489937581974613
DELETE FROM entities WHERE eid = 8394791714481758393

DELETE FROM entities WHERE eid = 7946028597290312044

----

DELETE FROM entities WHERE eid = 4822305416562049174

DELETE FROM entities WHERE eid = 4911644923930124201

DELETE FROM entities WHERE eid = 5230550472600805402

DELETE FROM entities WHERE eid = 8113007424844366194
DELETE FROM entities WHERE eid = 9150636073543254054
DELETE FROM entities WHERE eid = 5333350848329355092

----

GO

---- Fix Beholder hit surface

DECLARE @definition INT
DECLARE @field INT

-- Chassis

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_beholder_chassis')

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

UPDATE aggregatevalues SET value = 5 WHERE definition = @definition AND field = @field

GO