INSERT INTO #Description VALUES ('Update upload news image.')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'bIngress' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m123_tblInfo'))
BEGIN
    ALTER TABLE m123_tblInfo ADD bIngress BIT NOT NULL DEFAULT(0)
END 
GO

IF EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'bIngress' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m123_tblInfo'))
BEGIN
	UPDATE i
	SET		i.bIngress = 1
	FROM dbo.m123_tblInfo i
	JOIN dbo.m123_tblNewsMedia m ON i.iInfoId = m.InfoId
END 
GO

IF OBJECT_ID('[dbo].[m123_be_CreateNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_CreateNews] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_CreateNews]  
    @CategoryId INT,  
    @Title VARCHAR(300),  
    @Ingress VARCHAR(800),  
    @Body TEXT,  
    @Publish DATETIME,  
    @Expire DATETIME,  
    @AuthorId INT,  
    @Draft INT,
	@BIngress BIT  
AS  
BEGIN  
    DECLARE @InfoId INT;  
    DECLARE @Now DATETIME = GETDATE();  
    INSERT INTO  
        m123_tblInfo  
            (strTitle, strIngress, strBody, dtmCreated, dtmChanged, dtmPublish, dtmExpire, iAuthorId, iDraft, bIngress)  
        VALUES  
            (@Title, @Ingress, @Body, @Now, @Now, @Publish, @Expire, @AuthorId, @Draft, @BIngress)  
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
ALTER PROCEDURE [dbo].[m123_be_UpdateNews]  
    @InfoId INT,  
    @Title VARCHAR(300),  
    @Ingress VARCHAR(800),  
    @Body TEXT,  
    @Publish DATETIME,  
    @Expire DATETIME,  
    @AlterId INT,  
    @Draft INT,
	@BIngress BIT    
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
        iDraft = @Draft,
        bIngress = @BIngress
    WHERE  
        iInfoId = @InfoId  
END

GO
IF OBJECT_ID('[dbo].[m123_be_GetNewsDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_GetNewsDetailsById]
	@InfoId INT
AS
BEGIN
	SELECT
		i.iInfoId,
        ic.iCategoryId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
        i.dtmPublish,
        i.dtmExpire,
        i.iDraft,
        i.bIngress
	FROM 
		dbo.m123_tblInfo i
            INNER JOIN dbo.m123_relInfoCategory ic
                ON i.iInfoId = ic.iInfoId
	WHERE
		i.iInfoId  = @InfoId
    SELECT TOP 1
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId = @InfoId
    SELECT
        b.iItemId,
        b.strName,
        b.strExtension
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
        i.iInfoId = @InfoId
END

GO
IF OBJECT_ID('[dbo].[m123_be_DeleteNewsImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_DeleteNewsImage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_DeleteNewsImage]
    @InfoId INT
AS
BEGIN
    DELETE FROM
        m123_tblNewsMedia
    WHERE
        InfoId = @InfoId
END

GO
IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @UserId INT,
    @CategoryId INT,
	@ShowInModule INT
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
            (ri.iCategoryId = @CategoryId AND c.iShownIn & @ShowInModule = @ShowInModule)
            OR ri.iCategoryId IN (
                                 SELECT iCategoryId
                                 FROM m123_tblCategory
                                 WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule)
        )
        AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
    ORDER BY i.dtmPublish DESC
    SELECT TOP 3
        iInfoId,
        strTopic,
        strTitle,
        strIngress,
        strBody,
        dtmPublish,
        bIngress
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
		dtmPublish,
		bIngress
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


