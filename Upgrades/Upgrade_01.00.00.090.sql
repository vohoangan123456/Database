INSERT INTO #Description VALUES('Create [dbo].[m136_be_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation] 
	@DocumentId INT = NULL
AS
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy,
			d.iApproved,
			d.iDraft, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDocumentEventLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentEventLog] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentEventLog] 
	@iDocumentId INT,
	@PageSize INT,
	@PageIndex INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT	elog.Id,
			eLog.DocumentId,
			eLog.[Version],
			eLog.EmployeeId,
			eLog.EventType,
			eLog.FirstName,
			eLog.LastName,
			eLog.[Description],
			eLog.EventTime,
			ROW_NUMBER() OVER (ORDER BY elog.EventTime DESC) AS rownumber
	INTO	#Filters	
	FROM	tblEventlog eLog
	WHERE	eLog.DocumentId = @iDocumentId
		
	SELECT	elog.Id,
			eLog.DocumentId,
			eLog.[Version],
			eLog.EmployeeId,
			eLog.EventType,
			eLog.FirstName,
			eLog.LastName,
			eLog.[Description],
			eLog.EventTime
	FROM	#Filters eLog 
	WHERE	(@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
			
	SELECT COUNT(*) FROM #Filters;
			
	DROP TABLE #Filters;
END
GO