INSERT INTO #Description VALUES('Created script for update folder information')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 01, 2015
-- Modified date: JAN 22, 2016
-- Modified description: add pudate folder permissions according to new parent
-- Description:	Update folder information
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderInformation]
	@FolderId INT,
	@ParentFolderId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(700),
	@iDepartmentId INT,
	@iLevelType INT,
	@iViewType INT,
	@InheritNewParentPermissions BIT,
	@Recursive BIT,
	@OldParentFolderId INT
AS
BEGIN
	SET NOCOUNT ON;
    UPDATE [dbo].[m136_tblHandbook] 
    SET strName = @strName,
		iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),
		strDescription = @strDescription,
		iDepartmentId = @iDepartmentId,
		iLevelType = @iLevelType,
		iViewTypeId = (CASE WHEN @iViewType = -1 THEN 1 WHEN @iViewType = -2 THEN 3 END)
	WHERE iHandbookId = @FolderId;

	DECLARE @iHandbookId INT,
		@iApplicationId INT, 
		@iSecurityId INT, 
		@iPermissionSetId INT, 
		@iGroupingId INT, 
		@iBit INT;

	IF (@InheritNewParentPermissions = 1)
	BEGIN
		IF (@Recursive = 1)
		BEGIN
			DECLARE @SubFoldersPermission AS [dbo].[ACLDatatable];
			INSERT INTO @SubFoldersPermission 
			SELECT @FolderId 
				, iApplicationId
				, iSecurityId
				, iPermissionSetId
				, iGroupingId
				, iBit
				, 1
			FROM [dbo].[tblACL] WHERE iEntityId = @ParentFolderId
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);

			EXEC [dbo].[m136_be_UpdateFolderPermissions] @SubFoldersPermission;
		END --END IF (@Recursive = 1)----------------------------------------------------------------------------------
		ELSE
		BEGIN
			DECLARE @NewParentFolderPermissions AS [dbo].[ACLDatatable];
			INSERT INTO @NewParentFolderPermissions SELECT @FolderId
					, [iApplicationId]
					, iSecurityId
					, [iPermissionSetId]
					, [iGroupingId]
					, [iBit]
					, 0
				FROM [dbo].[tblACL] 
				WHERE iEntityId = @ParentFolderId 
					AND iApplicationId = 136
					AND (iPermissionSetId = 461 OR iPermissionSetId = 462);

			DECLARE ACL CURSOR FOR 
			SELECT iEntityId
					, [iApplicationId]
					, iSecurityId
					, [iPermissionSetId]
					, [iGroupingId]
					, [iBit]
				FROM @NewParentFolderPermissions;
			OPEN ACL; 
			FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iHandbookId 
					AND iApplicationId = @iApplicationId 
					AND iSecurityId = @iSecurityId 
					AND iPermissionSetId  = @iPermissionSetId)
				BEGIN
					INSERT INTO dbo.tblACL VALUES (
						 @iHandbookId
						, @iApplicationId
						, @iSecurityId
						, @iPermissionSetId
						, @iGroupingId
						, @iBit);
				END
				ELSE 
				BEGIN
					UPDATE dbo.tblACL
						SET iBit = @iBit,
							iGroupingId = @iGroupingId
					WHERE iEntityId = @iHandbookId 
					AND iApplicationId = @iApplicationId 
					AND iSecurityId = @iSecurityId 
					AND iPermissionSetId  = @iPermissionSetId
				END
				FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
			END
			CLOSE ACL;
			DEALLOCATE ACL;
			DELETE [dbo].[tblACL] WHERE iEntityId = @FolderId 
				AND iApplicationId = @iApplicationId 
				AND iSecurityId NOT IN (SELECT iSecurityId 
				FROM @NewParentFolderPermissions);
		END
	END
END
GO