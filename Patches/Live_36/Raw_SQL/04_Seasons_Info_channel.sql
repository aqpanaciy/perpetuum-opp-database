
USE perpetuumsa;
GO

---- Add Seasons Info channel and assign Announcer there

DECLARE @chanName AS VARCHAR(100) = 'Seasons Info';

IF NOT EXISTS (SELECT TOP 1 name FROM channels WHERE name=@chanName)
BEGIN
	PRINT N'INSERT INTO channels '+@chanName;
	INSERT INTO channels (name, password, topic, type, DiscordId) VALUES
	(@chanName, NULL, 'No active seasons', 1, '1503621202009391155');
END
ELSE
BEGIN
	PRINT N'UPDATE channels '+@chanName;
	UPDATE channels SET
		password=NULL,
		topic='No active seasons',
		type=1,
		DiscordId = '1503621202009391155'
	WHERE name=@chanName;
END

DECLARE @oppChar AS INT = (SELECT TOP 1 characterID FROM characters WHERE nick='[OPP] Announcer');
DECLARE @chanID AS INT = (SELECT TOP 1 id FROM channels WHERE name=@chanName);

DELETE FROM channelmembers WHERE channelid=@chanID AND memberid=@oppChar;
INSERT INTO channelmembers (channelid, memberid, role) VALUES
(@chanID, @oppChar, 2);

GO
