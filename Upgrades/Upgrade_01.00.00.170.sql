INSERT INTO #Description VALUES('Modify procedure and raiser error')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateRelatedInfo]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateRelatedInfo] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: 23 SEP, 2015
-- Description:	Update related information.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateRelatedInfo] 
	@iOldEntityId INT,
	@iEntityId INT,
	@EnforceStrictVersionPolicyOnAttachments BIT
AS
BEGIN
	SET NOCOUNT ON;
	
	-- For related internal attachments.
	DECLARE @iRelationTypeId INT = 20;
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId 
											AND iRelationTypeId = @iRelationTypeId;
    
    INSERT INTO dbo.m136_relInfo
    (
        iEntityId,
        iItemId,
        iPlacementId,
        iSort,
        iRelationTypeId,
        iNewWindow,
        iProcessRelationTypeId
    )
    SELECT @iEntityId, 
		mri.iItemId, 
		mri.iPlacementId, 
		mri.iSort, 
		@iRelationTypeId, 
		mri.iNewWindow, 
		mri.iProcessRelationTypeId 
    FROM dbo.m136_relInfo mri 
    WHERE mri.iEntityId = @iOldEntityId 
		AND mri.iRelationTypeId = @iRelationTypeId;
    
    UPDATE dbo.m136_tblBlob
    SET
        bInUse = 1
    WHERE iItemId IN (SELECT mri.iItemId FROM dbo.m136_relInfo mri 
		WHERE mri.iEntityId = @iEntityId AND mri.iRelationTypeId = @iRelationTypeId);
    
    
    --For related documents
    SET @iRelationTypeId = 136;
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId
											AND iRelationTypeId = @iRelationTypeId;
    
    INSERT INTO dbo.m136_relInfo
    (
        iEntityId,
        iItemId,
        iPlacementId,
        iSort,
        iRelationTypeId,
        iNewWindow,
        iProcessRelationTypeId
    )
    SELECT @iEntityId, 
		mri.iItemId, 
		mri.iPlacementId, 
		mri.iSort, 
		@iRelationTypeId, 
		mri.iNewWindow, 
		mri.iProcessRelationTypeId 
    FROM dbo.m136_relInfo mri	
    WHERE mri.iEntityId = @iOldEntityId 
		AND mri.iRelationTypeId = @iRelationTypeId;
    
    
    -- For images and internal images
    DELETE FROM [dbo].[m136_relInfo] WHERE iEntityId = @iEntityId
											AND (iRelationTypeId = 5 OR @iRelationTypeId = 50);
	INSERT INTO [dbo].m136_relInfo(
		iEntityId, 
		iItemId, 
		iRelationTypeId, 
		iSort, 
		iNewWindow, 
		iScaleDirId, 
		iSize, 
		iVJustifyId, 
		iHJustifyId, 
		strCaption, 
		strURL, 
		iWidth, 
		iHeight,
		iThumbWidth, 
		iThumbHeight,
		iPlacementId,
		iProcessRelationTypeId)
	SELECT @iEntityId, 
		mri.iItemId, 
		(CASE WHEN @EnforceStrictVersionPolicyOnAttachments = 1 THEN 50
		ELSE 5 END), 
		mri.iSort, 
		mri.iNewWindow, 
		mri.iScaleDirId, 
		mri.iSize, 
		mri.iVJustifyId, 
		mri.iHJustifyId, 
		mri.strCaption,
		mri.strURL,
		mri.iWidth,
		mri.iHeight,
		mri.iThumbWidth,
		mri.iThumbHeight,
		mri.iPlacementId,
		mri.iProcessRelationTypeId		
	FROM dbo.m136_relInfo mri
	WHERE mri.iEntityId = @iOldEntityId 
		AND ((mri.iRelationTypeId = 5 AND @EnforceStrictVersionPolicyOnAttachments = 0) 
		     OR (mri.iRelationTypeId = 50 AND @EnforceStrictVersionPolicyOnAttachments = 1));
		
	IF (@EnforceStrictVersionPolicyOnAttachments = 1)
	BEGIN
		-- For internal images 
		UPDATE dbo.m136_tblBlob
		SET
		    bInUse = 1
		WHERE iItemId IN (SELECT mri.iItemId FROM dbo.m136_relInfo mri 
		WHERE mri.iEntityId = @iEntityId AND mri.iRelationTypeId = 50);
	END
