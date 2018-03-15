INSERT INTO #Description VALUES('Modify procedure [dbo].[m136_be_CreateNewDocumentVersion]')
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
	
	SET @NewEntityId = @MaxEntityId + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	
	INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed]
								  )
	SELECT						   @NewEntityId,[iDocumentId],(@MaxVersion + 1),[iDocumentTypeId],[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	
	SELECT @NewEntityId;
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
	
	SET @NewEntityId = @MaxEntityId + 1;
	DECLARE @CurrentDate DATETIME = GETDATE();
	
	UPDATE dbo.m136_tblDocument
	SET
	    dbo.m136_tblDocument.iLatestVersion = 0
	WHERE iDocumentId = @iDocumentId;
	
	SET IDENTITY_INSERT dbo.m136_tblDocument ON;
	
	INSERT INTO	dbo.m136_tblDocument( [iEntityId],[iDocumentId],[iVersion],[iDocumentTypeId],[iHandbookId],[strName],[strDescription],[iCreatedbyId],[dtmCreated],[strAuthor]
								  ,[iAlterId],[dtmAlter],[strAlterer],[iApprovedById],[dtmApproved],[strApprovedBy],[dtmPublish],[dtmPublishUntil],[iStatus],[iSort]
								  ,[iDeleted],[iApproved],[iDraft],[iLevelType],[strHash],[iReadCount],[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,[iLatestVersion],[iInternetDoc],[strNameReversed],[strDescriptionReversed]
								  )
	SELECT						   @NewEntityId,[iDocumentId],(@MaxVersion + 1),@iDocumentTypeId,[iHandbookId],[strName],[strDescription],@iCreatedById,@CurrentDate,[strAuthor]
								  ,@iCreatedById,@CurrentDate,[dbo].fnOrgGetUserName(@iCreatedById, '', 0),0,null,'',[dtmPublish],[dtmPublishUntil],0,[iSort]
								  ,[iDeleted],0,1,[iLevelType],[strHash],0,[iCompareToVersion],[File],[UrlOrFileName],[UrlOrFileProperties]
								  ,1,[iInternetDoc],[strNameReversed],[strDescriptionReversed]
	FROM		dbo.m136_tblDocument d
	WHERE		iEntityId = @iEntityId; 								  
	
	SET IDENTITY_INSERT dbo.m136_tblDocument OFF;
	
	RETURN @NewEntityId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateContentFieldsOfChangeTemplate]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateContentFieldsOfChangeTemplate]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateContentFieldsOfChangeTemplate] 
	@MetaInfoIds AS [dbo].[Item] READONLY,
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
				   ISNULL(temp.[Value], @DefaultIntValue)
			FROM
			(SELECT TOP(1)
				  mtmin.[Value]
			FROM dbo.m136_tblMetaInfoNumber mtmin 
			JOIN @MetaInfoIds me ON me.Id = mtmin.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmin.iEntityId = @iOldEntityId) AS temp;
		END
		
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			DECLARE @ResultText VARCHAR(8000) = ''
			DECLARE @tempValue	VARCHAR(8000) = ''
			DECLARE curvalue CURSOR FOR
			SELECT
				mtmit.[Value]
			FROM dbo.m136_tblMetaInfoText mtmit 
			JOIN @MetaInfoIds me ON me.Id = mtmit.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmit.iEntityId = @iOldEntityId; 	
			
			OPEN curvalue; 
			FETCH NEXT FROM curvalue INTO @tempValue;
			WHILE @@FETCH_STATUS = 0
				BEGIN	
					IF @ResultText = '' OR @ResultText IS NULL
						BEGIN
							IF @tempValue IS NOT NULL
								SET @ResultText = @tempValue;
						END
					ELSE
						BEGIN
							IF @tempValue IS NOT NULL
								SET @ResultText = @ResultText + '\n' + @tempValue;
						END
				FETCH NEXT FROM curvalue INTO @tempValue;
				END
			CLOSE curvalue;
			DEALLOCATE curvalue;
			
			INSERT INTO [dbo].m136_tblMetaInfoText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			)
			VALUES(@iMetaRecordId, @iNewEntityId,ISNULL(@ResultText, @DefaultTextValue))
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
				ISNULL(temp.[Value], @DefaultDateValue) 
			FROM
				(SELECT TOP(1)
					mtmid.[Value]
					FROM dbo.m136_tblMetaInfoDate mtmid
					JOIN @MetaInfoIds me ON me.Id = mtmid.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
					WHERE mtmid.iEntityId = @iOldEntityId) temp; 
		END
		
		IF (@iInfoTypeId = 6)
		BEGIN
			DECLARE @ResultRichText NVARCHAR(MAX) = ''
			DECLARE @tempRichValue	NVARCHAR(MAX) = ''
			DECLARE curval CURSOR FOR
			SELECT
				mtmirt.[Value]
			FROM dbo.m136_tblMetaInfoRichText mtmirt 
			JOIN @MetaInfoIds me ON me.Id = mtmirt.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmirt.iEntityId = @iOldEntityId 
				
			OPEN curval; 
			FETCH NEXT FROM curval INTO @tempRichValue;
			WHILE @@FETCH_STATUS = 0
				BEGIN	
					IF @ResultRichText = '' OR @ResultRichText IS NULL
						BEGIN
							IF @tempRichValue IS NOT NULL
								SET @ResultRichText = @tempRichValue;
						END
					ELSE
						BEGIN
							IF @tempRichValue IS NOT NULL
								SET @ResultRichText = @ResultRichText + '<p></p>' + @tempRichValue;
						END
				FETCH NEXT FROM curval INTO @tempRichValue;
				END
			CLOSE curval;
			DEALLOCATE curval;
			
			INSERT INTO [dbo].m136_tblMetaInfoRichText
			(
				iMetaInfoTemplateRecordsId, 
				iEntityId, 
				[value]
			)
			VALUES(@iMetaRecordId, @iNewEntityId,ISNULL(@ResultRichText, @DefaultTextValue))
			
		END
		FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
    END
    CLOSE Fields;
	DEALLOCATE Fields;
END

GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentTemplate]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentTemplate]  AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: Nov 26, 2015
-- Description:	Change document template 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentTemplate] 
	@DocumentId AS INT,
	@ToDocumentTypeId AS INT,
	@MetaInfoIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
			DECLARE @iDocumentId INT
			DECLARE @NewEntityId INT
			DECLARE @OldEntityId INT
						
			SELECT @OldEntityId = iEntityId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @DocumentId 
				  AND iLatestVersion = 1
				  AND iApproved = 1
				  
			IF @OldEntityId IS NOT NULL 
				BEGIN
					EXEC @NewEntityId = dbo.m136_be_CreateNewDocumentVersionWithDocumetTypeId @UserId, @OldEntityId, @DocumentId, @ToDocumentTypeId;
					
					IF @NewEntityId IS NOT NULL AND @NewEntityId != 0
					BEGIN
						EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
						EXEC [dbo].[m136_be_UpdateContentFieldsOfChangeTemplate] @MetaInfoIds, @OldEntityId, @NewEntityId, @ToDocumentTypeId
					END
				END
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
	END CATCH
END
GO