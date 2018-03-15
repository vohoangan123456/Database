INSERT INTO #Description VALUES ('Create SP for Get attachment of document')
GO

IF OBJECT_ID('[dbo].[m136_be_GetAttachmentsForDocumentByEntityId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetAttachmentsForDocumentByEntityId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetAttachmentsForDocumentByEntityId]
	@EntityId INT
AS
BEGIN
    -- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension,
		   b.strDescription,
		   r.iSort 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
END
GO