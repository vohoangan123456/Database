INSERT INTO #Description VALUES('Add table CacheUpdate, add some procedures and modify some existing procedures to support update frontend''s cache from changes in backend')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CacheUpdate]') AND type in (N'U'))
    DROP TABLE [dbo].[CacheUpdate]
GO

CREATE TABLE [dbo].[CacheUpdate]
(
	Id INT IDENTITY(1, 1) PRIMARY KEY,
	ActionType INT NOT NULL,
    EntityId INT NOT NULL
)
GO

IF OBJECT_ID('[dbo].[DeleteCacheUpdateById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[DeleteCacheUpdateById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[DeleteCacheUpdateById]
	@Id INT
AS
BEGIN
    DELETE FROM
        CacheUpdate
    WHERE
        Id = @Id
END
GO

IF OBJECT_ID('[dbo].[DeleteAllCacheUpdate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[DeleteAllCacheUpdate] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[DeleteAllCacheUpdate]
AS
BEGIN
    DELETE FROM CacheUpdate
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderInformation]
	@FolderId INT,
	@ParentFolderId INT,
	@strName VARCHAR(100),
	@strDescription VARCHAR(700),
	@iDepartmentId INT,
	@iLevelType INT,
	@iViewType INT,
	@InheritNewParentPermissions BIT,
	@Recursive BIT,
	@OldParentFolderId INT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

            SET NOCOUNT ON;
            UPDATE [dbo].[m136_tblHandbook] 
            SET strName = @strName,
                iParentHandbookId = (CASE WHEN @ParentFolderId = 0 THEN NULL ELSE @ParentFolderId END),
                strDescription = @strDescription,
                iDepartmentId = @iDepartmentId,
                iLevelType = @iLevelType,
                iViewTypeId = (CASE WHEN @iViewType = -1 THEN 1 WHEN @iViewType = -2 THEN 3 END),
                iLevel = (CASE WHEN @ParentFolderId = 0 THEN 1 ELSE (SELECT  h.iLevel + 1 FROM dbo.m136_tblHandbook h WHERE h.iHandbookId = @ParentFolderId) END)
            WHERE iHandbookId = @FolderId;
            DECLARE @iHandbookId INT,
                @iApplicationId INT, 
                @iSecurityId INT, 
                @iPermissionSetId INT, 
                @iGroupingId INT, 
                @iBit INT;
            IF (@InheritNewParentPermissions = 1)
            BEGIN
                IF (@Recursive = 1)
                BEGIN
                    DECLARE @SubFoldersPermission AS [dbo].[ACLDatatable];
                    INSERT INTO @SubFoldersPermission 
                    SELECT @FolderId 
                        , iApplicationId
                        , iSecurityId
                        , iPermissionSetId
                        , iGroupingId
                        , iBit
                        , 1
                    FROM [dbo].[tblACL] WHERE iEntityId = @ParentFolderId
                        AND iApplicationId = 136
                        AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
                    EXEC [dbo].[m136_be_UpdateFolderPermissions] @SubFoldersPermission;
                END --END IF (@Recursive = 1)----------------------------------------------------------------------------------
                ELSE
                BEGIN
                    DECLARE @NewParentFolderPermissions AS [dbo].[ACLDatatable];
                    INSERT INTO @NewParentFolderPermissions SELECT @FolderId
                            , [iApplicationId]
                            , iSecurityId
                            , [iPermissionSetId]
                            , [iGroupingId]
                            , [iBit]
                            , 0
                        FROM [dbo].[tblACL] 
                        WHERE iEntityId = @ParentFolderId 
                            AND iApplicationId = 136
                            AND (iPermissionSetId = 461 OR iPermissionSetId = 462);
                    DECLARE ACL CURSOR FOR 
                    SELECT iEntityId
                            , [iApplicationId]
                            , iSecurityId
                            , [iPermissionSetId]
                            , [iGroupingId]
                            , [iBit]
                        FROM @NewParentFolderPermissions;
                    OPEN ACL; 
                    FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF NOT EXISTS(SELECT * FROM dbo.tblACL WHERE iEntityId = @iHandbookId 
                            AND iApplicationId = @iApplicationId 
                            AND iSecurityId = @iSecurityId 
                            AND iPermissionSetId  = @iPermissionSetId)
                        BEGIN
                            INSERT INTO dbo.tblACL VALUES (
                                 @iHandbookId
                                , @iApplicationId
                                , @iSecurityId
                                , @iPermissionSetId
                                , @iGroupingId
                                , @iBit);
                        END
                        ELSE 
                        BEGIN
                            UPDATE dbo.tblACL
                                SET iBit = @iBit,
                                    iGroupingId = @iGroupingId
                            WHERE iEntityId = @iHandbookId 
                            AND iApplicationId = @iApplicationId 
                            AND iSecurityId = @iSecurityId 
                            AND iPermissionSetId  = @iPermissionSetId
                        END
                        FETCH NEXT FROM ACL INTO @iHandbookId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
                    END
                    CLOSE ACL;
                    DEALLOCATE ACL;
                    DELETE [dbo].[tblACL] WHERE iEntityId = @FolderId 
                        AND iApplicationId = @iApplicationId 
                        AND iSecurityId NOT IN (SELECT iSecurityId 
                        FROM @NewParentFolderPermissions);
                END
            END
            
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (1, @FolderId);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UpdateFolderPermissions] 
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            SET NOCOUNT ON;
            DECLARE @iEntityId INT, @iAppicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT, @bRecursive BIT;
            DECLARE PermissionSet CURSOR FOR 
                SELECT iEntityId 
                    , iApplicationId
                    , iSecurityId
                    , iPermissionSetId
                    , iGroupingId
                    , iBit 
                    , bRecursive
                FROM @Permissions;
            OPEN PermissionSet; 
            FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
            WHILE @@FETCH_STATUS = 0
            BEGIN
                IF EXISTS(SELECT * FROM [dbo].[tblACL] 
                    WHERE iEntityId = @iEntityId 
                        AND iApplicationId = @iAppicationId 
                        AND iSecurityId = @iSecurityId 
                        AND iPermissionSetId = @iPermissionSetId)
                BEGIN
                    UPDATE [dbo].[tblACL]
                    SET iBit = @iBit
                    WHERE iEntityId = @iEntityId 
                        AND iApplicationId = @iAppicationId 
                        AND iSecurityId = @iSecurityId 
                        AND iPermissionSetId = @iPermissionSetId;
                END
                ELSE
                BEGIN
                    INSERT INTO [dbo].[tblACL] (iEntityId
                        , iApplicationId
                        , iSecurityId
                        , iPermissionSetId
                        , iGroupingId
                        , iBit) 
                    VALUES (@iEntityId
                        , @iAppicationId
                        , @iSecurityId
                        , @iPermissionSetId
                        , 0
                        , @iBit);
                END
                
                IF (@bRecursive = 1)
                BEGIN
                    DECLARE @iHandbookId INT;
                    DECLARE RecursivePermissionSet CURSOR FOR 
                    SELECT iHandbookId 
                        , @iAppicationId
                        , @iSecurityId
                        , @iPermissionSetId
                        , @iGroupingId
                        , @iBit
                    FROM dbo.m136_GetHandbookRecursive (@iEntityId, @iSecurityId, 0);
                    
                    OPEN RecursivePermissionSet; 
                    FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
                    WHILE @@FETCH_STATUS = 0
                    BEGIN
                        IF EXISTS(SELECT * FROM [dbo].[tblACL] 
                            WHERE iEntityId = @iHandbookId 
                                AND iApplicationId = @iAppicationId 
                                AND iSecurityId = @iSecurityId 
                                AND iPermissionSetId = @iPermissionSetId)
                        BEGIN
                            UPDATE [dbo].[tblACL]
                            SET iBit = @iBit
                            WHERE iEntityId = @iHandbookId 
                                AND iApplicationId = @iAppicationId 
                                AND iSecurityId = @iSecurityId 
                                AND iPermissionSetId = @iPermissionSetId;
                        END
                        ELSE
                        BEGIN
                            INSERT INTO [dbo].[tblACL] (iEntityId
                                , iApplicationId
                                , iSecurityId
                                , iPermissionSetId
                                , iGroupingId
                                , iBit) 
                            VALUES (@iHandbookId
                                , @iAppicationId
                                , @iSecurityId
                                , @iPermissionSetId
                                , 0
                                , @iBit);
                        END
                    
                        FETCH NEXT FROM RecursivePermissionSet INTO @iHandbookId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
                    END
                    CLOSE RecursivePermissionSet;
                    DEALLOCATE RecursivePermissionSet;
                    DELETE [dbo].[tblACL] WHERE iEntityId = @iHandbookId 
                        AND iApplicationId = @iAppicationId 
                        AND iSecurityId NOT IN (SELECT iSecurityId 
                        FROM @Permissions);
                END
                
                FETCH NEXT FROM PermissionSet INTO @iEntityId, @iAppicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit, @bRecursive;
            END
            CLOSE PermissionSet;
            DEALLOCATE PermissionSet;
            DELETE [dbo].[tblACL] WHERE iEntityId = @iEntityId 
                AND iApplicationId = @iAppicationId 
                AND iSecurityId NOT IN (SELECT iSecurityId 
                FROM @Permissions);
                
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (2, @iEntityId)
                
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_DeleteFolder]
	@HandbookId INT = 0,
	@SecurityId INT = 0
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION
            SET NOCOUNT ON;
            DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
            DECLARE @DocumentChildren TABLE(Id INT NOT NULL PRIMARY KEY);
            
            INSERT INTO @AvailableChildren(iHandbookId)
            SELECT 
                iHandbookId 
            FROM 
                [dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
                    
            INSERT INTO @DocumentChildren(Id)		
            SELECT DISTINCT d.iDocumentId AS Id
                FROM m136_tblDocument d
                    JOIN m136_tblHandbook h 
                        ON d.iHandbookId = h.iHandbookId
                    JOIN @AvailableChildren ac
                        ON d.iHandbookId = ac.iHandbookId
            
            --Delete virtual of handbook
            DELETE FROM	dbo.m136_relVirtualRelation	
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Delete virtual of document
            DELETE FROM	dbo.m136_relVirtualRelation	
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            --Delete Subcribe handbook
            DELETE FROM	dbo.m136_tblSubscribe
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Delete Subcribe of document
            DELETE FROM	dbo.m136_tblSubscriberDocument
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            --Set iDelete = 1 for handbook table
            UPDATE dbo.m136_tblHandbook
                SET iDeleted = 1
            WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
            
            --Set iDelete = 1 for Document table
            UPDATE dbo.m136_tblDocument
                SET iDeleted = 1
            WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
            
            INSERT INTO CacheUpdate(ActionType, EntityId) VALUES (3, @HandbookId);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
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
            
            INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
    
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
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
            
            INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
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
            
            INSERT INTO dbo.CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
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
    @IsInternetDocument BIT
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
                iInternetDoc = @isInternetDocument
            WHERE
                iDocumentId = @DocumentId
                AND iLatestVersion = 1
            
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
                strAlterer = @FullName
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
                strAlterer = @FullName
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
                    SET iCreatedbyId = @ResponsibleId
                    WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                          AND (iLatestVersion = 1 OR iLatestApproved = 1)
                END
            ELSE
                BEGIN 
                    IF @TypeUpdate = 2
                        BEGIN
                            UPDATE dbo.m136_tblDocument
                            SET iCreatedbyId = @ResponsibleId
                            WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
                                  AND iLatestApproved = 1
                        END
                    ELSE
                        BEGIN
                            UPDATE dbo.m136_tblDocument
                            SET iCreatedbyId = @ResponsibleId
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

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentTemplate]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentTemplate]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentTemplate] 
	@DocumentId AS INT,
	@ToDocumentTypeId AS INT,
	@MetaInfoIds AS [dbo].[Item] READONLY,
	@UserId INT
AS
BEGIN
	BEGIN TRY
		BEGIN TRANSACTION;
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
            
            INSERT INTO CacheUpdate (ActionType, EntityId) VALUES (11, @DocumentId);
            
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
            
            INSERT INTO CacheUpdate (ActionType, EntityId)
                SELECT 11, Id FROM @DocumentIds
	
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
                strAlterer = @FullName
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
		
            UPDATE dbo.m136_tblDocument
                SET iApproved = 4,
                    iApprovedById = @UserId,
                    dtmApproved = getdate(),
                    strApprovedBy = dbo.fnOrgGetUserName(@UserId, '', 0),
                    strDescription = CASE WHEN @Description IS NULL THEN strDescription
                                     ELSE (@Description + ' ' + strDescription)
                                     END,
                    iDraft = 0
                WHERE iEntityId IN(
                        SELECT iEntityId 
                        FROM @DocumentIds AS doc
                        JOIN	m136_tblDocument d ON d.iDocumentId = doc.Id AND d.iLatestVersion = 1
                      )
                
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