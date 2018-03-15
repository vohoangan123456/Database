INSERT INTO #Description VALUES('Create stored procedure for security.')
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
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetPermissionsByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPermissionsByUserId] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 07, 2015
-- Description:	Get permissions by userId
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetPermissionsByUserId]
	@iPermissionSetId AS [dbo].[Item] READONLY,
	@iUserId INT,
	@iFolderId INT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT ta.iEntityId, ta.iSecurityId, ta.iPermissionSetId AS iAccessRights, ta.iBit FROM dbo.tblACL ta 
	WHERE ta.iApplicationId = 136 
		AND ta.iPermissionSetId IN (SELECT Id FROM @iPermissionSetId) 
		AND ta.iSecurityId IN (SELECT resg.iSecGroupId FROM dbo.relEmployeeSecGroup resg WHERE resg.iEmployeeId = @iUserId)
		AND (ta.iEntityId = @iFolderId OR @iFolderId IS NULL);
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterItems] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 05, 2015
-- Description:	Get chapter items including folders and documents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetChapterItems]
	@iHandbookId INT = NULL,
	@iSecurityId INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				iLevelType as LevelType,
				iDepartmentId as DepartmentId,
				strDescription
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		SELECT	d.iDocumentId as Id,
				d.iHandbookId,
				d.strName,
				d.iDocumentTypeId,
				d.iVersion as Version,
				h.iLevelType as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path,
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
				d.iApproved,
				d.iDraft,
				d.dtmPublish,
				d.dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
				d.iCreatedbyId,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	v.iDocumentId as Id,
				d.iHandbookId,
				d.strName,
				d.iDocumentTypeId,
				d.iVersion as Version,
				h.iLevelType as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				h.iDepartmentId as DepartmentId,
				1 as Virtual,
				v.iSort,
				h.strName as ParentFolderName,
				dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
				d.iApproved,
				d.iDraft,
				d.dtmPublish,
				d.dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
				d.iCreatedbyId,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	h.iHandbookId as Id,
				h.iHandbookId,
				h.strName,
				-1 as iDocumentTypeId,
				NULL as Version,
				iLevelType as LevelType,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft,
				NULL as dtmPublish,
				NULL as dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) as iAccess,
				h.iCreatedbyId,
				NULL as iVersionStatus
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetMyWorkingDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMyWorkingDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetMyWorkingDocuments]
	@iSecurityId int = 1,
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
			h.strName as ParentFolderName,
			d.iApproved,
			d.iDraft,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus
        INTO #Filters
        FROM dbo.m136_tblDocument d 
        LEFT JOIN dbo.m136_tblHandbook h on d.iHandbookId = h.iHandbookId
       	WHERE
			d.iDeleted = 0
			AND (d.iApproved not in (1, 3, 4))
            AND not (d.iApproved = 0 and d.iDraft = 0)
			AND d.iCreatedById = @ISecurityId
			AND d.iLatestVersion = 1;
			
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
			d.ParentFolderName,
			NULL AS Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetOtherWorkingDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetOtherWorkingDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 15, 2015
-- Description:	Get other working documents that are not manage by user logedin.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetOtherWorkingDocuments]
	@iSecurityId int = 1,
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
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			d.iCreatedById,
			h.iDepartmentId,
			d.iSort,
			h.strName as ParentFolderName,
			d.iApproved,
			d.iDraft,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus
        INTO #Filters
        FROM dbo.m136_tblDocument d 
        LEFT JOIN dbo.m136_tblHandbook h on d.iHandbookId = h.iHandbookId
       	WHERE
       		d.iDeleted = 0
			AND d.iApproved NOT IN (1, 4)
		    AND d.iVersion = 0
		    AND d.iDraft = 1
		    AND d.iDeleted = 0
		    AND d.iCreatedById <> @ISecurityId
		    AND d.iLatestVersion = 1;
			
        SELECT  d.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
				d.iVersion as Version,
				d.LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				d.iDepartmentId as DepartmentId,
				0 as Virtual,
				d.iSort,
				d.ParentFolderName,
				NULL as Path,
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
				d.iApproved,
				d.iDraft,
				d.dtmPublish,
				d.dtmPublishUntil,
				d.iAccess,
				d.iCreatedbyId,
				d.iVersionStatus
            FROM #Filters d 
            WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
                
            SELECT COUNT(*) FROM #Filters;
                
            DROP TABLE #Filters;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetSoonToExpiredDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSoonToExpiredDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 16, 2015
-- Description:	Get documents that were expired or to be expiring.
-- =============================================
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
			h.strName as ParentFolderName,
			NULL AS [Path],
			d.iApproved,
			d.iDraft,
			row_number() OVER (ORDER BY d.dtmCreated DESC) AS rownumber,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus
        INTO #Filters
        FROM dbo.m136_tblDocument d 
        LEFT JOIN dbo.m136_tblHandbook h on d.iHandbookId = h.iHandbookId
       	WHERE
			d.iDeleted = 0
		    AND d.iApproved = 1
		    AND d.iLatestVersion = 1
		    AND DATEDIFF(d, GETDATE(), d.dtmPublishUntil) < @ExpireLimit;
			
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
			d.ParentFolderName,
			d.[Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
			d.iApproved,
			d.dtmPublishUntil,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iAccess,
			d.iCreatedbyId,
			d.iVersionStatus
		FROM #Filters d 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
			
	
	SELECT COUNT(*) FROM #Filters;
			
	DROP TABLE #Filters;
END
GO