INSERT INTO #Description VALUES ('be_GetReadingListDetailsById tblDepartmentGetSubDepartments')
GO

IF OBJECT_ID('[dbo].[be_GetReadingListDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetReadingListDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[be_GetReadingListDetailsById]
    @Id INT
AS
BEGIN

DECLARE @ExclusionList TABLE(
	ReadingListExclusionId INT,
	ReadingListId INT,
	DepartmentId INT,
	EmployeeId INT,
	DepartmentName NVARCHAR(500),
	EmployeeName NVARCHAR(500)
)

INSERT INTO @ExclusionList
    SELECT
        ReadingListExclusionId,
        ReadingListId,
        DepartmentId,
        EmployeeId,
        d.strName AS DepartmentName,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName
    FROM
        ReadingListExclusions rle
            INNER JOIN tblDepartment d ON rle.DepartmentId = d.iDepartmentId
            INNER JOIN tblEmployee e ON rle.EmployeeId = e.iEmployeeId
    WHERE
        rle.ReadingListId = @Id

--------------------------
    SELECT
        rl.ReadingListId,
        rl.Name,
        rl.Description,
        rl.IsInactive,
		rl.CreatedDate,
		rl.CreatedBy,
		ISNULL(e.strFirstName, '') + ' ' + ISNULL(e.strLastName, '') AS CreatedByName,
		ISNULL(e2.strFirstName, '') + ' ' + ISNULL(e2.strLastName, '') AS UpdatedByName,			
		rl.UpdatedDate,
		rl.UpdatedBy,
		rl.ReadingReceiptsExpire,
		rl.ReadingReceiptValidity
    FROM
        ReadingList rl
		LEFT JOIN tblEmployee e ON rl.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON rl.UpdatedBy = e2.iEmployeeId		
    WHERE
        rl.ReadingListId = @Id
        
--------------------------        
    SELECT
        rld.ReadingListDocumentId,
        rld.ReadingListId,
        rld.DocumentId,
        d.strName AS DocumentName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS DocumentPath
    FROM
        ReadingListDocuments rld
            JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
    WHERE
        d.iLatestVersion = 1
        AND ReadingListId = @Id
        
--------------------------        
    SELECT
        r.ReadingListReaderId,
        r.ReadingListId,
        r.ReaderTypeId,
        CASE
            WHEN r.ReaderTypeId = 1 THEN e.strFirstName + ' ' + e.strLastName
            WHEN r.ReaderTypeId = 2 THEN d.strName         
            WHEN r.ReaderTypeId = 3 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ReaderId)
        END AS ReaderName,
        r.ReaderId,
        CASE 
			WHEN r.ReaderTypeId = 1 THEN 1
			WHEN r.ReaderTypeId = 2 THEN ISNULL((SELECT COUNT(e2.iDepartmentId) FROM tblEmployee e2 WHERE e2.iDepartmentId = r.ReaderId AND e2.iEmployeeId NOT IN (SELECT e3.EmployeeId FROM @ExclusionList e3)), 0)
			WHEN r.ReaderTypeId = 3 THEN ISNULL((SELECT COUNT(s2.iEmployeeId) FROM dbo.relEmployeeSecGroup s2 WHERE s2.iSecGroupId = r.ReaderId), 0)
		END AS NumberOfReaders
    FROM
        ReadingListReaders r
        LEFT JOIN tblEmployee e ON r.ReaderId = e.iEmployeeId AND r.ReaderTypeId = 1
        LEFT JOIN tblDepartment d ON r.ReaderId = d.iDepartmentId AND r.ReaderTypeId = 2
        LEFT JOIN tblSecGroup s ON r.ReaderId = s.iSecGroupId AND r.ReaderTypeId = 3
    WHERE
        r.ReadingListId = @Id
        
--------------------------        
    SELECT * FROM @ExclusionList
END
GO







--tblDepartmentGetSubDepartments
IF (OBJECT_ID('[tblDepartmentGetSubDepartments]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [tblDepartmentGetSubDepartments] AS SELECT 1'
GO	

ALTER PROCEDURE [tblDepartmentGetSubDepartments]
(
	@Id INT
)
AS
BEGIN
	
	DECLARE @Sub TABLE(
		iDepartmentId INT
	)
	
	DECLARE @Result TABLE(
		Id INT,
		Name NVARCHAR(100),
		NumberOfReaders INT
	)
	
	INSERT INTO @Sub
		SELECT iDepartmentId
		FROM dbo.m136_GetDepartmentsRecursive(@Id)
		WHERE iDepartmentId <> @Id
		
	INSERT INTO @Result(Id, Name, NumberOfReaders) 
		SELECT e.iDepartmentId, d.strName, COUNT(e.iEmployeeId) AS NumberOfReaders
		FROM tblEmployee e INNER JOIN tblDepartment d ON e.iDepartmentId = d.iDepartmentId
		WHERE EXISTS (SELECT * FROM @Sub s WHERE s.iDepartmentId = e.iDepartmentId)
		GROUP BY e.iDepartmentId, d.strName
		
	SELECT * FROM @Result
	
END
GO