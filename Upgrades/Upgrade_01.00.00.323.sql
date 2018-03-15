INSERT INTO #Description VALUES ('update SP [dbo].[m136_GetDocumentConfirmationDate]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentConfirmationDate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentConfirmationDate] AS SELECT 1')
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
	ORDER BY dtmConfirm DESC
END
GO