INSERT INTO #Description VALUES ('Change permisions for calendar activities, create annual cycle tables')
GO

IF EXISTS (SELECT *
           FROM   sys.objects
           WHERE  object_id = OBJECT_ID(N'[CanUserAccessToActivityForCalendarView]')
                  AND type IN ( N'FN', N'IF', N'TF', N'FS', N'FT' ))
  DROP FUNCTION [dbo].[CanUserAccessToActivityForCalendarView]

GO 

Create FUNCTION [dbo].[CanUserAccessToActivityForCalendarView]
(
	@UserId INT,
	@ActivityId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
   IF EXISTS
    (
        SELECT 1
        FROM Calendar.Activities a
        WHERE
            a.ActivityId = @ActivityId
            AND 
            (
                --a.IsPermissionControlled = 0
                --OR
                (
                    CreatedBy = @UserId             -- Check creator permission
                    OR ResponsibleId = @UserId      -- Check main responsible permission
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
                    OR EXISTS(                      -- Check read permission
                        SELECT 1
                        FROM
                            tblAcl acl
                        WHERE
                            acl.iApplicationId = 160
                            AND acl.iEntityId = a.ActivityId
                            AND
                            (
                                (acl.iPermissionSetId = 701 AND acl.iSecurityId = @UserId)
                                OR (acl.iPermissionSetId = 702 AND acl.iSecurityId IN (SELECT Id FROM @UserDepartmentId))
                                OR (acl.iPermissionSetId = 703 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId))
                            )
                    )
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    RETURN @Result;
END
GO





IF OBJECT_ID('[Calendar].[GetUserActivitiesInYear]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInYear] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[GetUserActivitiesInYear]
    @UserId INT,
    @Year INT
AS
BEGIN
    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e1.strFirstName + ' ' + e1.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [Calendar].[Activities] activity INNER JOIN [Calendar].[ActivityTasks] task ON activity.ActivityId = task.ActivityId
                WHERE activity.ActivityId = a.ActivityId AND task.IsCompleted = 0 ) THEN 0
            ELSE 1
        END AS IsCompleted
    FROM
        [Calendar].[Activities] a
            LEFT JOIN tblEmployee e1 ON a.ResponsibleId = e1.iEmployeeId
            INNER JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        dbo.CanUserAccessToActivityForCalendarView(@UserId, a.ActivityId) = 1
        AND
        (
            Year(StartDate) = @Year
            OR Year(EndDate) = @Year
        )
    ORDER BY a.StartDate, a.Name
END
GO


IF OBJECT_ID('[Calendar].[GetUserActivitiesInMonthOfYear]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[GetUserActivitiesInMonthOfYear]
    @UserId INT,
    @Year INT,
    @Month INT
AS
BEGIN
    DECLARE @FirstDateOfMonth DATETIME;
    DECLARE @FirstDateOfNextMonth DATETIME;
    SET @FirstDateOfMonth = CAST(CONVERT(VARCHAR, @Year) + '-' + CONVERT(VARCHAR, @Month) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    IF(@Month < 12)
    BEGIN
        SET @FirstDateOfNextMonth = CAST(CONVERT(VARCHAR, @Year) + '-' + CONVERT(VARCHAR, @Month + 1) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    END
    ELSE
    BEGIN
        SET @FirstDateOfNextMonth = CAST(CONVERT(VARCHAR, @Year + 1) + '-' + CONVERT(VARCHAR, 1) + '-' + CONVERT(VARCHAR, 1) AS DATETIME)
    END
    SELECT
        a.ActivityId,
        a.Name,
        a.Description,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e1.strFirstName + ' ' + e1.strLastName AS ResponsibleName,
        a.CreatedBy,
        e2.strFirstName + ' ' + e2.strLastName AS CreatorName,
        CASE 
            WHEN EXISTS (
                SELECT 1 
                FROM [Calendar].[Activities] activity INNER JOIN [Calendar].[ActivityTasks] task ON activity.ActivityId = task.ActivityId
                WHERE activity.ActivityId = a.ActivityId AND task.IsCompleted = 0 ) THEN 0
            ELSE 1
        END AS IsCompleted
    FROM
        [Calendar].[Activities] a
            LEFT JOIN tblEmployee e1 ON a.ResponsibleId = e1.iEmployeeId
            INNER JOIN tblEmployee e2 ON a.CreatedBy = e2.iEmployeeId
    WHERE
        dbo.CanUserAccessToActivityForCalendarView(@UserId, a.ActivityId) = 1
        AND
        (
            EndDate >= @FirstDateOfMonth
            OR (StartDate >= @FirstDateOfMonth AND StartDate < @FirstDateOfNextMonth)
        )
    ORDER BY a.StartDate, a.Name
END
GO



IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.luAnnualCyclePartitionings') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.luAnnualCyclePartitionings(
		Id TINYINT PRIMARY KEY,
		Name NVARCHAR(100) NOT NULL
	);

	INSERT INTO Calendar.luAnnualCyclePartitionings(Id, Name) VALUES(1, 'Month');

	INSERT INTO Calendar.luAnnualCyclePartitionings(Id, Name) VALUES(2, 'Quarter');

	INSERT INTO Calendar.luAnnualCyclePartitionings(Id, Name) VALUES(3, 'Tertiary');

END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.AnnualCycles') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.AnnualCycles(
		AnnualCycleId INT IDENTITY(1,1) PRIMARY KEY,
		Name NVARCHAR(100) NOT NULL,
		[Description] NVARCHAR(4000) NULL,
		Partitioning TINYINT NOT NULL,
		[Year] INT NULL,
		ViewType TINYINT NOT NULL,
		IsInactive BIT NOT NULL,
		IsDeleted BIT NOT NULL
	);
	
	ALTER TABLE Calendar.AnnualCycles WITH NOCHECK ADD CONSTRAINT FK_AnnualCycles_luAnnualCyclePartitionings FOREIGN KEY (Partitioning) REFERENCES Calendar.luAnnualCyclePartitionings(Id)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.AnnualCycleActivities') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.AnnualCycleActivities(
		AnnualCycleActivitiyId INT IDENTITY(1,1) PRIMARY KEY,
		AnnualCycleId INT NOT NULL,
		ActivityId INT NOT NULL
	);

	ALTER TABLE Calendar.AnnualCycleActivities WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleActivities_AnnualCycles FOREIGN KEY (AnnualCycleId) REFERENCES Calendar.AnnualCycles(AnnualCycleId);
	ALTER TABLE Calendar.AnnualCycleActivities WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleActivities_Activities FOREIGN KEY (ActivityId) REFERENCES Calendar.Activities(ActivityId);
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.AnnualCycleReaders') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.AnnualCycleReaders(
		AnnualCycleViewerId INT IDENTITY(1,1) PRIMARY KEY,
		AnnualCycleId INT NOT NULL,
		ReaderTypeId SMALLINT NOT NULL,
		ReaderId INT NOT NULL
	);
	ALTER TABLE Calendar.AnnualCycleReaders WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleReaders_AnnualCycles FOREIGN KEY (AnnualCycleId) REFERENCES Calendar.AnnualCycles(AnnualCycleId);
	ALTER TABLE Calendar.AnnualCycleReaders WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleReaders_luReaderTypes FOREIGN KEY (ReaderTypeId) REFERENCES dbo.luReaderTypes(Id);
END
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Calendar.AnnualCycleExclusions') AND type in (N'U'))
BEGIN
	CREATE TABLE Calendar.AnnualCycleExclusions(
		AnnualCycleExclusionId INT IDENTITY(1,1) PRIMARY KEY,
		AnnualCycleId INT NOT NULL,
		DepartmentId INT NOT NULL,
		EmployeeId INT NOT NULL
	);
	ALTER TABLE Calendar.AnnualCycleExclusions WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleExclusions_AnnualCycles FOREIGN KEY (AnnualCycleId) REFERENCES Calendar.AnnualCycles(AnnualCycleId);
	ALTER TABLE Calendar.AnnualCycleExclusions WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleReaders_tblDepartment FOREIGN KEY (DepartmentId) REFERENCES dbo.tblDepartment(iDepartmentId);
	ALTER TABLE Calendar.AnnualCycleExclusions WITH NOCHECK ADD CONSTRAINT FK_AnnualCycleReaders_tblEmployee FOREIGN KEY (EmployeeId) REFERENCES dbo.tblEmployee(iEmployeeId);
END
GO

IF TYPE_ID(N'Calendar.AnnualCycleActivityType') IS NULL
CREATE TYPE [Calendar].[AnnualCycleActivityType] AS TABLE(
	ActivityId INT
)
GO

IF TYPE_ID(N'Calendar.AnnualCycleReaderType') IS NULL
CREATE TYPE [Calendar].[AnnualCycleReaderType] AS TABLE(
	ReaderTypeId SMALLINT,
	ReaderId INT
)
GO

IF TYPE_ID(N'Calendar.AnnualCycleExclusionType') IS NULL
CREATE TYPE [Calendar].[AnnualCycleExclusionType] AS TABLE(
	DepartmentId INT,
	EmployeeId INT
)
GO

IF TYPE_ID(N'Calendar.AnnualCycleDeletedIds') IS NULL
CREATE TYPE [Calendar].[AnnualCycleDeletedIds] AS TABLE(
	AnnualCycleId INT
)
GO

IF TYPE_ID(N'dbo.Ids') IS NULL
CREATE TYPE [dbo].[Ids] AS TABLE(
	Id INT
)
GO


IF (OBJECT_ID('[Calendar].[AnnualCycleDelete]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleDelete] AS SELECT 1'
GO

ALTER PROCEDURE [Calendar].[AnnualCycleDelete]
(
	@AnnualCycleIds [Calendar].[AnnualCycleDeletedIds] READONLY
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



IF (OBJECT_ID('[Calendar].[AnnualCycleGetById]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleGetById] AS SELECT 1'
GO

ALTER PROCEDURE [Calendar].[AnnualCycleGetById]
(
	@AnnualCycleId INT
)
AS
BEGIN
	SELECT * 
	FROM Calendar.AnnualCycles
	WHERE AnnualCycleId = @AnnualCycleId
	AND IsDeleted = 0

---activity
	SELECT 
	a.ActivityId,
	a.Name,
	a.[Description],
	a.StartDate,
	a.EndDate,
	a.CategoryId,
	ac.Name AS CategoryName
	FROM Calendar.Activities a
	INNER JOIN Calendar.AnnualCycleActivities aca ON aca.ActivityId = a.ActivityId
	LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
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





IF (OBJECT_ID('[Calendar].[AnnualCycleGetPaged]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleGetPaged] AS SELECT 1'
GO	

ALTER PROCEDURE [Calendar].[AnnualCycleGetPaged]
(
	@PageIndex int,
	@PageSize int,
	@Keyword nvarchar(200)
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

INSERT INTO @TempTable
               SELECT AnnualCycleId,
					Name,
					[Description],               
					Partitioning,
					[Year],
					ViewType,
					IsInactive,    
					IsDeleted,                         
                    ROW_NUMBER() OVER (ORDER BY 
							CASE WHEN @SortExpression='' THEN AnnualCycleId END DESC																																											      
						) AS rownumber
                FROM Calendar.AnnualCycles
				WHERE  (@Keyword IS NULL OR (@Keyword IS NOT NULL AND Name LIKE '%'+@Keyword+'%')) 
				AND IsDeleted = 0

            SELECT * FROM @TempTable WHERE (@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) ORDER BY rownumber
            --count total rows           
            SELECT COUNT(*)          
			FROM  @TempTable
	
END
GO





IF (OBJECT_ID('[Calendar].[AnnualCycleInsert]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleInsert] AS SELECT 1'
GO

ALTER PROCEDURE [Calendar].[AnnualCycleInsert]
(
	@Name NVARCHAR(100) ,
	@Description NVARCHAR(4000) ,
	@Partitioning TINYINT,
	@Year INT,
	@ViewType TINYINT
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRAN
		BEGIN TRY

			--function body
			INSERT INTO Calendar.AnnualCycles
			(Name, [Description], Partitioning, [Year], ViewType, IsInactive, IsDeleted)
			VALUES 
			(@Name, @Description, @Partitioning, @Year, @ViewType, 0, 0)
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



IF (OBJECT_ID('[Calendar].[AnnualCycleUpdate]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleUpdate] AS SELECT 1'
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
	@Exclusions [Calendar].[AnnualCycleExclusionType] READONLY
)
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRAN
		BEGIN TRY

			--function body
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



IF (OBJECT_ID('[Calendar].[AnnualCycleGetByUserId]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[AnnualCycleGetByUserId] AS SELECT 1'
GO

ALTER PROCEDURE [Calendar].[AnnualCycleGetByUserId]
(
	--TODO : how to filter by userId?
	@UserId INT
)
AS
BEGIN
	SELECT 
	AnnualCycleId,
	Name,
	[Description] 
	FROM Calendar.AnnualCycles
	WHERE IsDeleted = 0 AND IsInactive = 0
	ORDER BY Name ASC

END	
GO




IF (OBJECT_ID('[Calendar].[SearchActivities]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [Calendar].[SearchActivities] AS SELECT 1'
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
        Description NVARCHAR(MAX), 
        IsPermissionControlled BIT, 
        CategoryId INT, 
        CategoryName NVARCHAR(150)
    );
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    INSERT INTO @Activities
        (ActivityId, Name, StartDate, EndDate, ResponsibleId, ResponsibleName, CreatedBy, Description, IsPermissionControlled, CategoryId, CategoryName)
    SELECT
        a.ActivityId,
        a.Name,
        a.StartDate,
        a.EndDate,
        a.ResponsibleId,
        e.strFirstName + ' ' + e.strLastName AS ResponsibleName,
        a.CreatedBy,
        a.Description,
        a.IsPermissionControlled,
        ac.CategoryId,
        ac.Name AS CategoryName
    FROM
        Calendar.Activities a
            LEFT JOIN Calendar.ActivityCategories ac ON a.CategoryId = ac.CategoryId
            LEFT JOIN tblEmployee e ON a.ResponsibleId = e.iEmployeeId
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
    SELECT
        ActivityId, 
        Name, 
        StartDate, 
        EndDate, 
        ResponsibleId, 
        ResponsibleName, 
        CreatedBy, 
        Description, 
        IsPermissionControlled, 
        CategoryId, 
        CategoryName
    FROM @Activities
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
