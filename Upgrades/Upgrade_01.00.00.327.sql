INSERT INTO #Description VALUES ('Modify procedure m136_be_DeleteFolder')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteFolder]
	@HandbookId INT = 0,
	@SecurityId INT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            SET NOCOUNT ON;
            DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
            DECLARE @DocumentChildren TABLE(Id INT NOT NULL PRIMARY KEY);
            DECLARE @ParentHandbookId INT = (SELECT ISNULL(iParentHandbookId, 0) FROM m136_tblHandbook WHERE iHandbookId = @HandbookId);
            
            INSERT INTO @AvailableChildren(iHandbookId)
            SELECT 
                iHandbookId 
            FROM 
                [dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
                    
            INSERT INTO @DocumentChildren(Id)		
            SELECT DISTINCT d.iDocumentId AS Id
                FROM m136_tblDocument d
                    JOIN m136_tblHandbook h 
                        ON d.iHandbookId = h.iHandbookId
                    JOIN @AvailableChildren ac
                        ON d.iHandbookId = ac.iHandbookId
            
            --Delete virtual of handbook
            DELETE FROM	dbo.m136_relVirtualRelation	
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Delete virtual of document
            DELETE FROM	dbo.m136_relVirtualRelation	
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            --Delete Subcribe handbook
            DELETE FROM	dbo.m136_tblSubscribe
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Delete Subcribe of document
            DELETE FROM	dbo.m136_tblSubscriberDocument
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            --Set iDelete = 1 for handbook table
            UPDATE dbo.m136_tblHandbook
                SET iDeleted = 1
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Set iDelete = 1 for Document table
            UPDATE dbo.m136_tblDocument
                SET iDeleted = 1
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            INSERT INTO CacheUpdate(ActionType, EntityId) VALUES (5, @ParentHandbookId);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO