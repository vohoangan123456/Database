INSERT INTO #Description VALUES ('Modify SP for reading list report')
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
            INNER JOIN tblEmployee e ON e.iDepartmentId = rlr.ReaderId AND rlr.ReaderTypeId = 2 AND e.iEmployeeId NOT IN(SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId = r.ReadingListId AND DepartmentId = e.iDepartmentId)
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
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId AND e.iEmployeeId NOT IN (
																		SELECT EmployeeId 
																		FROM dbo.ReadingListExclusions 
																		WHERE ReadingListId = r.ReadingListId AND DepartmentId = e.iDepartmentId)
            LEFT JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        AND r.ReadingListId IN (SELECT Id FROM @ReadingListIds)
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfDepartments @DepartmentId, @IncludeSubDepartments, @ReadingListIds
END
GO

IF OBJECT_ID('[dbo].[GetReadingListDocumentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListDocumentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListDocumentsOfUser]
    @UserId INT,
    @ReadingListIds AS [dbo].[Item] READONLY
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
    
    SELECT DISTINCT 
        rl.Name AS ReadingListName,
        d.iDocumentId AS DocumentId,
        d.strName DocumentName,
        d.iVersion DocumentVersion,
        (SELECT TOP 1 dtmConfirm FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId) AS ConfirmationDate
    FROM 
        ReadingList rl 
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId 
            INNER JOIN ReadingListDocuments rld ON rl.ReadingListId = rld.ReadingListId 
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId 
    WHERE 
        rl.IsDeleted = 0 
        AND d.iLatestApproved = 1 
        AND ReaderTypeId IN (1,2,3) 
        AND 
        (
            (ReaderId = @UserId AND ReaderTypeId = 1)
            OR (
				ReaderTypeId = 2 AND ReaderId IN (SELECT Id FROM @UserDepartmentId) 
				 AND @UserId NOT IN (SELECT EmployeeId FROM dbo.ReadingListExclusions WHERE ReadingListId IN (SELECT Id FROM @ReadingListIds) AND DepartmentId IN (SELECT Id FROM @UserDepartmentId))
				)
            OR (ReaderTypeId = 3 AND ReaderId IN (SELECT Id FROM @UserRoleId))
        )
        AND rl.ReadingListId IN (SELECT Id FROM @ReadingListIds)
END
GO





