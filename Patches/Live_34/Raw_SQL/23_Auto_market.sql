
USE perpetuumsa;
GO

---- Create and fill raw material prices table

-- Drop existing objects if they exist
IF OBJECT_ID('dbo.raw_material_prices', 'U') IS NOT NULL DROP TABLE raw_material_prices;
GO

CREATE TABLE raw_material_prices (
    material_name VARCHAR(100) PRIMARY KEY,
    price_nic DECIMAL(18, 2) NOT NULL
);
GO

-- Insert material prices
INSERT INTO raw_material_prices (material_name, price_nic) VALUES
('def_titan', 3.00),
('def_crude', 0.5),
('def_silgium', 4.00),
('def_liquizit', 1.00),
('def_epriton', 4.00),
('def_triandlus', 3.00),
('def_stermonit', 4.00),
('def_imentium', 4.00),
('def_helioptris', 4.00),
('def_prismocitae', 3.00),
('def_electroplant_fruit', 10),
('def_gammaterial', 250),
('def_fluxore', 150.00),
('def_robotshard_common_basic', 700.00),
('def_robotshard_common_advanced', 600.00),
('def_robotshard_common_expert', 5000.00),
('def_robotshard_nuimqol_basic', 700.00),
('def_robotshard_nuimqol_advanced', 600.00),
('def_robotshard_nuimqol_expert', 1300.00),
('def_robotshard_thelodica_basic', 700.00),
('def_robotshard_thelodica_advanced', 600.00),
('def_robotshard_thelodica_expert', 1300.00),
('def_robotshard_pelistal_basic', 700.00),
('def_robotshard_pelistal_advanced', 600.00),
('def_robotshard_pelistal_expert', 1300.00);
GO

---- Create view that shows all the production tree

-- Drop and create view
IF OBJECT_ID('dbo.production_data', 'V') IS NOT NULL DROP VIEW production_data;
GO

CREATE VIEW production_data AS
SELECT 
    ed.definitionname AS product,
    ced.definitionname AS components,
    c.componentamount AS amount
FROM components c
INNER JOIN entitydefaults ed ON c.definition = ed.definition
INNER JOIN entitydefaults ced ON c.componentdefinition = ced.definition
WHERE ed.purchasable = 1 AND ed.enabled = 1 AND ed.hidden = 0;-- AND (ed.tiertype IS NULL OR ed.tiertype = 1);-- AND ed.attributeflags & CONVERT(BIGINT, 2147483648) = 0;
GO

---- Create view that shows production cost assuming 50% efficiency of all the facilities

CREATE OR ALTER VIEW v_all_production_costs AS
WITH all_items AS (
    SELECT product AS item FROM production_data
    UNION
    SELECT components AS item FROM production_data
),
recursive_materials AS (
    SELECT 
        base.item,
        pd.components AS raw_material,
        CAST(pd.amount * 2.0 AS FLOAT) AS quantity
    FROM all_items base
    JOIN production_data pd ON pd.product = base.item

    UNION ALL

    SELECT
        rm.item,
        pd.components AS raw_material,
        rm.quantity * pd.amount * 2.0 AS quantity
    FROM recursive_materials rm
    JOIN production_data pd ON rm.raw_material = pd.product
),
aggregated_costs AS (
    SELECT
        rm.item AS product,
        rm.raw_material,
        SUM(rm.quantity) AS total_quantity
    FROM recursive_materials rm
    GROUP BY rm.item, rm.raw_material
),
computed_costs AS (
    SELECT
        ac.product,
        SUM(COALESCE(ac.total_quantity * rmp.price_nic, 0)) AS production_cost_nic
    FROM aggregated_costs ac
    LEFT JOIN raw_material_prices rmp ON ac.raw_material = rmp.material_name
    GROUP BY ac.product
),
raw_resources AS (
    SELECT 
        material_name AS product,
        price_nic AS production_cost_nic
    FROM raw_material_prices
    WHERE NOT EXISTS (
        SELECT 1 FROM production_data WHERE product = material_name
    )
),
final_costs AS (
    SELECT * FROM computed_costs
    UNION
    SELECT * FROM raw_resources
)
SELECT 
    product,
    ROUND(production_cost_nic, 2) AS production_cost_nic
