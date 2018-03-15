INSERT INTO #Description VALUES ('Modify SP for Export job')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iTitle' AND Object_ID = Object_ID(N'[dbo].[m136_ExportJob]'))
BEGIN
    ALTER TABLE [dbo].[m136_ExportJob]
	ADD iTitle BIT;
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iDocId' AND Object_ID = Object_ID(N'[dbo].[m136_ExportJob]'))
BEGIN
    ALTER TABLE [dbo].[m136_ExportJob]
	ADD iDocId BIT;
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iVersion' AND Object_ID = Object_ID(N'[dbo].[m136_ExportJob]'))
BEGIN
    ALTER TABLE [dbo].[m136_ExportJob]
	ADD iVersion BIT;
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iDocResponsible' AND Object_ID = Object_ID(N'[dbo].[m136_ExportJob]'))
BEGIN
    ALTER TABLE [dbo].[m136_ExportJob]
	ADD iDocResponsible BIT;
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iApprover' AND Object_ID = Object_ID(N'[dbo].[m136_ExportJob]'))
BEGIN
    ALTER TABLE [dbo].[m136_ExportJob]
	ADD iApprover BIT;
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
	@TemplateName varchar(1000),
	@PrintTitle BIT,
	@PrintDocId BIT,
	@PrintVersion BIT,
	@PrintDocResponsible BIT,
	@PrintApprover BIT
AS
BEGIN
	INSERT INTO [dbo].[m136_ExportJob]
	(Id, ChapterId, UserIdentityId, CreatedDate, FilePath, PrintTypeJob, PrintSubFolder, ProcessStatus,
	 [Description], Method, TemplateName,iTitle,iDocId, iVersion, iDocResponsible,iApprover )
	VALUES (NEWID(), @ChapterId, @UserIdentityId, GETDATE(), NULL, @PrintTypeJob, @PrintSubFolder, 0,
			 NULL, @Method, @TemplateName,@PrintTitle,@PrintDocId,@PrintVersion,@PrintDocResponsible,@PrintApprover)
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
		PJ.PrintSubFolder, PJ.Id, PJ.CreatedDate, PJ.UserIdentityId, HB.strName AS ChapterName,
		PJ.iTitle AS IsDocTitle,
        PJ.iDocId AS IsDocId,
        PJ.iVersion AS IsVersion,
        PJ.iDocResponsible AS IsDocResponsible,
        PJ.iApprover AS IsApprover
	FROM [dbo].[m136_ExportJob] PJ
		INNER JOIN dbo.tblEmployee E ON E.iEmployeeId = PJ.UserIdentityId
		INNER JOIN dbo.m136_tblHandbook HB ON HB.iHandbookId = PJ.ChapterId
		WHERE PJ.ProcessStatus = @ProcessStatus
			  AND (PJ.Ignore = 0 OR PJ.Ignore IS NULL)
END
GO