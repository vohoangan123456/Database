INSERT INTO #Description VALUES('Add SP for retrieve from send to approval')
GO

IF OBJECT_ID('[dbo].[m136_be_RetrieveSendToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RetrieveSendToApproval] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RetrieveSendToApproval] 
	@DocumentId AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @EntityId INT
        
		SELECT @EntityId = iEntityId
		FROM dbo.m136_tblDocument
		WHERE iDocumentId = @DocumentId
			  AND iLatestVersion = 1
			  
		UPDATE dbo.m136_tblDocument 
		SET iDraft = 1 
		WHERE iEntityId =  @EntityId
		
		DELETE FROM dbo.m136_relSentEmpApproval          
		WHERE iEntityId = @EntityId
		
		EXEC dbo.m136_SetVersionFlags @DocumentId
	
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