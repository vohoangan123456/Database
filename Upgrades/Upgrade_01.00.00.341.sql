INSERT INTO #Description VALUES ('Update SP for Mobile')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItemsForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsForMobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItemsForMobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT *, ROW_NUMBER() OVER (ORDER BY iSort ASC, Name ASC) AS rowNumber
	INTO #ReturnRecords
	FROM
	(
			SELECT	d.iEntityId,
					d.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,					
					NULL as LevelType,
					null as DepartmentId,
					0 as Virtual,
					d.iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(d.iHandbookId) as Path
			FROM	m136_tblDocument d
			WHERE	d.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	d.iEntityId,
					v.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,
					NULL as LevelType,
					null as DepartmentId,
					1 as Virtual,
					v.iSort,
					h.strName as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_relVirtualRelation v
				INNER JOIN m136_tblDocument d 
					ON d.iDocumentId = v.iDocumentId
				INNER JOIN m136_tblHandbook h
					ON d.iHandbookId = h.iHandbookId
			WHERE	v.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_tblHandbook as h
			WHERE	(h.iParentHandbookId = @ChapterId OR (h.iParentHandbookId IS NULL AND @ChapterId IS NULL))
				AND h.iDeleted = 0
				AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, h.iHandbookId) & 0x11) > 0
		)OneTable
	

	IF(@PageSize = 0)
		BEGIN
			SELECT * FROM #ReturnRecords
		END
	ELSE
		BEGIN
			SELECT * FROM #ReturnRecords
			WHERE RowNumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)
		END
	
	DROP TABLE #ReturnRecords
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
								[Path] varchar(1000))
	
	INSERT INTO @ReturnTable
	SELECT  0 AS iEntityId,
			iHandbookId AS Id,
			strName AS Name,
			iHandbookId AS ChapterId,
			strName AS ParentFolderName,
			-1 AS DocumentTypeId,
			iLevelType AS LevelType,
			1 AS IsChapter,
			dbo.fn136_GetParentPathEx(iHandbookId) as [Path]
		FROM dbo.m136_tblHandbook
		WHERE iDeleted = 0
			  AND strName LIKE '%' + @LikeSearchWords + '%'
			  AND (@ChapterId IS NULL OR iParentHandbookId = @ChapterId)
	
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
		AND 
		(
			(@ChapterId IS NULL)
			OR
			(doc.iHandbookId = @ChapterId)
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
				AND 
				(
					(@ChapterId IS NULL)
					OR
					(doc.iHandbookId = @ChapterId)
				)
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
			RowNumber = ROW_NUMBER() OVER (ORDER BY IsChapter DESC, Name)
		FROM @ReturnTable
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	
	SELECT COUNT(*) FROM @ReturnTable
END
GO


IF OBJECT_ID('[dbo].[m136_GetChapterItemsForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsForMobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItemsForMobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT *, ROW_NUMBER() OVER (ORDER BY iSort ASC, Name ASC) AS rowNumber
	INTO #ReturnRecords
	FROM
	(
			SELECT	d.iEntityId,
					d.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,					
					NULL as LevelType,
					null as DepartmentId,
					0 as Virtual,
					d.iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(d.iHandbookId) as Path
			FROM	m136_tblDocument d
			WHERE	d.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	d.iEntityId,
					v.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,
					NULL as LevelType,
					null as DepartmentId,
					1 as Virtual,
					v.iSort,
					h.strName as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_relVirtualRelation v
				INNER JOIN m136_tblDocument d 
					ON d.iDocumentId = v.iDocumentId
				INNER JOIN m136_tblHandbook h
					ON d.iHandbookId = h.iHandbookId
			WHERE	v.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_tblHandbook as h
			WHERE	(h.iParentHandbookId = @ChapterId OR (h.iParentHandbookId IS NULL AND @ChapterId IS NULL))
				AND h.iDeleted = 0
				AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, h.iHandbookId) & 0x11) > 0
		)OneTable
	

	IF(@PageSize = 0)
		BEGIN
			SELECT * FROM #ReturnRecords
			
			SELECT COUNT(1) FROM #ReturnRecords
		END
	ELSE
		BEGIN
			SELECT * FROM #ReturnRecords
			WHERE RowNumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)
			
			SELECT COUNT(1) FROM #ReturnRecords
		END
	
	DROP TABLE #ReturnRecords
