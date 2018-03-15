INSERT INTO #Description VALUES('Modify some existing procedures and create some new procedures support for feature show reading document list in Frontend.')
GO

IF OBJECT_ID('[dbo].[fnUserHasConfirmedDocument]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnUserHasConfirmedDocument]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnUserHasConfirmedDocument]
(
	@UserId INT,
    @EntityId INT
) RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @UserId)
    BEGIN
        RETURN 1;
    END
    
    Return 0;
END
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
        IsConfirmed BIT
    );
    
    -- Insert reading documents from person readers
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId)
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iEntityId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 1
        AND ReaderId = @UserId
        
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
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId)
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iEntityId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 2
        AND ReaderId IN (SELECT Id FROM @UserDepartmentId)
    
    -- Insert reading documents from role readers
    INSERT INTO @UserRoleId (Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId)
    FROM
        m136_tblDocument d
            INNER JOIN m136_tblhandbook h
                ON d.iHandbookId = h.iHandbookId
            INNER JOIN ReadingListDocuments rld
                ON d.iEntityId = rld.DocumentId
            INNER JOIN ReadingListReaders rlr
                ON rld.ReadingListId = rlr.ReadingListId
            INNER JOIN ReadingList rl
                ON rld.ReadingListId = rl.ReadingListId
    WHERE
        d.iLatestApproved = 1
        AND ReaderTypeId = 3
        AND ReaderId IN (SELECT Id FROM @UserRoleId)    
    
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
        IsConfirmed
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
        rld.DocumentId AS EntityId,
        d.iDocumentId AS DocumentId,
        d.strName AS DocumentName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS DocumentPath
    FROM
        ReadingListDocuments rld
            JOIN m136_tblDocument d ON rld.DocumentId = d.iEntityId
    WHERE
        ReadingListId = @Id
    
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
END
GO

IF OBJECT_ID('[dbo].[be_UpdateReadingList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_UpdateReadingList] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[be_UpdateReadingList]
    @ReadingListId INT,
    @Name NVARCHAR(100),
    @IsInactive BIT,
    @Description NVARCHAR(4000),
    @Documents AS dbo.ReadingListDocumentItems READONLY,
    @Readers AS dbo.ReadingListReaderItems READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        -- Update Reading List
        UPDATE
            ReadingList
        SET
            Name = @Name,
            IsInActive = @IsInactive,
            Description = @Description
        WHERE
            ReadingListId = @ReadingListId
            
        -- Delete and re-insert Reading List Documents
        DELETE FROM
            ReadingListDocuments
        WHERE
            ReadingListId = @ReadingListId
        
        INSERT INTO
            ReadingListDocuments
                (ReadingListId, DocumentId)
            SELECT
                @ReadingListId,
                iEntityId
            FROM
                @Documents rd
                    INNER JOIN m136_tblDocument d ON rd.DocumentId = iDocumentId
            WHERE
                d.iLatestVersion = 1
                
        -- Delete and re-insert Reading List Readers
        DELETE FROM
            ReadingListReaders
        WHERE
            ReadingListId = @ReadingListId
        
        INSERT INTO
            ReadingListReaders
                (ReadingListId, ReaderTypeId, ReaderId)
            SELECT
                @ReadingListId,
                ReaderTypeId,
                ReaderId
            FROM
                @Readers
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    Rollback
END CATCH
END
GO