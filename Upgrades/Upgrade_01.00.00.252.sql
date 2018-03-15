INSERT INTO #Description VALUES('Add procedures to support feature move doc/folder in tree view')
GO

IF OBJECT_ID('[dbo].[m136_be_MoveDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveDocument]
    @DocumentId INT,
    @IsDocumentVirtual BIT,
    @PreviousDocumentId INT,
    @IsPreviousDocumentVirtual BIT,
    @OldFolderId INT,
    @NewFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        IF @PreviousDocumentId IS NULL
        BEGIN
            UPDATE m136_tblDocument
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId
            
            UPDATE m136_relVirtualRelation
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId
            
            IF @IsDocumentVirtual = 1
            BEGIN
                UPDATE m136_relVirtualRelation
                SET iSort = -2147483648, iHandbookId = @NewFolderId
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
            ELSE
            BEGIN
                UPDATE m136_tblDocument
                SET iSort = -2147483648, iHandbookId = @NewFolderId
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
        END
        ELSE
        BEGIN
            DECLARE @PreviousDocumentSortOrder INT;
            
            IF @IsPreviousDocumentVirtual = 1
            BEGIN
                SET @PreviousDocumentSortOrder = (SELECT TOP 1 iSort FROM m136_relVirtualRelation WHERE iHandbookId = @NewFolderId AND iDocumentId = @PreviousDocumentId);
            END
            ELSE
            BEGIN
                SET @PreviousDocumentSortOrder = (SELECT TOP 1 iSort FROM m136_tblDocument WHERE iDocumentId = @PreviousDocumentId);
            END        
            
            UPDATE m136_tblDocument
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId AND iSort > @PreviousDocumentSortOrder
            
            UPDATE m136_relVirtualRelation
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId AND iDocumentId = @DocumentId AND iSort > @PreviousDocumentSortOrder
            
            IF @IsDocumentVirtual = 1
            BEGIN
                UPDATE m136_relVirtualRelation
                SET iSort = @PreviousDocumentSortOrder + 1, iHandbookId = @NewFolderId
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
            ELSE
            BEGIN
                UPDATE m136_tblDocument
                SET iSort = @PreviousDocumentSortOrder + 1, iHandbookId = @NewFolderId
                WHERE iDocumentId = @DocumentId
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

IF OBJECT_ID('[dbo].[m136_be_MoveFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveFolder]
    @FolderId INT,
    @PreviousFolderId INT,
    @ParentFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        IF @PreviousFolderId IS NULL
        BEGIN
            UPDATE m136_tblHandbook
            SET iSort = iSort + 1
            WHERE @ParentFolderId IS NULL OR iParentHandbookId = @ParentFolderId
        
            UPDATE m136_tblHandbook
            SET iSort = -2147483648, iParentHandbookId = @ParentFolderId
            WHERE iHandbookId = @FolderId
        END
        ELSE
        BEGIN
            DECLARE @PreviousFolderSortOrder INT = (SELECT TOP 1 iSort FROM m136_tblHandbook WHERE iHandbookId = @PreviousFolderId);
            
            UPDATE m136_tblHandbook
            SET iSort = iSort + 1
            WHERE (@ParentFolderId IS NULL OR iParentHandbookId = @ParentFolderId) AND iSort > @PreviousFolderSortOrder
            
            UPDATE m136_tblHandbook
            SET iSort = @PreviousFolderSortOrder + 1, iParentHandbookId = @ParentFolderId
            WHERE iHandbookId = @FolderId
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