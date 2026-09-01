
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
USE perpetuumsa;

GO

---- Fix remote controller extra zero issue

UPDATE aggregatevalues SET value = 180000 WHERE definition = 8560 AND field = 677

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
-- 15_New_Virginia_Syndicate_Forces.sql

USE perpetuumsa

GO

DECLARE @targetDefinition INT
DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT

SET @spawnid = (SELECT TOP 1 spawnid FROM zones WHERE name = 'zone_TM')

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_forces_vektor_main_combat_bot', 1, 1024, 1167, '#faction=SSyndicate', 'Vektor, Armor, Machine Guns', 1, 0, 0, 0, 100, 'def_syndicate_forces_vektor_main_combat_bot_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SSyndicate' WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot'
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -0.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -0.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -10 WHERE definition = @targetDefinition AND field = @field
END

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT

DECLARE @sensor_booster INT
DECLARE @s_demob INT
DECLARE @firearm_tuning INT
DECLARE @small_mg INT
DECLARE @mg_ammo INT
DECLARE @small_armor_rep INT
DECLARE @medium_injector INT
DECLARE @injector_charges INT
DECLARE @uni_plate INT
DECLARE @small_plate INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_vektor_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_runner')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
SET @s_demob = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_webber')
SET @firearm_tuning = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_damage_mod_projectile')
SET @small_mg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_autocannon')
SET @mg_ammo = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_ammo_small_projectile_rewa')
SET @small_armor_rep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_armor_repairer')
SET @uni_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_resistant_plating')
SET @small_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_armor_plate')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Vektor_Main_Combat')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Vektor_Main_Combat', CONCAT(
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
		FORMAT(@sensor_booster, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@s_demob, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@firearm_tuning, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@small_mg, 'X'),
		'|slot=i1|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m1=[|definition=i',
		FORMAT(@small_mg, 'X'),
		'|slot=i2|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m2=[|definition=i',
		FORMAT(@small_mg, 'X'),
		'|slot=i3|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]|m3=[|definition=i',
		FORMAT(@small_mg, 'X'),
		'|slot=i4|ammoDefinition=i',
		FORMAT(@mg_ammo, 'X'),
		'|ammoQuantity=i17]]#legModules=[|m0=[|definition=i',
		FORMAT(@small_armor_rep, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@uni_plate, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@small_plate, 'X'),
		'|slot=i3]]'), 'Syndicate Forces Main Combat Vektor')
END

DECLARE @templateId INT

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Vektor_Main_Combat')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 15, 'def_npc_nv_vektor_main_combat')

--- support Argano

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_argano_main_support_bot')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_syndicate_forces_argano_main_support_bot', 1, 1024, 1167, '#faction=SSyndicate', 'Argano, Armor Repair, Energy Transfer', 1, 0, 0, 0, 100, 'def_syndicate_forces_argano_main_support_bot_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SSyndicate' WHERE definitionname = 'def_syndicate_forces_argano_main_support_bot'
END

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_argano_main_support_bot')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 40)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -10 WHERE definition = @targetDefinition AND field = @field
END

DECLARE @cpu_upgrade INT
DECLARE @eccm INT

DECLARE @energy_transferer INT
DECLARE @remote_armor_rep INT
DECLARE @small_shield INT
DECLARE @recharger INT
DECLARE @accu INT

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_ewmech_indy_runner')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
SET @cpu_upgrade = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_cpu_upgrade')
SET @eccm = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_eccm')

SET @energy_transferer = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_energy_transfer')
SET @remote_armor_rep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_remote_armor_repairer')

SET @small_shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_shield_generator')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
SET @accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_core_battery')


IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Argano_Main_Support')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Argano_Main_Support', CONCAT(
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
		FORMAT(@cpu_upgrade, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@eccm, 'X'),
		'|slot=i3]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@remote_armor_rep, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@remote_armor_rep, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i3]]#legModules=[|m0=[|definition=i',
		FORMAT(@small_shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@accu, 'X'),
		'|slot=i3]]'), 'Syndicate Forces Main Support Argano')
