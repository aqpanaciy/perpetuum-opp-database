
USE perpetuumsa
GO

EXEC dbo.indexesMaintenance

GO

USE perpetuumsa;
GO

---- Add or update items and amounts

DELETE FROM market_orders_configuration WHERE definitionname in ('def_kain_mk2_bot','def_tyrannos_mk2_bot','def_artemis_mk2_bot')

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_named3_medium_laser', 12),
('def_named3_medium_autocannon', 12),
('def_named3_missile_launcher', 12),
('def_named3_medium_railgun', 12),
('def_named3_longrange_medium_railgun', 12),
('def_named3_longrange_medium_laser', 12),
('def_named3_longrange_medium_autocannon', 12),
('def_named3_medium_armor_plate', 20),
('def_named3_medium_armor_repairer', 10),
('def_named3_thrm_armor_hardener', 10),
('def_named3_chm_armor_hardener', 10),
('def_named3_kin_armor_hardener', 10),
('def_named3_exp_armor_hardener', 10),
('def_named3_medium_shield_generator', 10),
('def_named3_shield_hardener', 20),
('def_named3_core_recharger', 20),
('def_named3_sensor_booster', 20),
('def_named3_eccm', 15),
('def_named3_medium_driller', 10),
('def_named3_mining_upgrade', 10),
('def_named3_powergrid_upgrades', 10),
('def_named3_cpu_upgrade', 10),
('def_named3_medium_harvester', 10),
('def_named3_medium_core_battery', 10),
('def_named3_medium_core_booster', 10),
('def_named3_tracking_upgrade', 10),
('def_named3_resistant_plating', 10),
('def_named3_mass_reductor', 10),
('def_named3_detection_modul', 10),
('def_named3_stealth_modul', 10),
('def_named3_kinetic_kers', 5),
('def_named3_thermal_kers', 5),
('def_named3_explosive_kers', 5),
('def_named3_weapon_stabilizer', 10),
('def_named3_ew_resist', 10),
('def_named3_adaptive_alloy', 10),
('def_named3_medium_energy_vampire', 10),
('def_named3_medium_energy_neutralizer', 10),
('def_named3_sensor_jammer', 10),
('def_named3_sensor_dampener', 10),
('def_named3_blob_emission_modulator', 10),
('def_named3_target_painter', 5),
('def_named3_longrange_webber', 10),
('def_named3_webber', 10),
('def_named3_reactor_sealing', 10),
('def_named3_energy_warfare_upgrade', 10),
('def_named3_ecm_booster', 10),
('def_named3_sensor_supressor_booster', 10),
('def_named3_landmine_detector', 10),
('def_beholder_bot', 3),
('def_terramotus_bot', 3),
('def_standard_tactical_remote_controller', 5),
('def_standard_remote_command_translator', 5),
('def_standard_large_driller', 3),
('def_standard_large_harvester', 3),
('def_standard_large_armor_plate', 5),
('def_standard_large_armor_repairer', 5),
('def_syndicate_attack_drone_unit', 10)

MERGE market_orders_configuration AS Target
USING (SELECT definitionname, amount FROM @tempTable) AS Source
ON (Target.definitionname = Source.definitionname)
WHEN MATCHED THEN
    UPDATE SET 
		Target.amount = Source.amount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definitionname, amount)
    VALUES (Source.definitionname, Source.amount);

GO

USE [perpetuumsa]
GO

