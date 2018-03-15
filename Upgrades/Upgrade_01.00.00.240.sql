INSERT INTO #Description VALUES('Create m136_be_GetEmployeesByFilter')
GO

IF OBJECT_ID('[dbo].[m136_be_GetEmployeesByFilter]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployeesByFilter] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetEmployeesByFilter]
    @Text NVARCHAR(100),
	@iEmployeeId INT,
	@PageIndex INT,
	@PageSize INT
AS
BEGIN
    SET NOCOUNT ON;
	
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
		te.strPhoneWork, 
		te.strFax, 
		te.strEmail, 
		te.LastLogin,
		te.strExpDep,
		te.strEmployeeNo,
		ROW_NUMBER() OVER (ORDER BY te.strFirstName ASC, te.strLastName ASC) AS RowNumber 
	INTO #Filters
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = te.iCountryId
    LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
    WHERE (@iEmployeeId IS NULL OR te.iEmployeeId = @iEmployeeId)
    AND ((@Text IS NULL OR @Text = '' OR te.strFirstName LIKE '%' + @Text + '%')
    OR (@Text IS NULL OR @Text = '' OR te.strLastName LIKE '%' + @Text + '%'))
    
    SELECT *  
    FROM #Filters
    WHERE (@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	ORDER BY RowNumber
END
GO