END
GO

IF OBJECT_ID('[dbo].[m136_GetHandbookRecursive]', 'if') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[m136_GetHandbookRecursive]() RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO

ALTER FUNCTION [dbo].[m136_GetHandbookRecursive]
(	
	@iHandbookId INT,
	@iSecurityId INT,
	@bCheckSecurity BIT
)
RETURNS TABLE
AS
RETURN 
(
    WITH Children AS
	(
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] 
			WHERE
				iHandbookId = @iHandbookId 
				AND iDeleted = 0
		UNION ALL
			SELECT 
				h.iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] h
				INNER JOIN Children 
					ON	iParentHandbookId = Children.iHandbookId 
						AND h.iDeleted = 0
	)
	SELECT 
		iHandbookId 
	FROM 
		Children
	WHERE 
		(@bCheckSecurity = 0 OR [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1)
)
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
			RowNumber = ROW_NUMBER() OVER (ORDER BY IsChapter DESC, Name)
		FROM @ReturnTable
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	
	SELECT COUNT(*) FROM @ReturnTable
END
GO

IF OBJECT_ID('[dbo].[m136_GetParentNodes_Mobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetParentNodes_Mobile] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetParentNodes_Mobile]
	@Id INT = NULL,
	@SecurityId INT,
	@IsChapter BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @chapterId INT = @Id;
	IF @IsChapter <> 1
		BEGIN
			SELECT @chapterId = iHandbookId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @Id
				  AND iLatestApproved = 1
		END
	;WITH Parents AS
		(
			SELECT 
				iParentHandbookId,
				iHandbookId AS Id,
				strName AS Name,
				iParentHandbookId AS ChapterId,
				iLevelType AS LevelType,
				iLevel
			FROM 
				[dbo].[m136_tblHandbook] 
			WHERE
				iHandbookId = @chapterId
			UNION ALL
			SELECT 
				h.iParentHandbookId,
				h.iHandbookId AS Id,
				h.strName AS Name,
				h.iParentHandbookId AS ChapterId,
				h.iLevelType AS LevelType,
				h.iLevel
			FROM 
				[dbo].[m136_tblHandbook] h
				INNER JOIN Parents
					ON	h.iHandbookId = Parents.iParentHandbookId 
		)
		SELECT
			Id,
			Name,
			ChapterId,
			LevelType
		FROM
			Parents
		WHERE (@IsChapter = 1 AND @chapterId <> Id) OR @IsChapter <> 1
		ORDER BY iLevel
END
GO

IF OBJECT_ID('[dbo].[m136_ValidateChapterExistence]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ValidateChapterExistence] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_ValidateChapterExistence]
(
	@SecurityId INT,
	@ChapterIds VARCHAR(8000)
)
AS
BEGIN
	DECLARE @TblChapterId TABLE    
	(
		Id  INT
	)
	INSERT INTO @TblChapterId
	SELECT ELEMENT FROM [dbo].[fnSplit_Gastro](@ChapterIds,',')
	
	SELECT h.iHandbookId AS Id,
		   h.strName AS Name,
		   h.iParentHandbookId AS ChapterId,
		   h.iLevelType AS LevelType,
		   dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path]
	FROM @TblChapterId t 
	INNER JOIN dbo.m136_tblHandbook h ON h.iHandbookId = t.Id and h.iDeleted = 0
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
			SELECT  0 AS iEntityId,
					iHandbookId AS Id,
					strName AS Name,
					iHandbookId AS ChapterId,
					strName AS ParentFolderName,
					-1 AS DocumentTypeId,
					iLevelType AS LevelType,
					1 AS IsChapter,
					dbo.fn136_GetParentPathEx(iHandbookId) as [Path]
				FROM dbo.m136_tblHandbook
				WHERE iDeleted = 0
					  AND iHandbookId Like + @Id + '%'
			
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
			SELECT DISTINCT 0 AS iEntityId,
					h.iHandbookId AS Id,
					h.strName AS Name,
					h.iHandbookId AS ChapterId,
					h.strName AS ParentFolderName,
					-1 AS DocumentTypeId,
					h.iLevelType AS LevelType,
					1 AS IsChapter,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path]
				FROM dbo.m136_tblHandbook h
					JOIN @AvailableChildren a ON h.iHandbookId = a.iHandbookId
				WHERE iDeleted = 0
					AND h.iHandbookId Like + @Id + '%'
					AND h.iHandbookId <> @ChapterId
			
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


