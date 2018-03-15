INSERT INTO #Description VALUES('Updated GetDocumentInformation')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestApproved = 1
END
GO