INSERT INTO #Description VALUES ('Create SP [dbo].[m136_GetFoldersByVirtualDocumentId]')
GO

IF OBJECT_ID('[dbo].[m136_GetFoldersByVirtualDocumentId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFoldersByVirtualDocumentId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFoldersByVirtualDocumentId]
	@DocumentId INT
AS
SET NOCOUNT ON
BEGIN
    SELECT
        h.iHandbookId Id,
        h.strName Name,
        h.iLevelType LevelType,
        dbo.fn136_GetParentPathEx(h.iHandbookId) as ParentPath
    FROM
        m136_relVirtualRelation v
            INNER JOIN m136_tblHandbook h
                ON v.iHandbookId = h.iHandbookId
    WHERE
        v.iDocumentId = @DocumentId
    ORDER BY v.iSort
END

GO