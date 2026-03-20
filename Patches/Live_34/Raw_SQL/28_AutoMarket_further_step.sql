
USE perpetuumsa;
GO

---- Create statistics table for plasma sold

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
CREATE TABLE dbo.plasma_sold
	(
	sold_on date NOT NULL,
	plasma_type varchar(100) NOT NULL,
	quantity BIGINT NOT NULL,
    income FLOAT
	)  ON [PRIMARY]
GO
ALTER TABLE dbo.plasma_sold SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create sp to register plasma sold statistics

CREATE PROCEDURE sp_RecordPlasmaSold
    @sold_on DATE,
    @plasma_type VARCHAR(50),
    @quantity BIGINT,
    @income FLOAT
AS
BEGIN
    SET NOCOUNT ON;

    MERGE plasma_sold AS target
    USING (SELECT @sold_on AS sold_on, @plasma_type AS plasma_type) AS source
    ON target.sold_on = source.sold_on AND target.plasma_type = source.plasma_type
    WHEN MATCHED THEN
        UPDATE SET quantity = quantity + @quantity, income = income + @income
    WHEN NOT MATCHED THEN
        INSERT (sold_on, plasma_type, quantity, income)
        VALUES (@sold_on, @plasma_type, @quantity, @income);
END;

GO

---- Create table function to calculate dynamic prices for a given island type

CREATE OR ALTER FUNCTION dbo.fn_CalculateDynamicPlasmaPrices (@island_type INT)
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
            ('def_thelodica_reactor_plasma', 1.35),
            ('def_pelistal_reactor_plasma', 1.35),
            ('def_nuimqol_reactor_plasma', 1.35)
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

---- Change auto orders placement so that it places plasma buy orders across all the islands

CREATE OR ALTER PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
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
                v.vendorEID AS submitereid,
                cdp.dynamic_price AS price,
                cdp.gathered AS quantity
            FROM dbo.fn_CalculateDynamicPlasmaPrices(3) cdp
            JOIN dbo.entitydefaults ed
                ON cdp.plasma_type = ed.definitionname
            CROSS JOIN Markets m
            JOIN dbo.vendors v
                ON m.eid = v.marketEID;

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

    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

---- Change raw resources price calculation to use dynamic plasma prices. Also set restrains to 50%-300%

