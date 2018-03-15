INSERT INTO #Description VALUES ('Implement PBI [B-13683] PoC - Forms Authentication with Active Directory in Multiple Domains')
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'Ignore'
      AND Object_ID = Object_ID(N'dbo.m136_ExportJob'))
BEGIN
    ALTER TABLE dbo.m136_ExportJob ADD Ignore [BIT] DEFAULT 0;
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'Reason'
      AND Object_ID = Object_ID(N'dbo.m136_ExportJob'))
BEGIN
    ALTER TABLE dbo.m136_ExportJob ADD Reason NVARCHAR(MAX);
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
			  AND (PJ.Ignore = 0 OR PJ.Ignore IS NULL)
END
GO

IF OBJECT_ID('[dbo].[m136_IgnorePrintJobFailed]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_IgnorePrintJobFailed] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_IgnorePrintJobFailed]
	@Id UNIQUEIDENTIFIER,
	@Reason NVARCHAR(MAX)
AS
SET NOCOUNT ON
BEGIN
	UPDATE dbo.m136_ExportJob
		SET Ignore = 1, Reason = @Reason
	WHERE Id = @Id
END
GO