/****** Object:  StoredProcedure [dbo].[usp_RefreshAutoMarketOrders]    Script Date: 17.07.2025 19:23:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---- Change auto orders placement so that it places plasma buy orders across all the islands

CREATE OR ALTER   PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @batch INT = 500000000;
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;
        DECLARE @itemdefinition INT;
        DECLARE @unit_price FLOAT;
        DECLARE @quantity BIGINT;
        DECLARE @remaining BIGINT;

        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 1.1: Place plasma buy orders on alphas:

        DECLARE alpha_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 1
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(1) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN alpha_cursor;

        FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE alpha_cursor;
        DEALLOCATE alpha_cursor;

        -- Step 1.2: Place plasma buy orders on betas:

        DECLARE beta_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 0
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(2) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN beta_cursor;

        FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE beta_cursor;
        DEALLOCATE beta_cursor;

        -- Step 1.3: Place plasma buy orders on gammas:

        DECLARE gamma_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT eid FROM dbo.getLiveGammaDockingBases()
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                0 AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(3) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m

        OPEN gamma_cursor;

        FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE gamma_cursor;
        DEALLOCATE gamma_cursor;

        -- Step 2: Fetch market and vendor EIDs
        
        SELECT @marketeid = eid 
        FROM entities 
        WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

        SELECT @vendoreid = vendorEID 
        FROM dbo.vendors 
        WHERE marketEID = @marketeid;

        -- Step 3: Insert product auto-orders (static config)
        INSERT INTO marketitems (
            marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
        )
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,
            0,
            1,
            pc.production_cost_nic,
            moc.amount,
            1,
            1
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product;

        -- Step 4: Insert raw material buy orders, split if quantity too large

        -- Use a cursor to handle splitting quantities
        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            rrm.total_quantity AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END
			
            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;

        -- Insert raw resources sell orders

        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            10000000 AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 1, @unit_price * 2.0, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 1, @unit_price * 2.0, @remaining, 1, 1
                );
            END
			
            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;


    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO



USE [perpetuumsa]
GO

/****** Object:  UserDefinedFunction [dbo].[fn_CalculateDynamicPlasmaPrices]    Script Date: 17.07.2025 19:16:06 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---- Create table function to calculate dynamic prices for a given island type

CREATE OR ALTER   FUNCTION [dbo].[fn_CalculateDynamicPlasmaPrices] (@island_type INT)
RETURNS TABLE
AS
RETURN
(
    WITH parameters AS (
        SELECT 
            MIN_PRICE = 
                CASE @island_type 
                    WHEN 1 THEN 25 
                    WHEN 2 THEN 125 
                    WHEN 3 THEN 200 
                    ELSE 0 
                END,
            MAX_PRICE = 
                CASE @island_type 
                    WHEN 1 THEN 150 
                    WHEN 2 THEN 250 
                    WHEN 3 THEN 275 
                    ELSE 0 
                END
    ),
    weights AS (
        SELECT * FROM (VALUES
            ('def_common_reactor_plasma', 1.0),
            ('def_thelodica_reactor_plasma', 1.0),
            ('def_pelistal_reactor_plasma', 1.0),
            ('def_nuimqol_reactor_plasma', 1.0)
        ) AS w(plasma_type, weight)
    ),
    gathered_cte AS (
        SELECT plasma_type, SUM(quantity) AS gathered
        FROM plasma_gathered
        WHERE gathered_on >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
        GROUP BY plasma_type
    ),
    sold_cte AS (
        SELECT plasma_type, SUM(quantity) AS sold
        FROM plasma_sold
        WHERE sold_on >= DATEADD(DAY, -7, CAST(GETDATE() AS DATE))
        GROUP BY plasma_type
    )
    SELECT 
        w.plasma_type,
        g.gathered,
        s.sold,
        w.weight,
        CAST(
            (
                CASE 
                    WHEN ISNULL(g.gathered, 0) = 0 THEN p.MAX_PRICE
                    ELSE
                        p.MIN_PRICE + (p.MAX_PRICE - p.MIN_PRICE) * 
                        (
                            CASE 
                                WHEN CAST(ISNULL(s.sold, 0) AS FLOAT) / NULLIF(g.gathered, 1) > 1 THEN 0
                                ELSE 1.0 - (CAST(ISNULL(s.sold, 0) AS FLOAT) / NULLIF(g.gathered, 1))
                            END
                        )
                END
            ) * w.weight AS DECIMAL(10, 2)
        ) AS dynamic_price
    FROM weights w
    CROSS JOIN parameters p
    LEFT JOIN gathered_cte g ON g.plasma_type = w.plasma_type
    LEFT JOIN sold_cte s ON s.plasma_type = w.plasma_type
);

GO



USE [perpetuumsa]
GO

---- Create table for daily resources
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[resources_gathered_daily](
	[gathered_on] [date] NOT NULL,
	[resource_name] [varchar](100) NOT NULL,
	[quantity] [bigint] NOT NULL
) ON [PRIMARY]
GO

---- Create table for daily plasma
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[plasma_gathered_daily](
	[gathered_on] [date] NOT NULL,
	[plasma_type] [varchar](100) NOT NULL,
	[quantity] [bigint] NOT NULL
) ON [PRIMARY]
GO

---- Alter resources statistics to write in daily

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---- Create sp to register resources statistics

ALTER PROCEDURE [dbo].[sp_RecordResourceGathered]
    @gathered_on DATE,
    @resource_name VARCHAR(100),
    @quantity BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO resources_gathered_daily (gathered_on, resource_name, quantity) VALUES
    (@gathered_on, @resource_name, @quantity)
END;

GO

---- Alter plasma statistics to write in daily

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---- Create sp to register plasma statistics

ALTER PROCEDURE [dbo].[sp_RecordPlasmaGathered]
    @gathered_on DATE,
    @plasma_type VARCHAR(50),
    @quantity BIGINT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO plasma_gathered_daily (gathered_on, plasma_type, quantity)
    VALUES (@gathered_on, @plasma_type, @quantity)
END;

GO

---- Add daily statistics compression

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


---- Create new stored procedure for consolidating statistics
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE consolidate_statistics
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-- This block consolidates and cleans up daily statistics for resources

    -- Step 1: Aggregate from Table B (buffer)
    WITH Aggregated AS (
        SELECT
            gathered_on,
            resource_name,
            SUM(quantity) AS total_quantity
        FROM resources_gathered_daily WITH (READPAST)  -- Skip locked rows (optional)
        GROUP BY gathered_on, resource_name
    )

    -- Step 2: Merge into Table A (summary)
    MERGE INTO resources_gathered AS target
    USING Aggregated AS source
    ON target.gathered_on = source.gathered_on
       AND target.resource_name = source.resource_name
    WHEN MATCHED THEN
        UPDATE SET quantity = target.quantity + source.total_quantity
    WHEN NOT MATCHED THEN
        INSERT (gathered_on, resource_name, quantity)
        VALUES (source.gathered_on, source.resource_name, source.total_quantity);

    -- Step 3: Delete processed rows from Table B
    DELETE FROM resources_gathered_daily;

    -- end of block

    -- This block consolidates and cleans up daily statistics for plasma

    -- Step 1: Aggregate from Table B (buffer)
    WITH Aggregated AS (
        SELECT
            gathered_on,
            plasma_type,
            SUM(quantity) AS total_quantity
        FROM plasma_gathered_daily WITH (READPAST)  -- Skip locked rows (optional)
        GROUP BY gathered_on, plasma_type
    )

    -- Step 2: Merge into Table A (summary)
    MERGE INTO plasma_gathered AS target
    USING Aggregated AS source
    ON target.gathered_on = source.gathered_on
       AND target.plasma_type = source.plasma_type
    WHEN MATCHED THEN
        UPDATE SET quantity = target.quantity + source.total_quantity
    WHEN NOT MATCHED THEN
        INSERT (gathered_on, plasma_type, quantity)
        VALUES (source.gathered_on, source.plasma_type, source.total_quantity);

    -- Step 3: Delete processed rows from Table B
    DELETE FROM plasma_gathered_daily;

    -- end of block
END
GO

USE perpetuumsa;
GO

---- Add or update items and amounts

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_seth_bot', 1),
('def_gropho_bot', 1),
('def_mesmer_bot', 1),
('def_legatus_bot', 1)

MERGE market_orders_configuration AS Target
USING (SELECT definitionname, amount FROM @tempTable) AS Source
ON (Target.definitionname = Source.definitionname)
WHEN MATCHED THEN
    UPDATE SET 
		Target.amount = Source.amount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definitionname, amount)
    VALUES (Source.definitionname, Source.amount);

GO

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

USE perpetuumsa;
GO

UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named1_tactical_remote_controller'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t2_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named1_tactical_remote_controller_pr'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named2_tactical_remote_controller'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i4#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t3_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named2_tactical_remote_controller_pr'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named3_tactical_remote_controller'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i5#ammoType=L3120a#powergrid_usage=f0.00#cpu_usage=f0.00#tier=$tierlevel_t4_pr#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_named3_tactical_remote_controller_pr'
UPDATE entitydefaults SET options = '#moduleFlag=i8#ammoCapacity=i3#ammoType=L3120a#powergrid_usage=f0.00  #cpu_usage=f0.00#tier=$tierlevel_t1#allowedBots=422ac,22b0,bdf,be1,1139,1137,be0,1138,1594' WHERE definitionname = 'def_standard_tactical_remote_controller'

GO

USE perpetuumsa;
GO

---- Make presents purchasable

UPDATE entitydefaults SET purchasable = 1 WHERE definitionname = 'def_anniversary_package'

GO

---- Place presents to Hershfield

DECLARE @marketeid BIGINT;
DECLARE @vendoreid BIGINT;
DECLARE @itemDefinition INT;

SELECT @marketeid = eid 
FROM entities 
WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

SELECT @vendoreid = vendorEID 
FROM dbo.vendors 
WHERE marketEID = @marketeid;

SET @itemDefinition = (SELECT TOP (1) [definition] FROM [perpetuumsa].[dbo].[entitydefaults] WHERE [definitionname] = 'def_anniversary_package');

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

USE perpetuumsa;
GO

---- Production and prorotyping cost in materials, modules and components ----

DECLARE @definition INT

DECLARE @titanium INT
DECLARE @plasteosine INT
DECLARE @cryoperine INT

DECLARE @alligior INT
DECLARE @espitium INT
DECLARE @bryochite INT

DECLARE @flux INT

DECLARE @axicoline INT
DECLARE @polynitrocol INT
DECLARE @polynucleit INT
DECLARE @phlobotil INT

DECLARE @statichnol INT
DECLARE @metachropin INT
DECLARE @isopropentol INT

DECLARE @hydrobenol INT

DECLARE @common_basic_components INT
DECLARE @common_advanced_components INT
DECLARE @common_expert_components INT

DECLARE @t1_remote_command_translator INT
DECLARE @t2_remote_command_translator INT
DECLARE @t3_remote_command_translator INT

SET @titanium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_titanium')
SET @plasteosine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_plasteosine')
SET @cryoperine = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicol') -- axicoline Y U NO cryoperine

SET @alligior = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_alligior')
SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')
SET @bryochite = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_unimetal') -- unimetal Y U NO bryochite

SET @espitium = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_espitium')

SET @flux = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_specimen_sap_item_flux')

SET @axicoline = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_axicoline')
SET @polynitrocol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynitrocol')
SET @polynucleit = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_polynucleit')
SET @phlobotil = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_phlobotil')

SET @statichnol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_statichnol')
SET @metachropin = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_metachropin')
SET @isopropentol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_isopropentol')

SET @hydrobenol = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_hydrobenol')

SET @common_basic_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
SET @common_advanced_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
SET @common_expert_components = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')

SET @t1_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
SET @t2_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
SET @t3_remote_command_translator = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')

DECLARE @tempTable TABLE (definition INT, componentdefinition INT, componentamount INT)

-- Modules --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200),
(@definition, @common_basic_components, 60)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200),
(@definition, @t1_remote_command_translator, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 125),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @t2_remote_command_translator, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 400),
(@definition, @hydrobenol, 200),
(@definition, @bryochite, 200),
(@definition, @t3_remote_command_translator, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

-- Prototypes --
SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 200),
(@definition, @t1_remote_command_translator, 1),
(@definition, @common_basic_components, 120)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 100),
(@definition, @cryoperine, 125),
(@definition, @axicoline, 100),
(@definition, @espitium, 300),
(@definition, @hydrobenol, 100),
(@definition, @t2_remote_command_translator, 1),
(@definition, @common_basic_components, 80),
(@definition, @common_advanced_components, 80)

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_remote_command_translator_pr')
INSERT INTO @tempTable (definition, componentdefinition, componentamount) VALUES
(@definition, @titanium, 200),
(@definition, @cryoperine, 250),
(@definition, @axicoline, 200),
(@definition, @espitium, 400),
(@definition, @hydrobenol, 200),
(@definition, @bryochite, 200),
(@definition, @t3_remote_command_translator, 1),
(@definition, @common_basic_components, 60),
(@definition, @common_advanced_components, 120),
(@definition, @common_expert_components, 180)

MERGE components AS Target
USING (SELECT definition, componentdefinition, componentamount FROM @tempTable) AS Source
ON (Target.definition = Source.definition AND Target.componentdefinition = Source.componentdefinition)
WHEN MATCHED THEN
    UPDATE SET Target.componentamount = Source.componentamount
WHEN NOT MATCHED BY TARGET THEN
    INSERT (definition, componentdefinition, componentamount)
    VALUES (Source.definition, Source.componentdefinition, Source.componentamount);

GO

USE [perpetuumsa]
GO

---- Force clear automarket

DELETE FROM marketitems WHERE isAutoOrder = 1;

GO

---- Add itemdefinition into production_data

/****** Object:  View [dbo].[production_data]    Script Date: 04.12.2025 11:13:46 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER VIEW [dbo].[production_data] AS
SELECT
    ed.definition AS itemdefinition,
    ed.definitionname AS product,
    ced.definitionname AS components,
    c.componentamount AS amount
FROM components c
INNER JOIN entitydefaults ed ON c.definition = ed.definition
INNER JOIN entitydefaults ced ON c.componentdefinition = ced.definition
WHERE ed.purchasable = 1 AND ed.enabled = 1 AND ed.hidden = 0;-- AND (ed.tiertype IS NULL OR ed.tiertype = 1);-- AND ed.attributeflags & CONVERT(BIGINT, 2147483648) = 0;

GO

---- Create table to store unsold leftovers

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[automarket_unsold_leftovers]') AND type in (N'U'))
DROP TABLE [dbo].automarket_unsold_leftovers
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[automarket_unsold_leftovers] (
	[itemdefinition] [int] NOT NULL,
	[quantity] [bigint] NOT NULL)

GO

---- Create table to store unbought resources

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[automarket_unbought_resources]') AND type in (N'U'))
DROP TABLE [dbo].automarket_unbought_resources
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].automarket_unbought_resources (
	[itemdefinition] [int] NOT NULL,
	[quantity] [bigint] NOT NULL)

GO

---- Change resources amount calculation to consider unsold leftovers

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



-- Create the view
CREATE OR ALTER   VIEW [dbo].[v_required_raw_materials] AS
    WITH RecursiveBreakdown AS (
        -- Base case: direct components
        SELECT 
            moc.definitionname AS product,
            pd.components AS component,
            SUM(CAST(ROUND(pd.amount * 2.1, 0) AS BIGINT)) AS total_amount  -- 50% efficiency adjustment
        FROM dbo.market_orders_configuration moc
        JOIN dbo.production_data pd ON moc.definitionname = pd.product
        GROUP BY moc.definitionname, pd.components

        UNION ALL

        -- Recursive case: break down intermediate components
        SELECT 
            rb.product,
            pd.components AS component,
            rb.total_amount * CAST(ROUND(pd.amount * 2.1, 0) AS BIGINT) AS total_amount
        FROM RecursiveBreakdown rb
        JOIN dbo.production_data pd ON rb.component = pd.product
    )

    -- Final aggregation: only raw materials (not further craftable)
    SELECT
        rb.product as product,
        rb.component AS raw_material,
        SUM(rb.total_amount) AS total_quantity
    FROM RecursiveBreakdown rb
    LEFT JOIN dbo.production_data pd ON rb.component = pd.product
    WHERE pd.product IS NULL
    GROUP BY rb.product, rb.component;

GO

---- Change auto orders placement so that it places plasma buy orders across all the islands

CREATE OR ALTER   PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @batch INT = 500000000;
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;
        DECLARE @itemdefinition INT;
        DECLARE @unit_price FLOAT;
        DECLARE @quantity BIGINT;
        DECLARE @remaining BIGINT;

        -- Step 0: Memorize unsold and unbought items

        DELETE FROM [automarket_unsold_leftovers];
        DELETE FROM [automarket_unbought_resources];

        INSERT INTO [automarket_unsold_leftovers] (itemdefinition, quantity)
        (SELECT itemdefinition, SUM(CAST(quantity AS BIGINT)) FROM marketitems WHERE isAutoOrder = 1 AND isSell = 1 GROUP BY itemdefinition);

        -- Unbought mats excluding plasma
        INSERT INTO automarket_unbought_resources (itemdefinition, quantity)
        (SELECT itemdefinition, SUM(CAST(quantity AS BIGINT)) FROM marketitems WHERE isAutoOrder = 1 AND isSell = 0 AND itemdefinition NOT IN (3271,3272,3273,3274) GROUP BY itemdefinition);

        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 1.1: Place plasma buy orders on alphas:

        DECLARE alpha_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 1
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(1) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN alpha_cursor;

        FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM alpha_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE alpha_cursor;
        DEALLOCATE alpha_cursor;

        -- Step 1.2: Place plasma buy orders on betas:

        DECLARE beta_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT e.eid
                FROM dbo.entities e
                JOIN dbo.zoneentities ze ON ze.eid = e.eid
                JOIN dbo.zones z ON z.id = ze.zoneID
                WHERE 
                    e.definition IN (
                        SELECT definition
                        FROM dbo.getDefinitionByCFString('cf_public_docking_base')
                    )
                    AND z.terraformable = 0
                    AND z.protected = 0
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(2) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

        OPEN beta_cursor;

        FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM beta_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE beta_cursor;
        DEALLOCATE beta_cursor;

        -- Step 1.3: Place plasma buy orders on gammas:

        DECLARE gamma_cursor CURSOR FOR
            WITH PublicMarkets AS (
                SELECT eid FROM dbo.getLiveGammaDockingBases()
            ),
            Markets AS (
                SELECT eid
                FROM dbo.entities
                WHERE definition = 10 AND parent IN (SELECT eid FROM PublicMarkets)
            )

            SELECT
                m.eid AS marketeid,
                ed.definition AS itemdefinition,
                0 AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(3) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m

        OPEN gamma_cursor;

        FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END
			
            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END

            FETCH NEXT FROM gamma_cursor INTO @marketeid, @itemdefinition, @vendoreid, @unit_price, @quantity;
        END

        CLOSE gamma_cursor;
        DEALLOCATE gamma_cursor;

        -- Step 2: Fetch market and vendor EIDs
        
        SELECT @marketeid = eid 
        FROM entities 
        WHERE ename = 'def_public_market_megacorp_TM_base_tm_pve';

        SELECT @vendoreid = vendorEID 
        FROM dbo.vendors 
        WHERE marketEID = @marketeid;

        -- Step 3: Insert product auto-orders (unsold leftovers or fresh set)
        INSERT INTO marketitems (
            marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
        )
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,
            0,
            1,
            pc.production_cost_nic,
            --ISNULL(us.quantity, moc.amount) AS quantity,
            moc.amount AS quantity,
            1,
            1
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        --LEFT JOIN [automarket_unsold_leftovers] us ON ed.definition = us.itemdefinition
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product

        -- Step 4: Insert raw material buy orders, split if quantity too large
        DECLARE raw_cursor CURSOR FOR
            WITH NeededProducts AS (
                SELECT 
                    moc.definitionname AS product,
                    CAST(moc.amount - ISNULL(us.quantity, 0) AS BIGINT) AS need_amount
                FROM market_orders_configuration moc
                INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
                LEFT JOIN automarket_unsold_leftovers us ON ed.definition = us.itemdefinition
            ),
            RequiredRaw AS (
                SELECT
                    ed.definition AS raw_material_def,
                    SUM(rm.total_quantity * np.need_amount) AS required_from_products
                FROM NeededProducts np
                INNER JOIN v_required_raw_materials rm ON rm.product = np.product
                INNER JOIN entitydefaults ed ON ed.definitionname = rm.raw_material
                WHERE np.need_amount > 0
                GROUP BY ed.definition
            ),
            Unbought AS (
                SELECT
                    ub.itemdefinition AS raw_material_def,
                    SUM(ub.quantity) AS required_from_unbought
                FROM automarket_unbought_resources ub
                GROUP BY ub.itemdefinition
            ),
            Combined AS (
                SELECT
                    COALESCE(r.raw_material_def, u.raw_material_def) AS combined_def,
                    COALESCE(r.required_from_products, 0) + COALESCE(u.required_from_unbought, 0) AS total_required_quantity
                FROM RequiredRaw r
                FULL OUTER JOIN Unbought u
                    ON u.raw_material_def = r.raw_material_def
            )
            SELECT
                c.combined_def AS definition,
                apc.production_cost_nic AS unit_price,
                c.total_required_quantity AS total_required_quantity
            FROM Combined c
            INNER JOIN entitydefaults ed ON ed.definition = c.combined_def
            INNER JOIN v_all_production_costs apc ON ed.definitionname = apc.product
            ORDER BY c.combined_def;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @remaining, 1, 1
                );
            END
			
            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;

        -- Step 5. Insert raw resources sell orders

        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            10000000 AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            SET @remaining = @quantity;

            WHILE @remaining > @batch
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 1, @unit_price * 2.0, @batch, 1, 1
                );

                SET @remaining -= @batch;
            END

            IF @remaining > 0
            BEGIN
			    INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 1, @unit_price * 2.0, @remaining, 1, 1
                );
            END
			
            FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;
        END

        CLOSE raw_cursor;
        DEALLOCATE raw_cursor;


    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO



USE perpetuumsa;
GO

---- Enable Santa

UPDATE npcpresence SET enabled = 1 WHERE name = 'roamer_santa_z8'

GO
