INSERT INTO #Description VALUES ('Update Activity Table')
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
	@IsBackend BIT = 0,
	@OnlyMine BIT = 0
)
AS
BEGIN
	DECLARE @UserRoleId TABLE(Id INT);	
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId;
        
    DECLARE @UserCanEdit BIT;		
	SET @UserCanEdit = 0;
	
	
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
		SET @UserCanEdit = 1;
	END
    

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
		IsSchoolYear BIT,
		[ReadOnly] BIT,
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
						ac.IsSchoolYear,
						CASE
							WHEN  @UserCanEdit = 1 THEN 0
							WHEN  @UserCanEdit = 0 AND @UserId = ac.CreatedBy THEN 0
							WHEN  @UserCanEdit = 0 AND ac.CreatedBy IS NULL THEN 0							
							WHEN  @UserCanEdit = 0 AND @UserId <> ac.CreatedBy THEN 1
						END AS [ReadOnly],                     
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
			WHERE EXISTS (SELECT * FROM @AnnualCycleIds targ WHERE targ.AnnualCycleId = src.AnnualCycleId AND [dbo].[CanUserEditAnnualCycle](@UserId, targ.AnnualCycleId) = 1)
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


IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[CanUserEditActivity]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[CanUserEditActivity]

GO 

CREATE FUNCTION [dbo].[CanUserEditActivity]
(
	@UserId INT,
	@ActivityId INT
)
RETURNS BIT
AS
BEGIN
	DECLARE @UserRoleId TABLE(Id INT);
	DECLARE @CreatedBy INT;
	SELECT @CreatedBy = CreatedBy FROM Calendar.Activities WHERE ActivityId = @ActivityId;	
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




IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[dbo].[ActivityMainResponsibles]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[ActivityMainResponsibles]

GO 

CREATE FUNCTION [dbo].[ActivityMainResponsibles]()
RETURNS @MainResponsibleActivities TABLE(
	UserId INT,
	ActivityId INT	
)
AS
BEGIN

	INSERT INTO @MainResponsibleActivities(UserId, ActivityId)
	SELECT ResponsibleId, ActivityId
	FROM Calendar.ActivityResponsibles
	WHERE ResponsibleTypeId = 701 --Person
	AND (ResponibilityType IS NULL OR ResponibilityType = 0)


	INSERT INTO @MainResponsibleActivities(UserId, ActivityId)
	SELECT es.iEmployeeId, ar.ActivityId
	FROM relEmployeeSecGroup es INNER JOIN Calendar.ActivityResponsibles ar ON es.iSecGroupId = ar.ResponsibleId
	WHERE ar.ResponsibleTypeId = 703 --Role
	AND (ar.ResponibilityType IS NULL OR ar.ResponibilityType = 0)

	INSERT INTO @MainResponsibleActivities(UserId, ActivityId)
	SELECT e.iEmployeeId, ar.ActivityId
	FROM [dbo].[tblEmployee] e INNER JOIN Calendar.ActivityResponsibles ar ON e.iDepartmentId = ar.ResponsibleId
	WHERE ar.ResponsibleTypeId = 702 --Deparment
	AND (ar.ResponibilityType IS NULL OR ar.ResponibilityType = 0)
	
	Return;
END
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
    @AnnualCycleId INT,
    @MainResponsibleId INT = null
AS
BEGIN
      
    DECLARE @UserCanEdit BIT;		
	SET @UserCanEdit = 0;

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
        CategoryName NVARCHAR(150),
        [ReadOnly] BIT
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
		SET @UserCanEdit = 1;
	END 
	
    -----
    INSERT INTO @Activities
        (ActivityId, Name, StartDate, EndDate, ResponsibleId, ResponsibleName, CreatedBy, CreatorName, Description, IsPermissionControlled, CategoryId, CategoryName, [ReadOnly])
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
        ac.Name AS CategoryName,
		CASE
			WHEN  @UserCanEdit = 1 THEN 0
			WHEN  @UserCanEdit = 0 AND @UserId = a.CreatedBy THEN 0
			WHEN  @UserCanEdit = 0 AND a.CreatedBy IS NULL THEN 0							
			WHEN  @UserCanEdit = 0 AND @UserId <> a.CreatedBy THEN 1
		END AS [ReadOnly]         
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
            LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
            LEFT JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        dbo.CanUserAccessToActivity(@UserId, a.ActivityId) = 1
        AND
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
        AND
        (
			@MainResponsibleId IS NULL
			OR
			(EXISTS (SELECT m.* FROM [dbo].[ActivityMainResponsibles]() m WHERE m.UserId = @MainResponsibleId AND m.ActivityId = a.ActivityId))
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
        CategoryName,
        [ReadOnly]
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


IF OBJECT_ID('[Calendar].[GetActivityDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetActivityDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[GetActivityDetailsById]
    @ActivityId INT,
    @UserId INT
AS
BEGIN
	DECLARE @CanUserEdit BIT;
	SET @CanUserEdit = [dbo].[CanUserEditActivity](@UserId, @ActivityId);
    SELECT
        a.ActivityId,
        a.Name,
        a.[Description],
        a.StartDate,
        a.EndDate,
        a.CategoryId,
        a.ResponsibleId,
        a.IsPermissionControlled,
		a.IsRecurring,
		a.RecurrenceId,
		r.RecurringEndDate,
		r.RecurringOrdinalId,
		r.RecurringDayId,
		r.RecurringMonthsId,
		r.RecurringMonthperiod,
		a.Period,
		r.FixedDate AS RecurringFixedDate,
		r.FixedDateType AS RecurringFixedDateType,
		a.CreatedBy,
		a.CreatedDate,	
		a.UpdatedBy,
		a.UpdatedDate,
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,			
		CASE
			WHEN @CanUserEdit = 1 THEN 0
			ELSE 1
		END AS [ReadOnly]		
    FROM
        [Calendar].[Activities] a
		LEFT JOIN [Calendar].[Recurrence] r ON a.RecurrenceId = r.Id AND a.RecurrenceId IS NOT NULL
		LEFT JOIN tblEmployee e ON a.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON a.UpdatedBy = e2.iEmployeeId		
    WHERE
        ActivityId = @ActivityId
	-----------------------------
    SELECT
        ActivityResponsibleId,
        ActivityId,
        ResponsibleTypeId,
        ResponsibleId,
        ISNULL(ResponibilityType, 0) AS ResponibilityType,
        CASE
            WHEN ResponsibleTypeId = 701 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ResponsibleId)
            WHEN ResponsibleTypeId = 702 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ResponsibleId)
            WHEN ResponsibleTypeId = 703 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ResponsibleId)
        END AS ResponsibleName
    FROM
        [Calendar].[ActivityResponsibles]
    WHERE
        ActivityId = @ActivityId
	-------------------------------
	DECLARE @ResponsibleTable TABLE(
		ResponsibleId INT,
		ResponibilityType BIT
	);
	DECLARE @DepartmentResponsible INT;
	DECLARE @DepartmentResponibilityType BIT;
	SELECT @DepartmentResponsible = ResponsibleId,
		@DepartmentResponibilityType = ResponibilityType
	FROM Calendar.ActivityResponsibles 
	WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 702 --Deparment
	INSERT INTO @ResponsibleTable
		SELECT ResponsibleId ,
		ResponibilityType
		FROM Calendar.ActivityResponsibles 
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 701 --Person
	INSERT INTO @ResponsibleTable
		SELECT es.iEmployeeId,
		ar.ResponibilityType
		FROM relEmployeeSecGroup es
		INNER JOIN Calendar.ActivityResponsibles ar
		ON es.iSecGroupId = ar.ResponsibleId
		WHERE ActivityId = @ActivityId AND ResponsibleTypeId = 703 --Role	
	IF @DepartmentResponsible IS NOT NULL
	BEGIN
		INSERT INTO @ResponsibleTable
		SELECT e.iEmployeeId As ResponsibleId,
		@DepartmentResponibilityType AS ResponibilityType
		FROM [dbo].[tblEmployee] e 
		INNER JOIN 
		(
			SELECT iDepartmentId 
			FROM m136_GetDepartmentsRecursive(@DepartmentResponsible)		
		)
		AS d
		ON e.iDepartmentId = d.iDepartmentId
	END	
    SELECT
        at.ActivityTaskId,
        at.ActivityId,
        at.Name,
        at.Description,
        at.CreatedBy,
        at.CreatedDate,
        at.IsCompleted,
        at.CompletedDate,
        at.ResponsibleId,
        e.[strFirstName] + ' ' + e.[strLastName] AS ResponsibleName
    FROM
        [Calendar].[ActivityTasks] at
        LEFT JOIN [dbo].[tblEmployee] e
        ON at.ResponsibleId = e.[iEmployeeId]
    WHERE
        at.ActivityId = @ActivityId 
        AND
        (
			at.CreatedBy = @UserId
			OR
			at.ResponsibleId = 0 
			OR 
			EXISTS (
						SELECT * 
						FROM @ResponsibleTable rt 
						WHERE rt.ResponsibleId = @UserId 
						AND (
								rt.ResponibilityType = 0
								OR
								rt.ResponibilityType IS NULL
								OR
								(
									rt.ResponibilityType = 1 AND rt.ResponsibleId = at.ResponsibleId									
								)
							) 
					)
		)
	---------------------------
    SELECT
        ad.ActivityDocumentId,
        ad.ActivityId,
        ad.DocumentId,
        d.strName AS DocumentName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS DocumentPath
    FROM
        [Calendar].[ActivityDocuments] ad
            INNER JOIN [dbo].[m136_tblDocument] d ON ad.DocumentId = d.iDocumentId
    WHERE
        ad.ActivityId = @ActivityId
        AND iLatestVersion = 1
	--
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
        iEntityId = @ActivityId
        AND iApplicationId = 160
