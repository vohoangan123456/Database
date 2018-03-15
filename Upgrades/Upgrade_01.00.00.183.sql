INSERT INTO #Description VALUES('Add some scripts to support store flow charts as json and also load existing flow charts')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'JsonImageContent' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_tblBlob'))
BEGIN
    ALTER TABLE m136_tblBlob ADD JsonImageContent NVARCHAR(MAX) NULL
END
GO

IF OBJECT_ID('[dbo].[m136_be_InsertImage]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertImage]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_InsertImage] 
	@RelationTypeId	INT,
	@strName VARCHAR(300),
	@strDescription VARCHAR(800),
	@iSize INT,
	@strFileName VARCHAR(200),
	@strContentType VARCHAR(100),
	@strExtension VARCHAR(100),
	@ImgContent [image],
    @JsonImageContent NVARCHAR(MAX),
	@iHeight INT,
	@iWidth INT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MaxId INT, @iItemId INT;
	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 
	SET @iItemId = (@MaxId + 1);
	
	SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    
    INSERT INTO
        [dbo].m136_tblBlob
            (iItemId, iInformationTypeId, strName, strDescription, iSize, strFileName, strContentType, strExtension, imgContent, JsonImageContent, bInUse, dtmRegistered, iWidth, iHeight)
        VALUES
            (@iItemId, @RelationTypeId, @strName, @strDescription, @iSize, @strFileName, @strContentType, @strExtension, @ImgContent, @JsonImageContent, 1, GETDATE(), @iWidth, @iHeight);
        
	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @iItemId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetChartJsonContent]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChartJsonContent]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetChartJsonContent] 
	@ItemId INT
AS
BEGIN
    SELECT
        JsonImageContent
    FROM
        m136_tblBlob
    WHERE
        iItemId = @ItemId
END
GO