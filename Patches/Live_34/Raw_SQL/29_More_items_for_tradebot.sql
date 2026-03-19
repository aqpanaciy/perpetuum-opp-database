
USE perpetuumsa;
GO

---- Add or update items and amounts

DECLARE @tempTable TABLE (definitionname VARCHAR(100), amount INT)

INSERT INTO @tempTable (definitionname, amount) VALUES
('def_riveler_bot', 3),
('def_symbiont_bot', 3),
('def_kain_mk2_bot', 1),
('def_tyrannos_mk2_bot', 1),
('def_artemis_mk2_bot', 1)

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
