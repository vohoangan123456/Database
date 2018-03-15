INSERT INTO #Description VALUES('Update script for metadata')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateItemPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateItemPermissions] AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 28, 2015
-- Description:	Update or Add permission meta register
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateItemPermissions]
	@ItemId INT,
	@ApplicationId INT,
	@PermissionSetId INT,
	@Permissions AS [dbo].[ACLDatatable] READONLY
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		SET NOCOUNT ON;
		DECLARE @iEntityId INT, @iApplicationId INT, @iSecurityId INT, @iPermissionSetId INT, @iGroupingId INT, @iBit INT;
		DECLARE PermissionSet CURSOR FOR 
			SELECT iEntityId 
				, iApplicationId
				, iSecurityId
				, iPermissionSetId
				, iGroupingId
				, iBit 
			FROM @Permissions;
		OPEN PermissionSet; 
		FETCH NEXT FROM PermissionSet INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
		WHILE @@FETCH_STATUS = 0
		BEGIN
			IF EXISTS(SELECT * FROM [dbo].[tblACL] 
				WHERE iEntityId = @iEntityId 
					AND iApplicationId = @iApplicationId 
					AND iSecurityId = @iSecurityId 
					AND iPermissionSetId = @iPermissionSetId)
			BEGIN
				UPDATE [dbo].[tblACL]
				SET iBit = @iBit
				WHERE iEntityId = @iEntityId 
					AND iApplicationId = @iApplicationId 
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
					, @iApplicationId
					, @iSecurityId
					, @iPermissionSetId
					, 0
					, @iBit);
			END
			FETCH NEXT FROM PermissionSet INTO @iEntityId, @iApplicationId, @iSecurityId, @iPermissionSetId, @iGroupingId, @iBit;
		END
		CLOSE PermissionSet;
		DEALLOCATE PermissionSet;
		DELETE [dbo].[tblACL] WHERE iEntityId = @ItemId 
			AND iApplicationId = @ApplicationId
			AND iPermissionSetId = @PermissionSetId 
			AND iSecurityId NOT IN (SELECT iSecurityId 
			FROM @Permissions);
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

IF OBJECT_ID('[dbo].[m147_spDeleteRegisterItem]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_spDeleteRegisterItem] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_spDeleteRegisterItem]
(
	@iSecurityId INT,
	@iRegisterItemId INT
)
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		DECLARE @iAccess INT
		DECLARE @iRegisterId INT
		SELECT @iRegisterId = iRegisterId 
		FROM m147_tblRegisterItem 
		WHERE iRegisterItemId = @iRegisterItemId
		SELECT @iAccess = dbo.fnSecurityGetPermission(147, 571, @iSecurityId, @iRegisterId)
		IF (@iAccess & 8) = 8 or (@iAccess & 16) = 16
			BEGIN
				DELETE FROM m147_relRegisterItemCategory 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_relRegisterItemItem 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_tblSynonym 
					   WHERE iRegisterItemValueId IN (SELECT DISTINCT iRegisterItemValueId 
													  FROM m147_tblRegisterItemValue 
													  WHERE iRegisterItemId = @iRegisterItemId)
				DELETE FROM m147_tblRegisterItemValue 
					   WHERE iRegisterItemId = @iRegisterItemId
				DELETE FROM m147_tblRegisterItem 
					   WHERE iRegisterItemId = @iRegisterItemId
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
				SET RegisterValue = @RegisterValue
				WHERE iRegisterItemValueId = @iRegisterItemValueId 
			END
			ELSE
			BEGIN
				INSERT INTO dbo.m147_tblRegisterItemValue (iRegisterItemId
					, RegisterValue) 
				VALUES (@RegisterItemId
					, @RegisterValue);
			END
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