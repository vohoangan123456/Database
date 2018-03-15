INSERT INTO #Description VALUES('Create stored procedures handbook permissions management.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 27, 2015
-- Description:	Get permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetPermissions]
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iSecurityId INT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT ta.iSecurityId, ta.iPermissionSetId, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId = 136 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId = @iSecurityId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateHandbookPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateHandbookPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 27, 2015
-- Description:	Update handbook permissions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateHandbookPermissions]
	@iRoleId INT,
	@iPermission INT,
	@iPermissionSetId INT
AS
BEGIN
	SET NOCOUNT ON;

	IF EXISTS(SELECT ta.* FROM dbo.tblACL ta WHERE ta.iApplicationId = 136 
		AND ta.iSecurityId = @iRoleId 
		AND ta.iPermissionSetId = @iPermissionSetId)
	BEGIN
		UPDATE dbo.tblACL
		SET
			iBit = @iPermission
		WHERE iApplicationId = 136 
			AND iSecurityId = @iRoleId
			AND iPermissionSetId = @iPermissionSetId;
    END
    ELSE
    BEGIN
		INSERT INTO dbo.tblACL
		(
		    iEntityId,
		    iApplicationId,
		    iSecurityId,
		    iPermissionSetId,
		    iGroupingId,
		    iBit
		)
		VALUES
		(
		    0, -- iEntityId - int
		    136, -- iApplicationId - int
		    @iRoleId, -- iSecurityId - int
		    @iPermissionSetId, -- iPermissionSetId - int
		    0, -- iGroupingId - int
		    @iPermission -- iBit - int
		)
    END
END
GO