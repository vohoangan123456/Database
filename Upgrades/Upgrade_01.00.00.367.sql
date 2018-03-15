INSERT INTO #Description VALUES ('Update SP [dbo].[m136_be_GetDocumentFieldsAndRelates] and create SP [dbo].[m136_be_VerifyDocumentTypeHasUsedOnDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates]
	@iEntityId INT,
	@SupportFileArchiveAttachments bit
AS
BEGIN
	DECLARE @DocumentTypeId INT;
	SELECT	@DocumentTypeId = d.iDocumentTypeId
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId;
	IF (@SupportFileArchiveAttachments = 1)
	BEGIN
		-- Get related attachment of document view.
		DECLARE @Attachments TABLE(iItemId int, strName varchar(1000), iPlacementId int, iProcessrelationTypeId int, strExtension varchar(10));
		INSERT INTO @Attachments
		SELECT r.iItemId,
			   b.strName,
			   r.iPlacementId,
			   r.iProcessrelationTypeId,
			   b.strExtension 
		FROM m136_relInfo r 
			 JOIN m136_tblBlob b 
				ON r.iItemId = b.iItemId
		WHERE r.iEntityId = @iEntityId 
			  AND r.iRelationTypeId = 20;
		
		INSERT INTO @Attachments
		SELECT r.iItemId,
			   f.strName,
			   r.iPlacementId,
			   r.iProcessrelationTypeId,
			   b.strExtension 
		FROM tblBlob b  
			 LEFT JOIN m136_relInfo r ON r.iItemId = b.iItemId
			 LEFT JOIN tblFile f ON f.iItemId = b.iItemId				
		WHERE r.iEntityId = @iEntityId 
			  AND r.iRelationTypeId = 2;
		
		SELECT * FROM @Attachments;
	END
	ELSE
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
		WHERE r.iEntityId = @iEntityId 
			  AND r.iRelationTypeId = 20
		ORDER BY r.iSort, b.strName;
	END
	
	-- Get related Document of document view.
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId,
		   d.iHandbookId,
		   h.strName AS strFolderName,
		   r.iProcessRelationTypeId,
		   d.iDocumentTypeId,
		   r.iSort,
		   h.iLevelType,
		   d.iApproved,
		   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
		   d.iVersion as Version,
		   d.dtmCreated,
		   d.dtmAlter,
		   d.dtmApproved,
		   d.strApprovedBy,
		   d.dtmPublishUntil,
		   dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		   d.iReadCount AS ReadCount,
		   d.iInternetDoc,
		   0 as Virtual,
		   d.iDraft,
		   d.iDeleted
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestVersion = 1
		JOIN m136_tblHandbook h 
			ON d.iHandbookId = h.iHandbookId
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort, d.strName;
	--Get Related Image	of document view.	
	SELECT	r.iItemId,
			r.iPlacementId,
			r.iScaleDirId,
			r.iSize,
			r.iVJustifyId, 
			r.iHJustifyId,
			r.iWidth, 
			r.iHeight,
			r.strCaption,
			r.strURL, 
			r.iNewWindow,
			r.iSort
	FROM  m136_relInfo r 
	WHERE iEntityId = @iEntityId 
		  AND (r.iRelationTypeId = 5 OR r.iRelationTypeId = 50)
		  AND r.iPlacementId > 0
	ORDER BY r.iSort, r.iItemId;
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
			mi.iFieldProcessType,
            rdi.iMaximized,
            rdi.iMandatory,
            mir.iPublish AS IsPublish,
            mi.iDeleted
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
	ORDER BY rdi.iSort;
END
GO

IF OBJECT_ID('[dbo].[m136_be_VerifyDocumentTypeHasUsedOnDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_VerifyDocumentTypeHasUsedOnDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_VerifyDocumentTypeHasUsedOnDocument]
	@DocumentType INT
AS
BEGIN
	IF EXISTS(SELECT 1 FROM dbo.m136_tblDocument WHERE iDocumentTypeId = @DocumentType)
	BEGIN
		SELECT 1
	END
	ELSE
	BEGIN
		SELECT 0
	END
END
GO