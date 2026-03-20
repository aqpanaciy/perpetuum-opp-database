
USE perpetuumsa;
GO

DECLARE @field INT
DECLARE @definition INT

SET @field = (SELECT TOP 1 Id FROM aggregatefields WHERE name = 'cpu_max')
--
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_head_reward1')
UPDATE aggregatevalues SET value = 421.05 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8#height=f0.15#max_locked_targets=f3.00#max_targeting_range=f35.00#sensor_strength=f100.00#cpu=f421.05' WHERE definitionname = 'def_mesmer_head_reward1'

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_head_reward1')
UPDATE aggregatevalues SET value = 363.3 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.01#max_locked_targets=f3.00#max_targeting_range=f37.50#sensor_strength=f100.00#cpu=f363.30' WHERE definitionname = 'def_seth_head_reward1'

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_head_reward1')
UPDATE aggregatevalues SET value = 481.95 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=48,8,8,8,8,8,8#height=f0.20#max_locked_targets=f3.00#max_targeting_range=f32.50#sensor_strength=f100.00#cpu=f481.95' WHERE definitionname = 'def_gropho_head_reward1'

--
SET @field = (SELECT TOP 1 Id FROM aggregatefields WHERE name = 'powergrid_max')
--
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_mesmer_chassis_reward1')
UPDATE aggregatevalues SET value = 1241.1 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=46d1,d1,4d1,6d1,d1,4d1,4d0#height=f1.10#armor_hp=f2650.00#core_recharge_time=f720.00#powergrid=f1241.10#signature_radius=f10.00#accuracy=f40.00#core=f4125.00#tracking=f40.00#decay=n450' WHERE definitionname = 'def_mesmer_chassis_reward1'

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_seth_chassis_reward1')
UPDATE aggregatevalues SET value = 1587.6 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=46d1,d1,4d1,6d1,d1,4d1#height=f0.75#armor_hp=f3100.00#core_recharge_time=f720.00#powergrid=f1587.60#signature_radius=f10.00#tracking=f30.00#core=f4750.00#decay=n450' WHERE definitionname = 'def_seth_chassis_reward1'

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_gropho_chassis_reward1')
UPDATE aggregatevalues SET value = 1299.38 WHERE definition = @definition AND field = @field
UPDATE entitydefaults SET options = '#slotFlags=4d2,d2,6d2,6d2,4d2,4d2,4d0#height=f0.80#armor_hp=f2850.00#core_recharge_time=f720.00#powergrid=f1299.38#signature_radius=f10.00#tracking=f30.00#core=f3250.00#decay=n450' WHERE definitionname = 'def_gropho_chassis_reward1'

--

GO

UPDATE entitydefaults SET purchasable = 1 WHERE definitionname = 'def_gropho_reward1_bot'
UPDATE entitydefaults SET purchasable = 1 WHERE definitionname = 'def_mesmer_reward1_bot'
UPDATE entitydefaults SET purchasable = 1 WHERE definitionname = 'def_seth_reward1_bot'

GO
