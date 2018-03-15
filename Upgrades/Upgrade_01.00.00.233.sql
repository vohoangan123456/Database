INSERT INTO #Description VALUES('Create type MenuPermission, modify existing procedures be_GetChildMenusOf, be_GetMenuById, be_CreateMenu, be_UpdateMenu')
GO

IF TYPE_ID(N'MenuPermission') IS NULL
	EXEC ('CREATE TYPE MenuPermission AS TABLE(Id INT, Type INT)')
GO

IF NOT EXISTS(SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 100 AND iPermissionSetTypeId = 3)
BEGIN
    INSERT INTO tblPermissionSet VALUES (100, 3, 'Department Permissions', 'Permission to a menu item for a department')
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
END
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
        strUrl AS Url
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
    @Permissions AS [dbo].[MenuPermission] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        DECLARE @MenuId INT;
        INSERT INTO
            tblMenu
                (iItemParentId, iMin, iMax, iLevel, iInformationTypeId, strName, strDescription, iSort, strUrl, bNewWindow, iChildCount, iPictureId, iPictureActiveId, iPictureSelectedId)
            VALUES
                (@ParentId, 0, 0, @Level, 7, @Name, '', 0, @Url, 0, 0, 0, 0, 0)
        
        SET @MenuId = SCOPE_IDENTITY();
        
        INSERT INTO tblAcl
        SELECT @MenuId, 99, Id, Type, 0, 1
        FROM
            @Permissions
            
    COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
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
    @Permissions AS [dbo].[MenuPermission] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
        UPDATE
            tblMenu
        SET
            strName = @Name,
            strUrl = @Url
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
END CATCH
END
GO