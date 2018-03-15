INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_GetDocumentData]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentData]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentData] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	DECLARE @EntityId INT,
		@DocumentTypeId INT
	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL,
		Sort int,
		UrlOrFileName NVARCHAR(4000) NULL,
		Type INT NULL,
		LevelType int
	)
	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	--Get Document Content

	DECLARE @DocumentContent TABLE
	(
		InfoTypeId INT NOT NULL,
		FieldName varchar(100) NOT NULL,
		FieldDescription varchar(4000) NOT NULL,
		InfoId INT NOT NULL,
		NumberValue INT NULL,
		DateValue datetime NULL,
		TextValue VARCHAR(8000) NULL,
		RichTextValue ntext NULL,
		FieldId int NOT NULL,
		FieldProcessType int NOT NULL,
		Maximized INT NOT NULL
	)

	INSERT INTO @DocumentContent
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0 
	ORDER BY rdi.iSort

	DELETE FROM @DocumentContent WHERE InfoTypeId = 1 AND NumberValue is NULL
	DELETE FROM @DocumentContent WHERE InfoTypeId in (2,3,4) AND (TextValue is NULL OR DATALENGTH(TextValue)=0)
	DELETE FROM @DocumentContent WHERE InfoTypeId = 5 AND DateValue is NULL
	DELETE FROM @DocumentContent WHERE InfoTypeId = 6 AND DATALENGTH(RichTextValue)=0

	SELECT	InfoTypeId, FieldName, FieldDescription, InfoId, NumberValue, 
			DateValue, TextValue, RichTextValue, FieldId, FieldProcessType, Maximized 
	FROM @DocumentContent

	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   FieldId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId IN (20, 2, 50)
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   FieldId = r.iPlacementId,
		   LevelType = d.iLevelType
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	--Get Document Info
	SELECT * FROM @Document
END
GO
