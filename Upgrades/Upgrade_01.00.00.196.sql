INSERT INTO #Description VALUES('Create some procedures to support feature Menu Management.')
GO

IF OBJECT_ID('[dbo].[be_GetChildMenusOf]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetChildMenusOf] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetChildMenusOf]	
    @ItemId INT
AS
BEGIN
	SELECT
        iItemId,
        strName,
        strUrl
    FROM
        tblMenu
    WHERE
        iItemParentId = @ItemId
END
GO

IF OBJECT_ID('[dbo].[be_GetMenuById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetMenuById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetMenuById]
    @ItemId INT
AS
BEGIN
    SELECT
        iItemId,
        strName,
        strUrl
    FROM
        tblMenu
    WHERE
        iItemId = @ItemId
END
GO

IF OBJECT_ID('[dbo].[be_GetMenuPermissionById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetMenuPermissionById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetMenuPermissionById]
    @ItemId INT
AS
BEGIN
    SELECT
        iEntityId,
        iPermissionSetId AS iAccessRights,
        iBit,
        iSecurityId AS iGroupingId,
        sg.strName as strGroupName
    FROM
        tblAcl acl
            LEFT JOIN tblSecGroup sg ON acl.iSecurityId = sg.iSecGroupId
    WHERE
        iEntityId = @ItemId
        AND iApplicationId = 99
        AND iPermissionSetId = 99
END
GO

IF OBJECT_ID('[dbo].[be_CreateMenu]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_CreateMenu] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_CreateMenu]
    @ParentItemId INT,
    @Level INT,
    @Name VARCHAR(50),
    @Url VARCHAR(300)
AS
BEGIN
    INSERT INTO
        tblMenu
            (iItemParentId, iMin, iMax, iLevel, iInformationTypeId, strName, strDescription, iSort, strUrl, bNewWindow, iChildCount, iPictureId, iPictureActiveId, iPictureSelectedId)
        VALUES
            (@ParentItemId, 0, 0, @Level, 7, @Name, '', 0, @Url, 0, 0, 0, 0, 0)
            
    SELECT SCOPE_IDENTITY();
END
GO

IF OBJECT_ID('[dbo].[be_UpdateMenu]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateMenu] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_UpdateMenu]
    @ItemId INT,
    @Name VARCHAR(50),
    @Url VARCHAR(300)
AS
BEGIN
    UPDATE
        tblMenu
    SET
        strName = @Name,
        strUrl = @Url
    WHERE
        iItemId = @ItemId
END
GO

IF OBJECT_ID('[dbo].[be_DeleteMenus]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_DeleteMenus] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_DeleteMenus]
    @ItemIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION
        
        DECLARE @DeletedMenuIds TABLE(iItemId INT);
        
        WITH MenuIds AS
        (
            SELECT iItemId
            FROM tblMenu
            WHERE iItemParentId IN (SELECT Id FROM @ItemIds)
            
            UNION ALL
            
            SELECT m.iItemId
            FROM tblMenu m
            INNER JOIN MenuIds ON m.iItemParentId = MenuIds.iItemId
        )
        INSERT INTO @DeletedMenuIds
        SELECT iItemId
        FROM MenuIds
        
        DELETE FROM tblMenu
        WHERE
            iItemId IN (SELECT iItemId FROM @DeletedMenuIds)
            OR iItemId IN (SELECT Id FROM @ItemIds)
            
        DELETE FROM tblAcl
        WHERE
            iApplicationId = 99
            AND iPermissionSetId = 99
            AND (
                iEntityId IN (SELECT iItemId FROM @DeletedMenuIds)
                OR iEntityId IN (SELECT Id FROM @ItemIds))
            
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
	ROLLBACK
END CATCH
END
GO