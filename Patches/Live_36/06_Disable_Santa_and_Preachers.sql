
USE perpetuumsa;
GO

---- Enable Santa

UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_santa_z8'
UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_cultists_z6'
UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_cultists_z7'
UPDATE npcpresence SET enabled = 0 WHERE name = 'roamer_cultists_z1'

GO
