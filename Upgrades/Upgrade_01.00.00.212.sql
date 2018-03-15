INSERT INTO #Description VALUES('Modify procedure m136_GetAttachmentsInFolder')
GO

IF OBJECT_ID('[dbo].[m136_GetAttachmentsInFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetAttachmentsInFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetAttachmentsInFolder]
    @UserId INT,
	@FolderId INT,
    @IsRecursive BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
    DECLARE @SearchFolderIds TABLE(Id INT);
    DECLARE @DocumentEntityIds TABLE(Id INT);
    
    INSERT INTO @SearchFolderIds
    SELECT iHandbookId
    FROM dbo.m136_GetHandbookRecursive(@FolderId, @UserId, 1);
    
    INSERT INTO @SearchFolderIds(Id) VALUES(@FolderId);
    
    INSERT INTO @DocumentEntityIds (Id)
    SELECT d.iEntityId
    FROM m136_tblDocument d
        LEFT JOIN m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
    WHERE d.iHandbookId IN (SELECT Id FROM @SearchFolderIds)
        AND d.iLatestApproved = 1
    
    INSERT INTO @DocumentEntityIds (Id)    
    SELECT d.iEntityId
    FROM m136_relVirtualRelation v
        INNER JOIN m136_tblDocument d ON d.iDocumentId = v.iDocumentId
        INNER JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
    WHERE v.iHandbookId IN (SELECT Id FROM @SearchFolderIds)
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
	WHERE r.iEntityId IN (SELECT Id FROM @DocumentEntityIds)
		  AND r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK;
END CATCH
END
GO