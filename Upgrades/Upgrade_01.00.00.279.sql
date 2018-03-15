INSERT INTO #Description VALUES ('Created script for upload video.')
GO

IF OBJECT_ID('[dbo].[GetUploads]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUploads] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUploads] 
	@iFolderId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT u.Id, 
		u.iEntityId, 
		u.iFolderId, 
		u.Url, 
		u.Location, 
		u.FileName, 
		u.ContentType, 
		u.iType AS [Type],
		0 AS ChildCount
    FROM dbo.Uploads u
    WHERE (u.iFolderId = @iFolderId OR @iFolderId IS NULL) 
    
    UNION
    
    SELECT uf.iFolderId AS Id, 
		NULL AS iEntityId,
		uf.iParentFolderId AS iFolderId, 
		NULL as Url, 
		uf.Location,
		uf.strName AS FileName,
		NULL AS ContentType,
		NULL  AS [Type],
		dbo.fnGetUploadFoldersChildCount(uf.iFolderId) AS ChildCount
    FROM dbo.UploadFolders uf
    WHERE (uf.iParentFolderId = @iFolderId OR @iFolderId IS NULL)
END
GO