INSERT INTO #Description VALUES ('Modified [dbo].[m136_GetUserEmailSubscriptions]')
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
			AND (sh.iEmail = 1 OR sh.iEmailFolder = 1)
END
GO



