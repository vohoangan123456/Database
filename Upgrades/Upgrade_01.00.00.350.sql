INSERT INTO #Description VALUES ('Get system users who can login via username and password or via domain')
GO

IF OBJECT_ID('[dbo].[GetSystemUsers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetSystemUsers] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetSystemUsers] 
	
AS
BEGIN
	SET NOCOUNT ON;

    SELECT  [iEmployeeId],
            [iDepartmentId],
            [strFirstName], 
            [strLastName],
            [LastLogin],
            [strLoginName],
            [strEmail],
            [strFirstName] + ' ' + [strLastName] + ' - ' + [dbo].[fnGetAllDepartmentName](iEmployeeId) AS FullNameAndDepartmentName
	FROM [dbo].[tblEmployee] 
	WHERE strLoginName <> '' AND (strPassword <> '' OR strLoginDomain <> '');
END
GO
