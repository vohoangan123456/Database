INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_fnGetFavoriteFolders]')
GO

IF OBJECT_ID('[dbo].[IsFolderDepartment]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[IsFolderDepartment]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[IsFolderDepartment] 
(
	@EmployeeId INT,
	@HandbookId INT
)  
RETURNS BIT
AS  
BEGIN 
	DECLARE @RecursiveDepartment BIT, @DepartmentId INT = NULL;
	DECLARE @DepartmentTable TABLE(DepartmentId INT)
	
	SELECT @RecursiveDepartment = h.RecursiveDepartment, @DepartmentId = h.iDepartmentId
	FROM dbo.m136_tblHandbook h
	WHERE h.iDeleted = 0
		 AND h.iDepartmentId IS NOT NULL AND h.iDepartmentId <> 0
		 AND h.iHandbookId = @HandbookId
	IF @DepartmentId IS NULL
		BEGIN
			Return 0;
		END
	ELSE
		BEGIN
		
			INSERT INTO @DepartmentTable
			SELECT
				iDepartmentId
			FROM
				tblEmployee
			WHERE
				iEmployeeId = @EmployeeId
				
			INSERT INTO @DepartmentTable
			SELECT
				iDepartmentId
			FROM
				relEmployeeDepartment
			WHERE iEmployeeId = @EmployeeId
			
			IF @RecursiveDepartment = 0 
				BEGIN
					IF EXISTS (SELECT d.DepartmentId FROM @DepartmentTable d WHERE d.DepartmentId = @DepartmentId)
						Return 1;
				END
			ELSE
				BEGIN
					IF EXISTS (SELECT d.DepartmentId FROM @DepartmentTable d WHERE d.DepartmentId IN
									(SELECT iDepartmentId
									  FROM dbo.m136_GetDepartmentsRecursive(@DepartmentId)))
						Return 1;
				END
		END
	
	Return 0;
END
GO

IF OBJECT_ID('[dbo].[m136_fnGetFavoriteFolders]', 'if') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_fnGetFavoriteFolders]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[m136_fnGetFavoriteFolders]
(
	@EmployeeId INT, 
	@TreatDepartmentFoldersAsFavorites BIT,
	@DepartmentId INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		h.iHandbookId,
		CASE
			WHEN [dbo].[m136_IsForcedHandbook](@EmployeeId, h.iHandbookId) = 1 THEN 1
			ELSE 0
		END AS isForced,
		[dbo].[IsFolderDepartment](@EmployeeId, H.iHandbookId) as isDepartment,
		sd.iSort
	FROM
		m136_tblHandbook h
		LEFT JOIN m136_tblSubscribe sd 
			ON sd.iHandbookId = h.iHandbookId AND sd.iEmployeeId = @EmployeeId
	WHERE
		h.iDeleted = 0 
		AND ((sd.iEmployeeId = @EmployeeId AND sd.iFrontpage = 1)
			OR	([dbo].[m136_IsForcedHandbook](@EmployeeId, h.iHandbookId) = 1)
			OR	( @TreatDepartmentFoldersAsFavorites = 1 AND [dbo].[IsFolderDepartment](@EmployeeId, H.iHandbookId) = 1))
);
GO


