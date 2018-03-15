INSERT INTO #Description VALUES ('Modify procedures m147_LinkHandbookToRegisterItem, m147_DeleteHandbookRegisterItem, m147_be_LinkDocumentToRegisterItemValues, m147_be_UntagDocumentRegisterItemValues')
GO

IF OBJECT_ID('[dbo].[m147_LinkHandbookToRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_LinkHandbookToRegisterItem] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_LinkHandbookToRegisterItem]
	@ChapterId INT,
    @RegisterItemId INT
AS
BEGIN
    BEGIN TRY
		BEGIN TRANSACTION 
			
            INSERT INTO
                m147_relRegisterItemCategory
                    (iRegisterItemId, iModuleId, iCategoryId, iInheritTypeId)
                VALUES
                    (@RegisterItemId, 136, @ChapterId, 2)
                    
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
            
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
    
END
GO

IF OBJECT_ID('[dbo].[m147_DeleteHandbookRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_DeleteHandbookRegisterItem] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_DeleteHandbookRegisterItem]
	@ChapterId INT,
    @RegisterItemIds AS [dbo].[Item] READONLY
AS
BEGIN
    BEGIN TRY
		BEGIN TRANSACTION 
			
            DELETE
                FROM m147_relRegisterItemCategory
            WHERE
                iCategoryId = @ChapterId
                AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
                
            DELETE
                FROM m147_relRegisterItemItem
            WHERE
                iItemId IN (SELECT iDocumentId FROM m136_tblDocument WHERE iHandbookId = @ChapterId)
                AND iRegisterItemId IN (SELECT Id FROM @RegisterItemIds)
                
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
            
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
END
GO

IF OBJECT_ID('[dbo].[m147_be_LinkDocumentToRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_LinkDocumentToRegisterItemValues]
    @ItemValues AS [dbo].[LinkDocumentRegisterItemValues] READONLY
AS
BEGIN
    
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iItemId IN (SELECT DocumentId FROM @ItemValues)
            AND iRegisterItemValueId IN (SELECT RegisterItemValueId FROM @ItemValues)
            
        INSERT INTO
            m147_relRegisterItemItem
                (iRegisterItemId, iModuleId, iCategoryId, iItemId, iRegisterItemValueId)
            SELECT
                RegisterItemId,
                136,
                0,
                DocumentId,
                RegisterItemValueId
            FROM
                @ItemValues
        
        INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
                    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
    
END
GO

IF OBJECT_ID('[dbo].[m147_be_UntagDocumentRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_UntagDocumentRegisterItemValues]
    @RegisterItemItemIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DELETE FROM
            m147_relRegisterItemItem
        WHERE
            iAutoId IN (SELECT Id FROM @RegisterItemItemIds)
        
        INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (4, 0)
                    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
    
END
GO