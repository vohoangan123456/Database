INSERT INTO #Description VALUES ('This is used to support Advanced-Publish Document to Internet feature')
GO

-- Add columns to tables

IF NOT EXISTS(SELECT * FROM sys.columns 
    WHERE [name] = N'iPublish' AND [object_id] = OBJECT_ID(N'dbo.m136_relDocumentTypeInfo'))
BEGIN
	ALTER TABLE [dbo].[m136_relDocumentTypeInfo]	 
    ADD iPublish BIT NOT NULL DEFAULT 1
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
    WHERE [name] = N'iPublish' AND [object_id] = OBJECT_ID(N'dbo.m136_tblMetaInfoRichText'))
BEGIN
	ALTER TABLE [dbo].[m136_tblMetaInfoRichText]	 
    ADD iPublish BIT NOT NULL DEFAULT 1
END
GO

-- Drop procedures

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplateInfo]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo]')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDocument]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_UpdateDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_PublishDocumentToInternet]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_PublishDocumentToInternet]')
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NOT NULL
    EXEC ('DROP PROCEDURE [dbo].[m136_be_ApproveDocument]')
GO

-- Drop and re-create Type [dbo].[DocumentTypeInfoTable]

IF EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'DocumentTypeInfoTable' AND ss.name = N'dbo')
	DROP TYPE [dbo].[DocumentTypeInfoTable]
GO

CREATE TYPE [dbo].[DocumentTypeInfoTable] AS TABLE(
	[iEntityId] [int] NOT NULL,
	[iDocumentTypeId] [int] NOT NULL,
	[iMetaInfoTemplateRecordsId] [int] NOT NULL,
	[iSort] [int] NOT NULL,
	[iDeleted] [int] NOT NULL,
	[iShowOnPDA] [int] NOT NULL,
	[iMandatory] [int] NOT NULL,
	[iMaximized] [int] NOT NULL,
    [iPublish] [int] NOT NULL
)
GO

IF EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'FieldContent' AND ss.name = N'dbo')
	DROP TYPE [dbo].[FieldContent]
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'FieldContent' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[FieldContent] AS TABLE(
		[iMetaInfoTemplateRecordsId] [int] NOT NULL,
		[iInfoTypeId] [int] NOT NULL,
		[RichText] [ntext] NULL,
		[Text] [varchar](800) NULL,
		[Number] [int] NULL,
		[Date] [datetime] NULL,
        [iPublish] BIT NULL
	)
GO

