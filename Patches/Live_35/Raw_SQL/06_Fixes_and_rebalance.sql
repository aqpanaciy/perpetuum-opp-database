USE perpetuumsa;

GO

---- Fix remote controller extra zero issue

UPDATE aggregatevalues SET value = 180000 WHERE definition = 8560 AND field = 677

GO