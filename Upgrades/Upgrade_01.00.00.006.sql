
INSERT INTO #Description VALUES('update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dt.[strName] AS DocumentTypeName
	FROM m136_tblDocument d
	JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId AND dt.iDeleted = 0
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentFieldsAndRelates]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
GO

CREATE  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId int,
@DocumentTypeId int
AS
BEGIN

	SELECT r.iItemId,b.strName
	FROM m136_relInfo r JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20 

	SELECT  d.strName, d.iDocumentId
	FROM m136_relInfo r
	JOIN m136_tblDocument d 
		ON r.iItemId = d.iDocumentId 
		AND d.iLatestApproved = 1
		AND  d.iApproved = 1
	JOIN m136_tblDocumentType dtype on d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 136
	ORDER BY r.iSort

	SELECT	mi.iInfoTypeId, mi.strName strFieldName, mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, DateValue = mid.value, TextValue = mit.value, RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, mi.iFieldProcessType, rdi.iMaximized
	FROM		[dbo].m136_tblMetaInfoTemplateRecords mi
				JOIN [dbo].m136_relDocumentTypeInfo rdi ON rdi.iDocumentTypeId = @DocumentTypeId AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoDate mid ON mid.iEntityId = @iEntityId AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoNumber mii ON mii.iEntityId = @iEntityId AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoText mit ON mit.iEntityId = @iEntityId AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoRichText mir ON mir.iEntityId = @iEntityId AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort

END
