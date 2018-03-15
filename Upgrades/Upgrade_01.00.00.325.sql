INSERT INTO #Description VALUES ('Create SP for transfer reading receipts')
GO

IF OBJECT_ID('[dbo].[m136_be_TransferReadingReceipts]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_TransferReadingReceipts] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_TransferReadingReceipts] 
	@Id INT,
	@TransferVersion INT
AS
BEGIN
	DECLARE @LatestEntity INT
	DECLARE @LatestVersion INT
	DECLARE @TableEntityVersion TABLE(entity INT)
	
	SELECT @LatestEntity = iEntityId, @LatestVersion = iVersion
	FROM dbo.m136_tblDocument
	WHERE iLatestVersion = 1 AND iLatestApproved = 1
		  AND iDocumentId = @Id
	
	IF @LatestEntity IS NOT NULL
	BEGIN
		INSERT INTO @TableEntityVersion
		SELECT iEntityId
		FROM dbo.m136_tblDocument
		WHERE iDocumentId = @Id
			  AND iVersion >= @TransferVersion AND iVersion < @LatestVersion
		
		INSERT INTO dbo.m136_tblConfirmRead (iEntityId, iEmployeeId,dtmConfirm,strEmployeeName)
		SELECT DISTINCT @LatestEntity,
				c.iEmployeeId,
				c.dtmConfirm,
				c.strEmployeeName
		FROM dbo.m136_tblConfirmRead c
		JOIN @TableEntityVersion e ON e.entity = c.iEntityId
		ORDER BY c.dtmConfirm DESC
	END
END
GO