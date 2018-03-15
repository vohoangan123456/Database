INSERT INTO #Description VALUES ('Modify procedures be_GetMenuById, be_CreateMenu, be_UpdateMenu')
GO

IF OBJECT_ID('[dbo].[be_GetMenuById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetMenuById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetMenuById]
    @Id INT
AS
BEGIN
    SELECT
        iItemId AS Id,
        strName AS Name,
        strUrl AS Url,
        bNewWindow AS OpenInNewWindow
    FROM
        tblMenu
    WHERE
        iItemId = @Id
        
    SELECT
        iSecurityId AS Id,
        iPermissionSetId AS Type,
        CASE iPermissionSetId
            WHEN 99 THEN (SELECT TOP 1 strName FROM tblSecGroup WHERE iSecGroupId = iSecurityId)
            WHEN 100 THEN (SELECT TOP 1 strName FROM tblDepartment WHERE iDepartmentId = iSecurityId)
        END Name
    FROM
        tblAcl
    WHERE
        iEntityId = @Id
        AND iApplicationId = 99
    ORDER BY Type, Name
END
GO

IF OBJECT_ID('[dbo].[be_CreateMenu]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_CreateMenu] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_CreateMenu]
    @ParentId INT,
    @Level INT,
    @Name VARCHAR(50),
    @Url VARCHAR(300),
    @OpenInNewWindow BIT,
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
                (@ParentId, 0, 0, @Level, 7, @Name, '', @SortOrder, @Url, @OpenInNewWindow, 0, 0, 0, 0)
        
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

IF OBJECT_ID('[dbo].[be_UpdateMenu]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateMenu] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_UpdateMenu]
    @Id INT,
    @Name VARCHAR(50),
    @Url VARCHAR(300),
    @OpenInNewWindow BIT,
    @Permissions AS [dbo].[MenuPermission] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        UPDATE
            tblMenu
        SET
            strName = @Name,
            strUrl = @Url,
            bNewWindow = @OpenInNewWindow
        WHERE
            iItemId = @Id
            
        DELETE FROM tblAcl
        WHERE iEntityId = @Id
            AND iApplicationId = 99
            
        INSERT INTO tblAcl
        SELECT @Id, 99, Id, Type, 0, 1
        FROM @Permissions
        
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