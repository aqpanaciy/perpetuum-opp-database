USE perpetuumsa;

GO

---- Make presents purchasable

UPDATE entitydefaults SET purchasable = 1 WHERE definitionname = 'def_anniversary_package'

GO

---- Place presents to Hershfield

DECLARE @marketeid BIGINT;
DECLARE @vendoreid BIGINT;

SELECT @marketeid = eid 
FROM entities 
WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

SELECT @vendoreid = vendorEID 
FROM dbo.vendors 
WHERE marketEID = @marketeid;

INSERT INTO marketitems (marketeid, itemdefinition, submittereid, submitted, duration, isSell, price, quantity, usecorporationwallet, isvendoritem) VALUES
(@marketeid, @itemDefinition, @vendoreid, getdate(), 0, 1, 40000000, -1, 0, 1)

GO

---- Extend gift list

DECLARE @tempTable TABLE (definition INT, minquantity INT, maxquantity INT)

INSERT INTO @tempTable (definition, minquantity, maxquantity) VALUES
(174, 600000, 1000000), --def_epriton
(2909, 600000, 1000000), --def_electroplant_fruit
(5843, 600000, 1000000), --def_fluxore
(5577, 1, 1), --def_paint_black
(5578, 1, 1), --def_paint_blue_dark
(5579, 1, 1), --def_paint_blue
(5580, 1, 1), --def_paint_green_dark
(5581, 1, 1), --def_paint_teal
(5582, 1, 1), --def_paint_green
(5583, 1, 1), --def_paint_cyan
(5584, 1, 1), --def_paint_red_dark
(5585, 1, 1), --def_paint_purple
(5586, 1, 1), --def_paint_gray
(5587, 1, 1), --def_paint_red
(5588, 1, 1), --def_paint_magenta
(5589, 1, 1), --def_paint_orange
(5590, 1, 1), --def_paint_yellow
(5591, 1, 1), --def_paint_white
(8559, 1, 1), --def_paint_maroon_dark
(5686, 1, 1), --def_boost_ep_t0
(5677, 1, 1), --def_boost_ep_t1
(5678, 1, 1), --def_boost_ep_t2
(5679, 1, 1), --def_boost_ep_t3
(8851, 1, 1), --def_server_wide_ep_booster_t0
(8852, 1, 1), --def_server_wide_ep_booster_t1
(8853, 1, 1), --def_server_wide_ep_booster_t2
(8854, 1, 1), --def_server_wide_ep_booster_t3
(8304, 1, 1), --def_respec_token
(8305, 1, 1), --def_spark_teleport_device_hersh
(8306, 1, 1), --def_spark_teleport_device_nv
(8787, 1, 1), --def_spark_teleport_device_daoden
(8318, 1, 1), --def_named3_landmine_detector
(8308, 5, 10), --def_light_landmine_capsule
(8310, 5, 10), --def_medium_landmine_capsule
(8312, 5, 10), --def_heavy_landmine_capsule
(6117, 1500, 2000), --def_ammo_cruisemissile_rewa
(6118, 1500, 2000), --def_ammo_longrange_cruisemissile_rewa
(6119, 1500, 2000), --def_ammo_large_lasercrystal_rewa	
(6120, 1500, 2000),	--def_ammo_large_railgun_rewa
(3271, 10000, 20000), ----def_common_reactor_plasma
(3272, 10000, 20000), ----def_pelistal_reactor_plasma
(3273, 10000, 20000), ----def_nuimqol_reactor_plasma
(3274, 10000, 20000), ----def_thelodica_reactor_plasma
(4430, 1, 1), ----def_anniversary_package
(5598, 1, 1), ----def_arbalest_mk2_C_CT_capsule
(5601, 1, 1), ----def_argano_mk2_C_CT_capsule
(5604, 1, 1), ----def_artemis_mk2_C_CT_capsule
(5607, 1, 1), ----def_baphomet_mk2_C_CT_capsule
(5610, 1, 1), ----def_cameleon_mk2_C_CT_capsule
(5613, 1, 1), ----def_castel_mk2_C_CT_capsule
(5616, 1, 1), ----def_gargoyle_mk2_C_CT_capsule
(5619, 1, 1), ----def_gropho_mk2_C_CT_capsule
(5622, 1, 1), ----def_ictus_mk2_C_CT_capsule
(5625, 1, 1), ----def_intakt_mk2_C_CT_capsule
(5628, 1, 1), ----def_kain_mk2_C_CT_capsule
(5631, 1, 1), ----def_laird_mk2_C_CT_capsule
(5634, 1, 1), ----def_lithus_mk2_C_CT_capsule
(5637, 1, 1), ----def_mesmer_mk2_C_CT_capsule
(5640, 1, 1), ----def_prometheus_mk2_C_CT_capsule
(5643, 1, 1), ----def_riveler_mk2_C_CT_capsule
(5646, 1, 1), ----def_scarab_mk2_C_CT_capsule
(5649, 1, 1), ----def_sequer_mk2_C_CT_capsule
(5652, 1, 1), ----def_seth_mk2_C_CT_capsule
(5655, 1, 1), ----def_symbiont_mk2_C_CT_capsule
(5658, 1, 1), ----def_termis_mk2_C_CT_capsule
(5661, 1, 1), ----def_troiar_mk2_C_CT_capsule
(5664, 1, 1), ----def_tyrannos_mk2_C_CT_capsule
(5667, 1, 1), ----def_vagabond_mk2_C_CT_capsule
(5670, 1, 1), ----def_waspish_mk2_C_CT_capsule
(5673, 1, 1), ----def_yagel_mk2_C_CT_capsule
(5676, 1, 1), ----def_zenith_mk2_C_CT_capsule
(8545, 1, 1), ----def_elite2_cultist_scorcher
(8546, 1, 1), ----def_elite2_cultist_nox_shield_negator
(8547, 1, 1), ----def_elite2_cultist_nox_repair_negator
(8548, 1, 1), ----def_elite2_cultist_nox_teleport_negator
(8565, 1, 1), ----def_named3_tactical_remote_controller
(8576, 1, 1), ----def_named3_industrial_remote_controller
(8587, 1, 1), ----def_named3_support_remote_controller
(8327, 1, 1), ----def_named3_assault_remote_controller
(8598, 5, 10), ----def_syndicate_assault_drone_unit
(8604, 5, 10), ----def_nuimqol_assault_drone_unit
(8610, 5, 10), ----def_thelodica_assault_drone_unit
(8616, 5, 10), ----def_pelistal_assault_drone_unit
(8622, 5, 10), ----def_syndicate_attack_drone_unit
(8628, 5, 10), ----def_nuimqol_attack_drone_unit
(8634, 5, 10), ----def_thelodica_attack_drone_unit
(8640, 5, 10), ----def_pelistal_attack_drone_unit
(8646, 5, 10), ----def_mining_industrial_drone_unit
(8652, 5, 10), ----def_harvesting_industrial_drone_unit
(8658, 5, 10), ----def_repair_support_drone_unit
(8686, 1, 1), ----def_named3_large_driller
(8796, 1, 1), ----def_named3_adaptive_alloy
(8807, 1, 1), ----def_named3_dreadnought_module
(8827, 1, 1), ----def_named3_excavator_module
(8839, 1, 1), ----def_named3_remote_command_translator
(8843, 1, 1), ----def_improved_attack_remote_command
(8845, 1, 1), ----def_improved_defend_remote_command
(8847, 1, 1), ----def_improved_gather_remote_command
(8849, 1, 1), ----def_improved_support_remote_command
(701, 1, 1), ----def_named3_large_armor_repairer
(731, 1, 1), ----def_named3_large_shield_generator
(821, 1, 1), ----def_named3_large_core_battery
(830, 1, 1), ----def_named3_large_core_booster
(839, 1, 1), ----def_named3_large_laser
(848, 1, 1), ----def_named3_hell_cannon
(857, 1, 1), ----def_named3_cruisemissile_launcher
(866, 1, 1), ----def_named3_large_railgun
(1023, 1, 1), ----def_named3_longrange_large_railgun
(1029, 1, 1), ----def_named3_longrange_large_laser
(1035, 1, 1) ----def_named3_raven_cannon

MERGE giftloots AS Target
USING (SELECT definition, minquantity, maxquantity FROM @tempTable) AS Source
ON (Target.definition = Source.definition)
WHEN MATCHED THEN
    UPDATE SET Target.minquantity = Source.minquantity, Target.maxquantity = Source.maxquantity
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, minquantity, maxquantity)
    VALUES (Source.definition, Source.minquantity, Source.maxquantity);

GO