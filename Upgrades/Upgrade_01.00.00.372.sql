INSERT INTO #Description VALUES ('Modify procedure m136_be_GetMyDocumentsSentToApproval, m136_be_GetDocumentInformation')
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
			dbo.fnOrgGetUserName(ap.iEmployeeId, '', 0) AS strApprovedBy,
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
            JOIN m136_relSentEmpApproval ap on d.iEntityId = ap.iEntityId
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

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation]
	@DocumentId INT = NULL
AS
BEGIN
    DECLARE @Approver NVARCHAR(102);
    
    SELECT
        @Approver = dbo.fnOrgGetUserName(ap.iEmployeeId, '', 0)
    FROM
        m136_tblDocument d
            INNER JOIN m136_relSentEmpApproval ap ON d.iEntityId = ap.iEntityId
    WHERE
        d.iDocumentId = @DocumentId
        AND d.iLatestVersion = 1

	DECLARE @iVersions INT;
	SELECT @iVersions = COUNT(1) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @DocumentId;
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
            CASE
                WHEN @Approver IS NOT NULL THEN @Approver
                ELSE d.strApprovedBy
            END AS strApprovedBy,
			d.iApproved,
            dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
			d.iDraft,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			h.iLevel,
			te.strEmail AS strCreatedByEmail,
			d.strAuthor,
			@iVersions AS iVersionsCount,
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File],
			d.iCompareToVersion	,
			d.iInternetDoc,
			d.iDeleted,
			d.iCreatedbyId,
			rel.iEmployeeId AS empApproveOnBehalfId,
			CASE WHEN rel.iEmployeeId IS NOT NULL THEN  dbo.fnOrgGetUserName(rel.iEmployeeId, '', 0) ELSE '' END AS strEmpApproveOnBehalf,
            CASE WHEN EXISTS(SELECT 1 FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS bIsLocked,
            dbo.fnOrgGetUserName((SELECT TOP 1 iEmployeeId FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId), '', 0) strLockedBy,
            iOrientation,
            CASE WHEN EXISTS (SELECT 1 FROM m136_tblCopyConfirms WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS IsCopyReadingReceiptFromResponsible,
			KeyWords,
			TitleAndKeyword
	FROM	m136_tblDocument d
        JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
        LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
        LEFT JOIN dbo.m136_relSentEmpApproval rel 
            ON d.iEntityId = rel.iEntityId 
            AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
GO