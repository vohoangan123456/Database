INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_be_GetPreviousVersions]')
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
			ROW_NUMBER() OVER (ORDER BY doc.iVersion DESC) AS rownumber,
			CASE WHEN EXISTS (SELECT EntityId FROM dbo.m136_Hearings WHERE EntityId = doc.iEntityId)
				THEN 1
			ELSE
				0
			END AS IsHearing
        INTO #Filters
        FROM dbo.m136_tblDocument doc
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
			doc.ReadCount,
			doc.IsHearing
		FROM #Filters doc 
		WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;
END
GO

