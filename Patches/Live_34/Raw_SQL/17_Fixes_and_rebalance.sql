USE perpetuumsa;

GO

---- Slow down the spectator

DECLARE @definition INT
DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'speed_max')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_leg')

UPDATE aggregatevalues SET value = 1.53 WHERE definition = @definition AND field = @field

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_spectator_leg_pr')

UPDATE aggregatevalues SET value = 1.53 WHERE definition = @definition AND field = @field

GO

---- Set allowed bots for dreadnoughts

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named1_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named1_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named2_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named2_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named3_dreadnought_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4_pr#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_named3_dreadnought_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t1#allowedBots=4177d,177e,1778,1779,1773,1774,22b8,22bc' WHERE definitionname = 'def_standard_dreadnought_module'

GO

---- Set allowed bots for excavators

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_excavator_module'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_excavator_module_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_excavator_module'

GO

---- Set allowed bots for assault remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a #powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=4209c,20e4' WHERE definitionname = 'def_named1_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named1_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=4209c,20e4' WHERE definitionname = 'def_named2_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named2_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=4209c,20e4' WHERE definitionname = 'def_named3_assault_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=4209c,20e4' WHERE definitionname = 'def_named3_assault_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L4120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=4209c,20e4' WHERE definitionname = 'def_standard_assault_remote_controller'

GO

---- Set allowed bots for tactical remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named1_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named1_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named2_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named2_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named3_tactical_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_named3_tactical_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00  #cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1130,1594' WHERE definitionname = 'def_standard_tactical_remote_controller'

GO

---- Set allowed bots for industrial remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=4beb,bec' WHERE definitionname = 'def_named1_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named1_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=4beb,bec' WHERE definitionname = 'def_named2_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named2_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=4beb,bec' WHERE definitionname = 'def_named3_industrial_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=4beb,bec' WHERE definitionname = 'def_named3_industrial_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L5120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=4beb,bec' WHERE definitionname = 'def_standard_industrial_remote_controller'

GO

---- Set allowed bots for support remote controllers

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=415a8' WHERE definitionname = 'def_standard_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=415a8' WHERE definitionname = 'def_named1_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=415a8' WHERE definitionname = 'def_named1_support_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=415a8' WHERE definitionname = 'def_named2_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=415a8' WHERE definitionname = 'def_named2_support_remote_controller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=415a8' WHERE definitionname = 'def_named3_support_remote_controller'

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L6120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=415a8' WHERE definitionname = 'def_named3_support_remote_controller_pr'

GO

---- Set allowed bots for large drillers

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_driller'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_driller_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L130A#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_large_driller'

GO

---- Set allowed bots for large harvesters

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t2#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t2_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named1_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t3#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t3_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named2_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t4#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_harvester'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t4_pr#allowedBots=421f5,21fa' WHERE definitionname = 'def_named3_large_harvester_pr'

UPDATE entitydefaults SET options = '#moduleFlag=i20#ammoCapacity=i2d#ammoType=L140A#tier=$tierlevel_t1#allowedBots=421f5,21fa' WHERE definitionname = 'def_standard_large_harvester'

GO

---- Turn slots into normal

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_ares_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_ares_head_pr'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_felos_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8,8' WHERE definitionname = 'def_hydra_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_onyx_bot_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_terramotus_head'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8' WHERE definitionname = 'def_terramotus_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.10' WHERE definitionname = 'def_spectator_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.10' WHERE definitionname = 'def_spectator_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8 #height=f0.10' WHERE definitionname = 'def_beholder_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8 #height=f0.10' WHERE definitionname = 'def_beholder_head_pr'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.15#max_locked_targets=f3.00#max_targeting_range=f35.00#sensor_strength=f100.00#cpu=f375.00' WHERE definitionname = 'def_mesmer_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.15#max_locked_targets=f3.00#max_targeting_range=f35.00#sensor_strength=f100.00#cpu=f375.00' WHERE definitionname = 'def_mesmer_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f475.00' WHERE definitionname = 'def_gropho_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f475.00' WHERE definitionname = 'def_gropho_head_reward1'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.01#max_locked_targets=f3.00#max_targeting_range=f37.50#sensor_strength=f100.00#cpu=f325.00' WHERE definitionname = 'def_seth_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.01#max_locked_targets=f3.00#max_targeting_range=f37.50#sensor_strength=f100.00#cpu=f325.00' WHERE definitionname = 'def_seth_head_reward1'

UPDATE entitydefaults SET options = '#height=f0.2#slotFlags=48,8,8,8,8,8' WHERE definitionname = 'def_legatus_head'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.20#max_locked_targets=f1.00#max_targeting_range=f21.00#sensor_strength=f100.00#cpu=f450.00' WHERE definitionname = 'def_riveler_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.20#max_locked_targets=f1.00#max_targeting_range=f21.00#sensor_strength=f100.00#cpu=f450.00' WHERE definitionname = 'def_symbiont_head_mk2'

UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8#height=f0.20' WHERE definitionname = 'def_metis_head'

UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg'

UPDATE entitydefaults SET options = '#slotFlags=420,20,20,20,20  #height=f1.10' WHERE definitionname = 'def_terramotus_leg_pr'

GO