USE perpetuumsa;

---- Alter add isAnnouncement to the sap table
BEGIN TRANSACTION
SET QUOTED_IDENTIFIER ON
SET ARITHABORT ON
SET NUMERIC_ROUNDABORT OFF
SET CONCAT_NULL_YIELDS_NULL ON
SET ANSI_NULLS ON
SET ANSI_PADDING ON
SET ANSI_WARNINGS ON
COMMIT
BEGIN TRANSACTION
GO
ALTER TABLE dbo.intrusionsites ADD
	isAnnounced bit NOT NULL CONSTRAINT DF_intrusionsites_isAnnounced DEFAULT 0
GO
ALTER TABLE dbo.intrusionsites SET (LOCK_ESCALATION = TABLE)
GO
COMMIT

GO

---- Add Syndicate Intel channel and assign Announcer there

DECLARE @chanName AS VARCHAR(100) = 'Syndicate Intel';

IF NOT EXISTS (SELECT TOP 1 name FROM channels WHERE name=@chanName)
BEGIN
	PRINT N'INSERT INTO channels '+@chanName;
	INSERT INTO channels (name, password, topic, type) VALUES
	(@chanName, NULL, '', 1);
END
ELSE
BEGIN
	PRINT N'UPDATE channels '+@chanName;
	UPDATE channels SET
		password=NULL,
		topic='',
		type=1
	WHERE name=@chanName;
END

DECLARE @oppChar AS INT = (SELECT TOP 1 characterID FROM characters WHERE nick='[OPP] Announcer');
DECLARE @chanID AS INT = (SELECT TOP 1 id FROM channels WHERE name=@chanName);

DELETE FROM channelmembers WHERE channelid=@chanID AND memberid=@oppChar;
INSERT INTO channelmembers (channelid, memberid, role) VALUES
(@chanID, @oppChar, 2);

GO