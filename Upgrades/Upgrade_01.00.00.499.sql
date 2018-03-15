INSERT INTO #Description VALUES ('Update SearchActivities proc')
GO

ALTER PROCEDURE [Calendar].[SearchActivities]
    @UserId INT,
    @Keyword NVARCHAR(MAX),
    @CategoryId INT,
    @ResponsibleId INT,
    @RoleId INT,
    @DepartmentId INT,
    @PersonId INT,
    @StartDate DATETIME,
    @EndDate DATETIME,
    @AnnualCycleId INT
AS
BEGIN
    -- This procedure is used in Activities Management view and Search Activities View
    -- Activities Management View allows users to search activities by Name & Description
    -- Search Activities View allows users to search activities by Keyword
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    DECLARE @Activities TABLE
    (
        ActivityId INT, 
        Name NVARCHAR(250), 
        StartDate DATETIME, 
        EndDate DATETIME, 
        ResponsibleId INT, 
        ResponsibleName NVARCHAR(250), 
        CreatedBy INT,
        CreatorName NVARCHAR(250), 
        Description NVARCHAR(MAX), 
        IsPermissionControlled BIT, 
        CategoryId INT, 
        CategoryName NVARCHAR(150)
    );
    ----
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    ----
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    -----
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    -----    
    INSERT INTO @Activities
        (ActivityId, Name, StartDate, EndDate, ResponsibleId, ResponsibleName, CreatedBy, CreatorName, Description, IsPermissionControlled, CategoryId, CategoryName)
    SELECT
        a.ActivityId,
        a.Name,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        a.Description,
        a.IsPermissionControlled,
        ac.CategoryId,
        ac.Name AS CategoryName
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
            LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
            LEFT JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
        (
            (
                @Keyword IS NULL
                OR a.Name LIKE '%' + @Keyword + '%'
                OR a.Description LIKE '%' + @Keyword + '%'
            )
            AND
            (
                @CategoryId IS NULL -- Get activities with and without category
                OR (@CategoryId = 0 AND a.CategoryId IS NULL) -- Get activities without category
                OR a.CategoryId = @CategoryId -- Get activities with specific category
            )
            AND
            (
                @ResponsibleId IS NULL
                OR a.ResponsibleId = @ResponsibleId
                OR EXISTS(                      -- Check co-responsible permission
                        SELECT 1
                        FROM
                            Calendar.ActivityResponsibles ar
                        WHERE
                            ar.ActivityId = a.ActivityId
                            AND
                            (
                                (ar.ResponsibleTypeId = 701 AND ar.ResponsibleId = @UserId)
                                OR (ar.ResponsibleTypeId = 702 AND ar.ResponsibleId IN (SELECT Id FROM @UserDepartmentId))
                                OR (ar.ResponsibleTypeId = 703 AND ar.ResponsibleId IN (SELECT Id FROM @UserRoleId))
                            )
                )
            )
            AND 
            (
                @RoleId IS NULL 
                OR (EXISTS(
                    SELECT 1 
                    FROM tblAcl acl
                    WHERE acl.iApplicationId = 160 
                        AND acl.iEntityId = a.ActivityId AND acl.iPermissionSetId = 703 AND acl.iSecurityId = @RoleId))
            )
            AND 
            (
                @DepartmentId IS NULL 
                OR (EXISTS(
                    SELECT 1 
                    FROM tblAcl acl 
                    WHERE iApplicationId = 160 
                        AND acl.iEntityId = a.ActivityId AND acl.iPermissionSetId = 702 AND acl.iSecurityId = @DepartmentId))
            )
            AND
            (
                @PersonId IS NULL 
                OR dbo.CanUserAccessToActivity(@PersonId, a.ActivityId) = 1
            )
            AND
            (
                @AnnualCycleId IS NULL
                OR (@AnnualCycleId IS NOT NULL AND EXISTS( SELECT targ.* FROM Calendar.AnnualCycleActivities targ WHERE targ.AnnualCycleId = @AnnualCycleId AND targ.ActivityId = a.ActivityId))
            )            
            AND (@StartDate IS NULL OR StartDate >= @StartDate)
            AND (@EndDate IS NULL OR EndDate <= @EndDate)
        )
    ORDER BY StartDate, Name
    -----
    SELECT
        ActivityId, 
        Name, 
        StartDate, 
        EndDate, 
        ResponsibleId, 
        ResponsibleName, 
        CreatedBy,
        CreatorName,         
        Description, 
        IsPermissionControlled, 
        CategoryId, 
        CategoryName
    FROM @Activities
    -----
    SELECT
        ActivityResponsibleId,
        ActivityId,
        ResponsibleTypeId,
        ResponsibleId,
        CASE
            WHEN ResponsibleTypeId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ResponsibleId)
            WHEN ResponsibleTypeId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ResponsibleId)
            WHEN ResponsibleTypeId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ResponsibleId)
        END AS ResponsibleName
    FROM
        [Calendar].[ActivityResponsibles]
    WHERE
        ActivityId IN (SELECT ActivityId FROM @Activities)
    ORDER BY ResponsibleTypeId, ResponsibleName
    -----
    SELECT
        iEntityId AS ActivityId,
        iPermissionSetId AS AccessTypeId,
        iSecurityId AS AccessId,
        CASE
            WHEN iPermissionSetId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = iSecurityId)
            WHEN iPermissionSetId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = iSecurityId)
            WHEN iPermissionSetId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = iSecurityId)
        END AS AccessName
    FROM
        tblAcl
    WHERE
        iEntityId IN (SELECT ActivityId FROM @Activities)
        AND iApplicationId = 160
    ORDER BY AccessTypeId, AccessName
END

GO



ALTER PROCEDURE [Calendar].[UpdateActivity] 
    @ActivityId INT,
    @Name NVARCHAR(250),
    @Description NVARCHAR(MAX),
    @StartDate DATETIME,
    @EndDate DATETIME,
    @CategoryId INT,
    @ResponsibleId INT,
    @UpdatedBy INT,
    @IsPermissionControlled BIT,
	@AnnualCycleId INT = NULL,
    @ActivityTasks AS Calendar.ActivityTaskItems READONLY,
    @ActivityDocuments AS Calendar.ActivityDocumentItems READONLY,
    @ActivityResponsibles AS Calendar.ActivityResponsibleItems READONLY,
    @ActivityAccesses AS Calendar.ActivityAccessItems READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DECLARE @Now DATETIME = GETDATE();
        UPDATE
            [Calendar].[Activities]
        SET
            Name = @Name,
            Description = @Description,
            StartDate = @StartDate,
            EndDate = @EndDate,
            CategoryId = @CategoryId,
            ResponsibleId = @ResponsibleId,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = @Now,
            IsPermissionControlled = @IsPermissionControlled
        WHERE
            ActivityId = @ActivityId
        -- Re-insert activity tasks
        DELETE FROM
            [Calendar].[ActivityTasks]
        WHERE
            ActivityId = @ActivityId
        INSERT INTO [Calendar].[ActivityTasks]
            (ActivityId, Name, Description, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate, IsCompleted)
            SELECT
                ActivityId,
                Name,
                Description,
                CreatedBy,
                CreatedDate,
                @UpdatedBy,
                @Now,
                IsCompleted
            FROM
                @ActivityTasks
        -- Re-insert activity documents
        DELETE FROM
            [Calendar].[ActivityDocuments]
        WHERE
            ActivityId = @ActivityId
        INSERT INTO [Calendar].[ActivityDocuments]
            (ActivityId, DocumentId)
            SELECT
                ActivityId,
                DocumentId
            FROM
                @ActivityDocuments
        -- Re-insert activity responsibles
        DELETE FROM
            Calendar.ActivityResponsibles
        WHERE
            ActivityId = @ActivityId
        INSERT INTO Calendar.ActivityResponsibles
            (ActivityId, ResponsibleTypeId, ResponsibleId)
            SELECT
                ActivityId,
                ResponsibleTypeId,
                ResponsibleId
            FROM
                @ActivityResponsibles
        -- Re-insert activity accesses
        DELETE FROM
            tblAcl
        WHERE
            iEntityId = @ActivityId
            AND iApplicationId = 160
        INSERT INTO tblAcl
            (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
            SELECT
                ActivityId,
                160,
                AccessId,
                AccessTypeId,
                0,
                0
            FROM
                @ActivityAccesses
				
		-- INSERT AnnualCycleActivities IF NOT EXISTS
		
		IF @AnnualCycleId IS NOT NULL AND NOT EXISTS( SELECT * FROM Calendar.AnnualCycleActivities WHERE AnnualCycleId = @AnnualCycleId AND ActivityId = @ActivityId)
		BEGIN
			INSERT INTO Calendar.AnnualCycleActivities(AnnualCycleId, ActivityId) VALUES(@AnnualCycleId, @ActivityId)
		END
		
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
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