INSERT INTO #Description VALUES('Edit type of dtmAccessed column and edit store procedure [dbo].[m136_InsertOrUpdateDocAccessLog], [dbo].[m136_LogDocumentRead]')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_InsertOrUpdateDocAccessLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertOrUpdateDocAccessLog] AS SELECT 1')
GO

ALTER procedure [dbo].[m136_InsertOrUpdateDocAccessLog]
	@iSecurityId INT,
	@iDocumentId INT,
	@dtmAccessed DATETIME
AS
BEGIN
	
	SET NOCOUNT ON;
	IF EXISTS (SELECT * FROM [dbo].[m136_tblDocAccessLog]
				 WHERE iSecurityId = @iSecurityId 
						AND iDocumentId = @iDocumentId)
        UPDATE [dbo].[m136_tblDocAccessLog]
			SET iAccessedCount = iAccessedCount + 1,
				dtmAccessed = @dtmAccessed
        WHERE iSecurityId = @iSecurityId 
			  AND iDocumentId = @iDocumentId
    ELSE    
        INSERT INTO [dbo].[m136_tblDocAccessLog]
        (
			iSecurityId, iDocumentId, dtmAccessed, iAccessedCount
		)
        VALUES
        (
			@iSecurityId, @iDocumentId, @dtmAccessed, 1
		)
END
GO

IF OBJECT_ID('[dbo].[m136_LogDocumentRead]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LogDocumentRead] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_LogDocumentRead]
	@iSecurityId INT,
	@iEntityId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iDocumentId INT
	DECLARE @now DATETIME
	SET @now = GETDATE()
	
	SET @iDocumentId = 
	(
		SELECT 
			iDocumentId 
		FROM
			[dbo].[m136_tblDocument]
		WHERE
			iEntityId = @iEntityId
	)
	
	UPDATE
		[dbo].[m136_tblDocument]
	SET
		iReadCount = iReadcount + 1
	WHERE
		iEntityId = @iEntityId
		
	EXEC [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @now
END

GO


