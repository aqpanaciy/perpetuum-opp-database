USE [perpetuumsa]
GO

---- Fix v_required_raw_materials

/****** Object:  View [dbo].[v_required_raw_materials]    Script Date: 04.07.2025 18:57:07 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


-- Create the view
CREATE OR ALTER VIEW [dbo].[v_required_raw_materials] AS
WITH RecursiveBreakdown AS (
    -- Base case: direct components
    SELECT 
        moc.definitionname AS product,
        pd.components AS component,
        pd.amount * CAST(ROUND(moc.amount * 2.1, 0) AS BIGINT) AS total_amount  -- 50% efficiency adjustment
    FROM dbo.market_orders_configuration moc
    JOIN dbo.production_data pd ON moc.definitionname = pd.product

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
    rb.component AS raw_material,
    SUM(rb.total_amount) AS total_quantity
FROM RecursiveBreakdown rb
LEFT JOIN dbo.production_data pd ON rb.component = pd.product
WHERE pd.product IS NULL
GROUP BY rb.component;

GO




---- Fix usp_RefreshAutoMarketOrders

CREATE OR ALTER PROCEDURE [dbo].[usp_RefreshAutoMarketOrders]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Step 1: Remove old auto orders
        DELETE FROM marketitems WHERE isAutoOrder = 1;

        -- Step 2: Fetch market and vendor EIDs
        DECLARE @marketeid BIGINT;
        DECLARE @vendoreid BIGINT;

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
        DECLARE @batch INT = 500000000;

        -- Use a cursor to handle splitting quantities
        DECLARE raw_cursor CURSOR FOR
        SELECT 
            ed.definition AS itemdefinition,
            apc.production_cost_nic AS unit_price,
            rrm.total_quantity AS total_quantity
        FROM v_required_raw_materials rrm
        INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
        INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product;

        DECLARE @itemdefinition INT;
        DECLARE @unit_price FLOAT;
        DECLARE @quantity BIGINT;
        DECLARE @remaining BIGINT;

        OPEN raw_cursor;
        FETCH NEXT FROM raw_cursor INTO @itemdefinition, @unit_price, @quantity;

        WHILE @@FETCH_STATUS = 0
        BEGIN
        PRINT(@quantity);
            SET @remaining = @quantity;

            WHILE @remaining > 0
            BEGIN
                INSERT INTO marketitems (
                    marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder
                )
                VALUES (
                    @marketeid, @itemdefinition, @vendoreid, 0, 0, @unit_price, @batch, 1, 1
                );

                SET @remaining -= @batch;
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
