
INSERT INTO #Description VALUES('Created stored procedures for update folder documents.')
GO
IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'Documents' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[Documents] AS TABLE(
		[iHandbookId] [int] NOT NULL,
		[iDocumentId] [int] NOT NULL,
		[iSort] [int] NULL,
		[iVirtual] [int] NULL
	)
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL
AS
SET NOCOUNT ON
BEGIN
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
		
		SELECT	d.iDocumentId as Id,
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
				d.iDraft
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	v.iDocumentId as Id,
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
				d.iDraft
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	h.iHandbookId as Id,
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
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment,
				NULL as iApproved,
				NULL as iDraft
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderDocuments] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 07, 2015
-- Description:	Update folder documents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderDocuments]
	-- Add the parameters for the stored procedure here
	@Documents AS [dbo].[Documents] READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	UPDATE doc
	SET doc.iSort = doc1.iSort
	FROM [dbo].[m136_tblDocument] doc
		INNER JOIN @Documents doc1
		ON doc.iDocumentId = doc1.iDocumentId; 
    
    UPDATE doc
	SET doc.iSort = doc1.iSort
	FROM [dbo].[m136_relVirtualRelation] doc
		INNER JOIN @Documents doc1
		ON doc.iDocumentId = doc1.iDocumentId; 
		
	SELECT doc.iHandbookId, doc.iDocumentId, doc.iSort INTO #VirtualDocuments
		FROM @Documents doc
		WHERE doc.iVirtual = 1 
			AND doc.iDocumentId NOT IN (SELECT iDocumentId
				FROM [dbo].[m136_relVirtualRelation] doc1 WHERE doc1.iHandbookId = doc.iHandbookId);

	INSERT INTO [dbo].[m136_relVirtualRelation]
		SELECT iHandbookId, iDocumentId, iSort FROM #VirtualDocuments;
		
	DELETE [dbo].[m136_relVirtualRelation] 
		WHERE iDocumentId NOT IN (SELECT doc1.iDocumentId 
			FROM @Documents doc1 WHERE iVirtual = 1 AND doc1.iHandbookId = iHandbookId);
		
	DROP TABLE #VirtualDocuments;
END
