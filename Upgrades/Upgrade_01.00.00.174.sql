INSERT INTO #Description VALUES('Created SP for rollback document')
GO

IF OBJECT_ID('[dbo].[m136_be_RollbackChangesDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RollbackChangesDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: DEC 18, 2015
-- Description:	Rollback changes Document
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_RollbackChangesDocument] 
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
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
			FETCH NEXT FROM curDocumentId INTO @iDocumentId;
		END
		CLOSE curDocumentId;
		DEALLOCATE curDocumentId;
	
	COMMIT
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