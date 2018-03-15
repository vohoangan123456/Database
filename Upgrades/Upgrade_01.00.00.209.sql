INSERT INTO #Description VALUES('Add procedures to support feature multi secondary departments for employee.')
GO

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'relEmployeeDepartment'))
BEGIN
    CREATE TABLE [dbo].[relEmployeeDepartment]
    (
        iEmployeeId INT NOT NULL,
        iDepartmentId INT NOT NULL,
        PRIMARY KEY (iEmployeeId, iDepartmentId)
    )
END
GO

DECLARE @sql1 NVARCHAR(MAX)
SET @sql1 = dbo.fn136_GetSqlDropConstraintKey('relEmployeeDepartment', 'FK_relEmployeeDepartment_tblEmployee') 
IF @sql1 IS NOT NULL
BEGIN
    EXEC(@sql1)
    
	ALTER TABLE dbo.relEmployeeDepartment ADD CONSTRAINT FK_relEmployeeDepartment_tblEmployee FOREIGN KEY (iEmployeeId)
        REFERENCES dbo.tblEmployee (iEmployeeId)
END
GO

DECLARE @sql2 NVARCHAR(MAX)
SET @sql2 = dbo.fn136_GetSqlDropConstraintKey('relEmployeeDepartment', 'FK_relEmployeeDepartment_tblDepartment') 
IF @sql2 IS NOT NULL
BEGIN
    EXEC(@sql2)
    
	ALTER TABLE [dbo].[relEmployeeDepartment] ADD CONSTRAINT FK_relEmployeeDepartment_tblDepartment FOREIGN KEY (iDepartmentId)
        REFERENCES dbo.tblDepartment (iDepartmentId)
END
GO

IF OBJECT_ID('[dbo].[be_GetSecondaryDepartmentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetSecondaryDepartmentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetSecondaryDepartmentsOfUser] 
	@UserId INT
AS
BEGIN
	SELECT iDepartmentId,
        dbo.fn136_GetDepartmentPath(iDepartmentId) AS Path
    FROM
        tblDepartment
    WHERE
        iDepartmentId IN (SELECT iDepartmentId FROM relEmployeeDepartment WHERE iEmployeeId = @UserId)
END
GO

IF OBJECT_ID('[dbo].[be_UpdateSecondaryDepartmentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateSecondaryDepartmentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_UpdateSecondaryDepartmentsOfUser] 
	@UserId INT,
    @DepartmentIds AS [dbo].[Item] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        
            DELETE FROM
                relEmployeeDepartment
            WHERE
                iEmployeeId = @UserId
                
            INSERT INTO relEmployeeDepartment (iEmployeeId, iDepartmentId)
            SELECT @UserId, Id
            FROM @DepartmentIds
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
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
            
            DELETE tblEmployee WHERE tblEmployee.iEmployeeId IN (SELECT Id FROM @Employees);
            
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
    END CATCH
END
GO