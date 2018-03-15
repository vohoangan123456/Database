INSERT INTO #Description VALUES('Update stored m136_SearchDocumentsById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT,
	@getTotal BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
		SET @TopMaxDocs = @maxCount
		
	DECLARE @SearchTable TABLE
	(
		iEntityId INT PRIMARY KEY
	)
	
	INSERT INTO @SearchTable
	SELECT TOP(@TopMaxDocs)
		doc.iEntityId
	FROM			
		m136_tblDocument doc
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, doc.iHandbookId) = 1
		
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
		
	SELECT TOP(@maxCount)
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE
		doc.iEntityId IN (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END