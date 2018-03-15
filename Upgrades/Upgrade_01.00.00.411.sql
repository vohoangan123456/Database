INSERT INTO #Description VALUES ('Ordering search security groups')
GO

IF OBJECT_ID('[dbo].[m136_be_SearchSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchSecurityGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SearchSecurityGroups]
	@iUserID INT, 
	@strName VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    SET NOCOUNT ON;
    SELECT DISTINCT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	LEFT JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	WHERE (esg.iEmployeeId = @iUserId OR @iUserId IS NULL)
	AND (@strName IS NULL OR @strName = '' OR sg.strName LIKE '%' + @strName + '%')
	ORDER BY sg.strName;
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchSecurityGroups] AS SELECT 1')
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
    OR te.strLastName LIKE '%' + @Text + '%'
    OR (te.strFirstName + ' '  + te.strLastName)  LIKE '%' + @Text + '%';
END
GO
