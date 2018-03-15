INSERT INTO #Description VALUES('Modify procedures m136_be_GetNewsForStartpage, m136_be_GetNewsById')
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @CategoryId AS INT
AS
BEGIN
	DECLARE @today Datetime;
    DECLARE @NewsIdTable TABLE (iInfoId INT);
    
	SET @Today = GETDATE();
    
	INSERT INTO @NewsIdTable (iInfoId)
    SELECT TOP 3
        i.iInfoId
    FROM 
        dbo.m123_tblInfo i
            INNER JOIN 
                m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
    WHERE
        i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
        AND 
            (
                ri.iCategoryId = @CategoryId
                OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory WHERE iParentCategoryId = @CategoryId)
            )
    ORDER BY i.dtmCreated DESC
    
    SELECT TOP 3
        iInfoId,
        strTopic,
        strTitle,
        strIngress,
        strBody,
        dtmCreated
    FROM
        dbo.m123_tblInfo
    WHERE
        iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
    
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

IF OBJECT_ID('[dbo].[m136_be_GetNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsById]
	@InfoId INT,
    @IsPreview BIT
AS
BEGIN
	DECLARE @Today Datetime;
	SET @Today = GETDATE();
	
	SELECT
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	FROM 
		dbo.m123_tblInfo i
	WHERE
		i.iInfoId  = @InfoId
        AND
            (
                @IsPreview = 1
                OR 
                    (
                        i.iDraft = 0
                        AND	i.dtmPublish <= @Today
                        AND i.dtmExpire >= @Today
                    )
            )
            
    SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId = @InfoId
    
    SELECT b.iItemId,
        b.strName,
        b.strExtension,
        b.strDescription
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
        i.iInfoId = @InfoId
    ORDER BY b.strName
END
GO