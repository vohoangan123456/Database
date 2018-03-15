INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_GetAboutDocumentDataForMobile].')
GO

IF OBJECT_ID('[dbo].[m136_GetAboutDocumentDataForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetAboutDocumentDataForMobile] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetAboutDocumentDataForMobile]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	DECLARE @returnTable TABLE(Name NVARCHAR(1000), Value NVARCHAR(1000))
	DECLARE @DocumentType VARCHAR(100), @DocumentTitle VARCHAR(200), @Placement VARCHAR(1000)
	DECLARE @reDocumentId INT, @DocumentVersion INT, @PublishedDate DATETIME, @Approver VARCHAR(200)
	SELECT @DocumentType = t.strName, 
		@DocumentTitle = doc.strName,
		@Placement = dbo.fn136_GetParentPathEx(doc.iHandbookId),
		@reDocumentId = doc.iDocumentId,
		@DocumentVersion = doc.iVersion,
		@PublishedDate = doc.dtmPublish,
		@Approver = doc.strApprovedBy
	FROM dbo.m136_tblDocument doc
	INNER JOIN dbo.m136_tblDocumentType t 
		ON doc.iDocumentTypeId = t.iDocumentTypeId
	WHERE doc.iDocumentId = @DocumentId
		AND doc.iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
		AND doc.iDeleted = 0
		AND doc.dtmPublish <= GETDATE()
	INSERT INTO @returnTable
	VALUES('Dokumenttype', @DocumentType)
	INSERT INTO @returnTable
	VALUES('Tittel', @DocumentTitle)
	INSERT INTO @returnTable
	VALUES('Plassering', @Placement)
	INSERT INTO @returnTable
	VALUES('Dokumentnummer', @reDocumentId)
	INSERT INTO @returnTable
	VALUES('Versjon', @DocumentVersion)
	INSERT INTO @returnTable
	VALUES('Godkjent', LEFT(CONVERT(VARCHAR, @PublishedDate, 104), 10) +  ' - ' +  @Approver)
	SELECT * FROM @returnTable
END

