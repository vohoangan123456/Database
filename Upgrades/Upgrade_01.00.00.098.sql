INSERT INTO #Description VALUES('Create stored procedure for update security group.')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateSecurityGroup]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateSecurityGroup] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 03, 2015
-- Description:	Update role information.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateSecurityGroup]
	@iRoleId INT,
	@strName VARCHAR(50),
	@strDescription VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE dbo.tblSecGroup
    SET
        dbo.tblSecGroup.strName = @strName,
        dbo.tblSecGroup.strDescription = @strDescription
    WHERE dbo.tblSecGroup.iSecGroupId = @iRoleId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderRolePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 03, 2015
-- Description:	Update folder role permissions.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions]
	@Permissions AS [dbo].[SecurityDatatable] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT;
	DECLARE PermissionSet CURSOR FOR 
		SELECT iEntityId 
			, iApplicationId
			, iSecurityId
			, iPermissionSetId
			, iGroupingId
			, iBit 
		FROM @Permissions;
	OPEN PermissionSet; 
	FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
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
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
	END
	CLOSE PermissionSet;
	DEALLOCATE PermissionSet;
END
GO