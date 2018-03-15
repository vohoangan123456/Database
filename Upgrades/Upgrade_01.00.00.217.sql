INSERT INTO #Description VALUES('Loading file document by DocumentId')
GO

IF OBJECT_ID('[dbo].[m136_GetFileDocumentByDocumentId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileDocumentByDocumentId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileDocumentByDocumentId]
	@UserId INT,
	@DocumentId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT	
        d.UrlOrFileName,
		d.UrlOrFileProperties,
		d.[File]
	FROM	
		m136_tblDocument d
	WHERE	
			d.iDocumentId = @DocumentId
		AND d.iLatestApproved = 1 
		AND [dbo].[fnHandbookHasReadContentsAccess](@UserId, d.iHandbookId) = 1
END
GO