-- Procedures

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTemplateInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTemplateInfo]
	@iDocumentTypeId INT,
	@MetaInfo AS [dbo].[DocumentTypeInfoTable] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	DECLARE @iEntityId INT, 
		@_iDocumentTypeId INT, 
		@iMetaInfoTemplateRecordsId INT, 
		@iSort INT, 
		@iDeleted INT, 
		@iShowOnPDA INT,
		@iMandatory INT,
		@iMaximized INT,
        @iPublish INT;
        
	DECLARE Metainfo CURSOR FOR 
		SELECT iEntityId 
			, iDocumentTypeId
			, iMetaInfoTemplateRecordsId
			, iSort
			, iDeleted
			, iShowOnPDA
			, iMandatory
			, iMaximized
            , iPublish
		FROM @MetaInfo;
	OPEN Metainfo; 
	FETCH NEXT FROM Metainfo INTO @iEntityId, @_iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized, @iPublish;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF EXISTS(SELECT * FROM  dbo.m136_relDocumentTypeInfo mrdti WHERE mrdti.iDocumentTypeInfoId = @iEntityId 
			OR (mrdti.iDocumentTypeId = @iDocumentTypeId AND mrdti.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId))
		BEGIN
			UPDATE dbo.m136_relDocumentTypeInfo
			SET
			    dbo.m136_relDocumentTypeInfo.iSort = @iSort,
			    dbo.m136_relDocumentTypeInfo.iDeleted = @iDeleted,
			    dbo.m136_relDocumentTypeInfo.iShowOnPDA = @iShowOnPDA,
			    dbo.m136_relDocumentTypeInfo.iMandatory = @iMandatory,
			    dbo.m136_relDocumentTypeInfo.iMaximized = @iMaximized,
                dbo.m136_relDocumentTypeInfo.iPublish = @iPublish
			WHERE (iDocumentTypeInfoId = @iEntityId) 
				OR (iDocumentTypeId = @iDocumentTypeId AND iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
		END
		ELSE
		BEGIN
			DECLARE @NewDocumentTypeInfoId INT;
			SELECT @NewDocumentTypeInfoId = MAX(iDocumentTypeInfoId) FROM dbo.m136_relDocumentTypeInfo mrdti;
			SET IDENTITY_INSERT dbo.m136_relDocumentTypeInfo ON;
			INSERT INTO dbo.m136_relDocumentTypeInfo
			(
			    iDocumentTypeInfoId,
			    iDocumentTypeId,
			    iMetaInfoTemplateRecordsId,
			    iSort,
			    iDeleted,
			    iShowOnPDA,
			    iMandatory,
			    iMaximized,
                iPublish
			)
			VALUES
			(
			    (ISNULL(@NewDocumentTypeInfoId, 0) + 1),
			    @iDocumentTypeId,
			    @iMetaInfoTemplateRecordsId,
			    @iSort,
			    @iDeleted,
			    @iShowOnPDA,
			    @iMandatory,
			    @iMaximized,
                @iPublish
			);
		END
		FETCH NEXT FROM Metainfo INTO @iEntityId, @iDocumentTypeId, @iMetaInfoTemplateRecordsId, @iSort, @iDeleted, @iShowOnPDA, @iMandatory, @iMaximized, @iPublish;
	END
	CLOSE Metainfo;
	DEALLOCATE Metainfo;
	DELETE [dbo].[m136_relDocumentTypeInfo] WHERE iDocumentTypeId = @iDocumentTypeId
		AND iMetaInfoTemplateRecordsId NOT IN (SELECT iMetaInfoTemplateRecordsId 
		FROM @MetaInfo WHERE [@MetaInfo].iDocumentTypeId = @iDocumentTypeId);
END
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
		dti.iMaximized,
        dti.iPublish,
		dti.iSort
	FROM [m136_tblMetaInfoTemplateRecords] mir
		INNER JOIN [m136_relDocumentTypeInfo] dti 
			ON dti.iDocumentTypeId = @TemplateId AND dti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
		LEFT JOIN [m136_tblInfoType] it 
			ON mir.iInfoTypeId = it.iInfoTypeId
	ORDER BY dti.iSort, it.strName;	
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation]
	@DocumentId INT = NULL
