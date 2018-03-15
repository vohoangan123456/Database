
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO

INSERT INTO #Description VALUES('Adding level type to the GetChapterItems')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
	-- Add the parameters for the stored procedure here
	@iHandbookId int = NULL
AS
BEGIN

		SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL

		SELECT	d.iDocumentId as Id,
				d.strName,
				dt.iDocumentTypeId as TemplateId,
				dt.Type as DocumentType,
				d.iVersion as Version,
				NULL as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	
	UNION

		SELECT v.iDocumentId as Id,
			   d.strName,
			   dt.iDocumentTypeId as TemplateId,
			   dt.Type as DocumentType,
			   d.iVersion as Version,
			   NULL as LevelType,
			   d.dtmApproved,
			   d.strApprovedBy,
			   dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			   null as DepartmentId,
			   1 as Virtual,
			   v.iSort,
			   h.strName as ParentFolderName,
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
				AND d.iDeleted = 0
				AND d.iLatestApproved = 1
    
	UNION
		
		SELECT	h.iHandbookId as Id,
				h.strName,
				NULL as TemplateId,
				-1 as DocumentType,
				NULL as Version,
				iLevelType as LevelType,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0

	ORDER BY d.iSort ASC, 
			 d.strName ASC	
END