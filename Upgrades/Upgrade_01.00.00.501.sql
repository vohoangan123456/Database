INSERT INTO #Description VALUES ('Update [AnnualCycleGetById] proc')
GO

ALTER PROCEDURE [Calendar].[AnnualCycleGetById]
(
	@AnnualCycleId INT,
	@UserId INT,
	@IsBackend BIT = 0	
)
AS
BEGIN
	DECLARE @UserDepartmentOId INT;
	SELECT @UserDepartmentOId = iDepartmentId
	FROM dbo.tblEmployee
	WHERE iEmployeeId = @UserId
	DECLARE @RoleIds TABLE(
		iSecGroupId INT
	);
	INSERT INTO @RoleIds
	SELECT iSecGroupId 
	FROM dbo.relEmployeeSecGroup
	WHERE iEmployeeId = @UserId
	GROUP BY iSecGroupId;	
	SELECT ac.*,
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName  
	FROM Calendar.AnnualCycles ac
		LEFT JOIN tblEmployee e ON ac.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON ac.UpdatedBy = e2.iEmployeeId
	WHERE ac.AnnualCycleId = @AnnualCycleId
	AND ac.IsDeleted = 0 AND (@IsBackend = 1 OR ac.IsInactive = 0)
	AND NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
	AND (
		ac.CreatedBy = @UserId OR 
		NOT EXISTS (SELECT acr.* FROM Calendar.AnnualCycleReaders acr WHERE ac.AnnualCycleId = acr.AnnualCycleId) OR
		EXISTS(
			SELECT acr.* 
			FROM Calendar.AnnualCycleReaders acr 
			WHERE ac.AnnualCycleId = acr.AnnualCycleId AND 
				(
					(acr.ReaderTypeId = 1 AND acr.ReaderId = @UserId)
					OR
					(acr.ReaderTypeId = 2 AND acr.ReaderId = @UserDepartmentOId)
					OR
					(acr.ReaderTypeId = 3 AND EXISTS (SELECT r.* FROM @RoleIds r WHERE r.iSecGroupId = acr.ReaderId))
				)
			)
		)		
---activity
	SELECT 
	a.ActivityId,
	a.Name,
	a.[Description],
	a.StartDate,
	a.EndDate,
	a.CategoryId,
	ac.Name AS CategoryName,
	e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
	a.CreatedBy
	FROM Calendar.Activities a
	INNER JOIN Calendar.AnnualCycleActivities aca ON aca.ActivityId = a.ActivityId
	LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
	LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
	WHERE aca.AnnualCycleId = @AnnualCycleId
	ORDER BY a.StartDate ASC
---reader
	SELECT
		AnnualCycleViewerId,
		AnnualCycleId,
		ReaderTypeId,
		CASE
			WHEN ReaderTypeId = 1 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ReaderId)
			WHEN ReaderTypeId = 2 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ReaderId)
			WHEN ReaderTypeId = 3 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ReaderId)
		END AS ReaderName,
		ReaderId
	FROM
		Calendar.AnnualCycleReaders
	WHERE
		AnnualCycleId = @AnnualCycleId
---exclusion
	SELECT
		rle.AnnualCycleExclusionId,
		rle.AnnualCycleId,
		rle.DepartmentId,
		d.strName AS DepartmentName,
		rle.EmployeeId,
		e.strFirstName + ' ' + e.strLastName AS EmployeeName
	FROM
		Calendar.AnnualCycleExclusions rle
			INNER JOIN tblDepartment d ON rle.DepartmentId = d.iDepartmentId
			INNER JOIN tblEmployee e ON rle.EmployeeId = e.iEmployeeId
	WHERE
		rle.AnnualCycleId = @AnnualCycleId
END
GO