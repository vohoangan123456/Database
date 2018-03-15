INSERT INTO #Description VALUES ('Update [dbo].[m136_be_GetEmployees]')
GO

IF (OBJECT_ID('[dbo].[m136_be_GetEmployees]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[m136_be_GetEmployees] AS SELECT 1'
GO	
ALTER PROCEDURE [dbo].[m136_be_GetEmployees] 
	@iEmployeeId INT,
	@iDepartmentId INT,
	@bRecursive BIT,
	@strFirstName VARCHAR(50),
	@strLastName VARCHAR(50),
	@strLoginName VARCHAR(100),
	@iPageSize INT,
	@iPageIndex INT,
	@roleId INT = NULL,
	@ExcludedEmployeeId AS [dbo].[Item] READONLY,
	@ExcludedQuitDepartmentId INT = NULL,
	@SearchIds NVARCHAR(4000) = NULL
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SearchIdTable TABLE(
		SearchId INT
	)	
	IF @SearchIds IS NOT NULL
	BEGIN
		INSERT INTO @SearchIdTable(SearchId)
		SELECT [value] FROM dbo.fn_Split(@SearchIds, ',');
	END
	
	DECLARE @RoleEmployees TABLE(iEmployeeId INT NOT NULL PRIMARY KEY);
	IF(@roleId IS NOT NULL)
		INSERT INTO @RoleEmployees(iEmployeeId)
		SELECT 
			iEmployeeId 
		FROM 
			dbo.relEmployeeSecGroup
		WHERE iSecGroupId = @roleId;
	DECLARE @Departments TABLE(iDepartmentId INT NOT NULL PRIMARY KEY);
	IF (@iDepartmentId IS NOT NULL)
	INSERT INTO @Departments(iDepartmentId)
		SELECT 
			iDepartmentId 
		FROM 
			[dbo].[m136_GetDepartmentsRecursive](@iDepartmentId);
	SET @iPageIndex = @iPageIndex - 1;
    SELECT te.iEmployeeId, 
		td.strName AS strDepartment,
		tc.strName AS strCountry,
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
		  OR (@bRecursive = 0 AND te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL))
	AND (@roleId IS NULL OR (@roleId IS NOT NULL AND te.iEmployeeId IN (SELECT iEmployeeId FROM @RoleEmployees)))
	AND te.iEmployeeId NOT IN (SELECT Id FROM @ExcludedEmployeeId)
	AND (@ExcludedQuitDepartmentId IS NULL OR te.iDepartmentId <> @ExcludedQuitDepartmentId)
	AND (@SearchIds IS NULL OR (@SearchIds IS NOT NULL AND EXISTS(SELECT SearchId FROM @SearchIdTable WHERE SearchId = te.iEmployeeId)))
	AND te.iEmployeeId <> -2 AND te.iEmployeeId <> 0
	SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		f.strDepartment,
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
		f.strCountry,
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
		te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName  
    FROM #Filters f
    JOIN dbo.tblEmployee te ON f.iEmployeeId = te.iEmployeeId
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber;
END
GO