CREATE OR ALTER   PROCEDURE [dbo].[recalculate_raw_material_prices]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @today DATE = CAST(GETDATE() AS DATE);
    DECLARE @week_start DATE = DATEADD(DAY, -DATEPART(WEEKDAY, @today) + 2, @today); -- Monday
    DECLARE @startDate DATE = DATEADD(DAY, -7, @today);

    -- Total NIC value from plasma gathered
    DECLARE @total_plasma_nic DECIMAL(18,2);

    --
    DECLARE @avg_common_price DECIMAL(18, 2);
    DECLARE @avg_racial_price DECIMAL(18, 2);

    WITH combined_prices AS (
        SELECT 1 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(1)
        UNION ALL
        SELECT 2 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(2)
        UNION ALL
        SELECT 3 AS island_type, * FROM dbo.fn_CalculateDynamicPlasmaPrices(3)
    )
    SELECT
        @avg_common_price = AVG(CASE WHEN plasma_type = 'def_common_reactor_plasma' THEN dynamic_price END),
        @avg_racial_price = AVG(CASE 
            WHEN plasma_type IN (
                'def_thelodica_reactor_plasma', 
                'def_pelistal_reactor_plasma', 
                'def_nuimqol_reactor_plasma') 
            THEN dynamic_price END)
    FROM combined_prices;
    --


    SELECT @total_plasma_nic = 
        ISNULL(SUM(CASE 
            WHEN plasma_type COLLATE DATABASE_DEFAULT = 'def_common_reactor_plasma' THEN quantity * @avg_common_price
            WHEN plasma_type COLLATE DATABASE_DEFAULT IN (
                'def_pelistal_reactor_plasma',
                'def_thelodica_reactor_plasma',
                'def_nuimqol_reactor_plasma'
            ) THEN quantity * @avg_racial_price
            ELSE 0 END), 0)
    FROM plasma_gathered
    WHERE gathered_on >= @startDate;

    -- Total resources gathered
    DECLARE @total_resources BIGINT;
    SELECT @total_resources = SUM(quantity)
    FROM resources_gathered
    WHERE gathered_on >= @startDate;

    -- Step 1: Compute new prices
    IF OBJECT_ID('tempdb..#new_prices') IS NOT NULL DROP TABLE #new_prices;
    CREATE TABLE #new_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        new_price_nic DECIMAL(18,2)
    );

    INSERT INTO #new_prices(resource_name, new_price_nic)
    SELECT 
        rg.resource_name COLLATE DATABASE_DEFAULT,
        ROUND(
            CASE 
                WHEN @total_resources = 0 THEN 0
                ELSE (@total_plasma_nic * 1.0 * SUM(rg.quantity) / @total_resources)
            END, 2
        )
    FROM resources_gathered rg
    WHERE gathered_on >= @startDate
    GROUP BY rg.resource_name;

    -- Step 2: Get fallback base prices
    IF OBJECT_ID('tempdb..#fallback_prices') IS NOT NULL DROP TABLE #fallback_prices;
    CREATE TABLE #fallback_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #fallback_prices(resource_name, unit_price)
    SELECT 
        rmp.material_name COLLATE DATABASE_DEFAULT,
        rmp.price_nic
    FROM raw_material_prices rmp
    WHERE NOT EXISTS (
        SELECT 1 FROM #new_prices np
        WHERE np.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT
    );

    -- Step 3: Combine new and fallback prices
    IF OBJECT_ID('tempdb..#merged_prices') IS NOT NULL DROP TABLE #merged_prices;
    CREATE TABLE #merged_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #merged_prices(resource_name, unit_price)
    SELECT resource_name, new_price_nic FROM #new_prices
    UNION ALL
    SELECT resource_name, unit_price FROM #fallback_prices;

    -- Step 4: Clamp against raw_material_prices base values
    IF OBJECT_ID('tempdb..#clamped_prices') IS NOT NULL DROP TABLE #clamped_prices;
    CREATE TABLE #clamped_prices (
        resource_name VARCHAR(100) COLLATE DATABASE_DEFAULT PRIMARY KEY,
        unit_price DECIMAL(18,2)
    );

    INSERT INTO #clamped_prices(resource_name, unit_price)
    SELECT 
        mp.resource_name,
        CASE 
            WHEN mp.unit_price > rmp.price_nic * 3 THEN rmp.price_nic * 3
            WHEN mp.unit_price < rmp.price_nic * 0.5 THEN rmp.price_nic * 0.5
            ELSE mp.unit_price
        END
    FROM #merged_prices mp
    JOIN raw_material_prices rmp
        ON mp.resource_name COLLATE DATABASE_DEFAULT = rmp.material_name COLLATE DATABASE_DEFAULT;

    -- Step 5: Upsert to resource_market_prices
    MERGE INTO dbo.resource_market_prices AS target
    USING (
        SELECT resource_name, unit_price FROM #clamped_prices
    ) AS source
    ON target.calculated_on = @week_start
       AND target.resource_name COLLATE DATABASE_DEFAULT = source.resource_name COLLATE DATABASE_DEFAULT
    WHEN MATCHED THEN
        UPDATE SET unit_price = source.unit_price
    WHEN NOT MATCHED THEN
        INSERT (calculated_on, resource_name, unit_price)
        VALUES (@week_start, source.resource_name, source.unit_price);

    -- Step 6: Optional cleanup of old stats
    DELETE FROM plasma_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
    DELETE FROM plasma_sold WHERE sold_on < DATEADD(DAY, -90, @today);
    DELETE FROM resources_gathered WHERE gathered_on < DATEADD(DAY, -90, @today);
END;
GO

---- Delete unlimited plasma buy orders

DELETE FROM marketitems WHERE isvendoritem = 1 AND itemdefinition IN (
    3271,
    3272,
    3273,
    3274
)
GO
