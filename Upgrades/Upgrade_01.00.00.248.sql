INSERT INTO #Description VALUES('Update Catch section for procedures be_CreateMenu, be_UpdateMenu, be_DeleteMenus')
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
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
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
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO