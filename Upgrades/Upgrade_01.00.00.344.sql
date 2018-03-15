INSERT INTO #Description VALUES ('Modify procedures for mobile app')
GO

IF OBJECT_ID('[dbo].[m136_GetLatestDocumentById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestDocumentById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetLatestDocumentById]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	SELECT EntityId = doc.iEntityId, 
		DocumentId = doc.iDocumentId,
		[Version] = doc.iVersion,
		DocumentTypeId = doc.iDocumentTypeId,
		HandbookId = doc.iHandbookId,
		Name = doc.strName,
		[Description] = doc.strDescription,
		CreatedbyId = doc.iCreatedbyId,
		CreatedDate = doc.dtmCreated,
		Author = doc.strAuthor,
		ApprovedById = doc.iApprovedById,
		ApprovedDate = doc.dtmApproved,
		ApprovedBy = doc.strApprovedBy,
		Sort = doc.iSort,
		UrlOrFileName = doc.UrlOrFileName,
		Type = t.Type,
		LevelType = doc.iLevelType
	FROM dbo.m136_tblDocument doc
	INNER JOIN dbo.m136_tblDocumentType t 
		ON doc.iDocumentTypeId = t.iDocumentTypeId
	WHERE doc.iDocumentId = @DocumentId
		AND doc.iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
		AND doc.iDeleted = 0
		AND doc.dtmPublish <= GETDATE()
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentData]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentData] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	DECLARE @EntityId INT,
		@DocumentTypeId INT
	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL,
		Sort int,
		UrlOrFileName NVARCHAR(4000) NULL,
		Type INT NULL,
		LevelType int
	)
	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	--Get Document Content
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   FieldId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId IN (20, 2, 50)
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   FieldId = r.iPlacementId,
		   LevelType = d.iLevelType
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	--Get Document Info
	SELECT * FROM @Document
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments_Mobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments_Mobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_SearchDocuments_Mobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@SearchString varchar(1024) = '',
	@LikeSearchWords varchar(900) = '',
	@SearchInContent BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @searchHits TABLE(iEntityId int not null PRIMARY KEY, RANK int not null)
	DECLARE @KEYWORD TABLE(strKeyWord varchar(900) not null)
	INSERT INTO @KEYWORD
	SELECT DISTINCT Value FROM fn_Split(@LikeSearchWords, ',')
	DECLARE @KEYWORDCOUNT as INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @Keyword
	DECLARE @ReturnTable TABLE (iEntityId int,
								Id int,
								Name VARCHAR(200),
								ChapterId int,
								ParentFolderName varchar(200), 
								DocumentTypeId int,
								LevelType int,
								IsChapter Bit,
								RANK int,
								[Path] varchar(1000))
	IF @ChapterId IS NULL
		BEGIN
			INSERT INTO @ReturnTable
			SELECT  0 AS iEntityId,
					iHandbookId AS Id,
					strName AS Name,
					iHandbookId AS ChapterId,
					strName AS ParentFolderName,
					-1 AS DocumentTypeId,
					iLevelType AS LevelType,
					1 AS IsChapter,
					0 AS RANK,
					dbo.fn136_GetParentPathEx(iHandbookId) as [Path]
				FROM dbo.m136_tblHandbook
				WHERE iDeleted = 0
					  AND
					(
					  (@KEYWORDCOUNT = 0 )
					  OR 
					  (iHandbookId in (SELECT iHandbookId
								FROM 
									dbo.m136_tblHandbook h
									INNER JOIN @Keyword k
								   ON h.strName like '%' + k.strKeyWord + '%'
								 GROUP BY 
								  iHandbookId
								 HAVING COUNT(iHandbookId) = @KEYWORDCOUNT))
					)
			INSERT INTO @searchHits
			SELECT DISTINCT doc.iEntityId
							,1000 AS RANK
			FROM
				dbo.m136_tblDocument doc	
				INNER JOIN	dbo.m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId				
			where
				iLatestApproved = 1
				AND	[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, handbook.iHandbookId) = 1
				AND
				(
				  (@KEYWORDCOUNT = 0 )
				  OR 
				  (doc.iEntityId in (SELECT iEntityId
							FROM 
								dbo.m136_tblDocument doc 
								INNER JOIN @Keyword k
							   ON doc.strName like '%' + k.strKeyWord + '%'
							 GROUP BY 
							  iEntityId
							 HAVING COUNT(iEntityId) = @KEYWORDCOUNT))
				)
			IF(@searchInContent = 1)
				BEGIN		
					insert into @searchHits
					select SearchHits.iEntityId
						,RANK
					FROM
						dbo.m136_tblDocument doc 	
						INNER JOIN	dbo.m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId		
						RIGHT JOIN 
						m136x_tblTextIndex SearchHits on doc.iEntityId=SearchHits.iEntityId 
						INNER JOIN CONTAINSTABLE (m136x_tblTextIndex, totalvalue, @SearchString) AS KEY_TBL
						on SearchHits.iEntityId=KEY_TBL.[KEY]
					where
						iLatestApproved = 1
						AND			[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, handbook.iHandbookId) = 1
						AND doc.iEntityId not in (select iEntityId from @searchHits)
				  END
		END
	ELSE
		BEGIN
			DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
			INSERT INTO @AvailableChildren(iHandbookId)
				SELECT 
					iHandbookId 
				FROM 
					[dbo].[m136_GetHandbookRecursive](@ChapterId, @SecurityId, 1);
			INSERT INTO @ReturnTable
			SELECT DISTINCT 0 AS iEntityId,
					h.iHandbookId AS Id,
					h.strName AS Name,
					h.iHandbookId AS ChapterId,
					h.strName AS ParentFolderName,
					-1 AS DocumentTypeId,
					h.iLevelType AS LevelType,
					1 AS IsChapter,
					0 as RANK,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path]
				FROM dbo.m136_tblHandbook h
					JOIN @AvailableChildren a ON h.iHandbookId = a.iHandbookId
				WHERE iDeleted = 0
					  AND
					(
					  (@KEYWORDCOUNT = 0 )
					  OR 
					  (h.iHandbookId in (SELECT iHandbookId
								FROM 
									dbo.m136_tblHandbook h
									INNER JOIN @Keyword k
								   ON h.strName like '%' + k.strKeyWord + '%'
								 GROUP BY 
								  iHandbookId
								 HAVING COUNT(iHandbookId) = @KEYWORDCOUNT))
					)
					AND h.iHandbookId <> @ChapterId
			INSERT INTO @searchHits
			SELECT DISTINCT doc.iEntityId
							,1000 AS RANK
			FROM
				dbo.m136_tblDocument doc	
				INNER JOIN	dbo.m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId
				JOIN @AvailableChildren a ON doc.iHandbookId = a.iHandbookId				
			where
				iLatestApproved = 1
				AND	[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, handbook.iHandbookId) = 1
				AND
				(
				  (@KEYWORDCOUNT = 0 )
				  OR 
				  (doc.iEntityId in (SELECT iEntityId
							FROM 
								dbo.m136_tblDocument doc 
								INNER JOIN @Keyword k
							   ON doc.strName like '%' + k.strKeyWord + '%'
							 GROUP BY 
							  iEntityId
							 HAVING COUNT(iEntityId) = @KEYWORDCOUNT))
				)
			IF(@searchInContent = 1)
				BEGIN		
					insert into @searchHits
					select SearchHits.iEntityId
						,RANK
					FROM
						dbo.m136_tblDocument doc 	
						INNER JOIN	dbo.m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId		
						INNER JOIN @AvailableChildren a ON doc.iHandbookId = a.iHandbookId				
						RIGHT JOIN 
						m136x_tblTextIndex SearchHits on doc.iEntityId=SearchHits.iEntityId 
						INNER JOIN CONTAINSTABLE (m136x_tblTextIndex, totalvalue, @SearchString) AS KEY_TBL
						on SearchHits.iEntityId=KEY_TBL.[KEY]
					where
						iLatestApproved = 1
						AND			[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, handbook.iHandbookId) = 1
						AND doc.iEntityId not in (select iEntityId from @searchHits)
				  END
		END
	INSERT INTO @ReturnTable
		SELECT DISTINCT	doc.iEntityId,
						doc.iDocumentId AS Id,
						doc.strName AS Name,
						doc.iHandbookId AS ChapterId,
						handbook.strName AS ParentFolderName,
						doc.iDocumentTypeId AS DocumentTypeId,
						handbook.iLevelType AS LevelType,
						0 AS IsChapter,
						SearchHits.RANK,
						dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path]
		FROM			m136_tblDocument doc
			INNER JOIN	dbo.m136_tblHandbook handbook 
				ON handbook.iHandbookId = doc.iHandbookId		
			INNER JOIN	@searchHits SearchHits on SearchHits.iEntityId=doc.iEntityId
	SELECT  iEntityId,
			Id,
			Name,
			ChapterId,
			ParentFolderName, 
			DocumentTypeId,
			LevelType,
			IsChapter,
			[Path]
	FROM (
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY IsChapter DESC, RANK DESC, LevelType, Name)
		FROM @ReturnTable
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	SELECT COUNT(*) FROM @ReturnTable
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById_Mobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById_Mobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_SearchDocumentsById_Mobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@Id VARCHAR(100)
AS
SET NOCOUNT ON
BEGIN
	DECLARE @ReturnTable TABLE (iEntityId int,
								Id int,
								Name VARCHAR(200),
								ChapterId int,
								ParentFolderName varchar(200), 
								DocumentTypeId int,
								LevelType int,
								IsChapter Bit,
								[Path] varchar(1000))
	IF @ChapterId IS NULL
		BEGIN
			
			INSERT INTO @ReturnTable
			SELECT DISTINCT	doc.iEntityId,
							doc.iDocumentId AS Id,
							doc.strName AS Name,
							doc.iHandbookId AS ChapterId,
							handbook.strName AS ParentFolderName,
							doc.iDocumentTypeId AS DocumentTypeId,
							handbook.iLevelType AS LevelType,
							0 AS IsChapter,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path]
			FROM			m136_tblDocument doc
			INNER JOIN	dbo.m136_tblHandbook handbook 
				ON handbook.iHandbookId = doc.iHandbookId		
			WHERE doc.iDeleted = 0
				  AND doc.iLatestApproved = 1
				  AND	[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, doc.iHandbookId) = 1
				  AND doc.iDocumentId Like + @Id + '%'
		END
	ELSE
		BEGIN
			DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
			INSERT INTO @AvailableChildren(iHandbookId)
				SELECT 
					iHandbookId 
				FROM 
					[dbo].[m136_GetHandbookRecursive](@ChapterId, @SecurityId, 1);
			
			INSERT INTO @ReturnTable
			SELECT DISTINCT	doc.iEntityId,
							doc.iDocumentId AS Id,
							doc.strName AS Name,
							doc.iHandbookId AS ChapterId,
							handbook.strName AS ParentFolderName,
							doc.iDocumentTypeId AS DocumentTypeId,
							handbook.iLevelType AS LevelType,
							0 AS IsChapter,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path]
			FROM			m136_tblDocument doc
			INNER JOIN	dbo.m136_tblHandbook handbook 
				ON handbook.iHandbookId = doc.iHandbookId		
			INNER JOIN @AvailableChildren a 
				ON doc.iHandbookId = a.iHandbookId				
			WHERE doc.iDeleted = 0
				  AND doc.iLatestApproved = 1
				  AND	[dbo].[fnHandbookHasReadContentsAccess](@SecurityId, doc.iHandbookId) = 1
				  AND doc.iDocumentId Like + @Id + '%'
		END
	SELECT  iEntityId,
			Id,
			Name,
			ChapterId,
			ParentFolderName, 
			DocumentTypeId,
			LevelType,
			IsChapter,
			[Path]
	FROM (
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY IsChapter DESC, Name)
		FROM @ReturnTable
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	SELECT COUNT(*) FROM @ReturnTable
END
GO

