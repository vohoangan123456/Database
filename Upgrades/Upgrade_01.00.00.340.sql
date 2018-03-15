INSERT INTO #Description VALUES ('Update SP for document keywords')
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'KeyWords'
      AND Object_ID = Object_ID(N'dbo.m136_tblDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblDocument ADD KeyWords VARCHAR(500);
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'TitleAndKeyword'
      AND Object_ID = Object_ID(N'dbo.m136_tblDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblDocument ADD TitleAndKeyword VARCHAR(1000);
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'TitleAndKeywordReversed'
      AND Object_ID = Object_ID(N'dbo.m136_tblDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblDocument ADD TitleAndKeywordReversed VARCHAR(1000); 
END
GO


UPDATE dbo.m136_tblDocument
	SET TitleAndKeyword = strName
WHERE TitleAndKeyword IS NULL
GO

UPDATE dbo.m136_tblDocument
	SET TitleAndKeywordReversed = strNameReversed
WHERE TitleAndKeywordReversed IS NULL
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
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	SELECT @NewEntityId;
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
		[dtmPublish]			= @dtmPublish,
		[dtmPublishUntil]		= @dtmPublishUntil,
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

IF OBJECT_ID('[dbo].[m136_be_UpdateDocumentTitle]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDocumentTitle] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateDocumentTitle] 
	-- Add the parameters for the stored procedure here
	@iEntityId int = 0,
	@strTitle nvarchar(200)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE [dbo].[m136_tblDocument]
        SET strName = @strTitle
        WHERE iEntityId = @iEntityId
    
    DECLARE @KeyWords VARCHAR(500)
    SELECT @KeyWords = KeyWords
    FROM dbo.m136_tblDocument
    WHERE iEntityId = @iEntityId
    
    DECLARE @TitleAndKeyword VARCHAR(1000)
    SET @TitleAndKeyword = @strTitle
    
    IF @KeyWords IS NOT NULL AND @KeyWords != ''
    BEGIN
		SET @TitleAndKeyword = @TitleAndKeyword + ' ' + REPLACE(@KeyWords,';',' '); 
    END
    
    UPDATE [dbo].[m136_tblDocument]
        SET TitleAndKeyword = @TitleAndKeyword
        WHERE iEntityId = @iEntityId
    
    DECLARE @DocumentId INT
    SELECT @DocumentId = idocumentId
    FROM dbo.m136_tblDocument
    WHERE iEntityId = @iEntityId
    IF(@DocumentId IS NOT NULL)
    BEGIN
		INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
		VALUES (11, @DocumentId);
	END
END
GO

IF EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'[dbo].[DocumentNameAndDescriptionReversal]'))
	DROP TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
GO

CREATE TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
   ON  [dbo].[m136_tblDocument]
   AFTER UPDATE, INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for trigger here
	IF UPDATE (strName) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET strNameReversed = REVERSE(D.strName)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
    IF UPDATE (strDescription) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET strDescriptionReversed = REVERSE(D.strDescription)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
    
    IF UPDATE (TitleAndKeyword) 
    begin
        UPDATE [dbo].[m136_tblDocument] 
        SET TitleAndKeywordReversed = REVERSE(D.TitleAndKeyword)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateNewDocumentVersionWithDocumetTypeId]
    @iCreatedById    INT,
    @iEntityId       INT,
    @iDocumentId     INT,
    @iDocumentTypeId INT
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
	SELECT						   @NewEntityId,[iDocumentId],(ISNULL(@MaxVersion, 0) + 1),@iDocumentTypeId,[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	RETURN @NewEntityId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_CopyDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CopyDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: April 14, 2016
-- Description:	Copy Document
-- Modified: add transaction
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_CopyDocument] 
	@DocumentId AS INT,
	@DocumentName AS VARCHAR(200),
	@FolderId AS INT,
	@UserId AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
			DECLARE @iDocumentId INT

			DECLARE @NewEntityId INT
			DECLARE @OldEntityId INT
			DECLARE @DocumentTypeId INT
			
			SELECT @OldEntityId = iEntityId,
				   @DocumentTypeId = iDocumentTypeId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @DocumentId 
				  AND iLatestVersion = 1
			
			DECLARE @MaxEntityId INT;
			SELECT @MaxEntityId = MAX(mtd.iEntityId) FROM dbo.m136_tblDocument mtd;
			SET @NewEntityId = ISNULL(@MaxEntityId,0) + 1;
			DECLARE @CurrentDate DATETIME = GETDATE();
			
			SET NOCOUNT ON;
			DECLARE @iMaxDocumentId INT = 0, @iMaxEntityId INT = 0, @Sort INT, @LevelType INT;
			SELECT @LevelType = iLevelType FROM dbo.m136_tblHandbook WHERE iHandbookId = @FolderId
			SELECT @iMaxDocumentId = MAX(iDocumentId) FROM dbo.m136_tblDocument;
			DECLARE @iNewDocumentId INT = ISNULL(@iMaxDocumentId,0) + 1;
			
			SELECT @Sort = ISNULL(MAX(iSort) + 1, 0) FROM (SELECT 0 iSort
					FROM dbo.m136_tblDocument d
					WHERE d.iHandbookId = @FolderId AND d.iDeleted = 0
					AND d.iLatestVersion = 1
				UNION all
					SELECT 1 iSort
					FROM dbo.m136_tblDocument d
					WHERE d.iLatestVersion = 1) Temp
					
			SET IDENTITY_INSERT dbo.m136_tblDocument ON;
			INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
								  )
			SELECT				  @NewEntityId,@iNewDocumentId, 0 ,[iDocumentTypeId],@FolderId,@DocumentName,[strDescription],@UserId,@CurrentDate,[strAuthor]
								  ,@UserId,@CurrentDate,[dbo].fnOrgGetUserName(@UserId, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,@Sort
								  ,0,0,1,@LevelType,[strHash],0,0,[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed],[KeyWords],[TitleAndKeyword],[TitleAndKeywordReversed]
			FROM		dbo.m136_tblDocument d
			WHERE		iEntityId = @OldEntityId; 
			SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
			
			EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
			EXEC [dbo].[m136_be_UpdateContentFields] @OldEntityId, @NewEntityId, @DocumentTypeId
			
			EXEC dbo.m136_SetVersionFlags @iNewDocumentId
			
			SELECT @iNewDocumentId
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateKeywordsForDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateKeywordsForDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateKeywordsForDocument] 
	@DocumentId AS INT,
	@KeyWords AS VARCHAR(500)
