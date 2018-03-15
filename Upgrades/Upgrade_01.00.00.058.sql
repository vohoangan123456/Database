INSERT INTO #Description VALUES('create stored [dbo].[m136_GetUserEmailSubsciptionsFolder],
[m136_UpdateFavoritesSortOrder]
table value type UpdatedFavoriteItemsTable, 
update stored [dbo][m136_GetMyFavorites] to get iSort values')
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		h.iParentHandbookId as iHandbookId,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId,
		-1 as iDocumentTypeId
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND sb.iEmail = 1
END
GO

IF OBJECT_ID('[dbo].[m136_GetMyFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMyFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMyFavorites]
	@EmployeeId INT = 0,
	@TreatDepartmentFoldersAsFavorites BIT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @EmployeeId;
	--chapter
	SELECT
		h.iHandbookId, 
		h.strName, 
		h.iLevelType,
		bf.isForced AS isForced,
		bf.isDepartment AS isDepartment,
		bf.iSort
	FROM
		m136_tblHandbook h
		JOIN [dbo].[m136_fnGetFavoriteFolders](@EmployeeId, @TreatDepartmentFoldersAsFavorites,@iUserDepId) bf
			ON h.iHandbookId = bf.iHandbookId
	ORDER BY
		CASE WHEN (isDepartment = 1 AND isForced = 1) OR (isDepartment = 1) THEN h.strName
		END,
		isDepartment,
		isForced,
		CASE WHEN isDepartment = 0 AND isForced = 0 THEN bf.iSort
		END,
		h.strName
	--document
	SELECT
		d.iHandbookId,
		d.strName,
		d.iDocumentId, 
		d.iDocumentTypeId,
		sd.iSort
	FROM
		m136_tblSubscriberDocument sd
		JOIN m136_tblDocument d 
			ON (sd.iDocumentId = d.iDocumentId AND d.iLatestApproved = 1)
	WHERE
		sd.iEmployeeId = @EmployeeId
	ORDER BY
		sd.iSort,
		strName
END
GO

IF TYPE_ID(N'UpdatedFavoriteItemsTable') IS NULL
	EXEC ('CREATE TYPE UpdatedFavoriteItemsTable AS TABLE([Id] INT NULL, [iSort] INT NULL )')
GO

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT = 0,
	@IsFolder BIT =0,
	@ChangedFavoriteItems AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN
	IF(@IsFolder = 1)
		BEGIN
			UPDATE 
				dbo.m136_tblSubscribe 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscribe s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iHandbookId = c.Id
		END
	ELSE
		BEGIN
			UPDATE 
				dbo.m136_tblSubscriberDocument 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscriberDocument s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iDocumentId = c.Id
		END
END
GO