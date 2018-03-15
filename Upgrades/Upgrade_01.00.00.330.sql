INSERT INTO #Description VALUES ('Implement PBI [B-13683] PoC - Forms Authentication with Active Directory in Multiple Domains')
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetUserEmailSubsciptions]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetUserEmailSubsciptions]
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubscriptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubscriptions]
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


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetUserEmailSubsciptionsFolders]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders]
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubscriptionsFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubscriptionsFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubscriptionsFolders]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND sb.iEmail = 1
	ORDER BY
		h.strName
END
GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetUserDocumentEmailSubsciptions]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetUserDocumentEmailSubsciptions]
GO

IF OBJECT_ID('[dbo].[m136_GetUserDocumentEmailSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserDocumentEmailSubscriptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserDocumentEmailSubscriptions]
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