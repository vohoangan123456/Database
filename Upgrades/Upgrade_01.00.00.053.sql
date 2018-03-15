INSERT INTO #Description VALUES('Updated m136_GetDocumentFieldsAndRelates')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
	ELSE
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
END
GO