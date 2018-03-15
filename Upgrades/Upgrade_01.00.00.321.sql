INSERT INTO #Description VALUES ('Create functions m136_GetRecursiveHandbooksWithVirtualLevels, modify procedures m136_be_MoveDocument, m136_be_MoveMultipleDocuments, m136_be_MoveFolder')
GO

IF OBJECT_ID('[dbo].[m136_GetRecursiveHandbooksWithVirtualLevels]', 'IF') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_GetRecursiveHandbooksWithVirtualLevels] () RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO

ALTER FUNCTION [dbo].[m136_GetRecursiveHandbooksWithVirtualLevels]  
(   
    @iHandbookId INT
)  
RETURNS TABLE  
AS  
RETURN   
(  
    WITH Children AS  
    (  
        SELECT iHandbookId, 1 AS Level  
        FROM   
            [dbo].[m136_tblHandbook]   
        WHERE  
            iHandbookId = @iHandbookId   
            AND iDeleted = 0  

        UNION ALL  

        SELECT h.iHandbookId, Level + 1 AS Level  
        FROM   
            [dbo].[m136_tblHandbook] h  
                INNER JOIN Children   
                    ON iParentHandbookId = Children.iHandbookId   
                    AND h.iDeleted = 0  
    )  
    SELECT iHandbookId, Level  
    FROM Children  
)
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
        DECLARE @NewLevelType INT = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = @NewFolderId);
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
                SET 
                    iSort = -2147483648, 
                    iHandbookId = @NewFolderId,
                    iLevelType = @NewLevelType
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
                SET 
                    iSort = @PreviousDocumentSortOrder + 1, 
                    iHandbookId = @NewFolderId,
                    iLevelType = @NewLevelType
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

IF OBJECT_ID('[dbo].[m136_be_MoveMultipleDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveMultipleDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveMultipleDocuments]
    @DocumentIds AS [dbo].[Item] READONLY,
    @OldFolderId INT,
    @NewFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE m136_tblDocument
        SET iSort = iSort + 1
        WHERE iHandbookId = @NewFolderId
        
        UPDATE m136_relVirtualRelation
        SET iSort = iSort + 1
        WHERE iHandbookId = @NewFolderId
        
        UPDATE
            m136_tblDocument
        SET 
            iSort = -2147483648,
            iHandbookId = @NewFolderId,
            iLevelType = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = @NewFolderId)
        WHERE
            iHandbookId = @OldFolderId 
            AND iDocumentId IN (SELECT Id FROM @DocumentIds)
        
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

UPDATE m136_tblHandbook
SET iLevel = 1
WHERE iParentHandbookId IS NULL