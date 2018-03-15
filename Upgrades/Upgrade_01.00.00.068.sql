INSERT INTO #Description VALUES('Update stored m136_UpdateFavoriteSortOrder to m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolder')
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolder]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder]
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId
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

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT,
	@IsFoldersOperation BIT,
	@ChangedFavoriteItems AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN
	IF(@IsFoldersOperation = 1)
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