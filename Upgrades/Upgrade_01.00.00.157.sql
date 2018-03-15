INSERT INTO #Description VALUES('Modify procedure m136_be_GetMyWorkingDocuments, m136_be_GetOtherWorkingDocuments, m136_be_GetSoonToExpiredDocuments')
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
            d.iInternetDoc,
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
            d.iInternetDoc,
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
            d.iInternetDoc,
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
                d.iInternetDoc,
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
            d.iInternetDoc,
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
            d.iInternetDoc,
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