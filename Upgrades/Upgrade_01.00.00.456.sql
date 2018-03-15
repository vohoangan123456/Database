INSERT INTO #Description VALUES ('Modify Table ReadingList.')
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'CreatedDate'
          AND Object_ID = Object_ID(N'dbo.ReadingList'))
BEGIN
	ALTER TABLE dbo.ReadingList
	ADD  CreatedDate DATETIME NULL	
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'CreatedBy'
          AND Object_ID = Object_ID(N'dbo.ReadingList'))
BEGIN
	ALTER TABLE dbo.ReadingList
	ADD  CreatedBy INT NULL	
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'UpdatedDate'
          AND Object_ID = Object_ID(N'dbo.ReadingList'))
BEGIN
	ALTER TABLE dbo.ReadingList
	ADD  UpdatedDate DATETIME NULL	
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns 
          WHERE Name = N'UpdatedBy'
          AND Object_ID = Object_ID(N'dbo.ReadingList'))
BEGIN
	ALTER TABLE dbo.ReadingList
	ADD  UpdatedBy INT NULL	
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
		rl.UpdatedBy
    FROM
        ReadingList rl
		LEFT JOIN tblEmployee e ON rl.CreatedBy = e.iEmployeeId
		LEFT JOIN tblEmployee e2 ON rl.UpdatedBy = e2.iEmployeeId
    WHERE
        IsDeleted = 0
    ORDER BY Name
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
    @Exclusions AS dbo.ReadingListExclusionsItems READONLY
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
            UpdatedDate = GETUTCDATE()
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





IF (OBJECT_ID('[dbo].[be_CreateReadingList]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[be_CreateReadingList] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[be_CreateReadingList]
    @Name NVARCHAR(100),
    @Description NVARCHAR(400),
    @IsInactive BIT,
	@CreatedBy INT = NULL
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO
            ReadingList
                (Name, Description, IsInactive, CreatedBy, CreatedDate)
            VALUES
                (@Name, @Description, @IsInactive, @CreatedBy, GETUTCDATE());
        SELECT SCOPE_IDENTITY()
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
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
		rl.UpdatedBy
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
