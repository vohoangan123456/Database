INSERT INTO #Description VALUES('Update stored m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolders')
GO

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT,
	@NewSortOrderFolders AS [dbo].[UpdatedFavoriteItemsTable] READONLY,
	@NewSortOrderDocuments AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN

	UPDATE 
		dbo.m136_tblSubscribe 
	SET 
		iSort = f.iSort
	FROM 
		dbo.m136_tblSubscribe s 
		INNER JOIN @NewSortOrderFolders f
			ON s.iEmployeeId = @iSecurityId AND s.iHandbookId = f.Id
					
	UPDATE 
		dbo.m136_tblSubscriberDocument 
	SET 
		iSort = d.iSort
	FROM 
		dbo.m136_tblSubscriberDocument s 
		INNER JOIN @NewSortOrderDocuments d
			ON s.iEmployeeId = @iSecurityId AND s.iDocumentId = d.Id
END
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
	ORDER BY
		h.strName
END
GO