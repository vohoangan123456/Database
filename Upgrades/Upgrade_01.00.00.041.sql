INSERT INTO #Description VALUES('Changed stored procedures to not use the UTC')
GO

IF OBJECT_ID('[dbo].[m136_UpdateEmployeeLoginTime]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime]
	@iEmployeeId int
AS
BEGIN

UPDATE 
	[dbo].[tblEmployee]
SET 
	PreviousLogin = LastLogin,
	LastLogin = GetDate()
WHERE 
	iEmployeeId = @iEmployeeId

END
GO


IF OBJECT_ID('[dbo].[m136_LogDocumentRead]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LogDocumentRead] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_LogDocumentRead]
	@iSecurityId int,
	@iEntityId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iDocumentId int
	DECLARE @now smalldatetime

	SET @now = GetDate()
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