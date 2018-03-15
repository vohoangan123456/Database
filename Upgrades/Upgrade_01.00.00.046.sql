INSERT INTO #Description VALUES('update stored m136_SearchDocuments, m136_SearchDocumentsById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@keyword VARCHAR(900),
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @KEYWORDCOUNT AS INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @searchTermTable
	
	SELECT DISTINCT
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO #searchResult
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN	m136x_tblTextIndex textIndex 
			ON textIndex.iEntityId = doc.iEntityId
	WHERE
		iLatestApproved = 1
		AND	(doc.iEntityId in (SELECT	iEntityId
							   FROM		m136_tblDocument d 
								 INNER JOIN @searchTermTable st
									ON	d.strName LIKE '%' + st.Term + '%'
							   WHERE		d.iLatestApproved = 1
							   GROUP BY	iEntityId
							   HAVING COUNT(iEntityId) = @KEYWORDCOUNT)
			OR	(@searchInContent = 1 AND CONTAINS(totalvalue,@keyword)))
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS Total 
	FROM 
		#searchResult
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	SELECT DISTINCT	
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO 
		#searchResult 
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS Total 
	FROM 
		#searchResult
END