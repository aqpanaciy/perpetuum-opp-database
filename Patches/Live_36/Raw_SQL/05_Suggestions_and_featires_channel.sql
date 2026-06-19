
USE perpetuumsa;
GO

---- Add Seasons Info channel and assign Announcer there

DECLARE @chanName AS VARCHAR(100) = 'Suggestions and features';

IF NOT EXISTS (SELECT TOP 1 name FROM channels WHERE name=@chanName)
BEGIN
	PRINT N'INSERT INTO channels '+@chanName;
	INSERT INTO channels (name, password, topic, type, DiscordId) VALUES
	(@chanName, NULL, 'Post your ideas and suggestions here!', 1, '440624329353330692');
END
ELSE
BEGIN
	PRINT N'UPDATE channels '+@chanName;
	UPDATE channels SET
		password=NULL,
		topic='Post your ideas and suggestions here!',
		type=1,
		DiscordId = '440624329353330692'
	WHERE name=@chanName;
END

DECLARE @oppChar AS INT = (SELECT TOP 1 characterID FROM characters WHERE nick='Discord');
DECLARE @chanID AS INT = (SELECT TOP 1 id FROM channels WHERE name=@chanName);

DELETE FROM channelmembers WHERE channelid=@chanID AND memberid=@oppChar;
INSERT INTO channelmembers (channelid, memberid, role) VALUES
(@chanID, @oppChar, 2);

GO
