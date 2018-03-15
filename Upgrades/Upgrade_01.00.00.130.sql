INSERT INTO #Description VALUES('Alter stored procedures admin roles.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserWithApprovePermission]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithApprovePermission]')
GO
ALTER  PROCEDURE [dbo].[m136_be_GetUserWithApprovePermission]
AS
BEGIN
	SELECT e.iEmployeeId, e.iDepartmentId, e.strLoginName, e.strEmail, e.strFirstName, e.strLastName, e.strLoginName 
	FROM tblEmployee e
	WHERE iEmployeeId IN (SELECT iEntityId 
						  FROM tblACL 
						  WHERE iPermissionSetId = 462 AND iBit & 16 = 16) -- 16: approval permission
END
GO


IF OBJECT_ID('[dbo].[m136_GetDepartmentsRecursive]', 'IF') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_GetDepartmentsRecursive] () RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Nov 17, 2015
-- Description:	Get all departments with their sub departments.
-- =============================================
ALTER FUNCTION [dbo].[m136_GetDepartmentsRecursive]
(	
	@iDepartmentId INT
)
RETURNS TABLE
AS
RETURN 
(
    WITH Children AS
	(
			SELECT 
				iDepartmentId
			FROM 
				[dbo].[tblDepartment]  
			WHERE
				iDepartmentId  = @iDepartmentId
		UNION ALL
			SELECT 
				d.iDepartmentId  
			FROM 
				[dbo].[tblDepartment] d
				INNER JOIN Children 
					ON	iDepartmentParentId = Children.iDepartmentId
			WHERE d.iDepartmentId <> 0
	)
	SELECT 
		iDepartmentId
	FROM 
		Children
)
GO


IF OBJECT_ID('[dbo].[m136_be_GetEmployees]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployees]')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 21, 2015
-- Description:	Get employees. It was paging because the number of employees too much.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetEmployees] 
	@iEmployeeId INT,
	@iDepartmentId INT,
	@bRecursive BIT,
	@strFirstName VARCHAR(50),
	@strLastName VARCHAR(50),
	@strLoginName VARCHAR(100),
	@iPageSize INT,
	@iPageIndex INT
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Departments TABLE(iDepartmentId INT NOT NULL PRIMARY KEY);
	INSERT INTO @Departments(iDepartmentId)
		SELECT 
			iDepartmentId 
		FROM 
			[dbo].[m136_GetDepartmentsRecursive](@iDepartmentId);
			
	SET @iPageIndex = @iPageIndex - 1;
	
    SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		td.strName AS strDepartment,
		te.strFirstName, 
		te.strLastName, 
		te.strTitle, 
		CASE WHEN te.strAddress1 IS NULL OR te.strAddress1 = '' THEN 
				(CASE WHEN te.strAddress2 IS NULL OR te.strAddress2 = '' THEN 
						te.strAddress3 
					ELSE te.strAddress2 
				END)
			ELSE te.strAddress1 
		END AS [strAddress],
		te.iCountryId, 
		tc.strName AS strCountry,
		te.strPhoneHome, 
		te.strPhoneInternal, 
		te.strPhoneWork, 
		te.strPhoneMobile, 
		te.strBeeper, 
		te.strCallNumber, 
		te.strFax, 
		te.strEmail, 
		te.strLoginName, 
		te.strLoginDomain, 
		te.strComment,
		te.LastLogin,
		te.strExpDep,
		te.strEmployeeNo,
		te.strPassword,
		ROW_NUMBER() OVER (ORDER BY te.strFirstName ASC, te.strLastName ASC) AS RowNumber 
	INTO #Filters
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = te.iCountryId
    LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
    WHERE (@iEmployeeId IS NULL OR te.iEmployeeId = @iEmployeeId)
    AND (@strFirstName IS NULL OR @strFirstName = '' OR te.strFirstName LIKE '%' + @strFirstName + '%')
    AND (@strLastName IS NULL OR @strLastName = '' OR te.strLastName LIKE '%' + @strLastName + '%')
    AND (@strLoginName IS NULL OR @strLoginName = '' OR te.strLoginName LIKE '%' + @strLoginName + '%')
    AND ((@bRecursive = 1 AND (te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		  OR (@bRecursive = 0 AND te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL));
    
    SELECT f.iEmployeeId, 
		f.iDepartmentId, 
		f.strDepartment, 
		f.strFirstName, 
		f.strLastName, 
		f.strTitle, 
		f.strAddress, 
		f.iCountryId, 
		f.strCountry, 
		f.strPhoneHome, 
		f.strPhoneInternal, 
		f.strPhoneWork, 
		f.strPhoneMobile, 
		f.strBeeper, 
		f.strCallNumber, 
		f.strFax, 
		f.strEmail, 
		f.strLoginName, 
		f.strLoginDomain, 
		f.strComment, 
		f.LastLogin,
		f.strExpDep, 
		f.strEmployeeNo,
		f.strPassword  
    FROM #Filters f
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber;
END
GO


IF OBJECT_ID('[dbo].[m136_be_SearchRoleMembers]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchRoleMembers]')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Search member by name, username....
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_SearchRoleMembers] 
	@iDepartmentId INT,
	@iRoleId INT,
	@strKeyword VARCHAR(100),
	@recursive BIT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strLoginName, td.strName AS strDepartment 
	FROM dbo.tblEmployee te
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
		WHERE (((@recursive = 0) AND (te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL OR @iDepartmentId = 0)) 
			OR (@recursive = 1 AND te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		AND (te.strLoginName LIKE '%' + @strKeyword + '%' 
			OR te.strFirstName LIKE '%' + @strKeyword + '%' 
			OR te.strLastName LIKE '%' + @strKeyword + '%')
		AND (@iRoleId IS NULL OR te.iEmployeeId NOT IN (SELECT resg.iEmployeeId 
			FROM dbo.relEmployeeSecGroup resg WHERE resg.iSecGroupId = @iRoleId));
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteSecurityGroups]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Delete roles
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]
	@SecurityGroupIds AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DELETE dbo.tblACL WHERE iSecurityId IN (SELECT Id FROM @SecurityGroupIds);
	
	DELETE dbo.relEmployeeSecGroup WHERE dbo.relEmployeeSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
	
    DELETE dbo.tblSecGroup WHERE dbo.tblSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
    
END
GO