INSERT INTO #Description VALUES ('Add and modify some procedure to allow administrator to change menus'' sort order')
GO

IF OBJECT_ID('[dbo].[be_CreateMenu]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_CreateMenu] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_CreateMenu]
    @ParentId INT,
    @Level INT,
    @Name VARCHAR(50),
    @Url VARCHAR(300),
    @Permissions AS [dbo].[MenuPermission] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DECLARE @MenuId INT;
        DECLARE @SortOrder INT;
        
        SELECT @SortOrder = MAX(iSort)
        FROM tblMenu
        WHERE iItemParentId = @ParentId
        
        IF @SortOrder IS NULL
        BEGIN
            SET @SortOrder = 0;
        END
        ELSE
        BEGIN
            SET @SortOrder = @SortOrder + 1;
        END
        
        INSERT INTO
            tblMenu
                (iItemParentId, iMin, iMax, iLevel, iInformationTypeId, strName, strDescription, iSort, strUrl, bNewWindow, iChildCount, iPictureId, iPictureActiveId, iPictureSelectedId)
            VALUES
                (@ParentId, 0, 0, @Level, 7, @Name, '', @SortOrder, @Url, 0, 0, 0, 0, 0)
        
        SET @MenuId = SCOPE_IDENTITY();
        
        INSERT INTO tblAcl
        SELECT @MenuId, 99, Id, Type, 0, 1
        FROM
            @Permissions
            
    COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

IF OBJECT_ID('[dbo].[be_GetChildMenusOf]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetChildMenusOf] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetChildMenusOf]	
    @Id INT
AS
BEGIN
	SELECT
        iItemId AS Id,
        strName AS Name,
        strUrl AS Url
    FROM
        tblMenu
    WHERE
        iItemParentId = @Id
    ORDER BY iSort, strName
END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'MenuSortOrder' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[MenuSortOrder] AS TABLE(
		[Id] [int] NOT NULL,
		[SortOrder] [int] NOT NULL
	)
GO

IF OBJECT_ID('[dbo].[be_UpdateMenusOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateMenusOrder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_UpdateMenusOrder] 
	@MenuSortOrder AS [dbo].[MenuSortOrder] READONLY
AS
BEGIN
    UPDATE
        MenuTable
    SET
        MenuTable.iSort = MenuSortOrder.SortOrder
    FROM
        tblMenu MenuTable
            INNER JOIN @MenuSortOrder MenuSortOrder
                ON MenuTable.iItemId = MenuSortOrder.Id
END
GO