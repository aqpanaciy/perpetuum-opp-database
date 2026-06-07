-- Perpetuum.AdminTool generated script
-- Generated: 2026-06-06 02:02:04 UTC
-- Author: devours@internet.ru

SET XACT_ABORT ON;
BEGIN TRANSACTION;

-- [1] market_orders_configuration: delete def_callisto_bot
DELETE FROM market_orders_configuration WHERE definitionname = N'def_callisto_bot'
;

-- [2] market_orders_configuration: delete def_echelon_bot
DELETE FROM market_orders_configuration WHERE definitionname = N'def_echelon_bot'
;

-- [3] market_orders_configuration: delete def_legatus_bot
DELETE FROM market_orders_configuration WHERE definitionname = N'def_legatus_bot'
;

COMMIT TRANSACTION;
