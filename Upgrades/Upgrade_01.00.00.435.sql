INSERT INTO #Description VALUES ('modify activity')
GO

IF OBJECT_ID('[Calendar].[DeleteActivities]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[DeleteActivities] AS SELECT 1')
GO
ALTER PROCEDURE [Calendar].[DeleteActivities] 
    @ActivityIds AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        DELETE FROM
            [Calendar].[ActivityResponsibles]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
			
        DELETE FROM
            [Calendar].[ActivityTasks]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
			
        DELETE FROM
            [Calendar].[ActivityDocuments]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
			
        DELETE FROM
            tblAcl
        WHERE
            iApplicationId = 160
            AND iEntityId IN (SELECT Id FROM @ActivityIds)
			
        DELETE FROM
            AnnualCycleActivities
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)		
			
        DELETE FROM
            [Calendar].[Activities]
        WHERE
            ActivityId IN (SELECT Id FROM @ActivityIds)
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




IF OBJECT_ID('[Calendar].[AnnualCycleGetById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[AnnualCycleGetById] AS SELECT 1')
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
