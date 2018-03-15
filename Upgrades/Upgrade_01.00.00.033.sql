INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems] for setting tree content level.')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL,
	@TreeContentLevel INT /* 0: all (folders and documents); 1: folders only */
AS
SET NOCOUNT ON
BEGIN
		SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				iLevelType as LevelType,
				iDepartmentId as DepartmentId
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		
		DECLARE @Documents TABLE
		(
			Id INT,
			strName VARCHAR(200),
			iDocumentTypeId INT,
			[Version] INT,
			LevelType INT,
			dtmApproved DATETIME,
			strApprovedBy VARCHAR(200),
			Responsible VARCHAR(200),
			DepartmentId INT,
			Virtual INT,
			iSort INT,
			ParentFolderName VARCHAR(200),
			[Path] VARCHAR(200),
			HasAttachment BIT
		);
		
		IF (@TreeContentLevel = 0) 
		BEGIN
			INSERT INTO @Documents
				SELECT	d.iDocumentId as Id,
						d.strName,
						d.iDocumentTypeId,
						d.iVersion as Version,
						NULL as LevelType,
						d.dtmApproved,
						d.strApprovedBy,
						dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
						null as DepartmentId,
						0 as Virtual,
						d.iSort,
						NULL as ParentFolderName,
						NULL as Path,
						[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
				FROM	m136_tblDocument d
				WHERE	d.iHandbookId = @iHandbookId
					AND d.iLatestApproved = 1
			UNION
				SELECT	v.iDocumentId as Id,
						d.strName,
						d.iDocumentTypeId,
						d.iVersion as Version,
						NULL as LevelType,
						d.dtmApproved,
						d.strApprovedBy,
						dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
						null as DepartmentId,
						1 as Virtual,
						v.iSort,
						h.strName as ParentFolderName,
						dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
						[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
				FROM	m136_relVirtualRelation v
					INNER JOIN m136_tblDocument d 
						ON d.iDocumentId = v.iDocumentId
					INNER JOIN m136_tblHandbook h
						ON d.iHandbookId = h.iHandbookId
				WHERE	v.iHandbookId = @iHandbookId
					AND d.iLatestApproved = 1;
		END
		
		SELECT * FROM @Documents
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
				NULL as Version,
				iLevelType as LevelType,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
			
	ORDER BY iSort ASC, 
			 strName ASC
END
GO