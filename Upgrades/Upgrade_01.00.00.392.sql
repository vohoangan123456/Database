INSERT INTO #Description VALUES ('Search employees by name')
GO

IF OBJECT_ID('[dbo].[SearchEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[SearchEmployees] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[SearchEmployees]
	@Text [nvarchar](250)
AS
BEGIN
	SET NOCOUNT ON;

    SELECT te.iEmployeeId, te.iDepartmentId, te.strFirstName, te.strLastName, 
		te.strEmail, te.strLoginName, te.strLoginDomain,
		te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName   
    FROM dbo.tblEmployee te 
    WHERE te.strFirstName LIKE '%' + @Text + '%'
    OR te.strLastName LIKE '%' + @Text + '%';
END
GO