INSERT INTO #Description VALUES ('Modified SP[dbo].[m136_GetAttachmentsForDocuments]')
GO

IF OBJECT_ID('[dbo].[m136_GetAttachmentsForDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetAttachmentsForDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetAttachmentsForDocuments]
	@DocumentIds AS [dbo].[Item] READONLY,
	@SupportFileArchiveAttachments bit,
	@IsBackEnd bit = NULL
AS
BEGIN
    DECLARE @EntityIds TABLE(Id INT);
    IF(@IsBackEnd IS NULL OR @IsBackEnd = 0)
    BEGIN
		INSERT INTO @EntityIds (Id)
		SELECT iEntityId
		FROM m136_tblDocument
		WHERE iDocumentId IN (SELECT Id FROM @DocumentIds) AND iLatestApproved = 1;
    END
    ELSE
    BEGIN
		INSERT INTO @EntityIds (Id)
		SELECT iEntityId
		FROM m136_tblDocument
		WHERE iDocumentId IN (SELECT Id FROM @DocumentIds) AND iLatestVersion = 1;
    END
    
    DECLARE @Attachments TABLE (iDocumentId int,  iItemId int, strName varchar(300), iPlacementId int, 
	iProcessrelationTypeId int, strExtension varchar(10), strDescription varchar(800), iSort int);
	
	IF (@SupportFileArchiveAttachments = 1)
	BEGIN
		INSERT INTO @Attachments
		SELECT (SELECT iDocumentId FROM m136_tblDocument WHERE iEntityId = r.iEntityId) AS iDocumentId,
				r.iItemId,
				dbo.fnArchiveGetFileName(1, r.iItemId, '') strName,
				r.iPlacementId,
				r.iProcessrelationTypeId,
				b.strExtension,
				'' as strDescription,
				r.iSort 
			FROM tblBlob b 
				LEFT JOIN m136_relInfo r ON r.iItemId = b.iItemId
			WHERE r.iEntityId IN (SELECT Id FROM @EntityIds)
				  AND r.iRelationTypeId = 2;
	END	
			  
	INSERT INTO @Attachments
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
	  order by iSort, strName;
	
    SELECT iDocumentId ,  iItemId , strName , iPlacementId , 
	iProcessrelationTypeId , strExtension , strDescription , iSort FROM @Attachments;
END
GO