IF OBJECT_ID('[dbo].[m136_ValidateDocumentExistence]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ValidateDocumentExistence] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_ValidateDocumentExistence]
(
	@SecurityId INT,
	@DocumentIds VARCHAR(8000)
)
AS
BEGIN
	DECLARE @TblDocumentId TABLE    
	(
		Id  INT
	) 
	INSERT INTO @TblDocumentId
	SELECT ELEMENT FROM [dbo].[fnSplit_Gastro](@DocumentIds,',')
	SELECT DocumentId =	s.iDocumentId, 
		[Version] = s.iVersion, 
		ApprovedDate = s.dtmApproved, 
		IsDeleted = s.iDeleted,
		iEntityId AS EntityId, 
		strName AS Name
	FROM @TblDocumentId t 
	INNER JOIN 
	(
		SELECT iDocumentId, iLatestVersion, iLatestApproved, iVersion, dtmApproved, iDeleted, iEntityId, strName
		FROM dbo.m136_tblDocument 
		WHERE iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, iHandbookId)&1)=1
		AND iDeleted = 0
		AND dtmPublish <= GETDATE()
	) s 
	ON s.iDocumentId = t.Id
END
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
		Type = t.Type
		
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
		Type INT NULL
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
		   FieldId = r.iPlacementId
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

IF OBJECT_ID('[dbo].[m136_GetStreamFileDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetStreamFileDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetStreamFileDocument]
	@EntityId INT = NULL
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
				d.iEntityId = @EntityId
			AND d.iLatestApproved = 1 
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItemsForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsForMobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItemsForMobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT *, ROW_NUMBER() OVER (ORDER BY iSort ASC, Name ASC) AS rowNumber
	INTO #ReturnRecords
	FROM
	(
			SELECT	d.iEntityId,
					d.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,					
					d.iLevelType as LevelType,
					null as DepartmentId,
					0 as Virtual,
					d.iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(d.iHandbookId) as Path
			FROM	m136_tblDocument d
			WHERE	d.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	d.iEntityId,
					v.iDocumentId as Id,
					d.strName as Name,
					d.iDocumentTypeId AS DocumentTypeId,
					d.iLevelType as LevelType,
					null as DepartmentId,
					1 as Virtual,
					v.iSort,
					h.strName as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_relVirtualRelation v
				INNER JOIN m136_tblDocument d 
					ON d.iDocumentId = v.iDocumentId
				INNER JOIN m136_tblHandbook h
					ON d.iHandbookId = h.iHandbookId
			WHERE	v.iHandbookId = @ChapterId
				AND d.iLatestApproved = 1
				AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		UNION
			SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
			FROM	m136_tblHandbook as h
			WHERE	(h.iParentHandbookId = @ChapterId OR (h.iParentHandbookId IS NULL AND @ChapterId IS NULL))
				AND h.iDeleted = 0
				AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, h.iHandbookId) & 0x11) > 0
		)OneTable
	

	IF(@PageSize = 0)
		BEGIN
			SELECT * FROM #ReturnRecords
			
			SELECT COUNT(1) FROM #ReturnRecords
		END
	ELSE
		BEGIN
			SELECT * FROM #ReturnRecords
			WHERE RowNumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)
			
			SELECT COUNT(1) FROM #ReturnRecords
		END
	
	DROP TABLE #ReturnRecords
END
GO