AS
BEGIN
	DECLARE @iVersions INT;
	SELECT @iVersions = COUNT(1) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @DocumentId;
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy,
			d.iApproved,
            dbo.fnDocumentCanBeApproved(d.iEntityId) AS bCanBeApproved,
			d.iDraft,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			h.iLevel,
			te.strEmail AS strCreatedByEmail,
			d.strAuthor,
			@iVersions AS iVersionsCount,
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File],
			d.iCompareToVersion	,
			d.iInternetDoc,
			d.iDeleted,
			d.iCreatedbyId,
			rel.iEmployeeId AS empApproveOnBehalfId,
			CASE WHEN rel.iEmployeeId IS NOT NULL THEN  dbo.fnOrgGetUserName(rel.iEmployeeId, '', 0) ELSE '' END AS strEmpApproveOnBehalf,
            CASE WHEN EXISTS(SELECT 1 FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS bIsLocked,
            dbo.fnOrgGetUserName((SELECT TOP 1 iEmployeeId FROM m136_tblDocumentLock WHERE iEntityId = d.iEntityId), '', 0) strLockedBy,
            iOrientation,
            CASE WHEN EXISTS (SELECT 1 FROM m136_tblCopyConfirms WHERE iEntityId = d.iEntityId) THEN 1 ELSE 0 END AS IsCopyReadingReceiptFromResponsible,
			KeyWords,
			TitleAndKeyword
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	LEFT JOIN dbo.m136_relSentEmpApproval rel 
		ON d.iEntityId = rel.iEntityId 
		AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
END
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
            mir.iPublish AS IsPublish
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

IF OBJECT_ID('[dbo].[m136_be_UpdateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateDocument] 
	@iEntityId				INT,
	@strName				VARCHAR(200),
	@RelatedAttachments		AS [dbo].[RelatedInfoTable] READONLY,
	@RelatedDocuments		AS [dbo].[RelatedInfoTable] READONLY,
	@FieldContents			AS [dbo].[FieldContent] READONLY,
	@File					[image],
	@UrlOrFileName			NVARCHAR(4000),
	@UrlOrFileProperties	NVARCHAR(4000),
	@strDescription			NVARCHAR(2000),
	@strAuthor				VARCHAR(200),
	@dtmPublish				DATETIME,
	@dtmPublishUntil		DATETIME,
	@iCompareToVersion		INT,
	@iInternetDoc			INT,
	@iHandbookId			INT,
    @iOrientation           INT,
    @KeyWords				VARCHAR(500),
    @TitleAndKeyword		VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;
	UPDATE dbo.m136_tblDocument
	SET [strName]				= @strName,
		[File]					= @File,
		[UrlOrFileName]			= @UrlOrFileName,
		[UrlOrFileProperties]	= @UrlOrFileProperties,
		[strDescription]		= @strDescription,
		[strAuthor]				= @strAuthor,
		[dtmPublish]			= convert(date,@dtmPublish),
		[dtmPublishUntil]		= convert(date,@dtmPublishUntil),
		[iCompareToVersion]		= @iCompareToVersion,
		[iInternetDoc]			= @iInternetDoc,
		[iHandbookId]			= @iHandbookId,
        [iOrientation]          = @iOrientation,
        [KeyWords]				= @KeyWords,
        [TitleAndKeyword]		= @TitleAndKeyword
	WHERE iEntityId = @iEntityId;   
	UPDATE r
		SET r.iSort = rd.iSort,
		r.iPlacementId = rd.iPlacementId,
		r.iProcessRelationTypeId = rd.iProcessRelationTypeId
	FROM dbo.m136_relInfo r INNER JOIN @RelatedDocuments rd 
		ON r.iItemId = rd.iItemId
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId = 136; -- HandbookRelationTypes.Document = 136  
    UPDATE r
		SET r.iSort = rd.iSort,
		r.iPlacementId = rd.iPlacementId,
		r.iProcessRelationTypeId = rd.iProcessRelationTypeId
	FROM dbo.m136_relInfo r INNER JOIN @RelatedAttachments rd 
		ON r.iItemId = rd.iItemId
	WHERE r.iEntityId = @iEntityId
		AND r.iRelationTypeId IN (2, 20); -- 2: attachment, 20: related attachment
	DECLARE @iDocumentTypeId INT, 
		@iMetaInfoTemplateRecordsId INT,
		@iInfoTypeId INT,
		@RichText [nvarchar](MAX),
		@Text VARCHAR(8000),
		@Number INT,
		@Date DATETIME,
        @iPublish BIT;
	SELECT @iDocumentTypeId = d.iDocumentTypeId FROM dbo.m136_tblDocument d
	WHERE d.iEntityId = @iEntityId;
	DECLARE FieldContens CURSOR FOR 
		SELECT [iMetaInfoTemplateRecordsId], [iInfoTypeId], [RichText], [Text], [Number], [Date], [iPublish]
		FROM @FieldContents;
	OPEN FieldContens; 
	FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date, @iPublish;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF (@iInfoTypeId = 1)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoNumber mtmin
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmin.iMetaInfoTemplateRecordsId
				WHERE mtmin.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmin.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmin 
				SET
					mtmin.[value] = ISNULL(@Number, 0)
				FROM dbo.m136_tblMetaInfoNumber mtmin
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmin.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmin.iEntityId = @iEntityId
				AND mtmin.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId;
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoNumberId INT;
				SELECT @iMaxiMetaInfoNumberId = MAX(mtmin.iMetaInfoNumberId) FROM dbo.m136_tblMetaInfoNumber mtmin;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoNumber ON;
				INSERT INTO dbo.m136_tblMetaInfoNumber
				(
				    iMetaInfoNumberId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoNumberId, 0) + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@Number, 0)
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoNumber OFF;
            END
		END
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoText mtmit
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmit.iMetaInfoTemplateRecordsId
				WHERE mtmit.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmit.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmit 
				SET
					mtmit.[value] = ISNULL(@Text, '')
				FROM dbo.m136_tblMetaInfoText mtmit
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmit.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmit.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mtmit.iEntityId = @iEntityId;
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoTextId INT;
				SELECT @iMaxiMetaInfoTextId = MAX(mtmit.iMetaInfoTextId) FROM dbo.m136_tblMetaInfoText mtmit;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoText ON;
				INSERT INTO dbo.m136_tblMetaInfoText
				(
				    iMetaInfoTextId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoTextId, 0) + 1),
				    @iMetaInfoTemplateRecordsId, 
				    @iEntityId, 
				    ISNULL(@Text, '')
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoText OFF;
            END
		END
		IF (@iInfoTypeId = 5)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoDate mtmid
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmid.iMetaInfoTemplateRecordsId
				WHERE mtmid.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmid.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mid 
				SET
					mid.[value] = @Date
				FROM dbo.m136_tblMetaInfoDate mid
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mid.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mid.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mid.iEntityId = @iEntityId;	
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoDateId INT;
				SELECT @iMaxiMetaInfoDateId = MAX(mtmit.iMetaInfoDateId) FROM dbo.m136_tblMetaInfoDate mtmit;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoDate ON;
				INSERT INTO dbo.m136_tblMetaInfoDate
				(
				    iMetaInfoDateId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (@iMaxiMetaInfoDateId + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@Date, GETDATE())
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoDate OFF;
            END
		END
		IF (@iInfoTypeId = 6)
		BEGIN
			IF EXISTS(SELECT * FROM dbo.m136_tblMetaInfoRichText mtmirt
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmirt.iMetaInfoTemplateRecordsId
				WHERE mtmirt.iEntityId = @iEntityId AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId)
			BEGIN
     			UPDATE mtmirt 
				SET
					mtmirt.[value] = ISNULL(@RichText, ''),
                    mtmirt.iPublish = @iPublish
				FROM dbo.m136_tblMetaInfoRichText mtmirt
				INNER JOIN dbo.m136_relDocumentTypeInfo mrdti ON mrdti.iMetaInfoTemplateRecordsId = mtmirt.iMetaInfoTemplateRecordsId
				AND mrdti.iDocumentTypeId = @iDocumentTypeId
				AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaInfoTemplateRecordsId
				AND mtmirt.iEntityId = @iEntityId;	
            END
            ELSE
            BEGIN
				DECLARE @iMaxiMetaInfoRichTextId INT;
				SELECT @iMaxiMetaInfoRichTextId = MAX(mtmirt.iMetaInfoRichTextId) FROM dbo.m136_tblMetaInfoRichText mtmirt;
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoRichText ON;
				INSERT INTO dbo.m136_tblMetaInfoRichText
				(
				    iMetaInfoRichTextId,
				    iMetaInfoTemplateRecordsId,
				    iEntityId,
				    [value]
				)
				VALUES
				(
				    (ISNULL(@iMaxiMetaInfoRichTextId, 0) + 1),
				    @iMetaInfoTemplateRecordsId,
				    @iEntityId,
				    ISNULL(@RichText, '')
				)
				SET IDENTITY_INSERT dbo.m136_tblMetaInfoRichText OFF;
            END
		END
		FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date, @iPublish;
    END
    CLOSE FieldContens;
	DEALLOCATE FieldContens;	
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateContentFields]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateContentFields] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateContentFields] 
	@iOldEntityId INT,
	@iNewEntityId INT,
	@iDocumentTypeId INT
