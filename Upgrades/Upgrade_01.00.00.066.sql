INSERT INTO #Description VALUES('update m136_SearchDocument and m136_SearchDocumentById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@maxCount INT,
	@getTotal BIT,
	@iDocumentTypeId INT = NULL,
	@fromDate DATE = NULL,
	@toDate DATE = NULL
AS
SET NOCOUNT ON
BEGIN

	DECLARE @SearchString varchar(100)
	DECLARE @ReversedSearchString varchar(100)
	
	DECLARE @TermsCount AS INT
	SELECT @TermsCount = COUNT(*) FROM @searchTermTable
	
	SELECT @SearchString = COALESCE(@SearchString + ' OR ', '') + '"' + Term + '*"' FROM @searchTermTable
	SELECT @ReversedSearchString = COALESCE(@ReversedSearchString + ' OR ', '') + '"' + REVERSE(Term) + '*"' FROM @searchTermTable
	
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000

	IF @getTotal = 0
	SET @TopMaxDocs = @maxCount

	DECLARE @TitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @InitialTitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY,
		strName varchar(200),
		iHandbookId int
	)

	DECLARE @ContentsSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @SearchTable TABLE
	(
		iEntityId INT
	)

	--
	-- Initial Search in title
	--
	INSERT INTO @InitialTitleSearchTable
		SELECT
			doc.iEntityId,
			doc.strName,
			doc.iHandbookId
		FROM
			m136_tblDocument doc
		WHERE
				iLatestApproved = 1
			AND
				(
					@SearchString = '"*"'
					OR 
					CONTAINS(doc.strName, @SearchString) 
					OR 
					CONTAINS(doc.strNameReversed, @ReversedSearchString)
				)
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
	--
	-- Verification that title search contains only documents with title that has EACH search term
	--
	INSERT INTO @TitleSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			@InitialTitleSearchTable doc
			INNER JOIN @searchTermTable terms
				ON @TermsCount = 1 OR doc.strName LIKE '%' + terms.Term + '%'
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
		GROUP BY	
			iEntityId
		HAVING 
			COUNT(iEntityId) = @TermsCount
     --
     -- Search in Contents
	 --
	INSERT INTO @ContentsSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			m136_tblDocument doc
			LEFT JOIN m136x_tblTextIndex textIndex 
				ON textIndex.iEntityId = doc.iEntityId
		WHERE
				@searchInContent = 1
			AND
				iLatestApproved = 1
			AND 
				@SearchString <> '"*"'
			AND	
				CONTAINS(totalvalue, @SearchString)
			AND
				[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
			
	
	--
	-- Union both results
	--
	INSERT INTO @SearchTable
		SELECT * FROM @TitleSearchTable
		UNION 
		SELECT * FROM @ContentsSearchTable
		
	-- Select the total number of search results
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable

	-- Select the data
	SELECT TOP (@maxCount) 
		iDocumentId AS Id,
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
		--,title.iEntityId --Test only
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook
				ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN @TitleSearchTable title
				ON @searchInContent = 1 AND doc.iEntityId = title.iEntityId
	WHERE
		doc.iEntityId in (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		title.iEntityId DESC, -- Will be null if it's not title
		LevelType ASC,
		strName ASC
END
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
		doc.iDocumentId IN (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END
GO