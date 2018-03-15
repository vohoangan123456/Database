INSERT INTO #Description VALUES ('Remove UserLogs, DepartmentLogs, RoleLogs when deleting Employees, Departments and Roles')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteEmployees] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteEmployees]
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            SET NOCOUNT ON;
            DELETE relEmployeePosition WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE relEmployeeSecGroup WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE relEmployeeDepartment WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE m136_HearingMembers WHERE EmployeeId IN (SELECT Id FROM @Employees);
			DELETE dbo.UserLogs WHERE EmployeeId IN (SELECT Id FROM @Employees);
            DELETE tblEmployee WHERE tblEmployee.iEmployeeId IN (SELECT Id FROM @Employees);
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


IF OBJECT_ID('[dbo].[m136_be_DeleteSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteSecurityGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]
	@SecurityGroupIds AS [dbo].[Item] READONLY
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
			SET NOCOUNT ON;
			DELETE dbo.tblACL WHERE iSecurityId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.relEmployeeSecGroup WHERE dbo.relEmployeeSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.RoleLogs WHERE RoleId IN (SELECT Id FROM @SecurityGroupIds);
			DELETE dbo.tblSecGroup WHERE dbo.tblSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
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

IF OBJECT_ID('[dbo].[m136_be_DeleteDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDepartments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteDepartments] 
	@iApplicationId		INT,
	@iPermissionSetId	INT,
	@Departments AS [dbo].[Item] READONLY
AS
BEGIN
	BEGIN TRY
        BEGIN TRANSACTION;
			SET NOCOUNT ON;

			DELETE dbo.tblACL WHERE iApplicationId = @iApplicationId 
				AND iPermissionSetId = @iPermissionSetId
				AND iEntityId IN (SELECT dd.Id FROM @Departments dd);
			
			DELETE dbo.relDepartmentPosition WHERE iDepartmentId IN (SELECT dd.Id FROM @Departments dd);
			
			DELETE dbo.DepartmentLogs WHERE DepartmentId IN (SELECT dd.Id FROM @Departments dd);
			
			DELETE dbo.tblDepartment WHERE iDepartmentId IN (SELECT dd.Id FROM @Departments dd);
			
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
