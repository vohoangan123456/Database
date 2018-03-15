INSERT INTO #Description VALUES('Fix template fields ordering')
GO

IF OBJECT_ID('[dbo].[m136_be_GetTemplateMetaInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo]
	@TemplateId INT
AS
BEGIN
	SELECT  dti.iDocumentTypeInfoId,
		mir.iMetaInfoTemplateRecordsId, 
		mir.strName,	
		mir.strDescription, 
		mir.iInfoTypeId,
		mir.iFlag,
		it.strName AS infoTypeName, 
		it.strDescription AS infoTypeDescription,
		dti.iDeleted,
		dti.iShowOnPDA,
		dti.iMandatory, 
		dti.iMaximized,
		dti.iSort
	FROM [m136_tblMetaInfoTemplateRecords] mir
		INNER JOIN [m136_relDocumentTypeInfo] dti 
			ON dti.iDocumentTypeId = @TemplateId AND dti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
		LEFT JOIN [m136_tblInfoType] it 
			ON mir.iInfoTypeId = it.iInfoTypeId
	ORDER BY dti.iSort, it.strName;	
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
			AND d.iLatestVersion = 1 AND d.iDeleted = 0
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
			AND d.iLatestVersion = 1 AND d.iDeleted = 0
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