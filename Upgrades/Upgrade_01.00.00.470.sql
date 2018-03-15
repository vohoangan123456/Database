INSERT INTO #Description VALUES ('Add SP for save search for annual cycle readers')
GO

IF NOT EXISTS (SELECT * FROM dbo.SearchFilterTypes WHERE Id = 8)
BEGIN
	INSERT INTO dbo.SearchFilterTypes(Name) VALUES('AnuualCycleReaders')
END
GO

IF OBJECT_ID('[Calendar].[GetReadersByReaderIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetReadersByReaderIds] AS SELECT 1')
GO
 
ALTER PROCEDURE [Calendar].[GetReadersByReaderIds]
(
	@Readers [Calendar].[AnnualCycleReaderType] READONLY
)
AS
BEGIN
	SELECT
		ReaderTypeId,
		CASE
			WHEN ReaderTypeId = 1 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ReaderId)
			WHEN ReaderTypeId = 2 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ReaderId)
			WHEN ReaderTypeId = 3 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ReaderId)
		END AS ReaderName,
		ReaderId
	FROM
		@Readers
	WHERE (ReaderTypeId = 1 AND EXISTS(SELECT 1 FROM tblEmployee WHERE iEmployeeId = ReaderId))
		  OR (ReaderTypeId = 2 AND EXISTS(SELECT 1 FROM tblDepartment WHERE iDepartmentId = ReaderId))
		  OR (ReaderTypeId = 3 AND EXISTS(SELECT 1 FROM tblSecGroup WHERE iSecGroupId = ReaderId))
	
END	
GO

IF OBJECT_ID('[Calendar].[GetUserExclusionsByIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [Calendar].[GetUserExclusionsByIds] AS SELECT 1')
GO
 
ALTER PROCEDURE [Calendar].[GetUserExclusionsByIds]
(
	@Exclusion Calendar.AnnualCycleExclusionType READONLY
)
AS
BEGIN
	SELECT
		e.DepartmentId,
		e.EmployeeId,
		d.strName as DepartmentName,
		ep.strFirstName + ' ' + ep.strLastName as EmployeeName
	FROM
		@Exclusion e
		JOIN dbo.tblDepartment d ON e.DepartmentId = d.iDepartmentId
		JOIN dbo.tblEmployee ep ON e.EmployeeId = ep.iEmployeeId
END	
GO