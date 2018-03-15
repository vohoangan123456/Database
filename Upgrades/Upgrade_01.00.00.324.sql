INSERT INTO #Description VALUES ('Get department responsibles')
GO

IF OBJECT_ID('[dbo].[GetDepartmentResponsiblesByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetDepartmentResponsiblesByUserId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetDepartmentResponsiblesByUserId] 
	@UserId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT dr.Id, 
		dr.DepartmentId AS iDepartmentId, 
		dr.EmployeeId AS iEmployeeId, 
		dr.ResponsibleTypeId AS iResponsibleTypeId 
    FROM dbo.DepartmentResponsibles dr WHERE dr.EmployeeId = @UserId;
END
GO