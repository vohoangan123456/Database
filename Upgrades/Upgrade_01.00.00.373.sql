INSERT INTO #Description VALUES ('Modify procedure m136_be_MoveFolder')
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
            DECLARE @SubFoldersPermission AS [dbo].[ACLDatatable];
            INSERT INTO @SubFoldersPermission
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
        
            IF (@RecursiveInheritance = 1)
            BEGIN
                EXEC [dbo].[m136_be_UpdateFolderPermissions] @SubFoldersPermission;
            END
            ELSE
            BEGIN
                DECLARE @iHandbookId INT;
                DECLARE @iApplicationId INT;
                DECLARE @iSecurityId INT;
                DECLARE @iPermissionSetId INT;
                DECLARE @iGroupingId INT;
                DECLARE @iBit INT;
                DECLARE ACL CURSOR FOR
                    SELECT iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit
                    FROM @SubFoldersPermission;
                
                OPEN ACL;
                FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit
                WHILE @@FETCH_STATUS = 0
                BEGIN
                    IF NOT EXISTS(SELECT 1 FROM dbo.tblACL
                                    WHERE iEntityId = @iHandbookId
                                        AND iApplicationId = @iApplicationId
                                        AND iSecurityId = @iSecurityId
                                        AND iPermissionSetId = @iPermissionSetId)
                    BEGIN
                        INSERT INTO
                            dbo.tblACL
                                (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
                            VALUES (
                                @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit);
                    END
                    ELSE
                    BEGIN
                        UPDATE tblAcl
                        SET
                            iBit = @iBit,
                            iGroupingId = @iGroupingId
                        WHERE
                            iEntityId = @iHandbookId
                            AND iApplicationId = @iApplicationId
                            AND iSecurityId = @iSecurityId
                            AND iPermissionSetId = @iPermissionSetId
                    END
                    FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
                END
                CLOSE ACL;
                DEALLOCATE ACL;
                
                DELETE tblAcl
                WHERE iEntityId = @FolderId
                    AND iApplicationId = @iApplicationId
                    AND iSecurityId NOT IN (SELECT iSecurityId FROM @SubFoldersPermission)
            END
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