INSERT INTO #Description VALUES('add stored
[dbo].[m136_AddHandbookToEmailSubscription],
[dbo].[m136_RemoveHandbookFromEmailSubscription],
[dbo].[m136_GetUserEmailSubsciptions]
update stored
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites]')
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
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
			VALUES (@iSecurityId, @HandbookId,1,0,0,0)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iEmail] = 1
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
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND iFrontpage <> 0)
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
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND iEmail <> 0)
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

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptions]
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	sh.iHandbookId
		FROM	m136_tblSubscribe sh
		WHERE	sh.iEmployeeId = @iSecurityId 
			AND sh.iEmail = 1
END
GO