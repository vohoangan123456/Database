INSERT INTO #Description VALUES ('Create SP for email subscription for document and folder')
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iEmail'
      AND Object_ID = Object_ID(N'dbo.m136_tblSubscriberDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblSubscriberDocument ADD iEmail [INT] NOT NULL DEFAULT 0;
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iFrontPage'
      AND Object_ID = Object_ID(N'dbo.m136_tblSubscriberDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblSubscriberDocument ADD iFrontPage INT NULL 
END
GO

IF NOT EXISTS (
    select *
      from sys.all_columns c
      join sys.tables t on t.object_id = c.object_id
      join sys.schemas s on s.schema_id = t.schema_id
      join sys.default_constraints d on c.default_object_id = d.object_id
    where t.name = 'm136_tblSubscriberDocument'
      and c.name = 'iFrontPage'
      and s.name = 'dbo')
BEGIN
	UPDATE dbo.m136_tblSubscriberDocument SET iFrontPage = 1
	
	ALTER TABLE dbo.m136_tblSubscriberDocument ADD CONSTRAINT DF_m136_tblSubscriberDocument_iFrontPage DEFAULT 0 FOR iFrontPage;
	
	ALTER TABLE dbo.m136_tblSubscriberDocument ALTER COLUMN iFrontPage INT NOT NULL
END      
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iEmailFolder'
      AND Object_ID = Object_ID(N'dbo.m136_tblSubscribe'))
BEGIN
    ALTER TABLE dbo.m136_tblSubscribe ADD iEmailFolder [INT] NOT NULL DEFAULT 0;
END
GO

IF OBJECT_ID('[dbo].[m136_GetMyFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMyFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMyFavorites]
	@EmployeeId INT = 0,
	@TreatDepartmentFoldersAsFavorites BIT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @EmployeeId;
	--chapter
	SELECT
		h.iHandbookId, 
		h.strName, 
		h.iLevelType,
		bf.isForced AS isForced,
		bf.isDepartment AS isDepartment,
		bf.iSort
	FROM
		m136_tblHandbook h
		JOIN [dbo].[m136_fnGetFavoriteFolders](@EmployeeId, @TreatDepartmentFoldersAsFavorites,@iUserDepId) bf
			ON h.iHandbookId = bf.iHandbookId
	ORDER BY
		CASE WHEN (isDepartment = 1 AND isForced = 1) OR (isDepartment = 1) THEN h.strName
		END,
		isDepartment,
		isForced,
		CASE WHEN isDepartment = 0 AND isForced = 0 THEN bf.iSort
		END,
		h.strName
	--document
	SELECT
		d.iHandbookId,
		d.strName,
		d.iDocumentId, 
		d.iDocumentTypeId,
		sd.iSort
	FROM
		m136_tblSubscriberDocument sd
		JOIN m136_tblDocument d 
			ON (sd.iDocumentId = d.iDocumentId AND d.iLatestApproved = 1)
	WHERE
		sd.iEmployeeId = @EmployeeId
		AND sd.iFrontPage = 1
	ORDER BY
		sd.iSort,
		strName
END
GO

IF OBJECT_ID('[dbo].[m136_AddDocumentToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddDocumentToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddDocumentToFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL,
	@iEmail INT = 0,
	@iFrontPage INT = 0
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscriberDocument] WHERE [iDocumentId] = @DocumentId AND [iEmployeeId] = @iSecurityId)
	BEGIN
		
		INSERT INTO [dbo].[m136_tblSubscriberDocument] ([iEmployeeId], [iDocumentId], [iSort], iEmail, iFrontPage) 
		VALUES (@iSecurityId, @DocumentId, 0, @iEmail, @iFrontPage)
	END
	ELSE
	BEGIN
		IF @iEmail <> 0
			UPDATE dbo.m136_tblSubscriberDocument SET iEmail = @iEmail
			WHERE [iDocumentId] = @DocumentId AND [iEmployeeId] = @iSecurityId
		ELSE
			UPDATE dbo.m136_tblSubscriberDocument SET iFrontPage = @iFrontPage
			WHERE [iDocumentId] = @DocumentId AND [iEmployeeId] = @iSecurityId
	END
END
GO

IF OBJECT_ID('[dbo].[m136_GetUserDocumentEmailSubsciptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserDocumentEmailSubsciptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserDocumentEmailSubsciptions]
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	sh.iDocumentId
		FROM	dbo.m136_tblSubscriberDocument sh
		WHERE	sh.iEmployeeId = @iSecurityId 
			AND sh.iEmail = 1
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromEmailSubscription] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromEmailSubscription]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscriberDocument] WHERE [iEmployeeId] = @iSecurityId AND [iDocumentId] = @DocumentId AND iFrontpage <> 0)
		BEGIN
			UPDATE	[dbo].[m136_tblSubscriberDocument]
			SET		iEmail = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iDocumentId] = @DocumentId
		END
	ELSE
		BEGIN
			DELETE FROM [dbo].[m136_tblSubscriberDocument]
			WHERE [iEmployeeId] = @iSecurityId
			AND [iDocumentId] = @DocumentId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
		BEGIN
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
			VALUES (@iSecurityId, @HandbookId,0,1,0,0)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iFrontpage] = 1
			WHERE	[iHandbookId] = @HandbookId 
				AND [iEmployeeId] = @iSecurityId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND (iEmail <> 0 OR iEmailFolder <> 0))
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iFrontpage] = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iHandbookId] = @HandbookId
		END
	ELSE
		BEGIN
			DELETE FROM	[dbo].[m136_tblSubscribe]
			WHERE		[iEmployeeId] = @iSecurityId
				AND		[iHandbookId] = @HandbookId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscriberDocument] WHERE [iEmployeeId] = @iSecurityId AND [iDocumentId] = @DocumentId AND iEmail <> 0)
		BEGIN
			UPDATE	[dbo].[m136_tblSubscriberDocument]
			SET		[iFrontpage] = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iDocumentId] = @DocumentId
		END
	ELSE
		BEGIN
			DELETE FROM [dbo].[m136_tblSubscriberDocument]
			WHERE [iEmployeeId] = @iSecurityId
			AND [iDocumentId] = @DocumentId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptions]
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	sh.iHandbookId,
				sh.iEmail,
				sh.iEmailFolder,
				sh.iSort
		FROM	m136_tblSubscribe sh
		WHERE	sh.iEmployeeId = @iSecurityId 
			AND sh.iEmail = 1 OR sh.iEmailFolder = 1