END

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Main_Support')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 15, 'def_npc_nv_argano_main_support')

--- squad 1

IF NOT EXISTS (SELECT 1 FROM npcpresence WHERE name = 'syndicate_N01_z0' AND spawnid = @spawnid)
BEGIN
	INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES
	('syndicate_N01_z0', 1025, 765, 1150, 895, 'new virginia syndicate forces 1', @spawnid, 1, 1, 900, 5, NULL, 1080, 850, 500, NULL, 1, 1, 1, NULL, NULL)
END
ELSE BEGIN
	UPDATE npcpresence SET enabled = 1, topx = 1025, topy = 765, bottomx = 1150, bottomy = 895, randomcenterx = 1080, randomcentery = 850, randomradius = 500, roamingrespawnseconds = 900
	WHERE name = 'syndicate_N01_z0'
END

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'syndicate_N01_z0')

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'syndicate_N01_z0_vektor_main_combat')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('syndicate_N01_z0_vektor_main_combat', @presenceid, 2, @definition, 0, 0, 0, 10, 7200, 0, 50, 'new virginia npc', 0.9, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 900 WHERE name = 'syndicate_N01_z0_vektor_main_combat'
END

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_argano_main_support_bot')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'syndicate_N01_z0_argano_main_support')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('syndicate_N01_z0_argano_main_support', @presenceid, 1, @definition, 0, 0, 0, 10, 7200, 0, 50, 'new virginia npc', 0.9, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 900 WHERE name = 'syndicate_N01_z0_argano_main_support'
END

GO
-- 16_Niani_Support_Bots.sql

USE perpetuumsa

GO

DECLARE @targetDefinition INT
DECLARE @spawnid INT
DECLARE @presenceid INT
DECLARE @definition INT

DECLARE @robot INT
DECLARE @head INT
DECLARE @chassis INT
DECLARE @leg INT
DECLARE @inventory INT

DECLARE @sensor_booster INT
DECLARE @eccm INT
DECLARE @shield_hardener INT
DECLARE @repair_upgrade INT
DECLARE @mg_ammo INT
DECLARE @remrep INT
DECLARE @energy_transferer INT
DECLARE @shield INT
DECLARE @recharger INT
DECLARE @accu INT
DECLARE @armor_plate INT

DECLARE @templateId INT

DECLARE @field INT

DECLARE @lootDefinition INT

----

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank1')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_termis_support_rank1', 1, 1024, 1167, '#faction=SNiani', 'Termis, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_termis_support_rank1_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_termis_support_rank1'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank2')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_termis_support_rank2', 1, 1024, 1167, '#faction=SNiani', 'Termis, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_termis_support_rank2_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_termis_support_rank2'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_termis_support_rank3', 1, 1024, 1167, '#faction=SNiani', 'Termis, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_termis_support_rank3_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_termis_support_rank3'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_termis_support_rank4', 1, 1024, 1167, '#faction=SNiani', 'Termis, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_termis_support_rank4_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_termis_support_rank4'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank5')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_termis_support_rank5', 1, 1024, 1167, '#faction=SNiani', 'Termis, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_termis_support_rank5_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_termis_support_rank5'
END

--

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_termis_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_indy_mech')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @eccm = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
SET @repair_upgrade = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')

SET @remrep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
SET @energy_transferer = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')

SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
SET @armor_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Termis_Niani_Support_Generic', CONCAT(
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
		FORMAT(@eccm, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@repair_upgrade, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i2]|m1=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i3]|m2=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i4]|m3=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i5]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@accu, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@armor_plate, 'X'),
		'|slot=i4]]'), 'Termis Niani Support Generic')
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank1')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 1, 'def_npc_termis_support_rank1')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.95 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank2')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_termis_support_rank2')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_termis_support_rank3')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.15 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_termis_support_rank4')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank5')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Termis_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_termis_support_rank5')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.75 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

