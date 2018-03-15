INSERT INTO #Description VALUES('Create procedure [dbo].[m136_DeleteExportJobs]')
GO

IF OBJECT_ID('[dbo].[m136_DeleteExportJobs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_DeleteExportJobs] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_DeleteExportJobs]
	@Minutes INT
AS
BEGIN

	DECLARE @Table TABLE (Col VARCHAR(1000));
	DECLARE @SomeHoursAgo DATETIME = DATEADD(MINUTE, -@Minutes, GETDATE());
	
	INSERT INTO @Table (Col) SELECT FilePath 
		FROM dbo.m136_ExportJob WHERE ProcessStatus = 2 AND @SomeHoursAgo >= CreatedDate;
		
	DELETE dbo.m136_ExportJob WHERE ProcessStatus = 2 AND @SomeHoursAgo >= CreatedDate;
	
	SELECT Col AS [FileName] FROM @Table;
END
GO
