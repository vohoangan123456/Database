INSERT INTO #Description VALUES('Update be_GetSecondaryDepartmentsOfUser')
GO

IF OBJECT_ID('[dbo].[be_GetSecondaryDepartmentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetSecondaryDepartmentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetSecondaryDepartmentsOfUser]
    @UserId INT
AS
BEGIN
    SELECT iDepartmentId,
        dbo.fn136_GetDepartmentPath(iDepartmentId) AS Path,
		strName, strDescription
    FROM
        tblDepartment
    WHERE
        iDepartmentId IN (SELECT iDepartmentId FROM relEmployeeDepartment WHERE iEmployeeId = @UserId)
END
GO
