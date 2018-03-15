INSERT INTO #Description VALUES('Updated m136_GetApprovedDocumentsByHandbookIdRecursive')
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

    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
    
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId AS TemplateId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
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
			d.iDocumentTypeId AS TemplateId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblHandbook h 
					ON virt.iHandbookId = h.iHandbookId
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	
		ORDER BY 
			iSort, 
			strName
END
GO