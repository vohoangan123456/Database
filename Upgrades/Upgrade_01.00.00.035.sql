INSERT INTO #Description VALUES('Stored procedure [m136_GetDocumentLatestApproved] added')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentLatestApproved]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentLatestApproved] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentLatestApproved]
	@DocumentId INT,
	@Version INT
AS
SET NOCOUNT ON
BEGIN

	SELECT
		iLatestApproved
	FROM
		m136_tblDocument
	WHERE
			iDocumentId = @DocumentId
		AND iVersion = @Version

END

GO