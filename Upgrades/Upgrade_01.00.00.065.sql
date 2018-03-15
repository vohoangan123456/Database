INSERT INTO #Description VALUES('Modify stored procedure m136_GetApprovedDocumentsByHandbookIdRecursive for reusing function [dbo].[m136_GetHandbookRecursive].')
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
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
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
			NULL AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
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
