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


