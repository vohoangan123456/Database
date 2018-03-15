INSERT INTO #Description VALUES ('Modify SP for reading list and reading receipt')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'ReadingReceiptsExpire' AND [OBJECT_ID] = OBJECT_ID(N'dbo.ReadingList'))
BEGIN
    ALTER TABLE dbo.ReadingList ADD ReadingReceiptsExpire BIT
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'ReadingReceiptValidity' AND [OBJECT_ID] = OBJECT_ID(N'dbo.ReadingList'))
BEGIN
    ALTER TABLE dbo.ReadingList ADD ReadingReceiptValidity SMALLINT
END
GO

IF (OBJECT_ID('[dbo].[be_CreateReadingList]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_CreateReadingList] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[be_CreateReadingList]
    @Name NVARCHAR(100),
    @Description NVARCHAR(400),
    @IsInactive BIT,
	@CreatedBy INT = NULL,
	@ReadingReceiptsExpire BIT = 0,
	@ReadingReceiptValidity SMALLINT = NULL
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
		DECLARE @DateNow DATETIME = GETUTCDATE();
        INSERT INTO
            ReadingList
                (Name, Description, IsInactive, CreatedBy, CreatedDate, UpdatedBy,UpdatedDate, ReadingReceiptsExpire, ReadingReceiptValidity)
            VALUES
                (@Name, @Description, @IsInactive, @CreatedBy, @DateNow, @CreatedBy, @DateNow, @ReadingReceiptsExpire, @ReadingReceiptValidity);
        SELECT SCOPE_IDENTITY()
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
END
GO

IF (OBJECT_ID('[dbo].[be_UpdateReadingList]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_UpdateReadingList] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[be_UpdateReadingList]
    @ReadingListId INT,
    @Name NVARCHAR(100),
    @IsInactive BIT,
    @Description NVARCHAR(4000),
    @UpdatedBy INT = NULL,
    @Documents AS dbo.ReadingListDocumentItems READONLY,
    @Readers AS dbo.ReadingListReaderItems READONLY,
    @Exclusions AS dbo.ReadingListExclusionsItems READONLY,
    @ReadingReceiptsExpire BIT = 0,
	@ReadingReceiptValidity SMALLINT = NULL
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
            Description = @Description,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE(),
            ReadingReceiptsExpire = @ReadingReceiptsExpire,
            ReadingReceiptValidity = @ReadingReceiptValidity
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
                DocumentId
            FROM
                @Documents
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
        -- Delete and re-insert Reading List Exclusions
        DELETE FROM
            ReadingListExclusions
        WHERE
            ReadingListId = @ReadingListId
        INSERT INTO
            ReadingListExclusions
                (ReadingListId, DepartmentId, EmployeeId)
            SELECT
                @ReadingListId,
                DepartmentId,
                EmployeeId
            FROM
                @Exclusions
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    Rollback
END CATCH
END
GO

IF (OBJECT_ID('[dbo].[be_GetReadingListDetailsById]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_GetReadingListDetailsById] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[be_GetReadingListDetailsById]
    @Id INT
AS
BEGIN
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

IF (OBJECT_ID('[dbo].[be_GetUndeletedReadingLists]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_GetUndeletedReadingLists] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[be_GetUndeletedReadingLists]
AS
BEGIN
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
		d.strName AS DepartmentName,
		rl.ReadingReceiptsExpire,
		rl.ReadingReceiptValidity
    FROM
        ReadingList rl
		LEFT JOIN tblEmployee e ON rl.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON rl.UpdatedBy = e2.iEmployeeId
		LEFT JOIN dbo.tblDepartment d ON e2.iDepartmentId = d.iDepartmentId
    WHERE
        IsDeleted = 0
    ORDER BY Name
END
GO

IF OBJECT_ID('[dbo].[fnUserHasConfirmedDocument]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnUserHasConfirmedDocument]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnUserHasConfirmedDocument]
(
	@UserId INT,
    @EntityId INT,
    @ReadingReceiptsExpire BIT,
    @ReadingReceiptValidity SMALLINT
) RETURNS BIT
AS
BEGIN
	IF @ReadingReceiptsExpire = 1 AND @ReadingReceiptValidity IS NOT NULL AND @ReadingReceiptValidity <> 0
	BEGIN
		DECLARE @DateCompare DATETIME = DATEADD(month, -@ReadingReceiptValidity ,GETDATE())
		DECLARE @dtmConfirm DATETIME
		SELECT @dtmConfirm = dtmConfirm 
		FROM m136_tblConfirmRead 
		WHERE iEntityId = @EntityId AND iEmployeeId = @UserId AND  dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @UserId)
		
		IF @dtmConfirm IS NOT NULL
		BEGIN
			IF @dtmConfirm >= @DateCompare
				RETURN 1;
		END
    END
    ELSE
    BEGIN
		IF EXISTS (SELECT 1 FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @UserId)
		BEGIN
			RETURN 1;
		END
    END
    Return 0;
END
GO

IF OBJECT_ID('[dbo].[fnGetExpiredConfirmedUserDocument]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnGetExpiredConfirmedUserDocument]() RETURNS DATETIME AS BEGIN RETURN NULL; END')
GO

ALTER FUNCTION [dbo].[fnGetExpiredConfirmedUserDocument]
(
	@UserId INT,
    @EntityId INT,
    @ReadingReceiptsExpire BIT,
    @ReadingReceiptValidity SMALLINT
) RETURNS DATETIME
AS
BEGIN
	IF @ReadingReceiptsExpire = 1 AND @ReadingReceiptValidity IS NOT NULL AND @ReadingReceiptValidity <> 0
	BEGIN
		DECLARE @DateCompare DATETIME = DATEADD(month, -@ReadingReceiptValidity ,GETDATE())
		DECLARE @dtmConfirm DATETIME
		SELECT @dtmConfirm = dtmConfirm 
		FROM m136_tblConfirmRead 
		WHERE iEntityId = @EntityId AND iEmployeeId = @UserId AND  dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead WHERE iEntityId = @EntityId AND iEmployeeId = @UserId)
		
		IF @dtmConfirm IS NOT NULL
		BEGIN
			IF @dtmConfirm < @DateCompare
				RETURN @dtmConfirm;
		END
    END
    Return NULL;
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
        IsConfirmed BIT,
        iInternetDoc INT,
        dtmConfirmed DATETIME,
        ReadingReceiptValidity SMALLINT
    );
    
    -- Insert reading documents from person readers
    INSERT INTO @UserReadingDocumentsList
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc,dtmConfirmed, ReadingReceiptValidity)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        d.iInternetDoc,
        [dbo].[fnGetExpiredConfirmedUserDocument](@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        rl.ReadingReceiptValidity
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
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc,dtmConfirmed, ReadingReceiptValidity)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        d.iInternetDoc,
        [dbo].[fnGetExpiredConfirmedUserDocument](@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        rl.ReadingReceiptValidity
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
        (iDocumentId, iHandbookId, strName, iDocumentTypeId, Version, dtmApproved, strApprovedBy, Responsible, ParentFolderName, Path, HasAttachment, iReadingListId, ReadingListName, IsConfirmed, iInternetDoc,dtmConfirmed, ReadingReceiptValidity)
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
        dbo.fnUserHasConfirmedDocument(@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        d.iInternetDoc,
        [dbo].[fnGetExpiredConfirmedUserDocument](@UserId, d.iEntityId, rl.ReadingReceiptsExpire, rl.ReadingReceiptValidity),
        rl.ReadingReceiptValidity
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
        iInternetDoc,
        dtmConfirmed,
        ReadingReceiptValidity
    FROM
        @UserReadingDocumentsList
END
GO