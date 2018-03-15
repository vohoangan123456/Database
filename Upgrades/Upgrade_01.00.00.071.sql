INSERT INTO #Description VALUES('Implement exportjob as background.')
GO

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'm136_ExportJob'))
BEGIN
    CREATE TABLE [dbo].[m136_ExportJob](
	[Id] [uniqueidentifier] NOT NULL,
	[ChapterId] int NULL,
	[UserIdentityId] int NOT NULL,
	[CreatedDate] [datetime] NULL,
	[FilePath] [varchar](1000) NULL,
	[PrintTypeJob] [int] NULL,
	[PrintSubFolder] [bit] NULL,
	[ProcessStatus] [int] NULL,
	[Description] [nvarchar](max) NULL,
	[Method] [varchar](200) NULL,
	[TemplateName] [varchar](1000) NULL,
	CONSTRAINT [PK_PrintJob] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF OBJECT_ID('[dbo].[m136_GetExportJobs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetExportJobs] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetExportJobs] 
	@ProcessStatus INT
AS
BEGIN
	SELECT E.strFirstName + ' ' + E.strLastName AS Fullname, PJ.FilePath AS URL, E.strEmail AS Email, PJ.Method, PJ.TemplateName, PJ.ChapterId, 
		PJ.PrintSubFolder, PJ.Id, PJ.CreatedDate, PJ.UserIdentityId, HB.strName AS ChapterName
	FROM [dbo].[m136_ExportJob] PJ
		INNER JOIN dbo.tblEmployee E ON E.iEmployeeId = PJ.UserIdentityId
		INNER JOIN dbo.m136_tblHandbook HB ON HB.iHandbookId = PJ.ChapterId
		WHERE PJ.ProcessStatus = @ProcessStatus
END
GO

IF OBJECT_ID('[dbo].[m136_UpdateExportJob]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateExportJob] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateExportJob]
	@Id	UNIQUEIDENTIFIER,
	@ProcessStatus INT,
	@FilePath VARCHAR(500)
AS
BEGIN
	UPDATE [dbo].[m136_ExportJob] SET ProcessStatus = @ProcessStatus, FilePath = @FilePath WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m136_InsertExportJob]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertExportJob] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_InsertExportJob]
	@ChapterId INT,
	@UserIdentityId INT,
	@PrintTypeJob INT,
	@PrintSubFolder BIT,
	@Method varchar(200),
	@TemplateName varchar(1000)
AS
BEGIN
	INSERT INTO [dbo].[m136_ExportJob]
	(Id, ChapterId, UserIdentityId, CreatedDate, FilePath, PrintTypeJob, PrintSubFolder, ProcessStatus, [Description], Method, TemplateName)
	VALUES (NEWID(), @ChapterId, @UserIdentityId, GETDATE(), NULL, @PrintTypeJob, @PrintSubFolder, 0, NULL, @Method, @TemplateName)
END
GO