AS
BEGIN
	SET NOCOUNT ON;

	DELETE FROM [dbo].m136_tblMetaInfoRichText WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoText WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoNumber WHERE iEntityId = @iNewEntityId;
	DELETE FROM [dbo].m136_tblMetaInfoDate WHERE iEntityId = @iNewEntityId;
	
	DECLARE @iMetaRecordId INT, 
		@iInfoTypeId INT, 
		@DefaultTextValue VARCHAR(7000), 
		@DefaultDateValue DATETIME, 
		@DefaultIntValue INT;
		
	DECLARE Fields CURSOR FOR 
		SELECT DISTINCT 
		    mi.iMetaInfoTemplateRecordsId, 
			mi.iInfoTypeId, 
			mi.DefaultTextValue, 
			mi.DefaultDateValue, 
			mi.DefaultIntValue
		FROM [dbo].m136_tblMetaInfoTemplateRecords mi 
		JOIN [dbo].m136_relDocumentTypeInfo r ON r.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId 
			AND r.iDocumentTypeId = @iDocumentTypeId;
			
	OPEN Fields; 
	FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF (@iInfoTypeId = 1)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoNumber
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultIntValue)
			FROM dbo.m136_tblMetaInfoNumber mtmin 
				WHERE mtmin.iEntityId = @iOldEntityId AND mtmin.iMetaInfoTemplateRecordsId = @iMetaRecordId;		
		END
		
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			)
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultTextValue)
			FROM dbo.m136_tblMetaInfoText mtmit 
				WHERE mtmit.iEntityId = @iOldEntityId AND mtmit.iMetaInfoTemplateRecordsId = @iMetaRecordId; 	
		END
		
		IF (@iInfoTypeId = 5)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoDate
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultDateValue) 
			FROM dbo.m136_tblMetaInfoDate mtmid 
				WHERE mtmid.iEntityId = @iOldEntityId AND mtmid.iMetaInfoTemplateRecordsId = @iMetaRecordId;	
		END
		
		IF (@iInfoTypeId = 6)
		BEGIN
			INSERT INTO [dbo].m136_tblMetaInfoRichText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value],
                iPublish
			) 
			SELECT @iMetaRecordId, 
				@iNewEntityId, 
				ISNULL([Value], @DefaultTextValue),
                iPublish
			FROM dbo.m136_tblMetaInfoRichText mtmirt 
				WHERE mtmirt.iEntityId = @iOldEntityId AND mtmirt.iMetaInfoTemplateRecordsId = @iMetaRecordId;		
		END
		FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
    END
    
    CLOSE Fields;
	DEALLOCATE Fields;