AS
BEGIN
	DECLARE @Title VARCHAR(200), @TitleAndKeyword VARCHAR(1000)
	
	SELECT @Title = strName
	FROM dbo.m136_tblDocument
	WHERE iDocumentId = @DocumentId
		  AND iLatestVersion = 1
		  
	SET @TitleAndKeyword = @Title
	
	IF @KeyWords IS NOT NULL AND @KeyWords != ''
    BEGIN
		SET @TitleAndKeyword = @TitleAndKeyword + ' ' + REPLACE(@KeyWords,';',' '); 
    END
    
    UPDATE [dbo].[m136_tblDocument]
    SET TitleAndKeyword = @TitleAndKeyword, KeyWords = @KeyWords
	WHERE iDocumentId = @DocumentId
		  AND iLatestVersion = 1
    
END
GO
INSERT INTO dbo. SchemaChanges
VALUES('01','00', '00', '340','Upgrade_01.00.00.340.sql', 'Update SP for document keywords')

COMMIT TRANSACTION ;

GO
-- Clean up.  
SET IMPLICIT_TRANSACTIONS OFF;
GO
DECLARE @IsTitleAndKeywordIndex INT;
SELECT @IsTitleAndKeywordIndex = COLUMNPROPERTY(OBJECT_ID('dbo.m136_tblDocument'), 'TitleAndKeyword', 'IsFulltextIndexed')
IF (@IsTitleAndKeywordIndex <> 1)
  ALTER FULLTEXT INDEX ON dbo.m136_tblDocument ADD ([TitleAndKeyword])
GO
 
DECLARE @TitleAndKeywordReversedIndex INT;
SELECT @TitleAndKeywordReversedIndex = COLUMNPROPERTY(OBJECT_ID('dbo.m136_tblDocument'), 'TitleAndKeywordReversed', 'IsFulltextIndexed')
IF (@TitleAndKeywordReversedIndex <> 1)
  ALTER FULLTEXT INDEX ON dbo.m136_tblDocument ADD ([TitleAndKeywordReversed])

GO  


