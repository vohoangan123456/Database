INSERT INTO #Description VALUES('Support Flowchartimage')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_FlowChart]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_FlowChart](
		[Id] [int] IDENTITY(1,1) NOT NULL,
		[Name] [varchar](300) NOT NULL,
		[Description] [varchar](800) NULL,
		[ContentType] [varchar](100) NOT NULL,
		[Extension] [varchar](10) NOT NULL,
		[ImageContent] [image] NOT NULL,
		[JsonContent] [nvarchar](max) NOT NULL,
		[IsTemplate] [bit] NULL,
		[Deleted] [bit] NULL,
		[CreatedBy] [bit] NULL,
		[DocumentId] [int] NULL,
		[DocumentVersion] [int] NULL,
	PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO


IF OBJECT_ID('[dbo].[m136_GetFlowchartImage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFlowchartImage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetFlowchartImage] 
	@EntityId INT,
	@DocumentId INT,
	@DocumentVersion INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT mfc.Id, 
		mfc.Name AS strFilename, 
		mfc.ContentType AS strContentType, 
		mfc.ImageContent AS imgContent
	FROM dbo.m136_FlowChart mfc
	WHERE mfc.Id = @EntityId 
		AND mfc.DocumentId = @DocumentId 
		AND mfc.DocumentVersion = @DocumentVersion;
END
GO