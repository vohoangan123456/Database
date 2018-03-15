INSERT INTO #Description VALUES('Create table EditorTemplate and some related sql script to load, create, update, delete editor templates.')
GO

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'EditorTemplate'))
BEGIN
    CREATE TABLE [dbo].[EditorTemplate]
    (
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        Title NVARCHAR(200) NOT NULL,
        Description NVARCHAR(2000) NULL,
        Html NVARCHAR(MAX) NULL,
        ImageId INT NOT NULL,
        Deleted BIT DEFAULT 0
    )
END
GO

IF OBJECT_ID('[dbo].[GetAllEditorTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetAllEditorTemplates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetAllEditorTemplates]
AS
BEGIN
	SELECT
        Id, Title, Description, Html, ImageId
    FROM
        EditorTemplate
    WHERE
        Deleted = 0
END
GO

IF OBJECT_ID('[dbo].[CreateEditorTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[CreateEditorTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[CreateEditorTemplate]
    @Title NVARCHAR(200),
    @Description NVARCHAR(2000),
    @Html NVARCHAR(MAX),
    @ImageId INT
AS
BEGIN
	INSERT INTO
        EditorTemplate
            (Title, Description, Html, ImageId)
        VALUES
            (@Title, @Description, @Html, @ImageId)
END
GO

IF OBJECT_ID('[dbo].[UpdateEditorTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[UpdateEditorTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[UpdateEditorTemplate]
    @Id INT,
    @Title NVARCHAR(200),
    @Description NVARCHAR(2000),
    @Html NVARCHAR(MAX),
    @ImageId INT
AS
BEGIN
    UPDATE
        EditorTemplate
    SET
        Title = @Title,
        Description = @Description,
        Html = @Html,
        ImageId = @ImageId
    WHERE
        Id = @Id
END
GO

IF OBJECT_ID('[dbo].[DeleteEditorTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[DeleteEditorTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[DeleteEditorTemplate]
    @Id INT
AS
BEGIN
    UPDATE
        EditorTemplate
    SET
        Deleted = 1
    WHERE
        Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFolderPermissions] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetFolderPermissions] 
	@iFolderId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT iEntityId
		, iPermissionSetId AS iAccessRights
		,[iBit]
		,iSecurityId AS iGroupingId,
		sg.strName AS strGroupName
	FROM [dbo].[tblACL] acl
		LEFT JOIN [dbo].[tblSecGroup] sg ON acl.iSecurityId = sg.iSecGroupId
	WHERE iEntityId = @iFolderId
		AND iApplicationId = 136 -- Handbook module
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462) -- 461: group permission for folder rights, 462: group permissions for document rights
END
GO