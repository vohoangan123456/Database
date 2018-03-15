INSERT INTO #Description VALUES ('Support auto-expand menu group feature on Frontend.')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
    WHERE [name] = N'bExpanded' AND [object_id] = OBJECT_ID(N'dbo.tblMenu'))
BEGIN
	ALTER TABLE [dbo].[tblMenu]	 
    ADD bExpanded BIT NOT NULL DEFAULT 0
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
        strUrl AS Url,
        bNewWindow AS OpenInNewWindow,
        bExpanded AS Expanded
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
        strUrl AS Url,
        bExpanded AS Expanded
    FROM
        tblMenu
    WHERE
        iItemParentId = @Id
    ORDER BY iSort, strName
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
    @Expanded BIT,
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
                (iItemParentId, iMin, iMax, iLevel, iInformationTypeId, strName, strDescription, iSort, strUrl, bNewWindow, iChildCount, iPictureId, iPictureActiveId, iPictureSelectedId, bExpanded)
            VALUES
                (@ParentId, 0, 0, @Level, 7, @Name, '', @SortOrder, @Url, @OpenInNewWindow, 0, 0, 0, 0, @Expanded)
        
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
    @Expanded BIT,
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
            bNewWindow = @OpenInNewWindow,
            bExpanded = @Expanded
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

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMenuGroups] 
    @UserId INT,
    @MenuId INT
AS
BEGIN
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @CurrentDate DATETIME = GETDATE();
	SELECT iItemId INTO #Groups FROM tblMenu WHERE iItemParentId = @MenuId;
	
    WITH Children AS
	(
			SELECT 
				iItemId, 
				iItemParentId, 
				strName, 
				strDescription,
				iLevel, 
				strURL, 
				dtmDisplay,
				dtmRemove,
				bNewWindow,
                bExpanded,
				iSort
			FROM 
				[dbo].[tblMenu] 
			WHERE
				iItemId IN (SELECT iItemId FROM #Groups) AND
				dbo.fnSecurityGetPermission(99, 99, @UserId, iItemId) & 1 = 1
		UNION ALL
			SELECT 
				m.iItemId, 
				m.iItemParentId, 
				m.strName, 
				m.strDescription,
				m.iLevel, 
				m.strURL, 
				m.dtmDisplay,
				m.dtmRemove,
				m.bNewWindow,
                m.bExpanded,
				m.iSort
			FROM 
				[dbo].[tblMenu] m
                    INNER JOIN Children 
                        ON	m.iItemParentId = Children.iItemId 
            WHERE
                dbo.fnSecurityGetPermission(99, 99, @UserId, m.iItemId) & 1 = 1
	)
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, bExpanded, iSort
	FROM 
		Children
	WHERE @CurrentDate BETWEEN dtmDisplay AND dtmRemove 
			OR (dtmRemove IS NULL AND dtmDisplay IS NULL)
			OR (@CurrentDate> dtmDisplay AND dtmRemove IS NULL)
			OR (dtmDisplay IS NULL AND @CurrentDate < dtmRemove)
	ORDER BY iSort, strName;
	DROP TABLE #Groups;
END
GO