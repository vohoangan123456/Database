INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_GetChapterItemsForReadingList].')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItemsForReadingList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItemsForReadingList] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItemsForReadingList]
	@iHandbookId INT = NULL,
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
    DECLARE @Items TABLE
    (
        Id INT,
        iEntityId INT,
        iHandbookId INT,
        strName VARCHAR(200),
        iDocumentTypeId INT,
        Version INT,
        LevelType INT,
        dtmApproved DATETIME,
        strApprovedBy VARCHAR(200),
        Responsible VARCHAR(102),
        DepartmentId INT,
        Virtual BIT,
        iSort INT,
        ParentFolderName VARCHAR(100),
        Path NVARCHAR(4000),
        HasAttachment BIT,
        iApproved INT,
        iDraft INT,
        iParentHandbookId INT,
        iChildCount INT,
        IsDocument BIT,
        dtmPublish DATETIME,
        dtmPublishUntil DATETIME
    );

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
		
    INSERT INTO @Items
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
			d.dtmPublish,
			d.dtmPublishUntil
    FROM	m136_tblDocument d
    LEFT JOIN m136_tblHandbook h 
        ON h.iHandbookId = d.iHandbookId
    WHERE	d.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
        
        
    INSERT INTO @Items
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
            d.dtmPublish,
			d.dtmPublishUntil
    FROM	m136_tblDocument d
    LEFT JOIN m136_tblHandbook h 
        ON h.iHandbookId = d.iHandbookId
    WHERE	d.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1
        AND d.iApproved = 0
        AND d.iDocumentId NOT IN (SELECT Id FROM @Items)
	
    INSERT INTO @Items
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
            d.dtmPublish,
			d.dtmPublishUntil
    FROM	m136_relVirtualRelation v
        INNER JOIN m136_tblDocument d 
            ON d.iDocumentId = v.iDocumentId
        INNER JOIN m136_tblHandbook h
            ON d.iHandbookId = h.iHandbookId
    WHERE	v.iHandbookId = @iHandbookId
        AND d.iLatestApproved = 1
        AND d.iDeleted = 0
        
    INSERT INTO @Items
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
            d.dtmPublish,
			d.dtmPublishUntil
    FROM	m136_relVirtualRelation v
        INNER JOIN m136_tblDocument d 
            ON d.iDocumentId = v.iDocumentId
        INNER JOIN m136_tblHandbook h
            ON d.iHandbookId = h.iHandbookId
    WHERE	v.iHandbookId = @iHandbookId
        AND d.iLatestVersion = 1
        AND d.iDeleted = 0
        AND d.iApproved = 0
        AND d.iDocumentId NOT IN (SELECT Id FROM @Items)
            
    INSERT INTO @Items
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
            [dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, 1) AS iChildCount,
            0 AS IsDocument,
            NULL as dtmPublish,
			NULL as dtmPublishUntil
    FROM	m136_tblHandbook as h
    WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
        
    SELECT
        Id,
        iEntityId,
        iHandbookId,
        strName,
        iDocumentTypeId,
        Version,
        LevelType,
        dtmApproved,
        strApprovedBy,
        Responsible,
        DepartmentId,
        Virtual,
        iSort,
        ParentFolderName,
        Path,
        HasAttachment,
        iApproved,
        iDraft,
        iParentHandbookId,
        iChildCount,
        IsDocument,
        dtmPublish,
        dtmPublishUntil
    FROM
        @Items
	ORDER BY IsDocument, iSort, strName;
END
GO