END
GO

IF OBJECT_ID('[dbo].[m136_be_PublishDocumentToInternet]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_PublishDocumentToInternet] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_PublishDocumentToInternet] 
	@EntityId INT,
    @FieldContents AS [dbo].[FieldContent] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            UPDATE m136_tblDocument
            SET iInternetDoc = 1
            WHERE iEntityId = @EntityId

            UPDATE mirt
            SET
                mirt.iPublish = fc.iPublish
            FROM
                dbo.m136_tblMetaInfoRichText mirt
                    INNER JOIN @FieldContents fc
                        ON mirt.iMetaInfoTemplateRecordsId = fc.iMetaInfoTemplateRecordsId
            WHERE mirt.iEntityId = @EntityId
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK
        DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
        SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ApproveDocument]
    @UserId INT,
    @EntityId INT,
    @TransferReadingReceipts BIT,
    @PublishFrom DATETIME,
    @PublishUntil DATETIME,
    @IsInternetDocument BIT,
    @FieldContents AS [dbo].[FieldContent] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            DECLARE @FullName NVARCHAR(100);
            
            SELECT
                @DocumentId = iDocumentId
            FROM
                m136_tblDocument
            WHERE
                iEntityId = @EntityId
            
            SELECT
                @FullName = strFirstName + ' ' + strLastName
            FROM
                tblEmployee
            WHERE
                iEmployeeId = @UserId
            
            IF @TransferReadingReceipts = 1
            BEGIN
                EXEC m136_doCopyConfirms @DocumentId
            END
            ELSE
            BEGIN
                EXEC m136_SetCopyConfirms @DocumentId, 0
            END

            UPDATE
                m136_tblDocument
            SET
                iApproved = 1,
                iApprovedById = @UserId,
                dtmApproved = GETDATE(),
                strApprovedBy = @FullName,
                dtmPublish = @PublishFrom,
                dtmPublishUntil = @PublishUntil,
                iInternetDoc = @isInternetDocument,
                iReceiptsCopied = @TransferReadingReceipts
            WHERE
                iDocumentId = @DocumentId
                AND iLatestVersion = 1
                
            UPDATE mirt
            SET
                mirt.iPublish = fc.iPublish
            FROM
                dbo.m136_tblMetaInfoRichText mirt
                    INNER JOIN @FieldContents fc
                        ON mirt.iMetaInfoTemplateRecordsId = fc.iMetaInfoTemplateRecordsId
            WHERE mirt.iEntityId = @EntityId
            
            EXEC m136_insertEntityIntoTextIndex @EntityId
                
            EXEC dbo.m136_SetVersionFlags @DocumentId
            
            INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateNewDocumentVersion]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateNewDocumentVersion] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_CreateNewDocumentVersion]
    @iCreatedById    INT,
    @iEntityId       INT,
    @iDocumentId     INT
