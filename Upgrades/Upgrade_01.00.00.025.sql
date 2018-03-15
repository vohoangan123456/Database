INSERT INTO #Description VALUES('Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

-- =============================================
-- Author:  si.manh.nguyen
-- Created date: DEC 11, 2014
-- Description: get fields and related of document
-- =============================================
ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT,
@DocumentTypeId INT,
@IsProcess BIT
AS
BEGIN
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
		  	  
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
				AND  d.iApproved = 1
		JOIN m136_tblDocumentType dtype 
			ON d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort

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

	IF @IsProcess = 1
	BEGIN
		
		SELECT
			d.iDocumentId,
			d.strName,
			d.iHandbookId,
			h.strName AS strFolderName
		FROM
			m136_relInfo rel
			JOIN m136_tblDocument d 
				ON rel.iItemId = iDocumentId 
			JOIN m136_tblHandbook h 
				ON d.iHandbookId=h.iHandbookId
		WHERE
			rel.iEntityId=@iEntityId
			AND rel.iRelationTypeId = 136
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
		ORDER BY
			h.strName, d.strName
			
	END
END
GO