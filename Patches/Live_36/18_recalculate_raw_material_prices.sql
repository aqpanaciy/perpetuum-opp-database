USE [perpetuumsa]
 GO
 
 SET ANSI_NULLS ON
 GO
 SET QUOTED_IDENTIFIER ON
 GO

 ---- Dynamic supply/demand + PvP-risk formula anchored to live plasma prices

 CREATE OR ALTER PROCEDURE [dbo].[recalculate_raw_material_prices]
 AS
 BEGIN
         SET NOCOUNT ON ;

         DECLARE @today             DATE     = CAST ( GETUTCDATE ( )   AS   DATE ) ;
         DECLARE @week_start   DATE     = DATEADD ( DAY ,   - DATEPART ( WEEKDAY ,   @today )   +   2 ,   @today ) ;
         DECLARE @start_date   DATE     = DATEADD ( DAY ,   - 7 ,   @today ) ;

         DECLARE @anchor_fraction   FLOAT   =   (
                 SELECT   param_value   FROM   automarket_config   WHERE   param_name   =   'plasma_anchor_fraction'
         ) ;
         DECLARE @ds_min   FLOAT   =   (
                 SELECT   param_value   FROM   automarket_config   WHERE   param_name   =   'resource_ds_ratio_min'
         ) ;
         DECLARE @ds_max   FLOAT   =   (
                 SELECT   param_value   FROM   automarket_config   WHERE   param_name   =   'resource_ds_ratio_max'
         ) ;

         -- Alpha common plasma price as the anchor
         DECLARE @plasma_anchor   FLOAT   =   (
                 SELECT   TOP   1   dynamic_price
                 FROM   fn_CalculateDynamicPlasmaPrices ( 1 )
                 WHERE   plasma_type   =   'def_common_reactor_plasma'
         )   *   @anchor_fraction ;

         -- Compute and upsert new prices for all raw materials in the production chain
         WITH
         supply   AS   (
                 SELECT
                         resource_name ,
                         SUM ( CASE   WHEN   is_pvp   =   1   THEN   quantity   ELSE   0   END )     AS   pvp_qty ,
                         SUM ( quantity )                                                                                   AS   total_qty ,
                         SUM ( quantity )   /   7.0                                                                       AS   supply_daily_avg
                 FROM   resources_gathered
                 WHERE   gathered_on   > =   @start_date
                 GROUP   BY   resource_name
         ) ,
         demand_cte   AS   (
                 SELECT   raw_material ,   SUM ( total_quantity )   /   7.0   AS   daily_demand
                 FROM   v_required_raw_materials
                 GROUP   BY   raw_material
         ) ,
         materials   AS   (
                 SELECT   DISTINCT   raw_material   AS   resource_name
                 FROM   v_required_raw_materials
         ) ,
         priced   AS   (
                 SELECT
                         m . resource_name ,
                         ROUND (
                                 @plasma_anchor
                                 *   CASE
                                         WHEN   s . supply_daily_avg   IS   NULL   OR   s . supply_daily_avg   =   0
                                                 THEN   @ds_max
                                         ELSE
                                                 CASE
                                                         WHEN   ISNULL ( d . daily_demand ,   0 )   /   s . supply_daily_avg   <   @ds_min   THEN   @ds_min
                                                         WHEN   ISNULL ( d . daily_demand ,   0 )   /   s . supply_daily_avg   >   @ds_max   THEN   @ds_max
                                                         ELSE   ISNULL ( d . daily_demand ,   0 )   /   s . supply_daily_avg
                                                 END
                                     END
                                 *   ( 1.0   +   ISNULL (
                                         CAST ( s . pvp_qty   AS   FLOAT )   /   NULLIF ( s . total_qty ,   0 ) ,
                                         1.0
                                     ) ) ,
                                 2
                         )   AS   new_price
                 FROM   materials   m
                 LEFT   JOIN   supply           s   ON   s . resource_name   =   m . resource_name
                 LEFT   JOIN   demand_cte   d   ON   d . raw_material     =   m . resource_name
         )
         MERGE   INTO   dbo . resource_market_prices   AS   target
         USING   priced   AS   source
         ON     target . calculated_on     =   @week_start
         AND   target . resource_name   COLLATE   DATABASE_DEFAULT   =   source . resource_name   COLLATE   DATABASE_DEFAULT
         WHEN   MATCHED   THEN
                 UPDATE   SET   unit_price   =   source . new_price
         WHEN   NOT   MATCHED   THEN
                 INSERT   ( calculated_on ,   resource_name ,   unit_price )
                 VALUES   ( @week_start ,   source . resource_name ,   source . new_price ) ;

         -- Cleanup old stats ( 90 - day rolling window )
         DELETE   FROM   plasma_gathered         WHERE   gathered_on   <   DATEADD ( DAY ,   - 90 ,   @today ) ;
         DELETE   FROM   plasma_sold                 WHERE   sold_on           <   DATEADD ( DAY ,   - 90 ,   @today ) ;
         DELETE   FROM   resources_gathered   WHERE   gathered_on   <   DATEADD ( DAY ,   - 90 ,   @today ) ;
 END ;
 GO
