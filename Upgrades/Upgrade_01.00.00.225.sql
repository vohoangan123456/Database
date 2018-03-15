INSERT INTO #Description VALUES('Modify procedure m136_be_CreateNewsCategory')
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
    @UserId INT
AS
BEGIN
    INSERT INTO
        m123_tblCategory
            (iParentCategoryId, strName, strDescription, iPublishLocation, iOwnerId, iAccess, iShownIn)
        VALUES
            (@ParentCategoryId, @Name, @Description, 0, @UserId, @Access, @ShownIn)
            
    SELECT SCOPE_IDENTITY();
END
GO