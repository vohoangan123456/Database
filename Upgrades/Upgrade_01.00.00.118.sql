INSERT INTO #Description VALUES('Get Permission by UserId.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetPermissionsByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPermissionsByUserId] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: OCT 28, 2015
-- Description:	Get Permission by UserId
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetPermissionsByUserId]
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iUserId INT,
	@iFolderId INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ta.iEntityId, ta.iSecurityId, ta.iPermissionSetId AS iAccessRights, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId = 136 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId IN (SELECT resg.iSecGroupId FROM dbo.relEmployeeSecGroup resg WHERE resg.iEmployeeId = @iUserId)
		AND (ta.iEntityId = @iFolderId OR @iFolderId IS NULL);
END
GO