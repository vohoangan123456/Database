INSERT INTO #Description VALUES ('Handbook cache - Change default view for folder')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO
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
    BEGIN TRY  
        BEGIN TRANSACTION;  
            SET NOCOUNT ON;  
            UPDATE [dbo].[m136_tblHandbook]   
            SET strName = @strName,  
                iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),  
                strDescription = @strDescription,  
                iDepartmentId = @iDepartmentId,  
                iLevelType = @iLevelType,  
                iViewTypeId = @iViewType,  
                iLevel = (CASE WHEN @ParentFolderId = 0 THEN 1 ELSE (SELECT  h.iLevel + 1 FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @ParentFolderId) END)  
            WHERE iHandbookId = @FolderId;  
            DECLARE @iHandbookId INT,  
                @iApplicationId INT,   
                @iSecurityId INT,   
                @iPermissionSetId INT,   
                @iGroupingId INT,   
                @iBit INT;  
            IF (@InheritNewParentPermissions = 1)  
            BEGIN  
                DECLARE @Permissions AS [dbo].[ACLDatatable];  
                INSERT INTO @Permissions  
                SELECT @FolderId   
                    , iApplicationId  
                    , iSecurityId  
                    , iPermissionSetId  
                    , iGroupingId  
                    , iBit  
                    , 1  
                FROM [dbo].[tblACL]   
                WHERE  
                    (  
                        (@ParentFolderId IS NULL AND iEntityId = 0)  
                        OR iEntityId = @ParentFolderId  
                    )  
                    AND iApplicationId = 136  
                    AND (iPermissionSetId = 461 OR iPermissionSetId = 462);  
                EXEC [dbo].[m136_be_UpdatePermissionsForFolder] @FolderId, @Recursive, @Permissions;  
                
            END  
            INSERT INTO CacheUpdate(ActionType, EntityId) VALUES (1, @FolderId);
        COMMIT TRANSACTION;  
    END TRY  
    BEGIN CATCH  
        ROLLBACK;  
    END CATCH  
END  
GO