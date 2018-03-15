INSERT INTO #Description VALUES('Modify SP for print')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: OCT 27, 2015
-- Description: Get documents by handbookId and all documents of sub chapters.
-- Modified on: FEB 16, 2016
-- Modified description: Get iDeleted, dtmCreated, dtmAlter 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			d.iHandbookId AS VirtualHandbookId
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(virt.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			virt.iHandbookId AS VirtualHandbookId			
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	ORDER BY 
		iSort, 
		strName
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO
-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iHandbookId AS VirtualHandbookId
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(virt.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			virt.iHandbookId AS VirtualHandbookId
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	ORDER BY 
		iSort, 
		strName
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetChapterItems]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetChapterItems]
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
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
				strDescription,
				[dbo].[fn136_be_GetChildCount] (@iSecurityId, iHandbookId, @bShowDocumentsInTree) AS iChildCount
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		SELECT	d.iDocumentId as Id,
				d.iEntityId,
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
                d.iInternetDoc,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
				h.iHandbookId AS iParentHandbookId,
				CAST(0 as INT) AS iChildCount,
				d.iDeleted,
				d.dtmCreated,
				d.dtmAlter,
				1 AS IsDocument,
				d.iHandbookId AS VirtualHandbookId
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	v.iDocumentId as Id,
				d.iEntityId,
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
                d.iInternetDoc,
				dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
				h.iHandbookId AS iParentHandbookId,
				CAST(0 as INT) AS iChildCount,
				d.iDeleted,
				d.dtmCreated,
				d.dtmAlter,
				1 AS IsDocument,
				v.iHandbookId AS VirtualHandbookId
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestVersion = 1
	UNION
		SELECT	h.iHandbookId as Id,
				-1 as iEntityId,
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
				h.iSort,
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft,
				NULL as dtmPublish,
				NULL as dtmPublishUntil,
				dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) as iAccess,
				h.iCreatedbyId,
                0 as iInternetDoc,
				NULL as iVersionStatus,
				h.iParentHandbookId,
				[dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
				h.iDeleted,
				NULL AS dtmCreated,
				NULL AS dtmAlter,
				0 AS IsDocument,
				h.iHandbookId AS VirtualHandbookId
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, d.strName;
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems] 
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
AS
SET NOCOUNT ON
BEGIN
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
				d.iEntityId,
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
				h.iParentHandbookId,
				0 AS iChildCount,
                1 AS IsDocument,
				d.iHandbookId AS VirtualHandbookId
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	v.iDocumentId as Id,
				d.iEntityId,
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
				h.iParentHandbookId,
				0 AS iChildCount,
                1 AS IsDocument,
				v.iHandbookId AS VirtualHandbookId
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	h.iHandbookId as Id,
				-1 as iEntityId,
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
				h.iSort,
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft,
				h.iParentHandbookId,
				[dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
                0 AS IsDocument,
				h.iHandbookId AS VirtualHandbookId
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, strName;
END
GO
