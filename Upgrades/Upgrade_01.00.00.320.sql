INSERT INTO #Description VALUES ('Modify procedures m136_be_GetDocumentsAwaitingMyApproval, m136_be_MoveMultipleDocuments, m136_be_GetChapterItems')
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

IF OBJECT_ID('[dbo].[m136_be_MoveMultipleDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveMultipleDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveMultipleDocuments]
    @DocumentIds AS [dbo].[Item] READONLY,
    @OldFolderId INT,
    @NewFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE m136_tblDocument
        SET iSort = iSort + 1
        WHERE iHandbookId = @NewFolderId
        
        UPDATE m136_relVirtualRelation
        SET iSort = iSort + 1
        WHERE iHandbookId = @NewFolderId
        
        UPDATE
            m136_tblDocument
        SET 
            iSort = -2147483648, 
            iHandbookId = @NewFolderId
        WHERE
            iHandbookId = @OldFolderId 
            AND iDocumentId IN (SELECT Id FROM @DocumentIds)
        
    COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
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
            dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
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
            dbo.fn136_GetParentPathEx(d.iHandbookId) as Path,
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
            dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
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
            h.iHandbookId AS VirtualHandbookId,
            0 AS ReadCount
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY IsDocument, iSort, d.strName;
END
GO