END
GO


ALTER PROCEDURE [Calendar].[ActivityIsCreator] 
    @UserId INT,
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    IF EXISTS(SELECT 1 FROM [Calendar].[Activities] WHERE [dbo].[CanUserEditActivity](@UserId, ActivityId) = 0 AND ActivityId IN (SELECT Id FROM @ActivityIds))
    BEGIN
        SELECT 0
    END
    ELSE
    BEGIN
        SELECT 1
    END
END
GO


IF OBJECT_ID('[Calendar].[ActivityIsCreatorOrResponsible]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[ActivityIsCreatorOrResponsible] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[ActivityIsCreatorOrResponsible] 
    @UserId INT,
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    IF EXISTS(
        SELECT 1 
        FROM [Calendar].[Activities] 
        WHERE [dbo].[CanUserEditActivity](@UserId, ActivityId) = 0
            AND ResponsibleId <> @UserId AND ActivityId IN (SELECT Id FROM @ActivityIds))
    BEGIN
        SELECT 0
    END
    ELSE
    BEGIN
        IF EXISTS
        (
            SELECT 1
            FROM
                Calendar.ActivityResponsibles ar
            WHERE
                ar.ActivityId IN (SELECT Id FROM @ActivityIds)
                AND
                (
                    (ar.ResponsibleTypeId = 701 AND ar.ResponsibleId <> @UserId)
                    OR (ar.ResponsibleTypeId = 702 AND ar.ResponsibleId NOT IN (SELECT Id FROM @UserDepartmentId))
                    OR (ar.ResponsibleTypeId = 703 AND ar.ResponsibleId NOT IN (SELECT Id FROM @UserRoleId))
                )
        )
        BEGIN
            SELECT 0
        END
        ELSE
        BEGIN
            SELECT 1
        END
    END
END
GO
