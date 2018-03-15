INSERT INTO #Description VALUES('Modify existing procedures to allow administrator set printing orientation of document.')
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(N'dbo.m136_tblDocument') AND name = 'iOrientation'
)
BEGIN
    ALTER TABLE dbo.m136_tblDocument
	ADD iOrientation INT NOT NULL DEFAULT(1)
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
            iOrientation
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

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
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
			d.iDraft, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			d.strAuthor,
			d.strAlterer,
			d.dtmApproved,
			d.iLatestVersion,
            d.iOrientation
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestApproved = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByEntityId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformationByEntityId] 
	@EntityId INT = NULL
AS
BEGIN
	DECLARE @iVersions INT;
	SELECT @iVersions = COUNT(1) FROM dbo.m136_tblDocument mtd WHERE mtd.iDocumentId IN 
		(SELECT iDocumentId FROM dbo.m136_tblDocument mtd2 WHERE mtd2.iEntityId = @EntityId);
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
            iOrientation
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	LEFT JOIN dbo.m136_relSentEmpApproval rel 
		ON d.iEntityId = rel.iEntityId 
		AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId) 
	WHERE	d.iEntityId = @EntityId;
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
    @iOrientation           INT
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
		[dtmPublish]			= @dtmPublish,
		[dtmPublishUntil]		= @dtmPublishUntil,
		[iCompareToVersion]		= @iCompareToVersion,
		[iInternetDoc]			= @iInternetDoc,
		[iHandbookId]			= @iHandbookId,
        [iOrientation]          = @iOrientation
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
		@Date DATETIME;
	SELECT @iDocumentTypeId = d.iDocumentTypeId FROM dbo.m136_tblDocument d
	WHERE d.iEntityId = @iEntityId;
	DECLARE FieldContens CURSOR FOR 
		SELECT [iMetaInfoTemplateRecordsId], [iInfoTypeId], [RichText], [Text], [Number], [Date]
		FROM @FieldContents;
	OPEN FieldContens; 
	FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date;
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
					mtmirt.[value] = ISNULL(@RichText, '')
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
		FETCH NEXT FROM FieldContens INTO @iMetaInfoTemplateRecordsId, @iInfoTypeId, @RichText, @Text, @Number, @Date;
    END
    CLOSE FieldContens;
	DEALLOCATE FieldContens;	
END
GO