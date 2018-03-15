INSERT INTO #Description VALUES ('Create procedure m136_be_GetDepartmentEmployees. Modify procedures GetNumberOfOkReadingListsForUsersOfDepartments, GetReadingListUsersOfDepartmentsForReport')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentEmployees] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDepartmentEmployees] 
	@DepartmentId INT
AS
BEGIN
	SELECT
        iEmployeeId,
        strFirstName,
        strLastName,
        strLoginName,
        strPhoneWork,
        strPhoneMobile
    FROM
        tblEmployee
    WHERE
        iDepartmentId = @DepartmentId
        OR iEmployeeId IN (SELECT iEmployeeId FROM relEmployeeDepartment WHERE iDepartmentId = @DepartmentId)
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]
	@DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN

    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    IF @IncludeSubDepartments = 1
    BEGIN
        INSERT INTO @DepartmentIds (DepartmentId)
        SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)
    END
    
    SELECT
        e.iEmployeeId AS UserId, 
        r.ReadingListId AS ReadingListId, 
        r.Name AS ReadingListName, 
        dbo.AreDocumentsInReadingListConfirmedByUser(e.iEmployeeId, r.ReadingListId) AS IsOK
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId
            INNER JOIN tblEmployee e ON e.iDepartmentId = rlr.ReaderId AND rlr.ReaderTypeId = 2 --Department reader
    WHERE
        r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
        
END
GO

IF OBJECT_ID('[dbo].[GetReadingListUsersOfDepartmentsForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport]
    @DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN

    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    IF @IncludeSubDepartments = 1
    BEGIN
        INSERT INTO @DepartmentIds (DepartmentId)
        SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)
    END
    
    SELECT
        e.iEmployeeId AS UserId,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName,
        d.strName AS DepartmentName,
        COUNT(DISTINCT r.ReadingListId) AS NumberOfReadingLists,
        COUNT(DISTINCT doc.iEntityId) AS NumberOfDocuments,
        COUNT(DISTINCT cr.iEntityId) AS NumberOfOKDocuments
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON rlr.ReaderId = d.iDepartmentId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
            LEFT JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfDepartments @DepartmentId, @IncludeSubDepartments, @ReadingListIds
END
GO