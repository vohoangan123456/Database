INSERT INTO #Description VALUES('Add new columns and procedures to support feature News Category Management')
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS
              WHERE TABLE_NAME = 'm123_tblCategory' AND COLUMN_NAME = 'iAccess')
BEGIN
    ALTER TABLE m123_tblCategory
        ADD iAccess TINYINT NULL
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS
              WHERE TABLE_NAME = 'm123_tblCategory' AND COLUMN_NAME = 'iShownIn')
BEGIN
    ALTER TABLE m123_tblCategory
        ADD iShownIn TINYINT NULL
END
GO

IF OBJECT_ID('[dbo].[m123_be_GetChildCategoryFromParentCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetChildCategoryFromParentCategory] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_GetChildCategoryFromParentCategory
    @ParentCategoryId INT
AS
BEGIN
    SELECT
        iCategoryId,
        iParentCategoryId,
        strName,
        iShownIn,
        iAccess,
        strDescription
    FROM
        m123_tblCategory
    WHERE
        iParentCategoryId = @ParentCategoryId
END
GO

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS
              WHERE TABLE_NAME = 'm123_tblCategory' AND COLUMN_NAME = 'iAccess')
BEGIN
    ALTER TABLE m123_tblCategory
        ADD iAccess INT NULL
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
    @UserId TINYINT
AS
BEGIN
    INSERT INTO
        m123_tblCategory
            (iParentCategoryId, strName, strDescription, iOwnerId, iAccess, iShownIn)
        VALUES
            (@ParentCategoryId, @Name, @Description, @UserId, @Access, @ShownIn)
            
    SELECT SCOPE_IDENTITY();
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
    @ShownIn TINYINT
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
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteNewsCategories]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteNewsCategories] AS SELECT 1')
GO

ALTER PROCEDURE m136_be_DeleteNewsCategories
    @NewsCategoryIds AS [dbo].[Item] READONLY
AS
BEGIN

    DELETE FROM
        m123_relInfoCategory
    WHERE
        iCategoryId IN (SELECT Id FROM @NewsCategoryIds);
        
    DELETE FROM
        m123_tblCategory
    WHERE
        iCategoryId IN (SELECT Id FROM @NewsCategoryIds);
END
GO