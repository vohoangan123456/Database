INSERT INTO #Description VALUES('Alter stored procedures m136_be_UpdateFolderDocuments.')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: OCT 20, 2015
-- Description:	Update folder documents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderDocuments]
	@Documents AS [dbo].[Documents] READONLY,
	@HandbookId as INT
AS
BEGIN
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
				FROM [dbo].[m136_relVirtualRelation] doc1 WHERE doc1.iHandbookId = @HandbookId);
				
	INSERT INTO [dbo].[m136_relVirtualRelation]
		SELECT @HandbookId, iDocumentId, iSort FROM #VirtualDocuments;
	
	DELETE [dbo].[m136_relVirtualRelation] 
		WHERE iHandbookId = @HandbookId AND iDocumentId NOT IN (SELECT doc1.iDocumentId 
			FROM @Documents doc1 WHERE iVirtual = 1);
	DROP TABLE #VirtualDocuments;
END

GO
