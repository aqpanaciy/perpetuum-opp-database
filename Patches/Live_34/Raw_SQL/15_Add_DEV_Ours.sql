
USE perpetuumsa
GO

---- turn pre-created account 'devours@internet.ru' into admin account

UPDATE accounts SET accLevel = 14 WHERE email = 'devours@internet.ru'

GO

---- turn pre-created character with the nick 'Dat Nick' into DEV Ours

UPDATE characters SET corporationeid = 495, allianceeid = 2401, nick = 'DEV Ours' WHERE nick = 'Dat Nick'

GO
