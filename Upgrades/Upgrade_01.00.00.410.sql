INSERT INTO #Description VALUES ('Modify SP for clear cache frontend')
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
        IF(@DocumentId IS NOT NULL)
		BEGIN
			INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
			VALUES (11, @DocumentId);
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
            
        INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
        SELECT 11 , Id FROM @DocumentIds
        
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