--------

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank1')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_argano_support_rank1', 1, 1024, 1167, '#faction=SNiani', 'Argano, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_argano_support_rank1_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_argano_support_rank1'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank2')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_argano_support_rank2', 1, 1024, 1167, '#faction=SNiani', 'Argano, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_argano_support_rank2_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_argano_support_rank2'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_argano_support_rank3', 1, 1024, 1167, '#faction=SNiani', 'Argano, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_argano_support_rank3_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_argano_support_rank3'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_argano_support_rank4', 1, 1024, 1167, '#faction=SNiani', 'Argano, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_argano_support_rank4_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_argano_support_rank4'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank5')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_argano_support_rank5', 1, 1024, 1167, '#faction=SNiani', 'Argano, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_argano_support_rank5_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_argano_support_rank5'
END

--

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_argano_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_combat_ewmech_indy_runner')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @eccm = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
SET @repair_upgrade = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')

SET @remrep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
SET @energy_transferer = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')

SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Argano_Niani_Support_Generic', CONCAT(
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
		FORMAT(@eccm, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@repair_upgrade, 'X'),
		'|slot=i3]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i3]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@accu, 'X'),
		'|slot=i3]]'), 'Argano Niani Support Generic')
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank1')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 1, 'def_npc_argano_support_rank1')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.95 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank2')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_argano_support_rank2')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_argano_support_rank3')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.15 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_argano_support_rank4')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank5')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Argano_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_argano_support_rank5')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.75 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

--------

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank1')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_riveler_support_rank1', 1, 1024, 1167, '#faction=SNiani', 'Riveler, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_riveler_support_rank1_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_riveler_support_rank1'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank2')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_riveler_support_rank2', 1, 1024, 1167, '#faction=SNiani', 'Riveler, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_riveler_support_rank2_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_riveler_support_rank2'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank3')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_riveler_support_rank3', 1, 1024, 1167, '#faction=SNiani', 'Riveler, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_riveler_support_rank3_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_riveler_support_rank3'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_riveler_support_rank4', 1, 1024, 1167, '#faction=SNiani', 'Riveler, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_riveler_support_rank4_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_riveler_support_rank4'
END

--

IF NOT EXISTS (SELECT 1 FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank5')
BEGIN
	INSERT INTO entitydefaults (definitionname, quantity, attributeflags, categoryflags, options, note, enabled, volume, mass, hidden, health, descriptiontoken, purchasable, tiertype, tierlevel) VALUES
	('def_npc_riveler_support_rank5', 1, 1024, 1167, '#faction=SNiani', 'Riveler, Shield, Remote Armor Repairer, Energy Transferer', 1, 0, 0, 0, 100, 'def_npc_riveler_support_rank5_desc', 1, NULL, NULL)
END
ELSE
BEGIN
	UPDATE entitydefaults SET options = '#faction=SNiani' WHERE definitionname = 'def_npc_riveler_support_rank5'
END

--

SET @robot = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_bot')
SET @head = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_head')
SET @chassis = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_chassis')
SET @leg = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_riveler_leg')
SET @inventory = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robot_inventory_indy_heavymech')

SET @sensor_booster = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
SET @eccm = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
SET @repair_upgrade = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
SET @shield_hardener = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')

SET @remrep = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
SET @energy_transferer = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')

SET @shield = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
SET @recharger = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
SET @accu = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
SET @armor_plate = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')

IF NOT EXISTS (SELECT 1 FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')
BEGIN
	INSERT INTO robottemplates (name, description, note) VALUES
	('Riveler_Niani_Support_Generic', CONCAT(
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
		FORMAT(@eccm, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@repair_upgrade, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@shield_hardener, 'X'),
		'|slot=i4]]#chassisModules=[|m0=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@remrep, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i5]|m5=[|definition=i',
		FORMAT(@energy_transferer, 'X'),
		'|slot=i6]]#legModules=[|m0=[|definition=i',
		FORMAT(@shield, 'X'),
		'|slot=i1]|m1=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i2]|m2=[|definition=i',
		FORMAT(@recharger, 'X'),
		'|slot=i3]|m3=[|definition=i',
		FORMAT(@accu, 'X'),
		'|slot=i4]|m4=[|definition=i',
		FORMAT(@armor_plate, 'X'),
		'|slot=i5]]'), 'Riveler Niani Support Generic')
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank1')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 1, 'def_npc_riveler_support_rank1')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.05)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.05 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.95 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank2')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_riveler_support_rank2')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank3')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_riveler_support_rank3')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.7)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.7 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.15)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.15 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.3 WHERE definition = @targetDefinition AND field = @field
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.85)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.85 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_riveler_support_rank4')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.6)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.6 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.8)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.8 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.95)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

