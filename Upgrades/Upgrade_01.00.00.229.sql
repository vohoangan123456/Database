INSERT INTO #Description VALUES('Update m136_be_GetRoleMembers, m136_be_GetDepartmentReponsibles')
GO

IF OBJECT_ID('[dbo].[m136_be_GetRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetRoleMembers] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 23, 2015
-- Description:	Get role members 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetRoleMembers]
	@RoleId INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT te.iEmployeeId
		, te.strFirstName
		, te.strLastName
		, te.strLoginName
		, td.strName AS strDepartment
		, te.strEmail
    FROM dbo.tblEmployee te 
		INNER JOIN dbo.relEmployeeSecGroup resg
			ON resg.iEmployeeId = te.iEmployeeId
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
	WHERE resg.iSecGroupId = @RoleId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentReponsibles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentReponsibles] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 15, 2015
-- Description:	Get all department responsibles by departmentId
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentReponsibles]
	@iDepartmentId INT = 0,
	@iResponsibleType INT = 0,
	@PageSize INT = 0, -- If @PageSize = 0 we will get all available records.
	@PageIndex INT = 0
AS
BEGIN
	SET NOCOUNT ON;
    SELECT dr.Id,
		e.strLoginName,
		(e.strFirstName + ' ' + e.strLastName) AS strName,
		e.iEmployeeId,
		td.strName AS strDepartmentName,
		lrt.Name AS strResponsibleType,
		lrt.Id AS iResponsibleTypeId,
		dr.DepartmentId AS iDepartmentId,
		td2.strName AS DepartmentResponsibleName,
		e.strEmail,
		ROW_NUMBER() OVER (ORDER BY (e.strFirstName + ' ' + e.strLastName) ASC) AS rownumber
		INTO #Filters
    FROM dbo.DepartmentResponsibles dr
    INNER JOIN dbo.tblEmployee e ON e.iEmployeeId = dr.EmployeeId
    INNER JOIN dbo.tblDepartment td ON td.iDepartmentId = e.iDepartmentId
    LEFT JOIN dbo.tblDepartment td2 ON dr.DepartmentId = td2.iDepartmentId
    INNER JOIN dbo.luResponsibleTypes lrt ON lrt.Id = dr.ResponsibleTypeId
    WHERE (dr.DepartmentId = @iDepartmentId OR @iDepartmentId IS NULL)
		AND (dr.ResponsibleTypeId = @iResponsibleType OR @iResponsibleType IS NULL OR @iResponsibleType = 0);
    SELECT f.* FROM #Filters f 
    WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;            
END
GO