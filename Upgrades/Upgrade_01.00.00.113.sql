INSERT INTO #Description VALUES('Create stored procedures for related management.')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: OCT 20, 2015
-- Description:	Update document content that includes:
--				document information, related attachments, related documents, contents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDocument] 
	@iEntityId				INT,
	@strName				VARCHAR(200),
	@RelatedAttachments		AS [dbo].[Item] READONLY,
	@RelatedDocuments		AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	UPDATE dbo.m136_tblDocument
	SET dbo.m136_tblDocument.strName = @strName
	WHERE iEntityId = @iEntityId;    
	    
	UPDATE r
		SET r.iSort = rd.Value
	FROM dbo.m136_relInfo r INNER JOIN @RelatedDocuments rd 
		ON r.iItemId = rd.Id
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId = 136; -- HandbookRelationTypes.Document = 136      
    
    UPDATE r
		SET r.iSort = rd.Value
	FROM dbo.m136_relInfo r INNER JOIN @RelatedAttachments rd 
		ON r.iItemId = rd.Id
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId IN (2, 20); -- 2: attachment, 20: related attachment
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentFieldsAndRelates]
	@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT;
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId;
	
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
		  
	-- Get related Document of document view.
	IF @IsProcess = 1
	BEGIN
		SELECT d.strName, 
			   d.iDocumentId,
			   r.iPlacementId,
			   d.iHandbookId,
			   h.strName AS strFolderName,
			   r.iProcessRelationTypeId,
			   d.iDocumentTypeId,
			   r.iSort
		FROM m136_relInfo r
			JOIN m136_tblDocument d 
				ON	r.iItemId = d.iDocumentId 
					AND d.iLatestVersion = 1
			JOIN m136_tblHandbook h 
				ON d.iHandbookId = h.iHandbookId
		WHERE	r.iEntityId = @iEntityId 
				AND r.iRelationTypeId = 136
		ORDER BY r.iSort, d.strName;
	END
	ELSE
	BEGIN
		SELECT d.strName, 
			   d.iDocumentId,
			   r.iPlacementId,
			   r.iProcessRelationTypeId,
			   d.iDocumentTypeId,
			   r.iSort
		FROM m136_relInfo r
			JOIN m136_tblDocument d 
				ON	r.iItemId = d.iDocumentId 
					AND d.iLatestVersion = 1
		WHERE	r.iEntityId = @iEntityId 
				AND r.iRelationTypeId = 136
		ORDER BY r.iSort, d.strName;
	END
	
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
	ORDER BY rdi.iSort;
END
GO


IF OBJECT_ID('[dbo].[m136_be_InsertRelatedAttachment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: SEP 23, 2015
-- Description:	Insert related attachments 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertRelatedAttachment] 
	@RelationTypeId		INT,
	@iItemId			INT,
	@strName			VARCHAR(300),
	@strDescription		VARCHAR(800),
	@iSize				INT,
	@strFileName		VARCHAR(200),
	@strContentType		VARCHAR(100),
	@strExtension		VARCHAR(100),
	@imgContent			[image]
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @MaxId INT;
	SELECT @MaxId = MAX(mtb.iItemId) FROM dbo.m136_tblBlob mtb; 
	SET @iItemId = (ISNULL(@MaxId, 0) + 1);
	
	SET IDENTITY_INSERT dbo.m136_tblBlob ON;
    INSERT INTO [dbo].m136_tblBlob
        (iItemId,
        iInformationTypeId,
        strName,
        strDescription,
        iSize,
        strFileName,
        strContentType,
        strExtension,
        imgContent,
        bInUse,
        dtmRegistered,
        iWidth,
        iHeight)
    VALUES
        (@iItemId,
        @RelationTypeId,
        @strName,
        @strDescription,
        @iSize,
        @strFileName,
        @strContentType,
        @strExtension,
        @imgContent,
        1,
        GETDATE(),
        0,
        0);
	SET IDENTITY_INSERT dbo.m136_tblBlob OFF;
	SELECT @iItemId;
END
GO