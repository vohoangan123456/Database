INSERT INTO #Description VALUES ('Modify procedure [dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin]')
GO

IF OBJECT_ID('[dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin] 
	@Months AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		
		DECLARE @TableDocument TABLE(EntityId INT, DocumentId INT, dtmSentToApproval DATETIME, Approver INT, Responsible INT, Version INT, Name VARCHAR(200))
		DECLARE @DateCompare DATETIME = DateAdd(month, - @Months, GETDATE())
		INSERT INTO  @TableDocument     
		SELECT d.iEntityId, d.iDocumentId, r.dtmSentToApproval, r.iEmployeeId, d.iCreatedbyId, d.iVersion, d.strName
		FROM dbo.m136_tblDocument d
		JOIN dbo.m136_relSentEmpApproval r ON d.iEntityId = r.iEntityId 
		     AND r.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
		     AND r.dtmSentToApproval < @DateCompare AND d.iDraft = 0 AND d.iApproved = 0
		WHERE d.iDraft = 0
			  AND d.iApproved = 0
			  AND iLatestVersion = 1
		
		DECLARE @EntityId INT, @DocumentId INT
		
        DECLARE curDocumentId CURSOR FOR 
            SELECT EntityId, DocumentId
            FROM @TableDocument;
            
        OPEN curDocumentId; 
        FETCH NEXT FROM curDocumentId INTO @EntityId , @DocumentId;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE dbo.m136_tblDocument 
			SET iDraft = 1,   dtmAlter = getdate()
			WHERE iEntityId =  @EntityId
			
			DELETE FROM dbo.m136_relSentEmpApproval          
			WHERE iEntityId = @EntityId
			
			EXEC dbo.m136_SetVersionFlags @DocumentId
            
            FETCH NEXT FROM curDocumentId INTO @EntityId , @DocumentId;
        END
        CLOSE curDocumentId;
        DEALLOCATE curDocumentId;
        COMMIT TRANSACTION;
        
        SELECT d.DocumentId, d.EntityId, d.Version, d.Approver, d.Responsible, e.strEmail ResponsibleEmail, e1.strEmail ApproverEmail, d.Name
        FROM @TableDocument d
			LEFT JOIN dbo.tblEmployee e ON d.Responsible = e.iEmployeeId
			LEFT JOIN dbo.tblEmployee e1 ON d.Approver = e1.iEmployeeId
        
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