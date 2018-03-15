INSERT INTO #Description VALUES('Implmenet feature show news by sites, update fields dtmCreated and dtmChanged when news is created, changed, seperate procedure GetNewsById into 2 procedures GetActivenewsById and GetNewsById')
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsWithPaging] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT,
	@CategoryId AS INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
	WITH info AS(	
		SELECT
			rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmCreated DESC),
			i.iInfoId,
			i.strTopic,
			i.strTitle,
			i.strIngress,
			i.strBody,
			i.dtmCreated
		FROM 
			dbo.m123_tblInfo i
                INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
		WHERE
			i.iDraft = 0
		AND	i.dtmPublish <= @today
		AND i.dtmExpire >= @today
		AND (ri.iCategoryId = @CategoryId
            OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory 
                                  WHERE iParentCategoryId = @CategoryId AND iShownIn & 2 = 2))
	)
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	FROM 
		info i
	WHERE 
		(@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))
	ORDER BY RowNumber
	
	SELECT
		COUNT(*) AS Total
	FROM 
		dbo.m123_tblInfo i
	INNER JOIN 
			m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
	WHERE
		i.iDraft = 0
        AND	i.dtmPublish <= @today
        AND i.dtmExpire >= @today
        AND (ri.iCategoryId = @CategoryId
            OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory
                                  WHERE iParentCategoryId = @CategoryId AND iShownIn & 2 = 2))
END
GO

IF OBJECT_ID('[dbo].[m123_be_CreateNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_CreateNews] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_CreateNews
    @CategoryId INT,
    @Title VARCHAR(300),
    @Ingress VARCHAR(800),
    @Body TEXT,
    @Publish DATETIME,
    @Expire DATETIME,
    @AuthorId INT,
    @Draft INT
AS
BEGIN
    DECLARE @InfoId INT;
    DECLARE @Now DATETIME = GETDATE();

    INSERT INTO
        m123_tblInfo
            (strTitle, strIngress, strBody, dtmCreated, dtmChanged, dtmPublish, dtmExpire, iAuthorId, iDraft)
        VALUES
            (@Title, @Ingress, @Body, @Now, @Now, @Publish, @Expire, @AuthorId, @Draft)
            
    SET @InfoId = SCOPE_IDENTITY();
    
    INSERT INTO
        m123_relInfoCategory
            (iInfoId, iCategoryId)
        VALUES
            (@InfoId, @CategoryId);
            
    SELECT @InfoId
END
GO

IF OBJECT_ID('[dbo].[m123_be_UpdateNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_UpdateNews] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_UpdateNews
    @InfoId INT,
    @Title VARCHAR(300),
    @Ingress VARCHAR(800),
    @Body TEXT,
    @Publish DATETIME,
    @Expire DATETIME,
    @AlterId INT,
    @Draft INT
AS
BEGIN
    UPDATE
        m123_tblInfo
    SET
        strTitle = @Title,
        strIngress = @Ingress,
        strBody = @Body,
        dtmChanged = GETDATE(),
        dtmPublish = @Publish,
        dtmExpire = @Expire,
        iAlterId = @AlterId,
        iDraft = @Draft
    WHERE
        iInfoId = @InfoId
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsById]
	@InfoId INT
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

IF OBJECT_ID('[dbo].[m136_be_GetActiveNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetActiveNewsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetActiveNewsById]
	@InfoId INT
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
        AND i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsById]', 'p') IS NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_GetNewsById]')
GO

IF OBJECT_ID('[dbo].[m136_GetActiveNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetActiveNewsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetActiveNewsById]
	@InfoId INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
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
        AND i.iDraft = 0
        AND	i.dtmPublish <= @today
        AND i.dtmExpire >= @today
	
	
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
                OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory 
                                      WHERE iParentCategoryId = @CategoryId AND iShownIn & 2 = 2) -- news in category with id 2 is shown in backend
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