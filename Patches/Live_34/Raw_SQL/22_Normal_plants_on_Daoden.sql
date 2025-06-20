USE perpetuumsa;

GO

---- Reconfigure plants

DECLARE @rulesetid INT

SET @rulesetid = (SELECT TOP 1 plantruleset FROM zones WHERE name = 'zone_ASI')

DELETE FROM plantrules WHERE rulesetid = @rulesetid

INSERT INTO plantrules (plantrule, rulesetid, note) VALUES
('bonsai.txt', @rulesetid, 'decor'),
('bush_a.txt', @rulesetid, 'decor'),
('bush_b.txt', @rulesetid, 'decor'),
('coppertree.txt', @rulesetid, 'decor'),
('devrinol.txt', @rulesetid, 'decor'),
('electroplant_hi.txt', @rulesetid, 'harvestable'),
('grass_a.txt', @rulesetid, 'decor'),
('grass_b.txt', @rulesetid, 'decor'),
('irontree_hi.txt', @rulesetid, 'harvestable'),
('nanowheat.txt', @rulesetid, 'decor'),
('pinetree.txt', @rulesetid, 'decor'),
('poffeteg.txt', @rulesetid, 'decor'),
('quag.txt', @rulesetid, 'decor'),
('rango.txt', @rulesetid, 'decor'),
('reed.txt', @rulesetid, 'decor'),
('rustbush_hi.txt', @rulesetid, 'harvestable'),
('slimeroot_hi.txt', @rulesetid, 'harvestable'),
('titanplant.txt', @rulesetid, 'decor'),
('wall.txt', @rulesetid, 'decor')

GO