END
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
		BEGIN
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort], iEmailFolder) 
			VALUES (@iSecurityId, @HandbookId,1,0,0,0,0)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iEmail] = 1, iEmailFolder = 0
			WHERE	[iHandbookId] = @HandbookId 
				AND [iEmployeeId] = @iSecurityId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_AddOnlyHandbookToEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddOnlyHandbookToEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddOnlyHandbookToEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
		BEGIN
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort], iEmailFolder) 
			VALUES (@iSecurityId, @HandbookId,0,0,0,0,1)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		 iEmailFolder = 1
			WHERE	[iHandbookId] = @HandbookId 
				AND [iEmployeeId] = @iSecurityId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND (iFrontpage <> 0 OR iEmailFolder <> 0))
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iEmail] = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iHandbookId] = @HandbookId
		END
	ELSE
		BEGIN
			DELETE FROM	[dbo].[m136_tblSubscribe]
			WHERE		[iEmployeeId] = @iSecurityId
				AND		[iHandbookId] = @HandbookId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveOnlyHandbookFromEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveOnlyHandbookFromEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveOnlyHandbookFromEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND (iFrontpage <> 0 OR iEmail <> 0))
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		iEmailFolder = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iHandbookId] = @HandbookId
		END
	ELSE
		BEGIN
			DELETE FROM	[dbo].[m136_tblSubscribe]
			WHERE		[iEmployeeId] = @iSecurityId
				AND		[iHandbookId] = @HandbookId
		END
END
GO