----

SET @targetDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank5')

SET @templateId = (SELECT TOP 1 id FROM robottemplates WHERE name = 'Riveler_Niani_Support_Generic')

DELETE FROM robottemplaterelation WHERE definition = @targetDefinition

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@targetDefinition, @templateId, 0, NULL, NULL, 2, 'def_npc_riveler_support_rank5')

--

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_amount_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_repair_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.75)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.75 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -20)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -20 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'shield_absorbtion_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

----

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs1')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn41')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn41', @presenceid, 1, @definition, 1510, 620, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn41'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs10')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank2')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn50')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn50', @presenceid, 1, @definition, 1540, 450, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank2', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn50'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs2')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn42')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn42', @presenceid, 2, @definition, 1540, 450, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn42'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs3')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn43')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn43', @presenceid, 2, @definition, 1350, 320, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn43'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs4')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn44')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn44', @presenceid, 2, @definition, 1260, 420, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn44'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs5')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn45')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn45', @presenceid, 2, @definition, 1170, 420, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn45'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs6')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn46')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn46', @presenceid, 2, @definition, 1030, 380, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn46'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs7')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn47')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn47', @presenceid, 3, @definition, 1320, 540, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn47'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs8')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn48')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn48', @presenceid, 1, @definition, 1470, 290, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn48'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_numiquol_npcs9')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn49')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn49', @presenceid, 3, @definition, 1290, 280, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn49'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank2')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn30')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn30', @presenceid, 2, @definition, 240, 1700, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank2', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn30'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn21')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn21', @presenceid, 1, @definition, 1290, 1410, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn21'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn22')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn22', @presenceid, 2, @definition, 1180, 1490, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn22'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn23')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn23', @presenceid, 2, @definition, 1030, 1390, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn23'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn24')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn24', @presenceid, 2, @definition, 940, 1500, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn24'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn25')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn25', @presenceid, 2, @definition, 740, 1450, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn25'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn26')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn26', @presenceid, 2, @definition, 600, 1485, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn26'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn26')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn26', @presenceid, 2, @definition, 600, 1485, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn26'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn27')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn27', @presenceid, 3, @definition, 690, 1700, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn27'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn27')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn27', @presenceid, 3, @definition, 690, 1700, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn27'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn28')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn28', @presenceid, 3, @definition, 500, 1730, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn28'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_pelistal_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn29')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn29', @presenceid, 3, @definition, 400, 1560, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn29'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn31')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn31', @presenceid, 1, @definition, 740, 550, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn31'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn32')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn32', @presenceid, 2, @definition, 620, 720, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn32'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn33')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn33', @presenceid, 2, @definition, 520, 920, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn33'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn34')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn34', @presenceid, 1, @definition, 455, 740, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn34'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn35')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn35', @presenceid, 2, @definition, 820, 320, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn35'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn35')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn35', @presenceid, 2, @definition, 820, 320, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank3', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn35'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn36')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn36', @presenceid, 2, @definition, 600, 430, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn36'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn37')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn37', @presenceid, 3, @definition, 430, 540, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn37'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'termis_support_at_spawn38')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('termis_support_at_spawn38', @presenceid, 2, @definition, 550, 250, 0, 5, 60, 0, 30, 'def_npc_termis_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'termis_support_at_spawn38'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'riveler_support_at_spawn39')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('riveler_support_at_spawn39', @presenceid, 3, @definition, 260, 650, 0, 5, 60, 0, 30, 'def_npc_riveler_support_rank4', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'riveler_support_at_spawn39'
END

--

SET @presenceid = (SELECT TOP 1 id FROM npcpresence WHERE name = 'hershfield_theolodical_npcs')

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank2')

IF NOT EXISTS (SELECT 1 FROM npcflock WHERE name = 'argano_support_at_spawn30')
BEGIN
INSERT INTO npcflock ([name], presenceid, flockmembercount, [definition], spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, [enabled], iscallforhelp, behaviorType, npcSpecialType) VALUES
	('argano_support_at_spawn30', @presenceid, 1, @definition, 385, 300, 0, 5, 60, 0, 30, 'def_npc_argano_support_rank2', 1, 1, 1, 1, 0)
END
ELSE
BEGIN
	UPDATE npcflock SET respawnseconds = 60 WHERE name = 'argano_support_at_spawn30'
END

----

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank1')

DELETE FROM npcloot WHERE definition = @definition

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 16, 1, 0, 0, 13)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 24, 1, 0, 1, 16)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 12, 1, 0, 1, 8)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank2')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 10, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 21, 1, 0, 0, 17)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 48, 1, 0, 1, 32)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 24, 1, 0, 1, 16)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank3')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 32, 1, 0, 0, 26)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 96, 1, 0, 1, 64)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 48, 1, 0, 1, 32)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank4')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 48, 1, 0, 0, 39)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 24, 1, 0, 1, 16)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 96, 1, 0, 1, 64)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_argano_support_rank5')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_small_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 71, 1, 0, 0, 58)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 48, 1, 0, 1, 32)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 192, 1, 0, 1, 128)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank1')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.05, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 66, 1, 0, 0, 54)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 96, 1, 0, 1, 64)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 48, 1, 0, 1, 32)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank2')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 10, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 10, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 86, 1, 0, 0, 70)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 96, 1, 0, 1, 64)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank3')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 132, 1, 0, 0, 108)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 384, 1, 0, 1, 256)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 192, 1, 0, 1, 128)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank4')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 197, 1, 0, 0, 161)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 96, 1, 0, 0, 64)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 384, 1, 0, 1, 256)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_termis_support_rank5')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 296, 1, 0, 0, 242)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 192, 1, 0, 1, 128)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 768, 1, 0, 1, 512)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank1')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.5, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 178, 1, 0, 0, 146)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 120, 1, 0, 1, 80)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 60, 1, 0, 1, 40)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank2')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 10, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.1, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 232, 1, 0, 0, 190)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 240, 1, 0, 1, 160)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 120, 1, 0, 1, 80)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank3')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.125, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named1_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_1')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_2')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 357, 1, 0, 0, 292)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_common')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 480, 1, 0, 1, 320)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 240, 1, 0, 1, 160)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank4')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.15, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named2_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_3')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_4')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 536, 1, 0, 0, 438)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_hitech')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 120, 1, 0, 1, 80)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_kernel_industrial')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 480, 1, 0, 1, 320)

