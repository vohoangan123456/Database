INSERT INTO #Description VALUES ('Delete roles - Logging')
GO
IF OBJECT_ID('[dbo].[m136_be_DeleteSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]
	@UserId INT,
	@Type INT,
	@Description VARCHAR(MAX),
	@SecurityGroupIds AS [dbo].[Item] READONLY
AS
BEGIN
	DECLARE @Roles VARCHAR(8000) 
	SELECT @Roles = COALESCE(@Roles + ', ', '') + G.strName 
	FROM @SecurityGroupIds S
	JOIN tblSecGroup G ON S.Id = G.iSecGroupId
	
	SET @Description = @Description + ' ' + @Roles;
	
	BEGIN TRY
        BEGIN TRANSACTION;
			SET NOCOUNT ON;
			DELETE dbo.tblACL WHERE iSecurityId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.relEmployeeSecGroup WHERE dbo.relEmployeeSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.RoleLogs WHERE RoleId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.tblSecGroup WHERE dbo.tblSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
			INSERT INTO dbo.RoleLogs(RoleId, EmployeeId, Time, Type, Description) VALUES (0, @UserId, GETDATE(), @Type, @Description)
		 COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
    END CATCH
END


GO