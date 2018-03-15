INSERT INTO #Description VALUES('Add procedure [dbo].[m136_be_EmployeesWithPermissions]')
GO

IF OBJECT_ID('[dbo].[m136_be_EmployeesWithPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EmployeesWithPermissions] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_EmployeesWithPermissions]
	@iParentHandbookId INT = 0,
	@iSecurityId INT = 0,
	@iBit INT = 0
AS
BEGIN

	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	-- Do we have a specified root or do we assume we will list everything?
	IF ISNULL(@iParentHandbookId,0) = 0
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_tblHandbook WHERE iDeleted = 0 
		END
	ELSE
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive (@iParentHandbookId, @iSecurityId, 0)
		END 

	SELECT iEmployeeid, strFirstName, strLastName, tblDep.strName AS DepartmentName 
	FROM tblemployee 
		INNER JOIN tblDepartment tblDep ON tblDep.iDepartmentID = tblEmployee.iDepartmentId
	WHERE iEmployeeId in (SELECT DISTINCT  relEmployeeSecGroup.iEmployeeId
							FROM           relEmployeeSecGroup 
								INNER JOIN tblSecGroup ON relEmployeeSecGroup.iSecGroupId = tblSecGroup.iSecGroupId 
								INNER JOIN tblACL ON tblSecGroup.iSecGroupId = tblACL.iSecurityId
							WHERE  (tblACL.iApplicationId = 136) 
									AND (tblACL.iPermissionSetId = 462) 
									AND ((tblACL.iBit & @iBit) = @iBit)
									AND (tblACL.iEntityId in (SELECT ihandbookId FROM @HandbookIdTable)))
	ORDER BY DepartmentName
	
END
GO