--

SET @definition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_npc_riveler_support_rank5')

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_sensor_booster')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_eccm')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_armor_repairer_upgrade')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_shield_hardener')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_remote_armor_repairer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_energy_transfer')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_shield_generator')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_core_recharger')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_core_battery')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_standard_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.175, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_named3_medium_armor_plate')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.0025, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_5')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_6')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.02, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_7')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_8')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.01, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_9')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_research_kit_10')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 1, 0.005, 0, 0, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_common_reactor_plasma')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 805, 1, 0, 0, 658)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_basic')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 3, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_advanced')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 5, 0.5, 0, 1, 1)

SET @lootDefinition = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_robotshard_common_expert')
INSERT INTO npcloot (definition, lootdefinition, quantity, probability, repackaged, dontdamage, minquantity)
VALUES (@definition, @lootDefinition, 7, 0.5, 0, 1, 1)

--

GO
-- 17_Orange_Syndicate_Soldiers.sql

USE perpetuumsa;
GO

-- Perpetuum.AdminTool generated script
-- Generated: 2026-05-06 07:18:00 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] npcflock: update id 8534 ('syndicate_N01_z2_echelon_main_combat', 1 column(s))
UPDATE npcflock SET behaviorType = 1 WHERE id = 8534
;

-- [2] npcflock: update id 8535 ('syndicate_N02_z2_echelon_main_combat', 1 column(s))
UPDATE npcflock SET behaviorType = 1 WHERE id = 8535
;

