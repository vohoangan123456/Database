INSERT INTO #Description VALUES('m136_GetFileOrImageContents')
GO

IF OBJECT_ID('[dbo].[m136_GetFileOrImageContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileOrImageContents] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileOrImageContents]
	@ItemId INT,
	@Thumbnail BIT
AS
BEGIN
	SELECT
		CASE i.iInformationTypeId
			WHEN 5 THEN 0
			ELSE 1
		END as isFile,
		CASE i.iInformationTypeId
			WHEN 5 THEN 
					CASE @Thumbnail
						WHEN 1 THEN im.strThumbURL
						ELSE im.strPictureURL
					END
			ELSE f.strFileName
		END AS strFileName,
		b.strContentType,
		b.imgContent
	FROM 
		tblItem i 
	LEFT OUTER JOIN tblFile f 
		ON f.iItemId = i.iItemId
	LEFT OUTER JOIN tblImage im 
		ON im.iItemId = i.iItemId 
	INNER JOIN tblBlob b 
		ON b.iItemId = i.iItemId 
		AND (
				(i.iInformationTypeId = 2 AND b.iType = 20)
				OR
				(@Thumbnail = 1 AND b.iType = 51)
				OR
				(@Thumbnail = 0 AND b.iType = 50)
			)
	WHERE 
		i.iItemId = @ItemId
END
GO