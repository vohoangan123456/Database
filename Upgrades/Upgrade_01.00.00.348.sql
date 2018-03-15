INSERT INTO #Description VALUES ('Update SP for metadata default folder view')
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
                iViewTypeId = @iViewType,
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

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iSort'
      AND Object_ID = Object_ID(N'dbo.m147_tblRegisterItemValue'))
BEGIN
    ALTER TABLE dbo.m147_tblRegisterItemValue ADD iSort INT NOT NULL   DEFAULT(0);
END
GO

IF OBJECT_ID('[dbo].[m147_be_UpdateRegisterItemValue]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_UpdateRegisterItemValue]
	@RegisterItemId INT,
	@RegisterItemValue AS [dbo].[Items] READONLY
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		SET NOCOUNT ON;
		DELETE dbo.m147_tblRegisterItemValue WHERE iRegisterItemId = @RegisterItemId 
			AND iRegisterItemValueId NOT IN (SELECT Id 
			FROM @RegisterItemValue);
		DECLARE @iRegisterItemValueId INT, @RegisterValue VARCHAR(200);
		DECLARE @iSort INT = 1;
		DECLARE RegisterItemValueSet CURSOR FOR 
			SELECT Id, Value
			FROM @RegisterItemValue;
		OPEN RegisterItemValueSet; 
		FETCH NEXT FROM RegisterItemValueSet INTO @iRegisterItemValueId, @RegisterValue;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF @iRegisterItemValueId IS NOT NULL AND @iRegisterItemValueId <> 0
			BEGIN
				UPDATE dbo.m147_tblRegisterItemValue
				SET RegisterValue = @RegisterValue, iSort = @iSort
				WHERE iRegisterItemValueId = @iRegisterItemValueId 
			END
			ELSE
			BEGIN
				INSERT INTO dbo.m147_tblRegisterItemValue (iRegisterItemId
					, RegisterValue, iSort) 
				VALUES (@RegisterItemId
					, @RegisterValue, @iSort);
			END
			SET @iSort = @iSort + 1;
			FETCH NEXT FROM RegisterItemValueSet INTO @iRegisterItemValueId, @RegisterValue;
		END
		CLOSE RegisterItemValueSet;
		DEALLOCATE RegisterItemValueSet;
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

IF OBJECT_ID('[dbo].[m147_be_GetRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterItemValues] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetRegisterItemValues]
(
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN
	DECLARE @iAccess INT
	DECLARE @iRegisterId INT
	DECLARE @iRegItemId INT
	
	SELECT @iRegisterId = iRegisterId 
	FROM m147_tblRegisterItem 
	WHERE iRegisterItemId = @RegisterItemId
	SELECT @iAccess = dbo.fnSecurityGetPermission(147, 571, @SecurityId, @iRegisterId)
	
	SELECT a.*
	FROM m147_tblRegisterItemValue a 
	WHERE a.iRegisterItemId = @RegisterItemId
		  AND ((@iAccess & 1) = 1 or (@iAccess & 16) = 16) 
	ORDER BY a.iSort, a.RegisterValue
END
GO

IF OBJECT_ID('[dbo].[m147_be_GetDocumentRegisterItemValues]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetDocumentRegisterItemValues] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetDocumentRegisterItemValues]
    @DocumentId INT
AS
BEGIN
    
    SELECT
        riv.iRegisterItemValueId,
        riv.iRegisterItemId,
        riv.RegisterValue,
        CASE
            WHEN EXISTS (SELECT 1 
                         FROM m147_relRegisterItemItem
                         WHERE
                            iItemId = @DocumentId
                            AND iRegisterItemValueId = riv.iRegisterItemValueId
                            AND iRegisterItemId = riv.iRegisterItemId) THEN 1
            ELSE 0
        END AS IsTagged
    FROM
        m147_tblRegisterItemValue riv
    ORDER BY iSort
END
GO
