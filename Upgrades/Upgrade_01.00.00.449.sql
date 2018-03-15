INSERT INTO #Description VALUES ('Specify columns in INSERT statement for tblACL table.')
GO

IF OBJECT_ID('[Calendar].[m123_be_EditNewsCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[m123_be_EditNewsCategory] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_EditNewsCategory]
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
    INSERT INTO tblAcl(iEntityId,iApplicationId,iSecurityId,iPermissionSetId,iGroupingId,iBit)
    SELECT @NewsCategoryId, 110, Id, Type, 0, 1
    FROM @Permissions
END
GO


IF EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'dbo.tblDepartment') 
         AND name = 'strName'
)
 BEGIN
	ALTER TABLE dbo.tblDepartment ALTER COLUMN strName VARCHAR(100) NOT NULL
 END
 GO
