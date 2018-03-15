INSERT INTO #Description VALUES('Modify procedure m136_be_SendDocumentToApproval')
GO

IF OBJECT_ID('[dbo].[m136_be_SendDocumentToApproval]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_SendDocumentToApproval] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_SendDocumentToApproval]
	@UserId INT,
	@EntityId INT,
	@TransferReadingReceipts BIT
AS
BEGIN
	UPDATE
		m136_tblDocument
	SET
		iDraft = 0
	WHERE
		iEntityId = @EntityId
	
	INSERT INTO
		m136_relSentEmpApproval
			(iEmployeeId, iEntityId, dtmSentToApproval)
		VALUES
			(@UserId, @EntityId, GETDATE())

	DELETE FROM
		m136_tblCopyConfirms
	WHERE
		iEntityId = @EntityId
	
	IF @TransferReadingReceipts = 1
	BEGIN
		INSERT INTO
			m136_tblCopyConfirms
				(iEntityId)
			VALUES
				(@EntityId)
	END
END
GO