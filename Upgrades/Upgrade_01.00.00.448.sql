INSERT INTO #Description VALUES ('Log searches words on Handbook frontend')
GO

IF OBJECT_ID('[dbo].[m136_LogSearchWords]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LogSearchWords] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_LogSearchWords]  
 @iDocumentId INT,  
 @iEmployeeId INT,  
 @searchKey VARCHAR(255)  
AS  
SET NOCOUNT ON  
BEGIN
	INSERT INTO m136_tblSearchLog(iDocumentId, iEmployeeId, dtmSearch, strSearchKey)
	VALUES(@iDocumentId, @iEmployeeId, GETDATE(), @searchKey)
END