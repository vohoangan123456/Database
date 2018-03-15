INSERT INTO #Description VALUES ('Handbook - add createdBy for annual cycle')
GO

IF COL_LENGTH('Calendar.AnnualCycles', 'CreatedBy') IS NULL
BEGIN
	ALTER TABLE Calendar.AnnualCycles
	Add CreatedBy INT NULL
END
GO



IF OBJECT_ID('[Calendar].[AnnualCycleInsert]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleInsert] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleInsert]
(
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT,
	@CreatedBy INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			--function body
			INSERT INTO Calendar.AnnualCycles
			(Name, [Description], Partitioning, [Year], ViewType, IsInactive, IsDeleted, CreatedBy)
			VALUES 
			(@Name, @Description, @Partitioning, @Year, @ViewType, 0, 0, @CreatedBy)
			--function body
			IF @@TRANCOUNT > 0
			COMMIT TRAN;
		END TRY
		BEGIN CATCH	
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(), 
				@ErrorSeverity INT = ERROR_SEVERITY(), 
				@ErrorState INT = ERROR_STATE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		END CATCH
	SELECT SCOPE_IDENTITY();	
END	
GO



IF OBJECT_ID('[Calendar].[AnnualCycleGetByUserId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetByUserId] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleGetByUserId]
(
	@UserId INT
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
	ac.IsInactive = 0 AND 
	NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
	AND (
		ac.CreatedBy = @UserId OR 
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



IF OBJECT_ID('[Calendar].[AnnualCycleGetPaged]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetPaged] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleGetPaged]
(
	@PageIndex int,
	@PageSize int,
	@Keyword nvarchar(200),
	@UserId INT
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
                    ROW_NUMBER() OVER (ORDER BY 
							CASE WHEN @SortExpression='' THEN ac.AnnualCycleId END DESC																																											      
						) AS rownumber
                FROM Calendar.AnnualCycles ac
				WHERE  (@Keyword IS NULL OR (@Keyword IS NOT NULL AND ac.Name LIKE '%'+@Keyword+'%')) 
				AND ac.IsDeleted = 0
				AND ac.IsInactive = 0
				AND NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
				AND (
					ac.CreatedBy = @UserId OR 
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



IF OBJECT_ID('[Calendar].[AnnualCycleGetById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetById] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleGetById]
(
	@AnnualCycleId INT,
	@UserId INT	
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
	
	SELECT ac.*  
	FROM Calendar.AnnualCycles ac
	WHERE ac.AnnualCycleId = @AnnualCycleId
	AND ac.IsDeleted = 0 AND ac.IsInactive = 0
	AND NOT EXISTS (SELECT ace.* FROM Calendar.AnnualCycleExclusions ace WHERE ac.AnnualCycleId = ace.AnnualCycleId AND ace.EmployeeId = @UserId)
	AND (
		ac.CreatedBy = @UserId OR 
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




IF OBJECT_ID('[Calendar].[AnnualCycleDelete]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleDelete] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleDelete]
(
	@AnnualCycleIds [Calendar].[AnnualCycleDeletedIds] READONLY,
	@UserId INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			--function body
			UPDATE src
			SET src.IsDeleted = 1
			FROM Calendar.AnnualCycles src
			WHERE EXISTS (SELECT * FROM @AnnualCycleIds targ WHERE targ.AnnualCycleId = src.AnnualCycleId)
			AND src.CreatedBy = @UserId
			--function body
			IF @@TRANCOUNT > 0
			COMMIT TRAN;
		END TRY
		BEGIN CATCH	
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(), 
				@ErrorSeverity INT = ERROR_SEVERITY(), 
				@ErrorState INT = ERROR_STATE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		END CATCH
	SELECT 1;	
END	
GO




IF OBJECT_ID('[Calendar].[AnnualCycleUpdate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleUpdate] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[AnnualCycleUpdate]
(
	@AnnualCycleId INT,
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT,
	@IsInactive BIT,
	@Activities [Calendar].[AnnualCycleActivityType] READONLY,
	@Readers [Calendar].[AnnualCycleReaderType] READONLY,
	@Exclusions [Calendar].[AnnualCycleExclusionType] READONLY,
	@UserId INT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
	BEGIN TRAN
		BEGIN TRY
			--function body
			
			IF EXISTS (SELECT * FROM Calendar.AnnualCycles WHERE AnnualCycleId = @AnnualCycleId AND CreatedBy = @UserId )
			BEGIN
				UPDATE Calendar.AnnualCycles
				SET 
				Name = @Name,
				[Description] = @Description,
				Partitioning = @Partitioning,
				[Year] = @Year,
				ViewType = @ViewType,
				IsInactive = @IsInactive
				WHERE AnnualCycleId = @AnnualCycleId
				
				DELETE FROM [Calendar].[AnnualCycleActivities] WHERE AnnualCycleId = @AnnualCycleId
				DELETE FROM [Calendar].[AnnualCycleReaders] WHERE AnnualCycleId = @AnnualCycleId
				DELETE FROM [Calendar].[AnnualCycleExclusions] WHERE AnnualCycleId = @AnnualCycleId
				
				INSERT [Calendar].[AnnualCycleActivities]
				(AnnualCycleId, ActivityId)
				SELECT @AnnualCycleId, ActivityId
				FROM @Activities
				
				INSERT  [Calendar].[AnnualCycleReaders]
				(AnnualCycleId, ReaderTypeId, ReaderId)
				SELECT @AnnualCycleId, ReaderTypeId, ReaderId
				FROM @Readers
				
				INSERT [Calendar].[AnnualCycleExclusions]
				(AnnualCycleId, DepartmentId, EmployeeId)
				SELECT @AnnualCycleId, DepartmentId, EmployeeId
				FROM @Exclusions
			END
			--function body
			IF @@TRANCOUNT > 0
			COMMIT TRAN;
		END TRY
		BEGIN CATCH	
			DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE(), 
				@ErrorSeverity INT = ERROR_SEVERITY(), 
				@ErrorState INT = ERROR_STATE();
			IF @@TRANCOUNT > 0
				ROLLBACK TRAN
			RAISERROR (@ErrorMessage, @ErrorSeverity, @ErrorState);
		END CATCH
	SELECT 1;	
END	

