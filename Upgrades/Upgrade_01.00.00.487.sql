INSERT INTO #Description VALUES ('Modify SP for Rollback document')
GO

IF OBJECT_ID('[dbo].[m136_be_GetFileDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFileDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFileDocument]
	@SecurityId INT = NULL,
	@EntityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DECLARE @HandbookId INT
	DECLARE @DocumentId INT
	SELECT @HandbookId = d.iHandbookId, @DocumentId = d.iDocumentId
	FROM dbo.m136_tblDocument d
	WHERE d.iEntityId = @EntityId
	
	IF @HandbookId = -1
		SELECT @HandbookId = HandbookId FROM dbo.m136_ArchivedDocuments WHERE DocumentId = @DocumentId
		
	SELECT	
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File]
	FROM	
			m136_tblDocument d
	WHERE	
				d.iEntityId = @EntityId
			AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, @HandbookId) = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_RollbackChangesDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RollbackChangesDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RollbackChangesDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
        
            DECLARE @TableEntityId AS TABLE (entityId INT  PRIMARY KEY)
            
            INSERT INTO @TableEntityId
            SELECT iEntityId
            FROM dbo.m136_tblDocument doc
            JOIN @DocumentIds docId ON  doc.iDocumentId = docId.Id
            WHERE doc.iLatestVersion = 1 
                  AND doc.iApproved NOT IN (1,4)
            
            DELETE FROM m136_tblFeedback 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoDate 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoNumber 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoText 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoRichText 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_relInfo 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
             DELETE FROM dbo.m136_HearingComments
            WHERE HearingsId IN (SELECT Id 
								  FROM dbo.m136_Hearings h
								  JOIN @TableEntityId d ON h.EntityId = d.entityId)
								  
            DELETE FROM dbo.m136_HearingMembers
            WHERE HearingsId IN (SELECT Id 
								  FROM dbo.m136_Hearings h
								  JOIN @TableEntityId d ON h.EntityId = d.entityId)
								  
			DELETE FROM dbo.m136_Hearings
            WHERE EntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblDocument 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
           								  
            DECLARE @iDocumentId INT
            DECLARE curDocumentId CURSOR FOR 
                SELECT Id
                FROM @DocumentIds;
            OPEN curDocumentId; 
            FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC dbo.m136_SetVersionFlags @iDocumentId
                
                
                DECLARE @HandbookId INT, @ApprovedStatus INT
                SELECT @HandbookId = iHandbookId, @ApprovedStatus = iApproved
                FROM dbo.m136_tblDocument
                WHERE iDocumentId = @iDocumentId
					  AND iLatestVersion = 1
                IF @ApprovedStatus = 4
                BEGIN
					UPDATE dbo.m136_tblDocument
					SET iHandbookId = -1
					WHERE iDocumentId = @iDocumentId
					  AND iLatestVersion = 1
					  
					INSERT INTO dbo.m136_ArchivedDocuments(HandbookId, DocumentId, CreatedById, dmtCreated)
					VALUES(@HandbookId, @iDocumentId, @UserId, getdate())
                END
                
                FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            END
            CLOSE curDocumentId;
            DEALLOCATE curDocumentId;
	
        COMMIT TRANSACTION;
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