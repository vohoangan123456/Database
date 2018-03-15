INSERT INTO #Description VALUES ('Update [CanUserEditAnnualCycle], [AnnualCycleGetById], [AnnualCycleUpdate] proc')
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[CanUserEditAnnualCycle]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[CanUserEditAnnualCycle]

GO 
CREATE FUNCTION [dbo].[CanUserEditAnnualCycle]
(
	@UserId INT,
	@AnnualCycleId INT
)
RETURNS BIT
AS
BEGIN
	DECLARE @UserRoleId TABLE(Id INT);
	DECLARE @CreatedBy INT;
	
	SELECT @CreatedBy = CreatedBy FROM Calendar.AnnualCycles WHERE AnnualCycleId = @AnnualCycleId;	
	
	IF @UserId = @CreatedBy
	BEGIN
		RETURN 1;
	END
	
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId	
	
	
	IF EXISTS ( 
                SELECT 1
                FROM
                    tblAcl acl
                WHERE
                    acl.iApplicationId = 160
                    AND iBit > 0
                    AND (acl.iPermissionSetId = 700 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId))
               )
	
	BEGIN
		RETURN 1;
	END
	
    RETURN 0;
END
GO


ALTER PROCEDURE [Calendar].[AnnualCycleGetById]
(
	@AnnualCycleId INT,
	@UserId INT,
	@IsBackend BIT = 0	
)
AS
BEGIN
	DECLARE @CanUserEditAnnualCycle BIT;
	SET @CanUserEditAnnualCycle = [dbo].[CanUserEditAnnualCycle](@UserId, @AnnualCycleId);
	
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
		CASE
			WHEN @CanUserEditAnnualCycle = 1 THEN 0
			ELSE 1
		END AS [ReadOnly],
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
			DECLARE @CanUserEditAnnualCycle BIT;
			SET @CanUserEditAnnualCycle = [dbo].[CanUserEditAnnualCycle](@UserId, @AnnualCycleId);		
			--function body
			IF EXISTS (SELECT * FROM Calendar.AnnualCycles WHERE AnnualCycleId = @AnnualCycleId AND @CanUserEditAnnualCycle = 1)
			BEGIN
				UPDATE Calendar.AnnualCycles
				SET 
				Name = @Name,
				[Description] = @Description,
				Partitioning = @Partitioning,
				[Year] = @Year,
				ViewType = @ViewType,
				IsInactive = @IsInactive,
				UpdatedBy = @UserId,
				UpdatedDate = GETUTCDATE()
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
GO



 ALTER PROCEDURE [Calendar].[AnnualCycleGetPaged]
(
	@PageIndex int,
	@PageSize int,
	@Keyword nvarchar(200),
	@UserId INT,
	@IsBackend BIT = 0,
	@OnlyMine BIT = 0
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
					AND	(@OnlyMine = 0 OR (@OnlyMine = 1 AND ac.CreatedBy = @UserId)) 
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