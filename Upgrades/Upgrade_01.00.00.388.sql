INSERT INTO #Description VALUES ('Modify procedures m136_be_UpdatePermissionsForFolder, m136_be_UpdateFolderInformation, m136_be_MoveFolder, m136_be_UpdateFolderPermissions')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdatePermissionsForFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdatePermissionsForFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdatePermissionsForFolder]
    @FolderId INT,
    @IsRecursive BIT,
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @FolderIds TABLE (Id INT);
            
            IF (@IsRecursive = 1)
            BEGIN
                INSERT INTO @FolderIds
                SELECT iHandbookId
                FROM dbo.m136_GetHandbookRecursive (@FolderId, NULL, 0)
            END
            ELSE
            BEGIN
                INSERT INTO @FolderIds VALUES (@FolderId)
            END
            
            DELETE FROM tblAcl
            WHERE iEntityId IN (SELECT Id FROM @FolderIds)
                AND iApplicationId = 136
                AND (iPermissionSetId = 461 OR iPermissionSetId = 462)
            
            INSERT INTO tblAcl
                (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
            SELECT
                f.Id, 136, p.iSecurityId, p.iPermissionSetId, p.iGroupingId, p.iBit
            FROM
                @FolderIds f CROSS JOIN @Permissions p
                
            INSERT INTO CacheUpdate
                (ActionType, EntityId)
            SELECT 2, Id
            FROM @FolderIds
                
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
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
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_MoveFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveFolder]
    @FolderId INT,
    @PreviousFolderId INT,
    @ParentFolderId INT,
    @InheritPermissions BIT,
    @RecursiveInheritance BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @ParentFolderLevel INT;
        
        IF (@ParentFolderId IS NULL)
        BEGIN
            SET @ParentFolderLevel = 0;
        END
        ELSE
        BEGIN
            SET @ParentFolderLevel = (SELECT iLevel FROM m136_tblHandbook WHERE iHandbookId = @ParentFolderId)
        END
        
        IF @PreviousFolderId IS NULL
        BEGIN
            UPDATE m136_tblHandbook
            SET iSort = iSort + 1
            WHERE @ParentFolderId IS NULL OR iParentHandbookId = @ParentFolderId
        
            UPDATE m136_tblHandbook
            SET 
                iSort = -2147483648,
                iParentHandbookId = @ParentFolderId
            WHERE iHandbookId = @FolderId
        END
        ELSE
        BEGIN
            DECLARE @PreviousFolderSortOrder INT = (SELECT TOP 1 iSort FROM m136_tblHandbook WHERE iHandbookId = @PreviousFolderId);
            
            UPDATE m136_tblHandbook
            SET iSort = iSort + 1
            WHERE (@ParentFolderId IS NULL OR iParentHandbookId = @ParentFolderId) AND iSort > @PreviousFolderSortOrder
            
            UPDATE m136_tblHandbook
            SET 
                iSort = @PreviousFolderSortOrder + 1, 
                iParentHandbookId = @ParentFolderId
            WHERE iHandbookId = @FolderId
        END
        
        UPDATE m136_tblHandbook
        SET iLevel = @ParentFolderLevel + tblTemp.Level
        FROM
            m136_tblHandbook tblHandbook
                INNER JOIN m136_GetRecursiveHandbooksWithVirtualLevels(@FolderId) tblTemp ON tblHandbook.iHandbookId = tblTemp.iHandbookId
        
        -- Inherit permissions from parent
        
        IF @InheritPermissions = 1
        BEGIN
            DECLARE @Permissions AS [dbo].[ACLDatatable];
            INSERT INTO @Permissions
            SELECT
                @FolderId,
                iApplicationId,
                iSecurityId,
                iPermissionSetId,
                iGroupingId,
                iBit,
                1
            FROM
                [dbo].[tblAcl]
            WHERE
                (
                    (@ParentFolderId IS NULL AND iEntityId = 0)
                    OR iEntityId = @ParentFolderId
                )
                AND iApplicationId = 136
                AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
                
			EXEC [dbo].[m136_be_UpdatePermissionsForFolder] @FolderId, @RecursiveInheritance, @Permissions
        END
    COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] 
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
                    DELETE [dbo].[tblACL] WHERE iEntityId = @iHandbookId 
                        AND iApplicationId = @iAppicationId 
                        AND iSecurityId NOT IN (SELECT iSecurityId 
                        FROM @Permissions);
                END
                
                FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
            END
            CLOSE PermissionSet;
            DEALLOCATE PermissionSet;
            DELETE [dbo].[tblACL] WHERE iEntityId = @iEntityId 
                AND iApplicationId = @iAppicationId 
                AND iSecurityId NOT IN (SELECT iSecurityId 
                FROM @Permissions);
                
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (2, @iEntityId)
                
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO