INSERT INTO #Description VALUES ('Support file archive attachments')
GO

IF OBJECT_ID('[dbo].[m136_be_GetAttachmentsForDocumentByEntityId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetAttachmentsForDocumentByEntityId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetAttachmentsForDocumentByEntityId]
	@EntityId INT,
	@SupportFileArchiveAttachments bit
AS
BEGIN
	DECLARE @Attachments TABLE(iItemId [int], strName [varchar](1000), iPlacementId [int], 
	iProcessrelationTypeId [int], strExtension [varchar](10), strDescription [varchar](800), iSort [int]);
	-- Get related attachment of document view.
	INSERT INTO @Attachments    
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
	IF (@SupportFileArchiveAttachments = 1)
	BEGIN
		-- For archive attachments
		INSERT INTO @Attachments 
		SELECT r.iItemId,
			   b.strFileName,
			   r.iPlacementId,
			   r.iProcessrelationTypeId,
			   b.strExtension,
			   '' as strDescription,
			   r.iSort 
		FROM tblBlob b 
			 LEFT JOIN m136_relInfo r 
				ON r.iItemId = b.iItemId
		WHERE r.iEntityId = @EntityId 
			  AND r.iRelationTypeId = 2
		ORDER BY r.iSort, b.strFileName;
	END
	SELECT * FROM @Attachments a;
END
GO
