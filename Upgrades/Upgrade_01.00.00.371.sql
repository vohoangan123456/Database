INSERT INTO #Description VALUES ('Modify procedures GetUserReadingDocumentsList, be_GetReadingListDetailsById')
GO

IF OBJECT_ID('[dbo].[GetUserReadingDocumentsList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserReadingDocumentsList] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserReadingDocumentsList]
    @UserId INT
AS
BEGIN
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    DECLARE @UserReadingDocumentsList TABLE
    (
        iDocumentId INT,
        iHandbookId INT,
        strName NVARCHAR(200),
        iDocumentTypeId INT,
        Version INT,
        dtmApproved DATETIME,
        strApprovedBy VARCHAR(200),
        Responsible VARCHAR(100),
        ParentFolderName VARCHAR(100),
        Path NVARCHAR(MAX),
        HasAttachment BIT,
        iReadingListId INT,
        ReadingListName NVARCHAR(100),
        IsConfirmed BIT,
        iInternetDoc INT
    );
    
    -- Insert reading documents from person readers
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND rl.IsDeleted = 0
        AND ReaderTypeId = 1
        AND ReaderId = @UserId
        AND NOT EXISTS (SELECT 1 FROM ReadingListExclusions WHERE ReadingListId = rl.ReadingListId AND EmployeeId = @UserId)
        
    -- Insert reading documents from department readers
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
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND rl.IsDeleted = 0
        AND ReaderTypeId = 2
        AND ReaderId IN (SELECT Id FROM @UserDepartmentId)
        AND NOT EXISTS (SELECT 1 FROM ReadingListExclusions WHERE ReadingListId = rl.ReadingListId AND EmployeeId = @UserId)
    
    -- Insert reading documents from role readers
    INSERT INTO @UserRoleId (Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc)
    SELECT
        d.iDocumentId,
        d.iHandbookId,
        d.strName,
        d.iDocumentTypeId,
        d.iVersion AS Version,
        d.dtmApproved,
        d.strApprovedBy,
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible,
        h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
        dbo.fnHasDocumentAttachment(d.iEntityId) AS HasAttachment,
        rl.ReadingListId,
        rl.Name,
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId),
        d.iInternetDoc
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iDocumentId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND rl.IsDeleted = 0
        AND ReaderTypeId = 3
        AND ReaderId IN (SELECT Id FROM @UserRoleId)
        AND NOT EXISTS (SELECT 1 FROM ReadingListExclusions WHERE ReadingListId = rl.ReadingListId AND EmployeeId = @UserId)
    
    -- get final reading documents
    
    SELECT
        DISTINCT(iDocumentId) AS Id,
        iHandbookId,
        strName,
        iDocumentTypeId,
        Version,
        dtmApproved,
        strApprovedBy,
        Responsible,
        ParentFolderName,
        Path,
        HasAttachment,
        iReadingListId,
        ReadingListName,
        IsConfirmed,
        iInternetDoc
    FROM
        @UserReadingDocumentsList
END
GO

IF OBJECT_ID('[dbo].[be_GetReadingListDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetReadingListDetailsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[be_GetReadingListDetailsById]
    @Id INT
AS
BEGIN
    SELECT
        ReadingListId,
        Name,
        Description,
        IsInactive
    FROM
        ReadingList
    WHERE
        ReadingListId = @Id
        
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
    
    SELECT
        ReadingListReaderId,
        ReadingListId,
        ReaderTypeId,
        CASE
            WHEN ReaderTypeId = 1 THEN (SELECT strFirstName + ' ' + strLastName FROM tblEmployee WHERE iEmployeeId = ReaderId)
            WHEN ReaderTypeId = 2 THEN (SELECT strName FROM tblDepartment WHERE iDepartmentId = ReaderId)
            WHEN ReaderTypeId = 3 THEN (SELECT strName FROM tblSecGroup WHERE iSecGroupId = ReaderId)
        END AS ReaderName,
        ReaderId
    FROM
        ReadingListReaders
    WHERE
        ReadingListId = @Id
        
    SELECT
        ReadingListExclusionId,
        ReadingListId,
        DepartmentId,
        d.strName AS DepartmentName,
        EmployeeId,
        e.strFirstName + ' ' + e.strLastName AS EmployeeName
    FROM
        ReadingListExclusions rle
            INNER JOIN tblDepartment d ON rle.DepartmentId = d.iDepartmentId
            INNER JOIN tblEmployee e ON rle.EmployeeId = e.iEmployeeId
    WHERE
        rle.ReadingListId = @Id
END
GO