
USE perpetuumsa
GO

---- Create and fill technical character
DELETE FROM characters WHERE nick = 'Discord'

INSERT INTO characters (
	accountId,
	rootEID,
	nick,
	moodMessage,
	creation,
	lastLogOut,
	lastUsed,
	credit,
	inUse,
	totalMinsOnline,
	activeChassis,
	active,
	deletedAt,
	baseEID,
	defaultcorporationEID,
	majorID,
	raceID,
	schoolID,
	sparkID,
	lastdocked, docked, lastteleported, zoneID, nickcorrected, offensivenick, positionX, positionY, homeBaseEID, blockTrades, globalMute, avatar, note, corporationeid, allianceeid, [language], LastRespec) VALUES
(
	3156,
	8702057415139945528,
	'Discord',
	NULL,
	GETDATE(),
	NULL,
	NULL,
	0,
	0,
	0,
	8669878442849126445,
	1,
	NULL,
	142,
	499,
	5,
	1,
	2,
	5, NULL, 1, NULL, NULL, 0, 0, NULL, NULL, 961, 0, 0, NULL, 'OPP Discord Integration Character', 47423, NULL, 0, NULL)
	
GO

DECLARE @characterId INT

SET @characterId = (SELECT TOP 1 characterID FROM characters WHERE nick = 'Discord')

DELETE FROM corporationmembers WHERE corporationEID = 666 and memberid = @characterId

INSERT INTO corporationmembers (corporationEID, memberid, role) VALUES
(47423, @characterId, 4194303)

GO