-- [3] npcflock: update id 8536 ('syndicate_N03_z2_echelon_main_combat', 1 column(s))
UPDATE npcflock SET behaviorType = 1 WHERE id = 8536
;

COMMIT TRANSACTION;

GO
-- 18_Hershfield_Syndicate_Forces.sql

USE perpetuumsa;
GO

-- Perpetuum.AdminTool generated script
-- Generated: 2026-05-07 04:46:41 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] entitydefaults: insert (def_syndicate_forces_locust_main_combat_bot) + 15 stat(s) — id auto-assigned via @new_def_c91060d8
INSERT INTO entitydefaults (definitionName, descriptionToken, categoryflags, attributeflags, mass, volume, health, quantity, hidden, purchasable, tiertype, tierlevel, options, enabled) VALUES (N'def_syndicate_forces_locust_main_combat_bot', N'def_syndicate_forces_locust_main_combat_bot_desc', 143, 1024, 0, 0, 100, 1, 0, 0, NULL, NULL, N'#faction=SSyndicate', 1);
DECLARE @new_def_c91060d8 INT = SCOPE_IDENTITY();

DELETE FROM aggregatevalues WHERE definition = @new_def_c91060d8

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_recharge_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, -0.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -0.25 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @new_def_c91060d8 AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @new_def_c91060d8 AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@new_def_c91060d8, @field, -10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -10 WHERE definition = @new_def_c91060d8 AND field = @field
END

-- [2] robottemplates: insert (Locust_Main_Combat) — id auto-assigned via @new_tmpl_f7c1f420
INSERT INTO robottemplates (name, description, note) VALUES (N'Locust_Main_Combat', N'#robot=i1588#head=i1589#chassis=i158a#leg=i158b#container=i148#headModules=[|m0=[|definition=i302|slot=i1]|m1=[|definition=i314|slot=i2]|m2=[|definition=i31d|slot=i3]|m3=[|definition=i3a7|slot=i4]|m4=[|definition=i3a7|slot=i5]]#chassisModules=[|m0=[|definition=i34a|slot=i1|ammoDefinition=i984|ammoQuantity=ic8]|m1=[|definition=i34a|slot=i2|ammoDefinition=i984|ammoQuantity=ic8]|m2=[|definition=i34a|slot=i3|ammoDefinition=i984|ammoQuantity=ic8]|m3=[|definition=i34a|slot=i4|ammoDefinition=i984|ammoQuantity=ic8]|m4=[|definition=i34a|slot=i5|ammoDefinition=i984|ammoQuantity=ic8]]#legModules=[|m0=[|definition=i2b7|slot=i1]|m1=[|definition=i3bc|slot=i2]|m2=[|definition=i3bc|slot=i3]|m3=[|definition=i2ae|slot=i4]]', N'Syndicate Forces Main Combat Locust');
DECLARE @new_tmpl_f7c1f420 INT = SCOPE_IDENTITY();

DELETE FROM robottemplaterelation WHERE definition = @new_def_c91060d8

INSERT INTO robottemplaterelation (definition, templateid, raceid, missionlevel, missionleveloverride, killep, note) VALUES
(@new_def_c91060d8, @new_tmpl_f7c1f420, 0, NULL, NULL, 15, 'def_npc_hersh_locust_main_combat')

-- [1] npcpresence: insert 'syndicate_N01_z8' (spawn 13)
INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES (N'syndicate_N01_z8', 640, 380, 1405, 1150, N'hershfield syndicate forces 1', 13, 1, 1, 900, 5, NULL, 945, 790, 350, NULL, 1, 1, 1, NULL, NULL)
;

