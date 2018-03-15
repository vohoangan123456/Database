INSERT INTO #Description VALUES('Create procedure m123_GetDeviationNewsForStartpage to get news for deviation')
GO

IF OBJECT_ID('[dbo].[m123_GetDeviationNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_GetDeviationNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m123_GetDeviationNewsForStartpage]
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
            (ri.iCategoryId = @CategoryId AND c.iShownIn & 4 = 4)
            OR ri.iCategoryId IN (
                                 SELECT iCategoryId 
                                 FROM m123_tblCategory 
                                 WHERE iParentCategoryId = @CategoryId AND iShownIn & 4 = 4)
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