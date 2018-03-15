INSERT INTO #Description VALUES ('This is used to support for managing news permissions')
GO

IF TYPE_ID(N'NewsCategoryPermission') IS NULL
	EXEC ('CREATE TYPE NewsCategoryPermission AS TABLE(Id INT, Type INT)')
GO

IF NOT EXISTS (SELECT 1 FROM tblApplication WHERE iApplicationId = 110)
BEGIN
    INSERT INTO
        tblApplication
            (iApplicationId, strName, strDescription, iMajorVersion, iMinorVersion, iBuildVersion, iActive, iHasAdmin, strAdminIconURL, strAdminEntryPage)
        VALUES
            (110, 'News category', 'New Dashboard security.', 0, 0, 0, 0, 0, '', '')
END
GO

IF NOT EXISTS (SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 110)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (110, 3, 'News category role permission', 'Permission to a news category for a role')
END
GO

IF NOT EXISTS (SELECT 1 FROM tblPermissionSet WHERE iPermissionSetId = 111)
BEGIN
    INSERT INTO
        tblPermissionSet
            (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
        VALUES
            (111, 3, 'News category department permission', 'Permission to a news category for a department')
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateNewsCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateNewsCategory] AS SELECT 1')
GO

ALTER PROCEDURE m136_be_CreateNewsCategory
    @ParentCategoryId INT,
    @Name VARCHAR(100),
    @Description VARCHAR(1000),
    @Access TINYINT,
    @ShownIn TINYINT,
    @UserId INT,
    @Permissions AS [dbo].[NewsCategoryPermission] READONLY
AS
BEGIN
    DECLARE @NewsCategoryId INT;

    INSERT INTO
        m123_tblCategory
            (iParentCategoryId, strName, strDescription, iPublishLocation, iOwnerId, iAccess, iShownIn)
        VALUES
            (@ParentCategoryId, @Name, @Description, 0, @UserId, @Access, @ShownIn)
            
    SET @NewsCategoryId = SCOPE_IDENTITY();
    
    INSERT INTO tblAcl
    SELECT @NewsCategoryId, 110, Id, Type, 0, 1
    FROM @Permissions
    
    SELECT @NewsCategoryId;
END
GO

IF OBJECT_ID('[dbo].[m123_be_EditNewsCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_EditNewsCategory] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_EditNewsCategory
    @ParentCategoryId INT,
    @NewsCategoryId INT,
    @Name VARCHAR(100),
    @Description VARCHAR(1000),
    @Access TINYINT,
    @ShownIn TINYINT,
    @Permissions AS [dbo].[NewsCategoryPermission] READONLY
AS
BEGIN
    UPDATE
        m123_tblCategory
    SET
        strName = @Name,
        strDescription = @Description,
        iAccess = @Access,
        iShownIn = @ShownIn
    WHERE
        iCategoryId = @NewsCategoryId
        AND iParentCategoryId = @ParentCategoryId
    
    DELETE FROM tblAcl
    WHERE iEntityId = @NewsCategoryId
        AND iApplicationId = 110
        
    INSERT INTO tblAcl
    SELECT @NewsCategoryId, 110, Id, Type, 0, 1
    FROM @Permissions
END
GO

IF OBJECT_ID('[dbo].[m123_be_GetNewsCategoryById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsCategoryById] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_GetNewsCategoryById
    @CategoryId INT
AS
BEGIN
    SELECT
        iCategoryId,
        strName,
        iAccess,
        iShownIn,
        strDescription
    FROM
        m123_tblCategory
    WHERE
        iCategoryId = @CategoryId
        
    SELECT
        iSecurityId AS Id,
        iPermissionSetId AS Type,
        CASE iPermissionSetId
            WHEN 110 THEN (SELECT TOP 1 strName FROM tblSecGroup WHERE iSecGroupId = iSecurityId)
            WHEN 111 THEN (SELECT TOP 1 strName FROM tblDepartment WHERE iDepartmentId = iSecurityId)
        END Name
    FROM
        tblAcl
    WHERE
        iEntityId = @CategoryId
        AND iApplicationId = 110
    ORDER BY Type, Name
END
GO