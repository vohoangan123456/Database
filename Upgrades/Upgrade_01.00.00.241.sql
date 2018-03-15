INSERT INTO #Description VALUES('Modify procedures m136_be_GetNewsForStartpage, m136_GetNewsForStartpage')
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @CategoryId AS INT
AS
BEGIN
	DECLARE @Today Datetime;
    DECLARE @NewsIdTable TABLE (iInfoId INT);
    
	SET @Today = GETDATE();
    
	INSERT INTO @NewsIdTable (iInfoId)
    SELECT TOP 3
        i.iInfoId
    FROM 
        dbo.m123_tblInfo i
            INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
    WHERE
        i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
        AND 
        (
            (ri.iCategoryId = @CategoryId AND c.iShownIn & 2 = 2)
            OR ri.iCategoryId IN (
                                 SELECT iCategoryId
                                 FROM m123_tblCategory
                                 WHERE iParentCategoryId = @CategoryId AND iShownIn & 2 = 2)
        )
    ORDER BY i.dtmPublish DESC
    
    SELECT TOP 3
        iInfoId,
        strTopic,
        strTitle,
        strIngress,
        strBody,
        dtmPublish
    FROM
        dbo.m123_tblInfo
    WHERE
        iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
    ORDER BY dtmPublish DESC
    
    SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT iInfoId FROM @NewsIdTable)
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetNewsForStartpage]
	@CategoryId AS INT
AS
BEGIN
	DECLARE @Today DATETIME;
	DECLARE @NewsIdTable TABLE (iInfoId INT);
    
	SET @Today = GETDATE();
    
	INSERT INTO @NewsIdTable (iInfoId)
    SELECT TOP 3
        i.iInfoId
    FROM 
        dbo.m123_tblInfo i
            INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
    WHERE
        i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
        AND 
        (
            (ri.iCategoryId = @CategoryId AND c.iShownIn & 1 = 1)
            OR ri.iCategoryId IN (
                                 SELECT iCategoryId 
                                 FROM m123_tblCategory 
                                 WHERE iParentCategoryId = @CategoryId AND iShownIn & 1 = 1)
        )
    ORDER BY i.dtmPublish DESC;

	SELECT TOP 3
		iInfoId,
		strTopic,
		strTitle,
		strIngress,
		strBody,
		dtmPublish
	FROM 
		dbo.m123_tblInfo
	WHERE
        iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
	ORDER BY dtmPublish DESC;
	
    SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT iInfoId FROM @NewsIdTable)
END
GO