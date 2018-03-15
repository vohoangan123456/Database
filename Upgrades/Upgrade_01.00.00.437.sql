INSERT INTO #Description VALUES ('Fixed: should not remove other role permissions')
GO

IF OBJECT_ID('[Calendar].[m136_be_UpdateFolderRolePermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[m136_be_UpdateFolderRolePermissions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderRolePermissions]
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
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
			IF (@bRecursive = 1)
			BEGIN
				DECLARE @iHandbookId INT;
				DECLARE RecursivePermissionSet CURSOR FOR 
				SELECT iHandbookId 
					, @iAppicationId
					, @iSecurityId
					, @iPermissionSetId
					, @iGroupingId
					, @iBit
				FROM dbo.m136_GetHandbookRecursive (@iEntityId, @iSecurityId, 0);
				OPEN RecursivePermissionSet; 
				FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
				WHILE @@FETCH_STATUS = 0
				BEGIN
					IF EXISTS(SELECT * FROM [dbo].[tblACL] 
						WHERE iEntityId = @iHandbookId 
							AND iApplicationId = @iAppicationId 
							AND iSecurityId = @iSecurityId 
							AND iPermissionSetId = @iPermissionSetId)
					BEGIN
						UPDATE [dbo].[tblACL]
						SET iBit = @iBit
						WHERE iEntityId = @iHandbookId 
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
						VALUES (@iHandbookId
							, @iAppicationId
							, @iSecurityId
							, @iPermissionSetId
							, 0
							, @iBit);
					END
					FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
				END
				CLOSE RecursivePermissionSet;
				DEALLOCATE RecursivePermissionSet;
				/*DELETE [dbo].[tblACL] WHERE iEntityId = @iHandbookId 
					AND iApplicationId = @iAppicationId 
					AND iSecurityId NOT IN (SELECT iSecurityId 
					FROM @Permissions);*/
			END
			FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
		END
		CLOSE PermissionSet;
		DEALLOCATE PermissionSet;
		/*DELETE [dbo].[tblACL] WHERE iEntityId = @iEntityId 
				AND iApplicationId = @iAppicationId 
				AND iSecurityId NOT IN (SELECT iSecurityId 
				FROM @Permissions);*/
		INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (2, @iEntityId);
		COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

