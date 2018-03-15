INSERT INTO #Description VALUES ('Implement department structure.')
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteEmployees] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteEmployees]
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            SET NOCOUNT ON;
            DELETE relEmployeePosition WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE relEmployeeSecGroup WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE relEmployeeDepartment WHERE iEmployeeId IN (SELECT Id FROM @Employees);
            DELETE m136_HearingMembers WHERE EmployeeId IN (SELECT Id FROM @Employees);
            DELETE tblEmployee WHERE tblEmployee.iEmployeeId IN (SELECT Id FROM @Employees);
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK;
        DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
    END CATCH
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'iSort'
      AND Object_ID = Object_ID(N'dbo.tblDepartment'))
BEGIN
    ALTER TABLE dbo.tblDepartment ADD iSort [int];
END
GO


IF OBJECT_ID('[dbo].[fnGetDepartmentsChildCount]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnGetDepartmentsChildCount]() RETURNS INT AS BEGIN RETURN 0; END')
GO
ALTER FUNCTION [dbo].[fnGetDepartmentsChildCount] 
(
	@iDepartmentId INT
)
RETURNS INT
AS
BEGIN
	
	DECLARE @ReturnVal INT = 0;
	SELECT @ReturnVal = COUNT(td.iDepartmentId) 
	FROM dbo.tblDepartment td WHERE td.iDepartmentParentId = @iDepartmentId;
	
	RETURN @ReturnVal;
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDepartments]
	@iDepartmentId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT	dpt.iDepartmentId, 
			dpt.strName, 
			dpt.strDescription,
			dpt.iDepartmentParentId, 
			dpt.iLevel,
			dpt.bCompany,
			dpt.strOrgNo,
			tc.strName AS Country,
			[dbo].[fn136_GetDepartmentPath](dpt.iDepartmentId) AS [Path],
			dpt.strVisitAddress1, 
			dpt.strVisitAddress2, 
			dpt.strVisitAddress3, 
			dpt.strAddress1, 
			dpt.strAddress2, 
			dpt.strAddress3,
			dpt.strPhone, 
			dpt.strFax, 
			dpt.strEmail, 
			dpt.strURL,
			dpt.iCountryId,
			dbo.fnGetDepartmentsChildCount(dpt.iDepartmentId) AS iChildCount
		FROM dbo.tblDepartment dpt
		LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = dpt.iCountryId
		WHERE ((@iDepartmentID IS NULL AND (dpt.iDepartmentParentId IS NULL OR dpt.iDepartmentParentId = 0)) 
			OR dpt.iDepartmentParentId = @iDepartmentID)
		ORDER BY dpt.iSort, dpt.strName;
END
GO


DECLARE @iDepartmentId [int] = 0,
	@iSort [int] = 0;
DECLARE DepartmentsCursor CURSOR FOR
	SELECT td.iDepartmentId
	FROM dbo.tblDepartment td ORDER BY td.strName;
OPEN DepartmentsCursor; 
FETCH NEXT FROM DepartmentsCursor INTO @iDepartmentId;
WHILE @@fetch_status = 0
BEGIN
	SET @iSort = @iSort + 1;
	UPDATE dbo.tblDepartment
	SET
	   iSort = @iSort
	WHERE iDepartmentId = @iDepartmentId;	   
			    
	FETCH NEXT FROM DepartmentsCursor INTO @iDepartmentId;
END
CLOSE DepartmentsCursor;
DEALLOCATE DepartmentsCursor;
GO

IF OBJECT_ID('[dbo].[MoveDepartment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[MoveDepartment] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[MoveDepartment] 
	@ItemId INT,
	@PreviousItemId INT,
	@ParentId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION;
			IF @PreviousItemId IS NULL
			BEGIN
				UPDATE dbo.tblDepartment
				SET iSort = iSort + 1
				WHERE @ParentId IS NULL OR iDepartmentParentId = @ParentId
				UPDATE tblDepartment
				SET iSort = -2147483648, iDepartmentParentId = @ParentId
				WHERE iDepartmentId = @ItemId
			END
			ELSE
			BEGIN
				DECLARE @PreviousSortOrder INT = (SELECT TOP 1 iSort FROM tblDepartment WHERE iDepartmentId = @PreviousItemId);
				UPDATE tblDepartment
				SET iSort = iSort + 1
				WHERE (@ParentId IS NULL OR iDepartmentParentId = @ParentId) AND iSort > @PreviousSortOrder
				UPDATE tblDepartment
				SET iSort = @PreviousSortOrder + 1, iDepartmentParentId = @ParentId
				WHERE iDepartmentId = @ItemId;
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
