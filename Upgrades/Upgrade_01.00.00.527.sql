INSERT INTO #Description VALUES ('Modify SP for add date for dtmAlter column')
GO

IF OBJECT_ID('[dbo].[m136_be_RejectDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RejectDocument]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RejectDocument] 
	@EntityId INT,
	@UserId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            
            SELECT @DocumentId = iDocumentId
                FROM dbo.m136_tblDocument
                WHERE iEntityId = @EntityId
                      AND iDeleted = 0
            
            UPDATE dbo.m136_tblDocument
            SET iApproved = 2,
                iDraft = 1,
                iApprovedById = @UserId,
                dtmApproved = getdate(),
                strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
                dtmAlter = getdate()
            WHERE iEntityId = @EntityId
                  AND iDeleted = 0
            
            EXEC dbo.m136_SetVersionFlags @DocumentId
            
            SELECT a.strEmail 
            FROM dbo.tblEmployee a 
                INNER JOIN dbo.m136_tblDocument b 
                ON a.iEmployeeId = b.iCreatedById 
            WHERE b.iEntityId = @EntityId
            
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

IF OBJECT_ID('[dbo].[m136_be_SendDocumentToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SendDocumentToApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SendDocumentToApproval]
    @ApproverId INT,
	@EntityId INT,
	@TransferReadingReceipts BIT,
	@Conclusion NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            SELECT
                @DocumentId = iDocumentId
            FROM
                m136_tblDocument
            WHERE
                iEntityId = @EntityId
            UPDATE
                m136_tblDocument
            SET
                iDraft = 0, 
                iApproved = 0,
                dtmAlter = getdate()
            WHERE
                iEntityId = @EntityId;
                
            INSERT INTO
                m136_relSentEmpApproval
                    (iEmployeeId, iEntityId, dtmSentToApproval)
                VALUES
                    (@ApproverId, @EntityId, GETDATE())
            DELETE FROM
                m136_tblCopyConfirms
            WHERE
                iEntityId = @EntityId;
                
            IF @TransferReadingReceipts = 1
            BEGIN
                INSERT INTO
                    m136_tblCopyConfirms
                        (iEntityId)
                    VALUES
                        (@EntityId)
            END
            EXEC m136_SetVersionFlags @DocumentId;
            
            IF @Conclusion IS NOT NULL
				Update dbo.m136_Hearings	
				SET Conclusion = @Conclusion
				WHERE EntityId = @EntityId AND  Id = (SELECT MAX(Id) FROM dbo.m136_Hearings WHERE EntityId = @EntityId)
				
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
                iReceiptsCopied = @TransferReadingReceipts,
                dtmAlter = getdate()
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

IF OBJECT_ID('[dbo].[m136_be_ArchiveDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ArchiveDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_ArchiveDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT,
	@Description varchar(2000)
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
			DECLARE @TableDocument TABLE (documentId INT, handbookId INT)
			
			INSERT INTO @TableDocument
			SELECT doc.iDocumentId, doc.iHandbookId
			FROM dbo.m136_tblDocument doc
				JOIN @DocumentIds d ON doc.iDocumentId = d.Id AND doc.iLatestVersion = 1
			 
			
            UPDATE dbo.m136_tblDocument
                SET iApproved = 4,
                    iApprovedById = @UserId,
                    dtmApproved = getdate(),
                    strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
                    strDescription = CASE WHEN @Description IS NULL THEN strDescription
                                     ELSE (@Description + ' ' + strDescription)
                                     END,
                    iDraft = 0,
                    iHandbookId = -1, --Move to archived folder\
                    dtmAlter = getdate()
                WHERE iEntityId IN(
                        SELECT iEntityId 
                        FROM @DocumentIds AS doc
                        JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
                      )
            
            INSERT INTO dbo.m136_ArchivedDocuments(HandbookId, DocumentId, CreatedById, dmtCreated)
            SELECT handbookId, documentId, @UserId, getdate()
            FROM @TableDocument
            
            DECLARE @iDocumentId INT
            DECLARE curDocumentId CURSOR FOR 
                SELECT Id
                FROM @DocumentIds;
            OPEN curDocumentId; 
            FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC dbo.m136_SetVersionFlags @iDocumentId
                FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            END
            CLOSE curDocumentId;
            DEALLOCATE curDocumentId;
            
            INSERT INTO CacheUpdate (ActionType, EntityId)
                SELECT 11, Id FROM @DocumentIds
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
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
        SET strName = @strTitle,
         dtmAlter = getdate()
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
	@DocumentId AS INT,
	@UserId INT,
	@HandbookId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION 
			DECLARE @Description VARCHAR(2000)
			DECLARE @LogDescription VARCHAR(2000)
			DECLARE @NewEntityId INT
			DECLARE @OldEntityId INT
			DECLARE @Version INT
			DECLARE @DocumentTypeId INT
			
			SELECT @OldEntityId = iEntityId,
				   @Description = strDescription,
				   @Version = iVersion,
				   @DocumentTypeId = iDocumentTypeId
			FROM dbo.m136_tblDocument
			WHERE iDocumentId = @DocumentId 
				  AND iLatestVersion = 1
				  
			SELECT @LogDescription = [Description]
			FROM dbo.tblEventlog
			WHERE DocumentId = @DocumentId
				  AND [Version] = @Version
				  AND EventType = 11
				  AND Id = (SELECT MAX(Id) FROM dbo.tblEventlog WHERE DocumentId = @DocumentId
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
			--Update HandbookId
			UPDATE dbo.m136_tblDocument
			SET iHandbookId = @HandbookId,
			dtmAlter = getdate()
			WHERE iEntityId = @OldEntityId
			--Create new version
			IF @OldEntityId IS NOT NULL
			BEGIN
				DECLARE @ResultSet table (SelectedValue int)
				INSERT INTO @ResultSet (SelectedValue)
				EXEC [dbo].[m136_be_CreateNewDocumentVersion] @UserId, @OldEntityId, @DocumentId
				SELECT @NewEntityId = SelectedValue FROM @ResultSet
				IF @NewEntityId IS NOT NULL AND @NewEntityId != 0
				BEGIN
					EXEC [dbo].[m136_be_UpdateRelatedInfo] @OldEntityId, @NewEntityId, 1
					EXEC [dbo].[m136_be_UpdateContentFields] @OldEntityId, @NewEntityId, @DocumentTypeId	
				END
			END
			--Delete From dbo.m136_ArchivedDocuments
			DELETE FROM dbo.m136_ArchivedDocuments
			WHERE DocumentId = @DocumentId
			
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

IF OBJECT_ID('[dbo].[m136_be_DeleteDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteDocuments]
	@UserId AS INT,
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @FullName NVARCHAR(100);
            DECLARE @DocumentId INT;
            DECLARE CurDocumentId CURSOR FOR
                SELECT Id From @DocumentIds;
                
            SELECT
                @FullName = strFirstName + ' ' + strLastName
            FROM
                tblEmployee
            WHERE
                iEmployeeId = @UserId

            UPDATE
                m136_tblDocument
            SET
                iDeleted = 1,
                iAlterId = @UserId,
                strAlterer = @FullName,
                dtmAlter = getdate()
            WHERE
                iDocumentId IN (SELECT Id FROM @DocumentIds)
                
            DELETE
                FROM m136_relVirtualRelation
            WHERE
                iDocumentId IN (SELECT Id FROM @DocumentIds)
            
            OPEN CurDocumentId;
            FETCH NEXT FROM CurDocumentId INTO @DocumentId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC m136_SetVersionFlags @DocumentId;
                FETCH NEXT FROM CurDocumentId INTO @DocumentId;
            END
            CLOSE CurDocumentId;
            DEALLOCATE CurDocumentId;
        COMMIT TRANSACTION;
        
        INSERT INTO CacheUpdate (ActionType, EntityId)
            SELECT 11, Id FROM @DocumentIds
        
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_RestoreDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RestoreDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RestoreDocuments] 
	@UserId INT,
	@DocumentIds AS Item READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @FullName NVARCHAR(100);
            DECLARE @DocumentId INT;
            DECLARE CurDocumentId CURSOR FOR
                SELECT Id From @DocumentIds;
                
            SELECT
                @FullName = strFirstName + ' ' + strLastName
            FROM
                tblEmployee
            WHERE
                iEmployeeId = @UserId

            UPDATE
                m136_tblDocument
            SET
                iDeleted = 0,
                iAlterId = @UserId,
                strAlterer = @FullName,
                dtmAlter = getdate()
            WHERE
                iDocumentId IN (SELECT Id FROM @DocumentIds)        
                
            OPEN CurDocumentId;
            FETCH NEXT FROM CurDocumentId INTO @DocumentId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC m136_SetVersionFlags @DocumentId;
                FETCH NEXT FROM CurDocumentId INTO @DocumentId;
            END
            CLOSE CurDocumentId;
            DEALLOCATE CurDocumentId;
            
            INSERT INTO CacheUpdate (ActionType, EntityId)
                SELECT 11, Id FROM @DocumentIds
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentResponsible]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentResponsible]  AS SELECT 1')
GO

-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: NOV 23, 2015
-- Description:	Change Document Responsible
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentResponsible] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@TypeUpdate AS INT,
	@SendEmailApprover AS BIT,
	@ResponsibleId as INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            IF @TypeUpdate = 1
                BEGIN
                    UPDATE dbo.m136_tblDocument
                    SET iCreatedbyId = @ResponsibleId,  dtmAlter = getdate()
                    WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                          AND (iLatestVersion = 1 OR iLatestApproved = 1)
                END
            ELSE
                BEGIN 
                    IF @TypeUpdate = 2
                        BEGIN
                            UPDATE dbo.m136_tblDocument
                            SET iCreatedbyId = @ResponsibleId,  dtmAlter = getdate()
                            WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                                  AND iLatestApproved = 1
                        END
                    ELSE
                        BEGIN
                            UPDATE dbo.m136_tblDocument
                            SET iCreatedbyId = @ResponsibleId,  dtmAlter = getdate()
                            WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                                  AND iLatestVersion = 1
                        END
                END
                
            DECLARE @EmailApprover VARCHAR(200) = '';
            
            DECLARE @ApproverId INT = null;
            IF @SendEmailApprover = 1
            BEGIN
                SELECT @EmailApprover = e.strEmail
                FROM dbo.m136_tblDocument doc
                JOIN dbo.tblEmployee e ON doc.iApprovedById = e.iEmployeeId
                WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                      AND iLatestApproved = 1
            END
                
            INSERT INTO CacheUpdate (ActionType, EntityId)
                SELECT 11, Id FROM @DocumentIds
            
            SELECT @EmailApprover
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH;
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
				UPDATE m136_tblDocument set iDocumentTypeId = @ToDocumentTypeId, dtmAlter = getdate()
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

IF OBJECT_ID('[dbo].[m136_be_ChangeInternetDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeInternetDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeInternetDocument]
    @UserId INT,
    @DocumentIds AS [dbo].[Item] READONLY,
    @IsInternetDocument BIT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
            DECLARE @FullName NVARCHAR(100);

            SELECT
                @FullName = strFirstName + ' ' + strLastName
            FROM
                tblEmployee
            WHERE
                iEmployeeId = @UserId
            
            UPDATE
                m136_tblDocument
            SET
                iInternetDoc = @IsInternetDocument,
                iAlterId = @UserId,
                strAlterer = @FullName,
                dtmAlter = getdate()
            WHERE
                iDocumentId IN (SELECT Id FROM @DocumentIds)
                AND iLatestVersion = 1
            
            INSERT INTO CacheUpdate (ActionType, EntityId)
                SELECT 11, Id FROM @DocumentIds
                
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO


IF OBJECT_ID('[dbo].[m136_be_ChangePrintOrientation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangePrintOrientation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangePrintOrientation]
	@DocumentId AS INT,
	@Orientation AS INT
AS
BEGIN

    UPDATE m136_tblDocument
    SET iOrientation = @Orientation,  dtmAlter = getdate()
    WHERE
        iDocumentId = @DocumentId
        AND iLatestVersion = 1
        
END
GO

IF OBJECT_ID('[dbo].[m136_be_RollbackChangesDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RollbackChangesDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RollbackChangesDocument] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
        
            DECLARE @TableEntityId AS TABLE (entityId INT  PRIMARY KEY)
            
            INSERT INTO @TableEntityId
            SELECT iEntityId
            FROM dbo.m136_tblDocument doc
            JOIN @DocumentIds docId ON  doc.iDocumentId = docId.Id
            WHERE doc.iLatestVersion = 1 
                  AND doc.iApproved NOT IN (1,4)
            
            DELETE FROM m136_tblFeedback 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoDate 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoNumber 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoText 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblMetaInfoRichText 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_relInfo 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
            
             DELETE FROM dbo.m136_HearingComments
            WHERE HearingsId IN (SELECT Id 
								  FROM dbo.m136_Hearings h
								  JOIN @TableEntityId d ON h.EntityId = d.entityId)
								  
            DELETE FROM dbo.m136_HearingMembers
            WHERE HearingsId IN (SELECT Id 
								  FROM dbo.m136_Hearings h
								  JOIN @TableEntityId d ON h.EntityId = d.entityId)
								  
			DELETE FROM dbo.m136_Hearings
            WHERE EntityId IN (SELECT entityId FROM @TableEntityId);
            
            DELETE FROM m136_tblDocument 
            WHERE iEntityId IN (SELECT entityId FROM @TableEntityId);
           								  
            DECLARE @iDocumentId INT
            DECLARE curDocumentId CURSOR FOR 
                SELECT Id
                FROM @DocumentIds;
            OPEN curDocumentId; 
            FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                EXEC dbo.m136_SetVersionFlags @iDocumentId
                
                
                DECLARE @HandbookId INT, @ApprovedStatus INT
                SELECT @HandbookId = iHandbookId, @ApprovedStatus = iApproved
                FROM dbo.m136_tblDocument
                WHERE iDocumentId = @iDocumentId
					  AND iLatestVersion = 1
                IF @ApprovedStatus = 4
                BEGIN
					UPDATE dbo.m136_tblDocument
					SET iHandbookId = -1,   dtmAlter = getdate()
					WHERE iDocumentId = @iDocumentId
					  AND iLatestVersion = 1
					  
					INSERT INTO dbo.m136_ArchivedDocuments(HandbookId, DocumentId, CreatedById, dmtCreated)
					VALUES(@HandbookId, @iDocumentId, @UserId, getdate())
                END
                ELSE
                BEGIN
						UPDATE dbo.m136_tblDocument
						SET dtmAlter = getdate()
						WHERE iDocumentId = @iDocumentId
							AND iLatestVersion = 1
                END
                
                FETCH NEXT FROM curDocumentId INTO @iDocumentId;
            END
            CLOSE curDocumentId;
            DEALLOCATE curDocumentId;
	
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

IF OBJECT_ID('[dbo].[m136_be_RetrieveSendToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RetrieveSendToApproval] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RetrieveSendToApproval] 
	@DocumentId AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		DECLARE @EntityId INT
        
		SELECT @EntityId = iEntityId
		FROM dbo.m136_tblDocument
		WHERE iDocumentId = @DocumentId
			  AND iLatestVersion = 1
			  
		UPDATE dbo.m136_tblDocument 
		SET iDraft = 1, dtmAlter = getdate()
		WHERE iEntityId =  @EntityId
		
		DELETE FROM dbo.m136_relSentEmpApproval          
		WHERE iEntityId = @EntityId
		
		EXEC dbo.m136_SetVersionFlags @DocumentId
	
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

IF OBJECT_ID('[dbo].[m136_be_MoveDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveDocument]
    @DocumentId INT,
    @IsDocumentVirtual BIT,
    @PreviousDocumentId INT,
    @IsPreviousDocumentVirtual BIT,
    @OldFolderId INT,
    @NewFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @NewLevelType INT = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = @NewFolderId);
        IF @PreviousDocumentId IS NULL
        BEGIN
            UPDATE m136_tblDocument
            SET iSort = iSort + 1, dtmAlter = getdate()
            WHERE iHandbookId = @NewFolderId
            
            UPDATE m136_relVirtualRelation
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId
            
            IF @IsDocumentVirtual = 1
            BEGIN
                UPDATE m136_relVirtualRelation
                SET iSort = -2147483648, iHandbookId = @NewFolderId
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
            ELSE
            BEGIN
                UPDATE m136_tblDocument
                SET 
                    iSort = -2147483648, 
                    iHandbookId = @NewFolderId,
                    iLevelType = @NewLevelType,
                    dtmAlter = getdate()
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
        END
        ELSE
        BEGIN
            DECLARE @PreviousDocumentSortOrder INT;
            
            IF @IsPreviousDocumentVirtual = 1
            BEGIN
                SET @PreviousDocumentSortOrder = (SELECT TOP 1 iSort FROM m136_relVirtualRelation WHERE iHandbookId = @NewFolderId AND iDocumentId = @PreviousDocumentId);
            END
            ELSE
            BEGIN
                SET @PreviousDocumentSortOrder = (SELECT TOP 1 iSort FROM m136_tblDocument WHERE iDocumentId = @PreviousDocumentId);
            END        
            
            UPDATE m136_tblDocument
            SET iSort = iSort + 1, dtmAlter = getdate()
            WHERE iHandbookId = @NewFolderId AND iSort > @PreviousDocumentSortOrder
            
            UPDATE m136_relVirtualRelation
            SET iSort = iSort + 1
            WHERE iHandbookId = @NewFolderId AND iDocumentId = @DocumentId AND iSort > @PreviousDocumentSortOrder
            
            IF @IsDocumentVirtual = 1
            BEGIN
                UPDATE m136_relVirtualRelation
                SET iSort = @PreviousDocumentSortOrder + 1, iHandbookId = @NewFolderId
                WHERE iHandbookId = @OldFolderId AND iDocumentId = @DocumentId
            END
            ELSE
            BEGIN
                UPDATE m136_tblDocument
                SET 
                    iSort = @PreviousDocumentSortOrder + 1, 
                    iHandbookId = @NewFolderId,
                    iLevelType = @NewLevelType,
                    dtmAlter = getdate()
                WHERE iDocumentId = @DocumentId
            END
        END
        IF(@DocumentId IS NOT NULL)
		BEGIN
			INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
			VALUES (11, @DocumentId);
		END
         
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

IF OBJECT_ID('[dbo].[m136_be_MoveMultipleDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_MoveMultipleDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_MoveMultipleDocuments]
    @DocumentIds AS [dbo].[Item] READONLY,
    @OldFolderId INT,
    @NewFolderId INT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        UPDATE m136_tblDocument
        SET iSort = iSort + 1, dtmAlter = getdate()
        WHERE iHandbookId = @NewFolderId
        
        UPDATE m136_relVirtualRelation
        SET iSort = iSort + 1
        WHERE iHandbookId = @NewFolderId
        
        UPDATE
            m136_tblDocument
        SET 
            iSort = -2147483648,
            iHandbookId = @NewFolderId,
            iLevelType = (SELECT iLevelType FROM m136_tblHandbook WHERE iHandbookId = @NewFolderId),
            dtmAlter = getdate()
        WHERE
            iHandbookId = @OldFolderId 
            AND iDocumentId IN (SELECT Id FROM @DocumentIds)
            
        INSERT INTO dbo.CacheUpdate (ActionType, EntityId)
        SELECT 11 , Id FROM @DocumentIds
        
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

IF OBJECT_ID('[dbo].[m136_be_CreateDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocumentHearing] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocumentHearing] 
	@EntityId			INT,
	@IsPublic			BIT,
	@CreateBy		    INT,
	@DueDate			DATETIME,
	@Employees AS [dbo].[Item] READONLY,
	@AllowForwarding BIT,
	@Notify BIT,
	@Description NVARCHAR(MAX)
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	SET NOCOUNT ON;
	DECLARE @HearingId INT;
	INSERT INTO dbo.m136_Hearings(EntityId,IsPublic,CreatedDate,CreatedBy,DueDate,IsActive,AllowForwarding,Notify,Description)
	VALUES(@EntityId, @IsPublic, GETDATE(), @CreateBy, @DueDate, 1,@AllowForwarding, @Notify,@Description)
	SET @HearingId = SCOPE_IDENTITY();
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
	FROM @Employees
	UPDATE dbo.m136_tblDocument 
		SET iApproved = 3, iStatus = 1,  dtmAlter = getdate()
	WHERE iEntityId = @EntityId
	SELECT @HearingId
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

IF OBJECT_ID('[dbo].[m136_be_EndHearingDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EndHearingDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_EndHearingDocument] 
	@EntityId INT,
	@ShouldUpdateDueDate bit
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
        
		DECLARE @HearingId AS INT;
		
		SELECT @HearingId = Id
		FROM dbo.m136_Hearings
		WHERE EntityId = @EntityId
			  AND IsActive = 1;

		IF (@ShouldUpdateDueDate = 1)			  
		BEGIN
			UPDATE dbo.m136_Hearings 
			SET IsActive = 0,
			DueDate = GETDATE()
			WHERE Id = @HearingId;
		END
		ELSE
		BEGIN
			UPDATE dbo.m136_Hearings 
			SET IsActive = 0
			WHERE Id = @HearingId;
		END		
		
		UPDATE dbo.m136_tblDocument
		SET iApproved = 0, iStatus = 0, dtmAlter = getdate()
		WHERE iEntityId = @EntityId;
		
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

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentLink]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentLink] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentLink] 
	@iEntityId INT,
	@FieldId INT,
	@FieldContentId INT,
	@OldUrl [nvarchar](max),
	@NewUrl [nvarchar](max)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iDocumentTypeId INT;
	SELECT @iDocumentTypeId = mtd.iDocumentTypeId 
	FROM dbo.m136_tblDocument mtd WHERE mtd.iEntityId = @iEntityId;

    UPDATE mir SET mir.[value] = CAST(REPLACE(CAST(value as nvarchar(max)), @OldUrl, @NewUrl) as ntext)
    FROM dbo.m136_tblMetaInfoRichText mir
    JOIN dbo.m136_relDocumentTypeInfo rdti ON rdti.iMetaInfoTemplateRecordsId = mir.iMetaInfoTemplateRecordsId
    WHERE mir.iMetaInfoRichTextId = @FieldContentId
    AND mir.iMetaInfoTemplateRecordsId = @FieldId
    AND rdti.iDocumentTypeId = @iDocumentTypeId;   
    
    UPDATE dbo.m136_tblDocument
		SET dtmAlter = getdate()
	WHERE iEntityId = @iEntityId;
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
    SET TitleAndKeyword = @TitleAndKeyword, KeyWords = @KeyWords, dtmAlter = getdate()
	WHERE iDocumentId = @DocumentId
		  AND iLatestVersion = 1
    
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
            SET iInternetDoc = 1,  dtmAlter = getdate()
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

IF OBJECT_ID('[dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RetrieveDocumentsSendToApprovalPlugin] 
	@Months AS INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
		
		DECLARE @TableDocument TABLE(EntityId INT, DocumentId INT, dtmSentToApproval DATETIME, Approver INT, Responsible INT, Version INT)
		DECLARE @DateCompare DATETIME = DateAdd(month, - @Months, GETDATE())
		INSERT INTO  @TableDocument     
		SELECT d.iEntityId, d.iDocumentId, r.dtmSentToApproval, r.iEmployeeId, d.iCreatedbyId, d.iVersion
		FROM dbo.m136_tblDocument d
		JOIN dbo.m136_relSentEmpApproval r ON d.iEntityId = r.iEntityId 
		     AND r.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
		     AND r.dtmSentToApproval < @DateCompare AND d.iDraft = 0 AND d.iApproved = 0
		WHERE d.iDraft = 0
			  AND d.iApproved = 0
			  AND iLatestVersion = 1
		
		DECLARE @EntityId INT, @DocumentId INT
		
        DECLARE curDocumentId CURSOR FOR 
            SELECT EntityId, DocumentId
            FROM @TableDocument;
            
        OPEN curDocumentId; 
        FETCH NEXT FROM curDocumentId INTO @EntityId , @DocumentId;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            UPDATE dbo.m136_tblDocument 
			SET iDraft = 1,   dtmAlter = getdate()
			WHERE iEntityId =  @EntityId
			
			DELETE FROM dbo.m136_relSentEmpApproval          
			WHERE iEntityId = @EntityId
			
			EXEC dbo.m136_SetVersionFlags @DocumentId
            
            FETCH NEXT FROM curDocumentId INTO @EntityId , @DocumentId;
        END
        CLOSE curDocumentId;
        DEALLOCATE curDocumentId;
        COMMIT TRANSACTION;
        
        SELECT d.DocumentId, d.EntityId, d.Version, d.Approver, d.Responsible, e.strEmail ResponsibleEmail, e1.strEmail ApproverEmail
        FROM @TableDocument d
			LEFT JOIN dbo.tblEmployee e ON d.Responsible = e.iEmployeeId
			LEFT JOIN dbo.tblEmployee e1 ON d.Approver = e1.iEmployeeId
        
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

UPDATE m136_tbldocument SET dtmAlter = dtmApproved WHERE dtmApproved > dtmAlter and iLatestApproved = 1
GO