END
GO

IF OBJECT_ID('[dbo].[m136_be_ReopenDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ReopenDocument] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: Nov 18, 2015
-- Description:	Reopen document after document is archived
-- Modified: add transaction
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ReopenDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
			DECLARE @iDocumentId INT
			DECLARE @Description VARCHAR(2000)
			DECLARE @LogDescription VARCHAR(2000)
			DECLARE @NewEntityId INT
			DECLARE @OldEntityId INT
			DECLARE @Version INT
			DECLARE @DocumentTypeId INT
			DECLARE curDocumentId CURSOR FOR 
				SELECT Id
				FROM @DocumentIds;
			OPEN curDocumentId; 
			FETCH NEXT FROM curDocumentId INTO @iDocumentId;
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SELECT @OldEntityId = iEntityId,
					   @Description = strDescription,
					   @Version = iVersion,
					   @DocumentTypeId = iDocumentTypeId
				FROM dbo.m136_tblDocument
				WHERE iDocumentId = @iDocumentId 
					  AND iLatestVersion = 1
				SELECT @LogDescription = [Description]
				FROM dbo.tblEventlog
				WHERE DocumentId = @iDocumentId
					  AND [Version] = @Version
					  AND EventType = 11
					  AND Id = (SELECT MAX(Id) FROM dbo.tblEventlog WHERE DocumentId = @iDocumentId
								  AND [Version] = @Version
								  AND EventType = 11)
				IF @LogDescription IS NOT NULL
				BEGIN
					IF (CHARINDEX(@LogDescription,@Description) = 1)
					BEGIN
						DECLARE @NewDescription VARCHAR(2000)
						SET @NewDescription = SUBSTRING(@Description,LEN(@LogDescription) + 1 ,LEN(@Description))
						UPDATE dbo.m136_tblDocument
						SET strDescription = @NewDescription
						WHERE iEntityId = @OldEntityId
					END
				END
				--Create new version
				IF @OldEntityId IS NOT NULL AND @iDocumentId IS NOT NULL
				BEGIN
					DECLARE @ResultSet table (SelectedValue int)
					INSERT INTO @ResultSet (SelectedValue)
					EXEC [dbo].[m136_be_CreateNewDocumentVersion] @UserId, @OldEntityId, @iDocumentId
					SELECT @NewEntityId = SelectedValue FROM @ResultSet
					IF @NewEntityId IS NOT NULL AND @NewEntityId != 0
					BEGIN
						EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
						EXEC [dbo].[m136_be_UpdateContentFields] @OldEntityId, @NewEntityId, @DocumentTypeId	
					END
				END
				FETCH NEXT FROM curDocumentId INTO @iDocumentId;
			END
			CLOSE curDocumentId;
			DEALLOCATE curDocumentId;
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
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentType]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentType] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentType]
	@UserId AS INT,
	@DocumentId AS INT,
	@DocumentTypeId AS INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
    
            DECLARE @OldEntityId INT;
            DECLARE @NewEntityId INT;
            
            SELECT
                @OldEntityId = iEntityId
            FROM
                dbo.m136_tblDocument
            WHERE
                iDocumentId = @DocumentId 
                AND iLatestVersion = 1
                AND iApproved = 1

            EXEC @NewEntityId = dbo.m136_be_CreateNewDocumentVersionWithDocumetTypeId @UserId, @OldEntityId, @DocumentId, @DocumentTypeId;
            
            EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
    
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