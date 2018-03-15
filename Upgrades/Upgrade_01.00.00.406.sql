INSERT INTO #Description VALUES ('Create SP and Table for save search function')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItemsForMobile]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsForMobile] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItemsForMobile]
	@ChapterId INT = NULL,
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@RegisterItemId INT = NULL
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
					dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
					0 as ViewType
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
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					0 as ViewType
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
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					ISNULL(iViewTypeId, -1) as ViewType
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
		
	IF @ChapterId IS NOT NULL
	BEGIN
		DECLARE @ViewType INT	
		SELECT	0 as iEntityId,
					h.iHandbookId as Id,
					h.strName as Name,
					-1 as DocumentTypeId,
					iLevelType as LevelType,
					h.iDepartmentId as DepartmentId,
					0 as Virtual,
					-2147483648 + h.iMin as iSort,
					NULL as ParentFolderName,
					dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
					ISNULL(iViewTypeId, -1) as ViewType
		INTO #Information
		FROM	m136_tblHandbook as h
		WHERE	h.iHandbookId = @ChapterId
			AND h.iDeleted = 0
			AND (dbo.fnSecurityGetPermission(136, 461, @SecurityId, @ChapterId) & 0x11) > 0
		IF @RegisterItemId IS NULL
		BEGIN		
			SELECT @ViewType = ViewType
			FROM #Information
			IF @ViewType > 10
				BEGIN
					SET @ViewType = @ViewType - 10
				END
			SET @RegisterItemId = @ViewType
		END
		
		SELECT *
		FROM #Information
		
		SELECT
			DISTINCT rel.iRegisterItemId AS RegisterItemId,
			reg.strName + ': ' + regitem.strName AS Name,
			doc.iHandbookId AS ChapterId
		FROM m147_relRegisterItemItem rel
			JOIN (SELECT iDocumentId, iHandbookId From m136_tbldocument Where iDeleted = 0 AND iLatestApproved = 1) doc ON doc.iDocumentId = rel.iItemId
			LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
			LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
			LEFT OUTER JOIN dbo.m147_tblRegisterItemValue val ON rel.iRegisterItemValueId = val.iRegisterItemValueId
		WHERE
			rel.iModuleId = 136
			AND rel.iRegisterItemId > 0
			AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @ChapterId AND d.iDeleted = 0 AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
		ORDER BY
			Name ASC
		
		SELECT
			DISTINCT rel.iRegisterItemId AS RegisterItemId,
			reg.strName + ': ' + regitem.strName AS Name,
			@ChapterId AS ChapterId,
			val.iRegisterItemValueId AS RegisterItemValueId,
			val.RegisterValue
		FROM m147_relRegisterItemItem rel
			LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
			LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
			LEFT OUTER JOIN dbo.m147_tblRegisterItemValue val ON rel.iRegisterItemValueId = val.iRegisterItemValueId
		WHERE
			rel.iModuleId = 136
			AND rel.iRegisterItemId = @RegisterItemId
			AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @ChapterId AND d.iDeleted = 0 AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
		ORDER BY
			Name ASC	
			
		DROP TABLE #Information
	END
	
	DROP TABLE #ReturnRecords
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByMetataggedAndChapterId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByMetataggedAndChapterId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByMetataggedAndChapterId]
(
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@RegisterItemValueId INT,
	@ChapterId INT
)
AS
BEGIN
		SELECT
			RowNumber = ROW_NUMBER() OVER (ORDER BY d.iSort, d.strName),
			d.iDocumentId AS DocumentId, 
			d.iEntityId AS EntityId,
			d.strName AS Name, 
			d.iHandbookId AS HandbookId, 
			h.strName AS ChapterName,
			d.iVersion AS Version,
			d.iSort AS Sort
		INTO #ReturnRecords
		FROM 
			m136_tblDocument d
			JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			JOIN m147_relRegisterItemItem dt 
				ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemValueId = @RegisterItemValueId AND dt.iModuleId=136) 				
		WHERE d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE()
			AND dt.iAutoId IS NOT NULL
			AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
			AND d.iHandbookId = @ChapterId
			
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

IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsForApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsForApprovedDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsForApprovedDocuments]
(
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		DISTINCT rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @iHandbookId AND d.iDeleted = 0 AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsRecursiveForApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsRecursiveForApprovedDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsRecursiveForApprovedDocuments]
(	
	@iSecurityId INT,
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	INSERT INTO @AvailableHandbooks	
		SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		
	SELECT DISTINCT 
		rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN 
			(SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN 
				(SELECT iHandbookId FROM @AvailableHandbooks)  AND d.iDeleted = 0  AND d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE())
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[SearchFilterTypes]') AND type in (N'U'))
	CREATE TABLE [dbo].[SearchFilterTypes](
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL
	)
GO

SET IDENTITY_INSERT [dbo].[SearchFilterTypes] ON;

MERGE [dbo].[SearchFilterTypes] AS t
USING (VALUES 
	(1, 'Handbook Backend Search'),
	(2, 'Handbook Reports'),
	(3, 'Deviation Backend Search'),
	(4, 'Deviation Reports'),
	(5, 'Risk Backend Search'),
	(6, 'Risk Reports')
	) AS src([Id], [Name])
ON (t.[Id] = src.[Id])

WHEN NOT MATCHED BY TARGET THEN 
	INSERT ([Id], [Name]) 
	VALUES(src.[Id], src.[Name])
WHEN MATCHED THEN
	UPDATE
	SET [Name] = src.[Name];
GO

SET IDENTITY_INSERT [dbo].[SearchFilterTypes] OFF;

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserSavedSearches]') AND type in (N'U'))
	CREATE TABLE [dbo].[UserSavedSearches](
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        SearchFilterType INT NOT NULL,
        Name NVARCHAR(100) NOT NULL,
        SearchFilters NVARCHAR(MAX) NOT NULL,
        Sort INT NOT NULL DEFAULT 0
	)
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_UserSavedSearches_SearchFilterTypes_Id')
BEGIN
	ALTER TABLE [dbo].[UserSavedSearches] ADD CONSTRAINT FK_UserSavedSearches_SearchFilterTypes_Id FOREIGN KEY (SearchFilterType)
        REFERENCES [dbo].[SearchFilterTypes] (Id)
END
GO

IF OBJECT_ID('[dbo].[GetUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUserSavedSearches] 
	@SearchFilterType INT
AS
BEGIN

	SELECT  
		Id,
        SearchFilterType,
        Name,
        SearchFilters,
        Sort 
	FROM [dbo].[UserSavedSearches]
	WHERE SearchFilterType = @SearchFilterType
	ORDER BY Sort
END
GO

IF OBJECT_ID('[dbo].[InsertUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[InsertUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[InsertUserSavedSearches] 
	@SearchFilterType INT,
	@Name NVARCHAR(100),
	@SearchFilters NVARCHAR(MAX)
AS
BEGIN
	DECLARE @SortTemp INT 
	
	SELECT @SortTemp = MAX(Sort) FROM [dbo].[UserSavedSearches] WHERE SearchFilterType = @SearchFilterType
	
	DECLARE @Sort INT = ISNULL(@SortTemp, 0) + 1;
	
	INSERT INTO [dbo].[UserSavedSearches]
		(SearchFilterType, Name, SearchFilters, Sort)
		VALUES(@SearchFilterType,@Name,@SearchFilters,@Sort)
END
GO

IF OBJECT_ID('[dbo].[UpdateUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[UpdateUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[UpdateUserSavedSearches] 
	@Id INT,
	@Name NVARCHAR(100),
	@SearchFilters NVARCHAR(MAX)
AS
BEGIN
	UPDATE [dbo].[UserSavedSearches]
		SET Name = @Name,
		SearchFilters = @SearchFilters
	WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[UpdateUserSavedSearchesByName]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[UpdateUserSavedSearchesByName] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[UpdateUserSavedSearchesByName] 
	@SearchFilterType INT,
	@Name NVARCHAR(100),
	@SearchFilters NVARCHAR(MAX)
AS
BEGIN
	UPDATE [dbo].[UserSavedSearches]
		SET SearchFilters = @SearchFilters
	WHERE Name = @Name AND SearchFilterType = @SearchFilterType
END
GO

IF OBJECT_ID('[dbo].[GetUserSavedSearchesByName]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserSavedSearchesByName] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUserSavedSearchesByName] 
	@Id INT = NULL,
	@Name NVARCHAR(100),
	@SearchFilterType INT
AS
BEGIN
	SELECT  
		Id,
		SearchFilterType,
		Name,
		SearchFilters,
		Sort 
	FROM [dbo].[UserSavedSearches]
	WHERE Name = @Name AND (@Id IS NULL OR Id <> @Id) AND SearchFilterType = @SearchFilterType
END
GO

IF OBJECT_ID('[dbo].[DeleteUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[DeleteUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[DeleteUserSavedSearches] 
	@Id INT
AS
BEGIN
	DELETE FROM [dbo].[UserSavedSearches]
	WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[SaveSortOrderUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[SaveSortOrderUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[SaveSortOrderUserSavedSearches] 
	@UserSavedSearchesIds AS [dbo].[Item] READONLY
AS
BEGIN

	UPDATE
        U
    SET
        Sort = I.Value
    FROM
        [dbo].[UserSavedSearches] U
            INNER JOIN @UserSavedSearchesIds I
                ON U.Id = I.Id
END
GO