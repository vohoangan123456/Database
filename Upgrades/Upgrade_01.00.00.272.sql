INSERT INTO #Description VALUES('Create store procedures for reports related to reading lists')
GO

/* Reading list person */

IF OBJECT_ID('[dbo].[GetReadingListDocumentsOfUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListDocumentsOfUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListDocumentsOfUser]
    @UserId INT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    DECLARE @UserReadingDocumentsList TABLE
    (
        ReadingListName NVARCHAR(100),
        DocumentId INT,
        DocumentName NVARCHAR(200),
        DocumentVersion INT,
        ConfirmationDate DATETIME
    );
    
    -- Insert reading documents from person readers
    INSERT INTO @UserReadingDocumentsList
        (ReadingListName, DocumentId, DocumentName, DocumentVersion, ConfirmationDate)
    SELECT
        rl.Name,
        d.iDocumentId,
        d.strName,
        d.iVersion,
        (SELECT TOP 1 dtmConfirm FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingListDocuments rld ON rl.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
    WHERE
        rl.IsDeleted = 0
        AND d.iLatestApproved = 1
        AND ReaderTypeId = 1 -- Person reader
        AND ReaderId = @UserId
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        
    -- Insert reading list documents from department readers
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (ReadingListName, DocumentId, DocumentName, DocumentVersion, ConfirmationDate)
    SELECT
        rl.Name,
        d.iDocumentId,
        d.strName,
        d.iVersion,
        (SELECT TOP 1 dtmConfirm FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingListDocuments rld ON rl.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
    WHERE
        rl.IsDeleted = 0
        AND d.iLatestApproved = 1
        AND ReaderTypeId = 2 -- Department reader
        AND ReaderId IN (SELECT Id FROM @UserDepartmentId)
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        AND d.iDocumentID NOT IN (SELECT DocumentId FROM @UserReadingDocumentsList)
        
    -- Insert reading list documents from role readers
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
    
    INSERT INTO @UserReadingDocumentsList
        (ReadingListName, DocumentId, DocumentName, DocumentVersion, ConfirmationDate)
    SELECT
        rl.Name,
        d.iDocumentId,
        d.strName,
        d.iVersion,
        (SELECT TOP 1 dtmConfirm FROM m136_tblConfirmRead WHERE iEntityId = d.iEntityId AND iEmployeeId = @UserId)
    FROM 
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingListDocuments rld ON rl.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
    WHERE
        rl.IsDeleted = 0
        AND d.iLatestApproved = 1
        AND ReaderTypeId = 3 -- Role reader
        AND ReaderId IN (SELECT Id FROM @UserRoleId)
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        AND d.iDocumentID NOT IN (SELECT DocumentId FROM @UserReadingDocumentsList)
    
    -- Get final reading list documents
    SELECT
        DISTINCT DocumentId,
        ReadingListName,
        DocumentName,
        DocumentVersion,
        ConfirmationDate
    FROM
        @UserReadingDocumentsList
END
GO

/* End of reading list person */

/* Reading list department */

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfDepartments]
	@DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    DECLARE @UserConfirmedDocumentsOnReadingLists TABLE
    (
        UserId INT,
        ReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsOK BIT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    INSERT INTO @DepartmentIds (DepartmentId)
    SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)
    
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
    SELECT
        e.iEmployeeId, r.ReadingListId, r.Name, dbo.AreDocumentsInRedingListConfirmedByUser(e.iEmployeeId, r.ReadingListId)
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId
            INNER JOIN tblEmployee e ON e.iDepartmentId = rlr.ReaderId AND rlr.ReaderTypeId = 2 --Department reader
    WHERE
        (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
        
    SELECT
        UserId,
        ReadingListId,
        ReadingListName,
        IsOK
    FROM
        @UserConfirmedDocumentsOnReadingLists
END
GO

IF OBJECT_ID('[dbo].[GetReadingListUsersOfDepartmentsForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListUsersOfDepartmentsForReport]
    @DepartmentId INT,
    @IncludeSubDepartments BIT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @DepartmentIds TABLE
    (
        DepartmentId INT
    );
    
    INSERT INTO @DepartmentIds (DepartmentId) VALUES (@DepartmentId)
    
    INSERT INTO @DepartmentIds (DepartmentId)
    SELECT iDepartmentId FROM m136_GetDepartmentsRecursive(@DepartmentId)

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
        (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND r.IsDeleted = 0
        AND e.iDepartmentId IN (SELECT DepartmentId FROM @DepartmentIds)
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfDepartment @DepartmentId, @IncludeSubDepartments, @ReadingListId
END
GO

/* End of reading list department */

/* Reading list role */

IF OBJECT_ID('[dbo].[m136_be_GetSecurityGroupById]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetSecurityGroupById]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetSecurityGroupById]
	@RoleId INT
AS
BEGIN
    SELECT
        iSecGroupId,
		strName
	FROM
        tblSecGroup
	WHERE
        iSecGroupId = @RoleId
END
GO

IF OBJECT_ID('[dbo].[AreDocumentsInRedingListConfirmedByUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[AreDocumentsInRedingListConfirmedByUser]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[AreDocumentsInRedingListConfirmedByUser]
(
    @UserId INT,
	@ReadingListId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT;
    DECLARE @NumberOfDocuments INT;
    DECLARE @NumberOfConfirmedDocuments INT;
    
    SELECT
        @NumberOfDocuments = COUNT(1)
    FROM
        ReadingListDocuments
    WHERE
        ReadingListId = @ReadingListId
        
    SELECT
        @NumberOfConfirmedDocuments = COUNT(1)
    FROM
        ReadingListDocuments rld
            INNER JOIN m136_tblDocument d ON rld.DocumentId = d.iDocumentId
            INNER JOIN m136_tblConfirmRead cr ON d.iEntityId = cr.iEntityId
    WHERE
        ReadingListId = @ReadingListId
        AND cr.iEmployeeId = @UserId
            
    IF @NumberOfDocuments = @NumberOfConfirmedDocuments
    BEGIN
        SET @Result = 1;
    END
    ELSE
    BEGIN
        SET @Result = 0;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForUsersOfRole]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfRole] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForUsersOfRole]
	@RoleId INT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @UserConfirmedDocumentsOnReadingLists TABLE
    (
        UserId INT,
        ReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsOK BIT
    );
    
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
    SELECT
        e.iEmployeeId, r.ReadingListId, r.Name, dbo.AreDocumentsInRedingListConfirmedByUser(e.iEmployeeId, r.ReadingListId)
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId AND rlr.ReaderTypeId = 3 --Role reader
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN tblEmployee e ON esg.iEmployeeId = e.iEmployeeId
    WHERE
        (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND r.IsDeleted = 0
        AND sg.iSecGroupId = @RoleId
        
    SELECT
        UserId,
        ReadingListId,
        ReadingListName,
        IsOK
    FROM
        @UserConfirmedDocumentsOnReadingLists
END
GO

IF OBJECT_ID('[dbo].[GetReadingListUserRoleForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListUserRoleForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListUserRoleForReport]
    @RoleId INT,
    @ReadingListId INT
AS
BEGIN
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
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId 
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN tblEmployee e ON esg.iEmployeeId = e.iEmployeeId
            INNER JOIN tblDepartment d ON e.iDepartmentId = d.iDepartmentId
            LEFT JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
    WHERE
        (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND r.IsDeleted = 0
        AND sg.iSecgroupId = @RoleId
    GROUP BY e.iEmployeeId, d.strName, e.strFirstName + ' ' + e.strLastName
    
    EXEC GetNumberOfOkReadingListsForUsersOfRole @RoleId, @ReadingListId
END
GO

/* End of reading list role */

/* Reading list closest leader */

IF OBJECT_ID('[dbo].[GetLeaderUsers]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[GetLeaderUsers]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetLeaderUsers]
AS
BEGIN
    SELECT
        iEmployeeId,
        strFirstName,
        strLastName
    FROM
        tblEmployee
    WHERE
        iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1)
END
GO

IF OBJECT_ID('[dbo].[NumberOfReadingListsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListIds TABLE (ReadingListId INT);
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListIds (ReadingListId)
    SELECT r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT ReadingListId)
    FROM @ReadingListIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[NumberOfReadingListDocumentsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListDocumentsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListDocumentsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListDocumentIds TABLE (DocumentId INT);
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT DocumentId)
    FROM @ReadingListDocumentIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]() RETURNS BIT AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[NumberOfReadingListConfirmedDocumentsAssociateWithUser]
(
	@UserId INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Result INT;
	DECLARE @ReadingListDocumentIds TABLE (DocumentId INT);
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON e.iEmployeeId = rlr.ReaderId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON e.iDepartmentId = d.iDepartmentId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = e.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND e.iEmployeeId = @UserId
    
    INSERT INTO @ReadingListDocumentIds (DocumentId)
    SELECT rld.DocumentId
    FROM
        ReadingList r
            INNER JOIN ReadingListDocuments rld ON r.ReadingListId = rld.ReadingListId
            INNER JOIN m136_tblDocument doc ON rld.DocumentId = doc.iDocumentId AND doc.iLatestApproved = 1
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iSecGroupId
            INNER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId AND cr.iEmployeeId = esg.iEmployeeId
    WHERE
        r.IsDeleted = 0
        AND esg.iEmployeeId = @UserId
    
    SELECT @Result = COUNT(DISTINCT DocumentId)
    FROM @ReadingListDocumentIds
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNumberOfOkReadingListsForLeaderOfDepartments]
	@LeaderId INT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @UserConfirmedDocumentsOnReadingLists TABLE
    (
        UserId INT,
        ReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsOK BIT
    );
    
    -- Insert reading lists from person readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        e.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInRedingListConfirmedByUser(e.iEmployeeId, rl.ReadingListId)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON rlr.ReaderId = e.iEmployeeId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )        
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        
    -- Insert reading list from department readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        e.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInRedingListConfirmedByUser(e.iEmployeeId, rl.ReadingListId)
    FROM
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON d.iDepartmentId = e.iDepartmentId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        AND NOT EXISTS(SELECT 1 FROM @UserConfirmedDocumentsOnReadingLists WHERE UserId = e.iEmployeeId AND ReadingListId = rl.ReadingListId)
        
    -- Insert reading list documents from role readers
    INSERT INTO @UserConfirmedDocumentsOnReadingLists
        (UserId, ReadingListId, ReadingListName, IsOK)
    SELECT
        esg.iEmployeeId, rl.ReadingListId, rl.Name, dbo.AreDocumentsInRedingListConfirmedByUser(esg.iEmployeeId, rl.ReadingListId)
    FROM 
        ReadingList rl
            INNER JOIN ReadingListReaders rlr ON rl.ReadingListId = rlr.ReadingListId AND ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iEmployeeId
    WHERE
        rl.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND esg.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND esg.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND (@ReadingListId IS NULL OR rl.ReadingListId = @ReadingListId)
        AND NOT EXISTS(SELECT 1 FROM @UserConfirmedDocumentsOnReadingLists WHERE UserId = esg.iEmployeeId AND ReadingListId = rl.ReadingListId)
        
    SELECT DISTINCT
        UserId,
        ReadingListId,
        ReadingListName,
        IsOK
    FROM
        @UserConfirmedDocumentsOnReadingLists
END
GO

IF OBJECT_ID('[dbo].[GetReadingListLeaderOfDepartmentsForReport]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetReadingListLeaderOfDepartmentsForReport] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetReadingListLeaderOfDepartmentsForReport]
    @LeaderId INT,
    @ReadingListId INT
AS
BEGIN
    DECLARE @LeaderReadingLists TABLE
    (
        LeaderId INT,
        EmployeeName VARCHAR(100),
        DepartmentName VARCHAR(80),
        ReadingListId INT
    );
    
    -- Insert reading list documents from person readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 1 -- Person reader
            INNER JOIN tblEmployee e ON rlr.ReaderId = e.iEmployeeId
            INNER JOIN tblDepartment d ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
    
    -- Insert reading list documents from department readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 2 -- Department reader
            INNER JOIN tblDepartment d ON d.iDepartmentId = rlr.ReaderId
            INNER JOIN tblEmployee e ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND NOT EXISTS (SELECT 1 FROM @LeaderReadingLists lrl WHERE lrl.LeaderId = e.iEmployeeId AND lrl.ReadingListId = r.ReadingListId)
        
    -- INSERT reading list documents from role readers
    INSERT INTO @LeaderReadingLists
        (LeaderId, EmployeeName, DepartmentName, ReadingListId)
    SELECT
        e.iEmployeeId, e.strFirstName + ' ' + e.strLastName, d.strName, r.ReadingListId
    FROM
        ReadingList r
            INNER JOIN ReadingListReaders rlr ON r.ReadingListId = rlr.ReadingListId AND rlr.ReaderTypeId = 3 -- Role reader
            INNER JOIN tblSecGroup sg ON rlr.ReaderId = sg.iSecGroupId
            INNER JOIN relEmployeeSecGroup esg ON sg.iSecGroupId = esg.iEmployeeId
            INNER JOIN tblEmployee e ON e.iEmployeeId = esg.iEmployeeId
            INNER JOIN tblDepartment d ON d.iDepartmentId = e.iDepartmentId
    WHERE
        r.IsDeleted = 0
        AND (
            (@LeaderId IS NOT NULL AND e.iEmployeeId = @LeaderId)
            OR (@LeaderId IS NULL AND e.iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1))
        )
        AND (@ReadingListId IS NULL OR r.ReadingListId = @ReadingListId)
        AND NOT EXISTS (SELECT 1 FROM @LeaderReadingLists lrl WHERE lrl.LeaderId = e.iEmployeeId AND lrl.ReadingListId = r.ReadingListId)
        
    SELECT
        DISTINCT LeaderId AS UserId,
        EmployeeName,
        DepartmentName,
        dbo.NumberOfReadingListsAssociateWithUser(LeaderId) AS NumberOfReadingLists,
        dbo.NumberOfReadingListDocumentsAssociateWithUser(LeaderId) AS NumberOfDocuments,
        dbo.NumberOfReadingListConfirmedDocumentsAssociateWithUser(LeaderId) AS NumberOfOKDocuments
    FROM
        @LeaderReadingLists
    
    EXEC GetNumberOfOkReadingListsForLeaderOfDepartments @LeaderId, @ReadingListId
END
GO

/* End of reading list closest leader */