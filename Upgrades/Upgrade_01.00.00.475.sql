INSERT INTO #Description VALUES ('Modify SP [dbo].[GetUserDepartmentIds]')
GO

IF OBJECT_ID('[dbo].[GetUserDepartmentIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserDepartmentIds] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserDepartmentIds]
    @UserId INT
AS
BEGIN
    DECLARE @UserDepartmentIds TABLE(Id INT);
        
    INSERT INTO @UserDepartmentIds(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        AND iDepartmentId <>  0
        
    INSERT INTO @UserDepartmentIds(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    AND iDepartmentId <>  0
    
    SELECT Id FROM @UserDepartmentIds
END
GO