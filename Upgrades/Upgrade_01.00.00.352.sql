INSERT INTO #Description VALUES ('Update SP change logic delete document and archive document')
GO

IF NOT EXISTS(SELECT * FROM dbo.m136_tblHandbook WHERE iHandbookId = -1)
	BEGIN
		SET IDENTITY_INSERT dbo.m136_tblHandbook ON;
		INSERT INTO dbo.m136_tblHandbook(
			iHandbookId,
			iParentHandbookId, 
			strName, 
			strDescription, 
			iDepartmentId, 
			iLevelType, 
			iViewTypeId, 
			dtmCreated, 
			iCreatedById, 
			iDeleted,
			iMin,
			iMax,
			iLevel) 
		VALUES(
			-1,
			NULL, 
			'Archived', 
			'This folder contains document archived', 
			NULL, 
			1, 
			-1, 
			GETDATE(), 
			1, 
			0,
			0,
			0,
			1);
	        
		SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_ArchivedDocuments]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_ArchivedDocuments]
    (
		Id INT IDENTITY(1, 1) PRIMARY KEY,
		HandbookId INT NOT NULL,
		DocumentId INT NOT NULL,
		CreatedById INT NULL,
		dmtCreated DATETIME NOT NULL
    )
GO

IF OBJECT_ID('[dbo].[m136_be_VerifyDeleteFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: OCT 27, 2015
-- Description:	Count number Folder and document recursive
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions]
	@HandbookId INT = 0,
	@SecurityId INT = 0,
	@DeleteFolderPermission INT,
	@DeleteDocumentPermission INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @returnPermission BIT = 1;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
		INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	   
	   DECLARE @CountFolderRecursive AS INT
	   DECLARE @CountFolder AS INT
	   DECLARE @CountDocument AS INT
	   
	   SELECT @CountFolderRecursive = Count(iHandbookId)
	   FROM @AvailableChildren
	   
	   SELECT 
			@CountFolder = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 461, @SecurityId, iHandbookId) & @DeleteFolderPermission  = @DeleteFolderPermission
		
		SELECT 
			@CountDocument = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 462, @SecurityId, iHandbookId) & @DeleteDocumentPermission  = @DeleteDocumentPermission
		
		
		DECLARE @NumberSubFolder AS INT
		DECLARE @NumberDocument AS INT
		
		SELECT  @NumberDocument = COUNT(*)
		FROM (	
				SELECT DISTINCT 
					d.iDocumentId AS Id
				FROM 
					m136_tblDocument d
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON d.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1
					AND d.iDeleted = 0
			UNION       
				SELECT 
					d.iDocumentId AS Id
				FROM 
					m136_relVirtualRelation virt 
						JOIN m136_tblDocument d
							ON virt.iDocumentId = d.iDocumentId
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON virt.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1
					AND d.iDeleted = 0) AS Document
					
		SELECT 
			@NumberSubFolder = COUNT(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		WHERE iHandbookId != @HandbookId
		
		IF @CountFolderRecursive = 0 OR @CountFolder != @CountFolderRecursive
			SET @returnPermission = 0;
			
		IF @NumberDocument <> 0 AND (@CountFolderRecursive = 0 OR @CountDocument != @CountFolderRecursive)
			SET @returnPermission = 0;
		
		SELECT @returnPermission
		
		SELECT @NumberDocument
		
		SELECT @NumberSubFolder
		
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
                    iHandbookId = -1 --Move to archived folder
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

IF OBJECT_ID('[dbo].[m136_be_RollbackChangesDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_RollbackChangesDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_RollbackChangesDocument] 
	@DocumentIds AS [dbo].[Item] READONLY
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

IF OBJECT_ID('[dbo].[m136_be_GetHandbookIdFromArchivedDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHandbookIdFromArchivedDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetHandbookIdFromArchivedDocument] 
	@DocumentId AS INT
AS
BEGIN
	DECLARE @HandbookId INT = NULL
	DECLARE @IsDeleted INT = 0
	
	SELECT @HandbookId = HandbookId
	FROM dbo.m136_ArchivedDocuments
	WHERE DocumentId = @DocumentId
	
	
	IF NOT EXISTS(SELECT 1 FROM dbo.m136_tblHandbook WHERE iHandbookId = @HandbookId AND iDeleted = 0)
	BEGIN 
		SET @IsDeleted = 1
	END
	
	SELECT @HandbookId AS HandbookId, @IsDeleted AS IsDeleted
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
			SET iHandbookId = @HandbookId
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