AS
BEGIN
	DECLARE @NewEntityId INT, @iExistEntityId INT;
	DECLARE @MaxEntityId INT, @MaxVersion INT;
	SELECT @MaxEntityId = MAX(mtd.iEntityId) FROM dbo.m136_tblDocument mtd;
	SELECT @MaxVersion = MAX(mtd.iVersion) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId = @iDocumentId;
	SET @NewEntityId = ISNULL(@MaxEntityId, 0) + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
								  )
	SELECT						   @NewEntityId,[iDocumentId],(ISNULL(@MaxVersion, 0) + 1),[iDocumentTypeId],[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',convert(date,[dtmPublish]),convert(date,[dtmPublishUntil]),0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
    
    INSERT INTO 
        [dbo].m136_tblMetaInfoRichText
            (iMetaInfoTemplateRecordsId, iEntityId, [value], iPublish) 
    SELECT mirt.iMetaInfoTemplateRecordsId, 
		@NewEntityId, 
		mirt.value,
        mirt.iPublish
	FROM dbo.m136_tblMetaInfoRichText mirt 
	WHERE mirt.iEntityId = @iEntityId
    
	SELECT @NewEntityId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_CreateDocument] 
	@HandbookId   INT,
	@TemplateId   INT,
	@DocumentType  INT,
	@CreatorId   INT,
	@AllowOffline  BIT,
	@Title    NVARCHAR(MAX),
	@Publish   DATETIME,
	@PublishUntil  DATETIME
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iMaxDocumentId INT = 0, @iMaxEntityId INT = 0, @Sort INT, @LevelType INT;
	SELECT @LevelType = iLevelType FROM dbo.m136_tblHandbook WHERE iHandbookId = @HandbookId
	SELECT @iMaxDocumentId = MAX(iDocumentId) FROM dbo.m136_tblDocument;
	DECLARE @iNewDocumentId INT = ISNULL(@iMaxDocumentId, 0) + 1;
	SELECT @iMaxEntityId = MAX(iEntityId) FROM dbo.m136_tblDocument;
	DECLARE @iNewEntityId INT = ISNULL(@iMaxEntityId, 0) + 1;
	
    SELECT @Sort = ISNULL(MAX(iSort) + 1, 0) FROM (SELECT 0 iSort
    FROM dbo.m136_tblDocument d
    WHERE
        d.iHandbookId = @HandbookId AND d.iDeleted = 0
        AND d.iLatestVersion = 1
	
    UNION all
	
    SELECT 1 iSort
	FROM dbo.m136_tblDocument d
	WHERE d.iLatestVersion = 1) Temp
    
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	INSERT INTO dbo.m136_tblDocument
        (iEntityId, iDocumentId, iVersion, iDocumentTypeId, iHandbookId, strName, strDescription, iCreatedbyId, dtmCreated,
        strAuthor, iAlterId, dtmAlter, strAlterer, iApprovedById, strApprovedBy, iStatus, iSort, iDeleted, iApproved,
        iDraft, iLevelType, strHash, iReadCount, iLatestVersion, iLatestApproved, dtmPublish, dtmPublishUntil, iInternetDoc) 
    VALUES
        (@iNewEntityId, @iNewDocumentId, 1, @TemplateId, @HandbookId, @Title, '', @CreatorId, GETDATE(),
        '', @CreatorId, GETDATE(), [dbo].[fnOrgGetUserName] (@CreatorId, 'System', 0), 0, '', 0, @Sort, 0, 0,
        1, @LevelType, '', 0, 1, 0, convert(date,@Publish), convert(date,@PublishUntil), 0);
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
    
    INSERT INTO dbo.m136_tblMetaInfoRichText
        (iMetaInfoTemplateRecordsId, iEntityId, [Value], iPublish)
    SELECT
        rdi.iMetaInfoTemplateRecordsId, @iNewEntityId, '', rdi.iPublish
    FROM
        m136_relDocumentTypeInfo rdi
            INNER JOIN m136_tblMetaInfoTemplateRecords mitr
                ON rdi.iMetaInfoTemplateRecordsId = mitr.iMetaInfoTemplateRecordsId
    WHERE
        rdi.iDocumentTypeId = @TemplateId
        AND mitr.iInfoTypeId = 6
    
	SELECT @iNewDocumentId;
END
GO