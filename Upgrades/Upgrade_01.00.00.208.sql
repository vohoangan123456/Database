INSERT INTO #Description VALUES('Create procedure m136_GetAttachmentsInFolder')
GO

IF OBJECT_ID('[dbo].[m136_GetAttachmentsInFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetAttachmentsInFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetAttachmentsInFolder]
	@FolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;

    DECLARE @EntityIds TABLE(Id INT);
    
    INSERT INTO @EntityIds (Id)
    SELECT d.iEntityId
    FROM m136_tblDocument d
        LEFT JOIN m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
    WHERE d.iHandbookId = @FolderId
        AND d.iLatestApproved = 1
    
    INSERT INTO @EntityIds (Id)    
    SELECT d.iEntityId
    FROM m136_relVirtualRelation v
        INNER JOIN m136_tblDocument d ON d.iDocumentId = v.iDocumentId
        INNER JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
    WHERE v.iHandbookId = @FolderId
        AND d.iLatestApproved = 1
    
    SELECT (SELECT iDocumentId FROM m136_tblDocument WHERE iEntityId = r.iEntityId) AS iDocumentId,
        r.iItemId,
		b.strName,
		r.iPlacementId,
		r.iProcessrelationTypeId,
		b.strExtension,
		b.strDescription,
		r.iSort 
	FROM m136_relInfo r 
		JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iEntityId IN (SELECT Id FROM @EntityIds)
		  AND r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_GetAttachmentsForDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetAttachmentsForDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetAttachmentsForDocuments]
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @EntityIds TABLE(Id INT);
    
    INSERT INTO @EntityIds (Id)
    SELECT iEntityId
    FROM m136_tblDocument
    WHERE iDocumentId IN (SELECT Id FROM @DocumentIds) AND iLatestApproved = 1

    SELECT (SELECT iDocumentId FROM m136_tblDocument WHERE iEntityId = r.iEntityId) AS iDocumentId,
        r.iItemId,
		b.strName,
		r.iPlacementId,
		r.iProcessrelationTypeId,
		b.strExtension,
		b.strDescription,
		r.iSort 
	FROM m136_relInfo r 
		JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iEntityId IN (SELECT Id FROM @EntityIds)
		  AND r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
END
GO