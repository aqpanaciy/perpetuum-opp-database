
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


