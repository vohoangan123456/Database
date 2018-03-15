INSERT INTO #Description VALUES('Create stored procedure get virtual of a document')
GO

IF OBJECT_ID('[dbo].[m136_be_GetVirtualDocumentByDocumentId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetVirtualDocumentByDocumentId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetVirtualDocumentByDocumentId] 
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN

SELECT 
	dbo.fn136_GetParentPathEx(vir.iHandbookId) as Path,
	han.strName AS FolderName,
	han.iHandbookId 
FROM dbo.m136_relVirtualRelation AS vir
	JOIN dbo.m136_tblHandbook AS han ON vir.iHandbookId = han.iHandbookId AND han.iDeleted = 0
WHERE vir.iDocumentId = @DocumentId
ORDER BY han.iHandbookId
		
END
GO