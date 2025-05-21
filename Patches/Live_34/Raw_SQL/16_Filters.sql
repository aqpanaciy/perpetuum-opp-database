USE perpetuumsa

GO

IF NOT EXISTS (SELECT 1 FROM categoryflags WHERE name = 'cf_drones' )
BEGIN
	INSERT INTO categoryflags (value, name, note, hidden, isunique) VALUES
	(4353, 'cf_drones', 'Drones', 1, 0)
END

UPDATE categoryflags SET value = 69889, hidden = 1, isunique = 0 WHERE name = 'cf_assault_drones'
UPDATE categoryflags SET value = 135425, hidden = 1, isunique = 0 WHERE name = 'cf_industrial_drones'
UPDATE categoryflags SET value = 200961, hidden = 1, isunique = 0 WHERE name = 'cf_support_drones'
UPDATE categoryflags SET value = 266497, hidden = 1, isunique = 0 WHERE name = 'cf_attack_drones'

UPDATE entitydefaults SET categoryflags = 69889 WHERE categoryflags = 4498
UPDATE entitydefaults SET categoryflags = 135425 WHERE categoryflags = 4754
UPDATE entitydefaults SET categoryflags = 200961 WHERE categoryflags = 5010
UPDATE entitydefaults SET categoryflags = 266497 WHERE categoryflags = 5266

GO