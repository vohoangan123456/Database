INSERT INTO #Description VALUES('Modify procedures m136_be_GetNewsById, m136_be_GetNewsForStartpage')
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
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @CategoryId AS INT
AS
BEGIN
	DECLARE @today Datetime;
    
	SET @Today = GETDATE();
	
    SELECT TOP 3
        i.iInfoId,
        i.strTopic,
        i.strTitle,
        i.strIngress,
        i.strBody,
        i.dtmCreated
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
END
GO

IF OBJECT_ID('[dbo].[m123_be_DeleteNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_DeleteNews] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m123_be_DeleteNews]
    @NewsIds AS [dbo].[Item] READONLY
AS
BEGIN
    DELETE FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT Id FROM @NewsIds);

    DELETE FROM
        m136_tblBlob
    WHERE
        iItemId IN (SELECT DISTINCT iEntityId FROM m123_relInfo WHERE iInfoId IN (SELECT Id From @NewsIds));
        
    DELETE FROM
        m123_relInfo
    WHERE
        iInfoId IN (SELECT Id FROM @NewsIds);

    DELETE FROM
        m123_relInfoCategory
    WHERE
        iInfoId IN (SELECT Id FROM @NewsIds);

	DELETE FROM
        m123_tblInfo
    WHERE
        iInfoId IN (SELECT Id FROM @NewsIds);
END
GO