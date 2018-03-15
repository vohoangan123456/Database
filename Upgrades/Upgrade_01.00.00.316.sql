INSERT INTO #Description VALUES ('Modify procedures m136_be_GetMyWorkingDocuments, m136_be_GetDocumentsAwaitingMyApproval')
GO

IF OBJECT_ID('[dbo].[m136_be_GetMyWorkingDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMyWorkingDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetMyWorkingDocuments]
	@iSecurityId int = 0,
	@PageSize int = 10,
	@PageIndex int = 0
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  d.iDocumentId, 
			d.iEntityId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion,
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
            h.iHandbookId,
			h.strName as ParentFolderName,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			d.iDeleted,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path],
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount
        INTO #Filters
        FROM dbo.m136_tblDocument d 
        LEFT JOIN dbo.m136_tblHandbook h on d.iHandbookId = h.iHandbookId
       	WHERE
			d.iDeleted = 0
			AND (d.iApproved not in (1, 3, 4))
            AND not (d.iApproved = 0 and d.iDraft = 0)
			AND d.iCreatedById = @ISecurityId
			AND d.iLatestVersion = 1
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) & 3) = 3;
			
	SELECT  d.iDocumentId AS Id,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			d.LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
			d.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
            d.iHandbookId,
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount AS ReadCount
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsAwaitingMyApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsAwaitingMyApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentsAwaitingMyApproval] 
	@iSecurityId int = 0,
	@PageSize int = 10,
	@PageIndex int = 0
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  d.iDocumentId, 
			d.iEntityId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion,
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
            h.iHandbookId,
			h.strName as ParentFolderName,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			d.iDeleted,
			dbo.fn136_GetParentPathEx(d.iHandbookId) as [Path],
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount			
		INTO #Filters
		FROM dbo.m136_tblDocument d
			JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
			LEFT JOIN m136_vSentForApproval sfa on sfa.iEntityId = d.iEntityId
		WHERE d.iLatestVersion = 1
			AND sfa.iEmployeeId = @iSecurityId
			AND d.iDraft = 0
			AND d.iApproved = 0
			AND d.iDeleted = 0
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) & 17) = 17;
	SELECT  d.iDocumentId AS Id,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			d.LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
			d.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
            h.iHandbookId,
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount AS ReadCount
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetMyDocumentsSentToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMyDocumentsSentToApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetMyDocumentsSentToApproval] 
	@iSecurityId int = 0,
	@PageSize int = 10,
	@PageIndex int = 0
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  d.iDocumentId, 
			d.iEntityId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion,
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
            h.iHandbookId,
			h.strName AS ParentFolderName,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, GETDATE(), d.iDraft, d.iApproved) iVersionStatus,
			d.iDeleted,
			dbo.fn136_GetParentPathEx(d.iHandbookId) as [Path],
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount
		INTO #Filters
		FROM m136_tblDocument d
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
		WHERE d.iDeleted = 0
			AND d.iLatestVersion = 1 
			AND d.iDraft = 0
			AND d.iApproved = 0
			AND (d.iCreatedById = @iSecurityId OR d.iAlterId = @iSecurityId);  
	SELECT  d.iDocumentId AS Id,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			d.LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
			d.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
            d.iHandbookId,
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount AS ReadCount
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;                                 
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetSoonToExpiredDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSoonToExpiredDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetSoonToExpiredDocuments]
	@iSecurityId INT,
	@ExpireLimit INT,
	@PageSize INT = 10,
	@PageIndex INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SELECT  d.iDocumentId, 
			d.iEntityId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion,
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
            h.iHandbookId,
			h.strName as ParentFolderName,
			d.iApproved,
			d.iDraft,
            d.iInternetDoc,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			d.iDeleted,
			dbo.fn136_GetParentPathEx(d.iHandbookId) as [Path],
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount
        INTO #Filters
        FROM dbo.m136_tblDocument d 
        LEFT JOIN dbo.m136_tblHandbook h on d.iHandbookId = h.iHandbookId
       	WHERE
			d.iDeleted = 0
		    AND d.iApproved = 1
		    AND d.iLatestVersion = 1
		    AND ((dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) & 16) = 16 
		        OR (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) & 4) = 4)
		    AND (d.iApprovedById = @iSecurityId OR d.iCreatedById = @iSecurityId)
		    AND (DATEDIFF(d, GETDATE(), d.dtmPublishUntil) < @ExpireLimit OR d.dtmPublishUntil < GETDATE());
	SELECT  d.iDocumentId AS Id,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion AS Version,
			d.LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
			d.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
            d.iHandbookId,
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.dtmPublishUntil,
			d.iDraft,
            d.iInternetDoc,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iReadCount AS ReadCount
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO