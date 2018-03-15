INSERT INTO #Description VALUES('Add sql scripts to support features news/news category')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects 
WHERE object_id = OBJECT_ID(N'[dbo].[m123_tblNewsMedia]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[m123_tblNewsMedia]
	(
		Id INT NOT NULL IDENTITY(1, 1),
		InfoId INT NOT NULL,
		Name NVARCHAR(250) NOT NULL,
		MimeType NVARCHAR(50) NOT NULL,
		Value VARCHAR(MAX) NOT NULL
		CONSTRAINT [PK_InfoNewsMedia] PRIMARY KEY CLUSTERED 
		(
			[Id] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
	) ON [PRIMARY]
    
    ALTER TABLE [dbo].[m123_tblNewsMedia] WITH CHECK ADD CONSTRAINT [FK_NewsMedia_Info] FOREIGN KEY ([InfoId])
    REFERENCES [dbo].[m123_tblInfo]([iInfoId])
END
GO

IF OBJECT_ID('[dbo].[m123_be_GetNewsCategoryById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsCategoryById] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_GetNewsCategoryById
    @CategoryId INT
AS
BEGIN
    SELECT
        iCategoryId,
        strName,
        iAccess,
        iShownIn,
        strDescription
    FROM
        m123_tblCategory
    WHERE
        iCategoryId = @CategoryId
END
GO

IF OBJECT_ID('[dbo].[m123_be_GetNewsOfCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsOfCategory] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_GetNewsOfCategory
    @CategoryId INT
AS
BEGIN
    SELECT
        i.iInfoId,
        i.iAuthorId,
        e.strFirstName + ' ' + e.strLastName AS strAuthorName,
        i.strTitle,
        i.dtmPublish,
        i.dtmExpire,
        i.iReadCount,
        i.iDraft
    FROM
        m123_tblInfo i
            INNER JOIN m123_relInfoCategory ic
                ON i.iInfoId = ic.iInfoId
            LEFT JOIN tblEmployee e
				ON i.iAuthorId = e.iEmployeeId
    WHERE
        ic.iCategoryId = @CategoryId
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
        i.iDraft
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

    INSERT INTO
        m123_tblInfo
            (strTitle, strIngress, strBody, dtmPublish, dtmExpire, iAuthorId, iDraft)
        VALUES
            (@Title, @Ingress, @Body, @Publish, @Expire, @AuthorId, @Draft)
            
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
        dtmPublish = @Publish,
        dtmExpire = @Expire,
        iAlterId = @AlterId,
        iDraft = @Draft
    WHERE
        iInfoId = @InfoId
END
GO

IF OBJECT_ID('[dbo].[m123_be_InsertNewsMedia]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_InsertNewsMedia] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_InsertNewsMedia
    @NewsId INT,
    @Name NVARCHAR(250),
    @MimeType NVARCHAR(50),
    @Value VARCHAR(MAX)
AS
BEGIN
    INSERT INTO
        m123_tblNewsMedia
            (InfoId, Name, MimeType, Value)
        VALUES
            (@NewsId, @Name, @MimeType, @Value)
            
    SELECT SCOPE_IDENTITY();
END
GO

IF OBJECT_ID('[dbo].[m123_be_UpdateNewsMedia]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_UpdateNewsMedia] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_UpdateNewsMedia
    @Id INT,
    @Name NVARCHAR(250),
    @MimeType NVARCHAR(50),
    @Value VARCHAR(MAX)
AS
BEGIN
    UPDATE
        m123_tblNewsMedia
    SET
        Name = @Name,
        MimeType = @MimeType,
        Value = @Value
    WHERE
        Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m123_be_AddNewsRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_AddNewsRelatedAttachment] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_AddNewsRelatedAttachment
    @RelationTypeId INT,
    @Name VARCHAR(300),
    @Description VARCHAR(800),
    @Size INT,
    @FileName VARCHAR(200),
    @ContentType VARCHAR(100),
    @Extension VARCHAR(100),
    @ImgContent [image]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaxId INT;
    DECLARE @ItemId INT;
    
    SELECT @MaxId = MAX(iItemId) FROM dbo.m136_tblBlob;
    SET @ItemId = @MaxId + 1;
    
    SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    
    INSERT INTO
        m136_tblBlob
            (iItemId, iInformationTypeId, strName, strDescription, iSize, strFileName, strContentType, strExtension, imgContent, bInUse, dtmRegistered, iWidth, iHeight)
        VALUES
            (@ItemId, @RelationTypeId, @Name, @Description, @Size, @FileName, @ContentType, @Extension, @ImgContent, 1, GETDATE(), 0, 0);
    
    SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @ItemId;
END
GO

IF OBJECT_ID('[dbo].[m123_LinkNewsAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_LinkNewsAttachment] AS SELECT 1')
GO

ALTER PROCEDURE m123_LinkNewsAttachment
    @NewsId INT,
    @ItemId INT,
    @RelationTypeId INT,
    @CategoryId INT
AS
BEGIN
    INSERT INTO
        m123_relInfo
            (iInfoId, iEntityId, iVJustifyId, iHJustifyId, iRelationTypeId, iCategoryId)
        VALUES
            (@NewsId, @ItemId, 0, 0, @RelationTypeId, @CategoryId);
END
GO

IF OBJECT_ID('[dbo].[m123_be_DeleteNewsAttachments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_DeleteNewsAttachments] AS SELECT 1')
GO

ALTER PROCEDURE m123_be_DeleteNewsAttachments
    @ItemIds AS [dbo].[Item] READONLY
AS
BEGIN
    DELETE FROM
        m123_relInfo
    WHERE
        iEntityId IN (SELECT Id FROM @ItemIds)
        
    DELETE FROM
        m136_tblBlob
    WHERE
        iItemId IN (SELECT Id FROM @ItemIds)
END
GO