-- [1] npcflock: insert 'syndicate_N01_z8_argano_main_support' (presence 2511, def 8941)
INSERT INTO npcflock (name, presenceid, flockmembercount, definition, spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, enabled, iscallforhelp, behaviorType, npcSpecialType) VALUES (N'syndicate_N01_z8_argano_main_support', 2511, 2, 8941, 0, 0, 0, 10, 7200, 0, 50, N'hershfield npc', 0.9, 1, 1, 1, 0)
;

-- [2] npcflock: insert 'syndicate_N01_z8_locust_main_combat' (presence 2511, def 8957)
INSERT INTO npcflock (name, presenceid, flockmembercount, definition, spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, enabled, iscallforhelp, behaviorType, npcSpecialType) VALUES (N'syndicate_N01_z8_locust_main_combat', 2511, 3, 8957, 0, 0, 0, 10, 7200, 0, 50, N'hershfield npc', 0.9, 1, 1, 1, 0)
;

-- [1] npcpresence: insert 'syndicate_N02_z8' (spawn 13)
INSERT INTO npcpresence (name, topx, topy, bottomx, bottomy, note, spawnid, enabled, roaming, roamingrespawnseconds, presencetype, maxrandomflock, randomcenterx, randomcentery, randomradius, dynamiclifetime, isbodypull, isrespawnallowed, safebodypull, izgroupid, growthseconds) VALUES (N'syndicate_N02_z8', 640, 380, 1405, 1150, N'hershfield syndicate forces 2', 13, 1, 1, 900, 5, NULL, 945, 790, 350, NULL, 1, 1, 1, NULL, NULL)
;

-- [1] npcflock: insert 'syndicate_N01_z8_argano_main_support' (presence 2511, def 8941)
INSERT INTO npcflock (name, presenceid, flockmembercount, definition, spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, enabled, iscallforhelp, behaviorType, npcSpecialType) VALUES (N'syndicate_N02_z8_argano_main_support', 2511, 2, 8941, 0, 0, 0, 10, 7200, 0, 50, N'hershfield npc', 0.9, 1, 1, 1, 0)
;

-- [2] npcflock: insert 'syndicate_N01_z8_locust_main_combat' (presence 2511, def 8957)
INSERT INTO npcflock (name, presenceid, flockmembercount, definition, spawnoriginX, spawnoriginY, spawnrangeMin, spawnrangeMax, respawnseconds, totalspawncount, homerange, note, respawnmultiplierlow, enabled, iscallforhelp, behaviorType, npcSpecialType) VALUES (N'syndicate_N02_z8_locust_main_combat', 2511, 3, 8957, 0, 0, 0, 10, 7200, 0, 50, N'hershfield npc', 0.9, 1, 1, 1, 0)
;

COMMIT TRANSACTION;

GO
-- 19_Redefine_Syndicate_Forces_Vektor_stats.sql

USE perpetuumsa;
GO

DECLARE @targetDefinition INT = (SELECT TOP 1 definition FROM entitydefaults WHERE definitionname = 'def_syndicate_forces_vektor_main_combat_bot')

DELETE FROM aggregatevalues WHERE definition = @targetDefinition

DECLARE @field INT

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'armor_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.3)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 3 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'core_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
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

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'cpu_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'damage_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'falloff_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.5)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.5 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'locking_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'optimal_range_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1.2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1.2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'powergrid_max_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 2)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 2 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'signature_radius')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -0.25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -0.25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'turret_cycle_time_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.9)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.9 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_radius_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 0.4)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 0.4 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'blob_emission_modifier_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 1)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 1 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'detection_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, 25)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = 25 WHERE definition = @targetDefinition AND field = @field
END

SET @field = (SELECT TOP 1 id FROM aggregatefields WHERE name = 'stealth_strength_modifier')

IF NOT EXISTS (SELECT 1 FROM aggregatevalues WHERE definition = @targetDefinition AND field = @field)
BEGIN
	INSERT INTO aggregatevalues (definition, field, value) VALUES (@targetDefinition, @field, -10)
END
ELSE
BEGIN
	UPDATE aggregatevalues SET value = -10 WHERE definition = @targetDefinition AND field = @field
END

GO
