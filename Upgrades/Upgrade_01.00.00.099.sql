INSERT INTO #Description VALUES('Create [dbo].[m136_be_GetTemplateMetaInfo]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetTemplateMetaInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetTemplateMetaInfo] 
	@TemplateId INT
AS
BEGIN
	SELECT  dti.iDocumentTypeInfoId,
		mir.iMetaInfoTemplateRecordsId, 
		mir.strName,	
		mir.strDescription, 
		mir.iInfoTypeId,
		mir.iFlag,
		it.strName AS infoTypeName, 
		it.strDescription AS infoTypeDescription,
		dti.iDeleted,
		dti.iShowOnPDA,
		dti.iMandatory, 
		dti.iMaximized
	FROM [m136_tblMetaInfoTemplateRecords] mir
		INNER JOIN [m136_relDocumentTypeInfo] dti 
			ON dti.iDocumentTypeId = @TemplateId AND dti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
		LEFT JOIN [m136_tblInfoType] it 
			ON mir.iInfoTypeId = it.iInfoTypeId
	ORDER BY dti.iSort, it.strName;	
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocument] 
	@HandbookId INT,
	@TemplateId INT,
	@DocumentType INT,
	@CreatorId INT,
	@AllowOffline BIT,
	@Title NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iMaxDocumentId INT = 0, @iMaxEntityId INT = 0, @Sort INT, @LevelType INT;
	
	SELECT @LevelType = iLevelType FROM dbo.m136_tblHandbook WHERE iHandbookId = @HandbookId
	
	SELECT @iMaxDocumentId = MAX(iDocumentId) FROM dbo.m136_tblDocument;
	DECLARE @iNewDocumentId INT = @iMaxDocumentId + 1;
	
	SELECT @iMaxEntityId = MAX(iEntityId) FROM dbo.m136_tblDocument;
	DECLARE @iNewEntityId INT = @iMaxEntityId + 1;
	
	SELECT @Sort = ISNULL(MAX(iSort) + 1, 0) FROM (SELECT 0 iSort
			FROM dbo.m136_tblDocument d
			WHERE d.iHandbookId = @HandbookId AND d.iDeleted = 0
			AND d.iLatestVersion = 1
		UNION all
			SELECT 1 iSort
			FROM dbo.m136_tblDocument d
			WHERE d.iLatestVersion = 1) Temp
			
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	INSERT INTO dbo.m136_tblDocument(
		iEntityId,
		iDocumentId,
		iVersion,
		iDocumentTypeId,
		iHandbookId,
		strName,
		strDescription,
		iCreatedbyId,
		dtmCreated,
		strAuthor,
		iAlterId,
		dtmAlter,
		strAlterer,
		iApprovedById,
		strApprovedBy,
		iStatus,
		iSort,
		iDeleted,
		iApproved,
		iDraft,
		iLevelType,
		strHash,
		iReadCount,
		iLatestVersion,
		iLatestApproved) 
    VALUES(
		@iNewEntityId,
		@iNewDocumentId,
		0,
		@TemplateId,
		@HandbookId,
		@Title,
		'',
		@CreatorId,
		GETDATE(),
		[dbo].[fnOrgGetUserName] (@CreatorId, 'System', 0),
		@CreatorId,
		GETDATE(),
		[dbo].[fnOrgGetUserName] (@CreatorId, 'System', 0),
		0,
		'',
		0,
		@Sort,
		0,
		0,
		1,
		@LevelType,
		'',
		0,
		1,
		0);
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	
	SELECT @iNewDocumentId;
END
GO