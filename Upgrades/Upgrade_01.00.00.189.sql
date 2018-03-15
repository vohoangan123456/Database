INSERT INTO #Description VALUES('Created script for updating role folder permissions')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderRolePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 03, 2015
-- Description:	Update folder role permissions.
-- Modified date: FEB 01, 2016
-- Description: Remove recursive checking, we will do it on client side.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions]
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT, @bRecursive BIT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, iSecurityId
			, iPermissionSetId
			, iGroupingId
			, iBit 
			, bRecursive
		FROM @Permissions;
		
	OPEN PermissionSet; 
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM [dbo].[tblACL] 
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId = @iSecurityId 
				AND iPermissionSetId = @iPermissionSetId)
		BEGIN
			UPDATE [dbo].[tblACL]
			SET iBit = @iBit
			WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId = @iSecurityId 
				AND iPermissionSetId = @iPermissionSetId;
		END
		ELSE
		BEGIN
			INSERT INTO [dbo].[tblACL] (iEntityId
				, iApplicationId
				, iSecurityId
				, iPermissionSetId
				, iGroupingId
				, iBit) 
			VALUES (@iEntityId
				, @iAppicationId
				, @iSecurityId
				, @iPermissionSetId
				, 0
				, @iBit);
		END
            
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
END
GO