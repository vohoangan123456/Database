INSERT INTO #Description VALUES ('Folder information - Add creation information')
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
    SELECT
        h.strName as FolderName,
		h.iParentHandbookId as ParentId,
		dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
		h.iLevel as Level,
		h.iViewTypeId as ViewType,
		h.iLevelType as LevelType,
		h.iDepartmentId as DepartmentId,
		h.strDescription,
		[dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
		RTRIM(ISNULL(e.strFirstName,'') + ' ' + ISNULL(e.strLastName,'')) AS FullNameCreatedBy,
		h.dtmCreated
    FROM
        m136_tblHandbook h
        LEFT JOIN dbo.tblEmployee e ON h.iCreatedById = e.iEmployeeId
	WHERE
        h.iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
    SELECT
        d.iDocumentId as Id,
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
        dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
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
        d.iHandbookId AS VirtualHandbookId,
        d.iReadCount AS ReadCount
    FROM
        m136_tblDocument d
            LEFT JOIN m136_tblHandbook h 
                ON h.iHandbookId = d.iHandbookId
    WHERE
        d.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1 AND d.iDeleted = 0
	UNION
    SELECT
        v.iDocumentId as Id,
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
        dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
        [dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        d.iApproved,
        dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
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
        v.iHandbookId AS VirtualHandbookId,
        d.iReadCount AS ReadCount
    FROM
        m136_relVirtualRelation v
            INNER JOIN m136_tblDocument d 
                ON d.iDocumentId = v.iDocumentId
            INNER JOIN m136_tblHandbook h
                ON d.iHandbookId = h.iHandbookId
    WHERE
        v.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1 AND d.iDeleted = 0 and d.iApproved != 4
	UNION
    SELECT	
        h.iHandbookId as Id,
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
        dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
        0 as HasAttachment,
        NULL as iApproved,
        NULL AS bCanBeApproved,
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
        h.iHandbookId AS VirtualHandbookId,
        0 AS ReadCount
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iHandbookId > 0
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
    SELECT	
        h.iHandbookId AS Id,
        h.strName as FolderName,
        h.iParentHandbookId as ParentId,
        dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
        h.iLevel as Level,
        h.iViewTypeId as ViewType,
        h.iLevelType as LevelType,
        h.iDepartmentId as DepartmentId,
        h.strDescription,
        RTRIM(ISNULL(e.strFirstName,'') + ' ' + ISNULL(e.strLastName,'')) AS FullNameCreatedBy,
		h.dtmCreated
    FROM
        m136_tblHandbook h
        LEFT JOIN dbo.tblEmployee e ON h.iCreatedById = e.iEmployeeId
    WHERE
        h.iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
    SELECT
        d.iDocumentId as Id,
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
        d.iHandbookId AS VirtualHandbookId,
        d.iInternetDoc
    FROM
        m136_tblDocument d
            LEFT JOIN m136_tblHandbook h 
                ON h.iHandbookId = d.iHandbookId
    WHERE
        d.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
	UNION
    SELECT
        v.iDocumentId as Id,
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
        v.iHandbookId AS VirtualHandbookId,
        d.iInternetDoc
    FROM
        m136_relVirtualRelation v
            INNER JOIN m136_tblDocument d 
                ON d.iDocumentId = v.iDocumentId
            INNER JOIN m136_tblHandbook h
                ON d.iHandbookId = h.iHandbookId
    WHERE
        v.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
	UNION
    SELECT
        h.iHandbookId as Id,
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
        h.iHandbookId AS VirtualHandbookId,
        0 AS iInternetDoc
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, strName;
END
