INSERT INTO #Description VALUES ('Modify SP for annual cycle')
GO

IF OBJECT_ID('[Calendar].[AnnualCycleGetById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetById] AS SELECT 1')
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
	e.strFirstName + ' ' + e.strLastName AS ResponsibleName
	FROM Calendar.Activities a
	INNER JOIN Calendar.AnnualCycleActivities aca ON aca.ActivityId = a.ActivityId
	LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
	LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
	WHERE aca.AnnualCycleId = @AnnualCycleId
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

IF OBJECT_ID('[Calendar].[AnnualCycleGetPaged]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetPaged] AS SELECT 1')
GO
 ALTER PROCEDURE [Calendar].[AnnualCycleGetPaged]
(
	@PageIndex int,
	@PageSize int,
	@Keyword nvarchar(200),
	@UserId INT,
	@IsBackend BIT = 0
)
AS
BEGIN
	DECLARE @TempTable TABLE(
		AnnualCycleId INT ,
		Name NVARCHAR(100) ,
		[Description] NVARCHAR(4000) ,
		Partitioning TINYINT,
		[Year] INT,
		ViewType TINYINT,
		IsInactive BIT,
		IsDeleted BIT,
		CreatedDate DATETIME,
		CreatedBy INT,
		CreatedByName NVARCHAR(500),
		UpdatedByName  NVARCHAR(500),
		UpdatedDate DATETIME,
		UpdatedBy INT,
		[Rownumber] [int]
	);
	DECLARE @SortExpression nvarchar;
	SET @SortExpression = '';
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
	INSERT INTO @TempTable
				   SELECT ac.AnnualCycleId,
						ac.Name,
						ac.[Description],               
						ac.Partitioning,
						ac.[Year],
						ac.ViewType,
						ac.IsInactive,    
						ac.IsDeleted,
						ac.CreatedDate,
						ac.CreatedBy,
						ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
						ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,		
						ac.UpdatedDate,
						ac.UpdatedBy,                         
						ROW_NUMBER() OVER (ORDER BY 
								CASE WHEN @SortExpression='' THEN ac.AnnualCycleId END DESC																																											      
							) AS rownumber
					FROM Calendar.AnnualCycles ac
					LEFT JOIN tblEmployee e ON ac.CreatedBy = e.iEmployeeId
					LEFT JOIN tblEmployee e2 ON ac.UpdatedBy = e2.iEmployeeId
					WHERE  (@Keyword IS NULL OR (@Keyword IS NOT NULL AND ac.Name LIKE '%'+@Keyword+'%')) 
					AND ac.IsDeleted = 0
					AND (@IsBackend = 1 OR ac.IsInactive = 0)
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
				SELECT * FROM @TempTable WHERE (@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) ORDER BY rownumber
				--count total rows           
				SELECT COUNT(*)          
				FROM  @TempTable
END
GO

IF OBJECT_ID('[Calendar].[AnnualCycleGetByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetByUserId] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleGetByUserId]
(
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
		
	SELECT 
	ac.AnnualCycleId,
	ac.Name,
	ac.Description 
	FROM Calendar.AnnualCycles ac
	WHERE ac.IsDeleted = 0 AND 
	(@IsBackend = 1 OR ac.IsInactive = 0)
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
	ORDER BY ac.Name ASC
END	
GO