FROM final_costs;

GO

---- Create and fill market orders condifuration that will be used to renew sell orders

IF OBJECT_ID('dbo.market_orders_configuration', 'U') IS NOT NULL DROP TABLE market_orders_configuration;
GO

CREATE TABLE market_orders_configuration (
    definitionname VARCHAR(100) NOT NULL,
    amount INT NOT NULL
);
GO

-- Insert items and amount
INSERT INTO market_orders_configuration (definitionname, amount) VALUES
('def_kain_bot', 5),
('def_artemis_bot', 5),
('def_tyrannos_bot', 5),
('def_echelon_bot', 5),
('def_named3_medium_laser', 20),
('def_named3_medium_autocannon', 20),
('def_named3_missile_launcher', 20),
('def_named3_medium_railgun', 20),
('def_named3_longrange_medium_railgun', 20),
('def_named3_longrange_medium_laser', 20),
('def_named3_longrange_medium_autocannon', 20)

GO

---- Create view that shows required raw materials

-- Drop existing view if it exists
IF OBJECT_ID('dbo.v_required_raw_materials', 'V') IS NOT NULL
    DROP VIEW dbo.v_required_raw_materials;
GO

-- Create the view
CREATE VIEW dbo.v_required_raw_materials AS
WITH RecursiveBreakdown AS (
    -- Base case: direct components
    SELECT 
        moc.definitionname AS product,
        pd.components AS component,
        pd.amount * moc.amount * 2 AS total_amount  -- 50% efficiency adjustment
    FROM dbo.market_orders_configuration moc
    JOIN dbo.production_data pd ON moc.definitionname = pd.product

    UNION ALL

    -- Recursive case: break down intermediate components
    SELECT 
        rb.product,
        pd.components AS component,
        rb.total_amount * pd.amount * 2 AS total_amount
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

---- Add isAutoOrder into marketitems

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
ALTER TABLE dbo.marketitems ADD
	isAutoOrder bit NULL
GO
ALTER TABLE dbo.marketitems SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Create stored procedure that will refresh autoorders

CREATE OR ALTER PROCEDURE usp_RefreshAutoMarketOrders
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

        -- Step 3: Insert new auto-orders
        INSERT INTO marketitems (marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoorder)
        SELECT 
            @marketeid,
            ed.definition,
            @vendoreid,     -- Note: double-check if this should be used as duration or another field
            0 AS isSell,
            1 AS duration,   -- ← You may want to fix this mapping: @vendoreid seems misplaced
            pc.production_cost_nic,
            moc.amount,
            1 AS isvendoritem,
            1 AS isAutoorder
        FROM market_orders_configuration moc
        INNER JOIN entitydefaults ed ON moc.definitionname = ed.definitionname
        INNER JOIN v_all_production_costs pc ON moc.definitionname = pc.product;

		-- Final selection: only include components that are not themselves products (i.e., raw materials)
		INSERT INTO marketitems (marketeid, itemdefinition, submittereid, duration, isSell, price, quantity, isvendoritem, isAutoOrder)
			SELECT @marketeid, ed.definition, @vendoreid,  0, 0, apc.production_cost_nic, total_quantity, 1, 1 FROM v_required_raw_materials rrm
			INNER JOIN entitydefaults ed ON rrm.raw_material = ed.definitionname
			INNER JOIN v_all_production_costs apc ON rrm.raw_material = apc.product

    END TRY
    BEGIN CATCH
        PRINT 'Error in usp_RefreshAutoMarketOrders: ' + ERROR_MESSAGE();
        THROW;
    END CATCH
END;

GO
