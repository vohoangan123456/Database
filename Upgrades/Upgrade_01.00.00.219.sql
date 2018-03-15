INSERT INTO #Description VALUES('Create SP for function Change document draft template')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateContentFieldsOfChangeTemplateDraft]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateContentFieldsOfChangeTemplateDraft] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateContentFieldsOfChangeTemplateDraft] 
	@MetaInfoIds AS [dbo].[Item] READONLY,
	@EntityId INT,
	@iDocumentTypeId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @tblMetaInfoNumber AS TABLE(iMetaInfoTemplateRecordsId INT, iEntityId INT, value INT)
	DECLARE @tblMetaInfoText AS TABLE(iMetaInfoTemplateRecordsId INT, iEntityId INT, value VARCHAR(8000))
	DECLARE @tblMetaInfoRichText AS TABLE(iMetaInfoTemplateRecordsId INT, iEntityId INT, value NTEXT)
	DECLARE @tblMetaInfoDate AS TABLE(iMetaInfoTemplateRecordsId INT, iEntityId INT, value DATETIME)
	
	INSERT INTO @tblMetaInfoNumber (iMetaInfoTemplateRecordsId, iEntityId, value)
		SELECT iMetaInfoTemplateRecordsId, iEntityId, value 
		FROM [dbo].m136_tblMetaInfoNumber 
		WHERE iEntityId = @EntityId;
	INSERT INTO @tblMetaInfoText (iMetaInfoTemplateRecordsId, iEntityId, value)
		SELECT iMetaInfoTemplateRecordsId, iEntityId, value 
		FROM [dbo].m136_tblMetaInfoText 
		WHERE iEntityId = @EntityId;
	
	INSERT INTO @tblMetaInfoRichText (iMetaInfoTemplateRecordsId, iEntityId, value)
		SELECT iMetaInfoTemplateRecordsId, iEntityId, value 
		FROM [dbo].m136_tblMetaInfoRichText 
		WHERE iEntityId = @EntityId;
		
	INSERT INTO @tblMetaInfoDate (iMetaInfoTemplateRecordsId, iEntityId, value)
		SELECT iMetaInfoTemplateRecordsId, iEntityId, value 
		FROM [dbo].m136_tblMetaInfoDate 
		WHERE iEntityId = @EntityId;
	
	DELETE FROM [dbo].m136_tblMetaInfoRichText WHERE iEntityId = @EntityId;
	DELETE FROM [dbo].m136_tblMetaInfoText WHERE iEntityId = @EntityId;
	DELETE FROM [dbo].m136_tblMetaInfoNumber WHERE iEntityId = @EntityId;
	DELETE FROM [dbo].m136_tblMetaInfoDate WHERE iEntityId = @EntityId;
	
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
				   @EntityId, 
				   ISNULL(temp.[Value], @DefaultIntValue)
			FROM
			(SELECT TOP(1)
				  mtmin.[Value]
			FROM @tblMetaInfoNumber mtmin 
			JOIN @MetaInfoIds me ON me.Id = mtmin.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmin.iEntityId = @EntityId) AS temp;
		END
		IF (@iInfoTypeId = 2 OR @iInfoTypeId = 3 OR @iInfoTypeId = 4)
		BEGIN
			DECLARE @ResultText VARCHAR(8000) = ''
			DECLARE @tempValue	VARCHAR(8000) = ''
			DECLARE curvalue CURSOR FOR
			SELECT
				mtmit.[Value]
			FROM @tblMetaInfoText mtmit 
			JOIN @MetaInfoIds me ON me.Id = mtmit.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmit.iEntityId = @EntityId; 	
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
			VALUES(@iMetaRecordId, @EntityId,ISNULL(@ResultText, @DefaultTextValue))
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
				@EntityId, 
				ISNULL(temp.[Value], @DefaultDateValue) 
			FROM
				(SELECT TOP(1)
					mtmid.[Value]
					FROM @tblMetaInfoDate mtmid
					JOIN @MetaInfoIds me ON me.Id = mtmid.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
					WHERE mtmid.iEntityId = @EntityId) temp; 
		END
		IF (@iInfoTypeId = 6)
		BEGIN
			DECLARE @ResultRichText NVARCHAR(MAX) = ''
			DECLARE @tempRichValue	NVARCHAR(MAX) = ''
			DECLARE curval CURSOR FOR
			SELECT
				mtmirt.[Value]
			FROM @tblMetaInfoRichText mtmirt 
			JOIN @MetaInfoIds me ON me.Id = mtmirt.iMetaInfoTemplateRecordsId AND me.Value = @iMetaRecordId
				WHERE mtmirt.iEntityId = @EntityId 
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
			VALUES(@iMetaRecordId, @EntityId,ISNULL(@ResultRichText, @DefaultTextValue))
		END
		FETCH NEXT FROM Fields INTO @iMetaRecordId, @iInfoTypeId, @DefaultTextValue, @DefaultDateValue, @DefaultIntValue;
    END
    CLOSE Fields;
	DEALLOCATE Fields;
END
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentDraftTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentDraftTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentDraftTemplate] 
	@DocumentId AS INT,
	@ToDocumentTypeId AS INT,
	@MetaInfoIds AS [dbo].[Item] READONLY
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
			DECLARE @EntityId INT
			SELECT @EntityId = iEntityId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @DocumentId 
				  AND iLatestVersion = 1
				  AND iDraft = 1
				  
			IF @EntityId IS NOT NULL 
            BEGIN
				UPDATE m136_tblDocument set iDocumentTypeId = @ToDocumentTypeId
				WHERE iEntityId = @EntityId
					
                EXEC [dbo].[m136_be_UpdateContentFieldsOfChangeTemplateDraft] @MetaInfoIds, @EntityId, @ToDocumentTypeId
            END
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
		COMMIT TRANSACTION;
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