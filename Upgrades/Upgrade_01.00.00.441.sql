INSERT INTO #Description VALUES ('Modify Sp for save search filters')
GO

IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'dbo.UserSavedSearches') 
         AND name = 'EmployeeId'
)
 BEGIN
	ALTER TABLE dbo.UserSavedSearches
	ADD EmployeeId INT
 END
 GO

IF OBJECT_ID('[dbo].[InsertUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[InsertUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[InsertUserSavedSearches] 
	@SearchFilterType INT,
	@Name NVARCHAR(100),
	@SearchFilters NVARCHAR(MAX),
	@EmployeeId INT
AS
BEGIN
	DECLARE @SortTemp INT 
	
	SELECT @SortTemp = MAX(Sort) FROM [dbo].[UserSavedSearches] WHERE SearchFilterType = @SearchFilterType AND EmployeeId = @EmployeeId
	
	DECLARE @Sort INT = ISNULL(@SortTemp, 0) + 1;
	
	INSERT INTO [dbo].[UserSavedSearches]
		(SearchFilterType, Name, SearchFilters, Sort, EmployeeId)
		VALUES(@SearchFilterType,@Name,@SearchFilters,@Sort, @EmployeeId)
END
GO
 
IF OBJECT_ID('[dbo].[UpdateUserSavedSearchesByName]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[UpdateUserSavedSearchesByName] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[UpdateUserSavedSearchesByName] 
	@SearchFilterType INT,
	@Name NVARCHAR(100),
	@SearchFilters NVARCHAR(MAX),
	@EmployeeId INT
AS
BEGIN
	UPDATE [dbo].[UserSavedSearches]
		SET SearchFilters = @SearchFilters
	WHERE Name = @Name AND SearchFilterType = @SearchFilterType
		  AND EmployeeId = @EmployeeId
END
GO

IF OBJECT_ID('[dbo].[GetUserSavedSearchesByName]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserSavedSearchesByName] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUserSavedSearchesByName] 
	@Id INT = NULL,
	@Name NVARCHAR(100),
	@SearchFilterType INT,
	@EmployeeId INT
AS
BEGIN
	SELECT  
		Id,
		SearchFilterType,
		Name,
		SearchFilters,
		Sort,
		EmployeeId 
	FROM [dbo].[UserSavedSearches]
	WHERE Name = @Name AND (@Id IS NULL OR Id <> @Id) AND SearchFilterType = @SearchFilterType AND EmployeeId = @EmployeeId
END
GO

IF OBJECT_ID('[dbo].[GetUserSavedSearches]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserSavedSearches] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUserSavedSearches] 
	@SearchFilterType INT,
	@EmployeeId INT
AS
BEGIN

	SELECT  
		Id,
        SearchFilterType,
        Name,
        SearchFilters,
        Sort,
        EmployeeId 
	FROM [dbo].[UserSavedSearches]
	WHERE SearchFilterType = @SearchFilterType AND EmployeeId = @EmployeeId
	ORDER BY Sort
END
GO