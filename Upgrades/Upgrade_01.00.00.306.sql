INSERT INTO #Description VALUES ('Modify procedures m136_be_RejectDocument, m136_be_SendDocumentToApproval, m136_be_RollbackChangesDocument, m136_be_InsertFolder')
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
                strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0)
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
	@TransferReadingReceipts BIT
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
                iDraft = 0
            WHERE
                iEntityId = @EntityId
            
            INSERT INTO
                m136_relSentEmpApproval
                    (iEmployeeId, iEntityId, dtmSentToApproval)
                VALUES
                    (@ApproverId, @EntityId, GETDATE())

            DELETE FROM
                m136_tblCopyConfirms
            WHERE
                iEntityId = @EntityId
            
            IF @TransferReadingReceipts = 1
            BEGIN
                INSERT INTO
                    m136_tblCopyConfirms
                        (iEntityId)
                    VALUES
                        (@EntityId)
            END
            
            EXEC m136_SetVersionFlags @DocumentId;
        
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

IF OBJECT_ID('[dbo].[m136_be_InsertFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_InsertFolder]
	@iUserId INT,
	@iParentHandbookId	INT,
    @strName			VARCHAR(100),
    @strDescription		VARCHAR(7000),
    @iDepartmentId		INT,
    @iLevelType			INT,
    @iViewTypeId		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @iParentLevel INT = 0, @iMaxHandbookId INT = 0;
	SELECT @iParentLevel = h.iLevel FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @iParentHandbookId;
	SELECT @iMaxHandbookId = MAX(ihandbookid) FROM dbo.m136_tblHandbook;
	DECLARE @iNewHandbookId INT = ISNULL(@iMaxHandbookId, 0) + 1;
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
		@iNewHandbookId,
		(CASE WHEN @iParentHandbookId = 0 THEN NULL ELSE @iParentHandbookId END), 
		@strName, 
		@strDescription, 
		@iDepartmentId, 
		@iLevelType, 
		(CASE WHEN @iViewTypeId = -1 THEN 1 WHEN @iViewTypeId = -2 THEN 3 END), 
		GETDATE(), 
		@iUserId, 
		0,
		0,
		0,
		(@iParentLevel + 1));
        
	SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
    
	DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermisionSetId INT, @iGroupingId INT, @iBit INT
	DECLARE ACL CURSOR FOR 
		SELECT @iNewHandbookId
				, [iApplicationId]
				, iSecurityId
				, [iPermissionSetId]
				, [iGroupingId]
				, [iBit]
			FROM [dbo].[tblACL] 
			WHERE iEntityId = @iParentHandbookId 
				AND iApplicationId = 136
				AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
	OPEN ACL; 
	FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId)
		BEGIN
			INSERT INTO dbo.tblACL VALUES (
			     @iEntityId
				, @iApplicationId
				, @iSecurityId
				, @iPermisionSetId
				, @iGroupingId
				, @iBit);
		END
		ELSE 
		BEGIN
			UPDATE dbo.tblACL
				SET iBit = @iBit,
					iGroupingId = @iGroupingId
			WHERE iEntityId = @iEntityId 
			AND iApplicationId = @iApplicationId 
			AND iSecurityId = @iSecurityId 
			AND iPermissionSetId  = @iPermisionSetId
		END
		FETCH NEXT FROM ACL INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermisionSetId, @iGroupingId, @iBit;
	END
	CLOSE ACL;
	DEALLOCATE ACL;
    
    INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (5, @iParentHandbookId);
    
	SELECT @iNewHandbookId;
END
GO