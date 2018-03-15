INSERT INTO #Description VALUES('Get user by permission. Fixed get file document issue, shoud remove iLatestVersion = 1')
GO

IF OBJECT_ID('[dbo].[GetUsersByPermission]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUsersByPermission] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUsersByPermission] 
	@Permission INT,
	@ApplicationIds AS dbo.[Item] READONLY,
	@PermissionSetIds AS dbo.[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

    SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		te.strFirstName, 
		te.strLastName, 
		te.strEmail 
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.relEmployeeSecGroup resg ON resg.iEmployeeId = te.iEmployeeId
    WHERE resg.iSecGroupId IN (
		SELECT ta.iSecurityId FROM dbo.tblACL ta 
			WHERE ta.iApplicationId IN (SELECT Id FROM @ApplicationIds)
			AND ta.iPermissionSetId IN (SELECT Id FROM @PermissionSetIds)
			AND (ta.iBit & @Permission) = @Permission
		);
    
END
GO



IF OBJECT_ID('[dbo].[m136_be_GetFileDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFileDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFileDocument]
	@SecurityId INT = NULL,
	@EntityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File]
	FROM	
			m136_tblDocument d
	WHERE	
				d.iEntityId = @EntityId
			AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, d.iHandbookId) = 1
END
GO
