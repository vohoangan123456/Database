INSERT INTO #Description VALUES('edit stored procedure [dbo].[m136_GetFileContents] and [dbo].[m136_GetDocumentConfirmationDate]')
GO

IF OBJECT_ID('[dbo].[m136_GetFileContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileContents] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId INT
AS
BEGIN

	SELECT strFilename,
		   strContentType,
		   imgContent
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentConfirmationDate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentConfirmationDate] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentConfirmationDate]
	@SecurityId INT,
	@EntityId INT
AS
BEGIN
	
	SELECT TOP 1 dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEmployeeId=@SecurityId 
		AND iEntityId=@EntityId 
	
END
GO