INSERT INTO #Description VALUES('Update store [dbo].[m136_be_GetDocumentEventLog] and [dbo].[m136_be_GetPreviousVersions] and create store [dbo].[m136_be_GetDocumentInformationByEntityId] ')
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
			eLog.LoginName,
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
			eLog.EventTime,
			eLog.LoginName
	FROM	#Filters eLog 
	WHERE	(@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END

GO

IF OBJECT_ID('[dbo].[m136_be_GetPreviousVersions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPreviousVersions] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_be_GetPreviousVersions]
	@iDocumentId INT,
	@PageSize INT,
	@PageIndex INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  doc.iDocumentId, 
			doc.iEntityId,
			doc.strName,
			doc.iDocumentTypeId,
			doc.iVersion,
			NULL AS LevelType,
			--h.iLevelType AS LevelType,
			doc.dtmApproved,
			doc.strApprovedBy,
			doc.iCreatedById,
			NULL AS iDepartmentId,
			--h.iDepartmentId,
			doc.iSort,
			NULL AS ParentFolderName,
			--h.strName AS ParentFolderName,
			doc.iApproved,
			doc.iDraft,
			doc.iLatestVersion,
			doc.iLatestApproved,
			doc.iReadCount AS ReadCount,
			ROW_NUMBER() OVER (ORDER BY doc.iVersion DESC) AS rownumber
        INTO #Filters
        FROM dbo.m136_tblDocument doc
        --LEFT JOIN dbo.m136_tblHandbook h on doc.iHandbookId = h.iHandbookId 
       	WHERE
			doc.iDeleted = 0
			AND NOT (doc.iApproved = 0 AND doc.iDraft = 0)
			AND doc.iDocumentId = @iDocumentId
	SELECT  doc.iEntityId AS Id,
			doc.strName,
			doc.iDocumentTypeId,
			doc.iVersion AS Version,
			doc.LevelType,
			doc.dtmApproved,
			doc.strApprovedBy,
			dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) AS Responsible,
			doc.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			doc.iSort,
			doc.ParentFolderName,
			NULL AS Path,
			[dbo].[fnHasDocumentAttachment](doc.iEntityId) AS HasAttachment,
			doc.iApproved,
			doc.iDraft,
			doc.iLatestApproved,
			doc.iLatestVersion,
			doc.ReadCount
		FROM #Filters doc 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByEntityId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId] 
	@EntityId INT = NULL
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
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE	d.iEntityId = @EntityId
END
GO
