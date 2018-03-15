INSERT INTO #Description VALUES ('Modify procedures m136_GetFileArchiveContents, m136_GetFileContents')
GO

IF OBJECT_ID('[dbo].[m136_GetFileArchiveContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileArchiveContents] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileArchiveContents]
	@ItemId INT
AS
BEGIN
	DECLARE @iRelationTypeId int;
	SELECT @iRelationTypeId = iRelationTypeId FROM dbo.m136_relInfo WHERE iItemId = @ItemId;
	
	IF (@iRelationTypeId = 2)
	BEGIN
		SELECT f.strFilename,
			   b.strContentType,
			   b.imgContent,
               '' as strExtension
		FROM [dbo].tblBlob b
		LEFT OUTER JOIN dbo.tblFile f ON f.iItemId = b.iItemId
		WHERE b.iItemId = @ItemId;
	END
	ELSE
	BEGIN
		SELECT strFilename,
			   strContentType,
			   imgContent,
               strExtension
		FROM [dbo].m136_tblBlob 
		WHERE iItemId = @ItemId;
	END	
END
GO

IF OBJECT_ID('[dbo].[m136_GetFileContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileContents] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId INT
AS
BEGIN

	SELECT strFilename,
		   strContentType,
		   imgContent,
           strExtension
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO