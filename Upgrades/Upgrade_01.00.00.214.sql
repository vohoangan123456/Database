INSERT INTO #Description VALUES('Create tables and procedures support feature manage reading lists')
GO

------------------------------------------------ Begin to create structure for tables -----------------------------------------

IF (NOT EXISTS (SELECT * 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'dbo' 
                AND  TABLE_NAME = 'ReadingList'))
BEGIN
    CREATE TABLE ReadingList
    (
        ReadingListId INT IDENTITY(1, 1) PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL,
        Description NVARCHAR(4000) NULL,
        IsInactive BIT NOT NULL DEFAULT 1,
        IsDeleted BIT NOT NULL DEFAULT 0,
	)
END
GO

IF (NOT EXISTS (SELECT * 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'dbo' 
                AND  TABLE_NAME = 'ReadingListDocuments'))
BEGIN
    CREATE TABLE ReadingListDocuments
    (
        ReadingListDocumentId INT IDENTITY(1, 1) PRIMARY KEY,
        ReadingListId INT NOT NULL,
        DocumentId INT NOT NULL
    )
END
GO

DECLARE @sql1 NVARCHAR(MAX)
SET @sql1 = dbo.fn136_GetSqlDropConstraintKey('ReadingListDocuments', 'FK_ReadingListDocuments_ReadingList') 
IF @sql1 IS NOT NULL
BEGIN
    EXEC(@sql1)
END
GO

ALTER TABLE ReadingListDocuments ADD CONSTRAINT FK_ReadingListDocuments_ReadingList FOREIGN KEY (ReadingListId)
    REFERENCES ReadingList (ReadingListId)
GO

DECLARE @sql2 NVARCHAR(MAX)
SET @sql2 = dbo.fn136_GetSqlDropConstraintKey('ReadingListDocuments', 'FK_ReadingListDocuments_m136_tblDocument') 
IF @sql2 IS NOT NULL
BEGIN
    EXEC(@sql2)
END
GO

ALTER TABLE ReadingListDocuments ADD CONSTRAINT FK_ReadingListDocuments_m136_tblDocument FOREIGN KEY (DocumentId)
    REFERENCES m136_tblDocument (iEntityId)
GO

IF (NOT EXISTS (SELECT * 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'dbo' 
                AND  TABLE_NAME = 'luReaderTypes'))
BEGIN
    CREATE TABLE luReaderTypes
    (
        Id SMALLINT PRIMARY KEY,
        Name NVARCHAR(100) NOT NULL
    )
END
GO

IF (NOT EXISTS (SELECT 1 FROM luReaderTypes))
BEGIN
    INSERT INTO
        luReaderTypes
            (Id, Name)
        VALUES
            (1, 'Person'),
            (2, 'Department'),
            (3, 'Role')
END
GO

IF (NOT EXISTS (SELECT * 
                FROM INFORMATION_SCHEMA.TABLES 
                WHERE TABLE_SCHEMA = 'dbo' 
                AND  TABLE_NAME = 'ReadingListReaders'))
BEGIN
    CREATE TABLE ReadingListReaders
    (
        ReadingListReaderId INT IDENTITY(1, 1) PRIMARY KEY,
        ReadingListId INT NOT NULL,
        ReaderTypeId SMALLINT NOT NULL,
        ReaderId INT NOT NULL
    )
END
GO

DECLARE @sql3 NVARCHAR(MAX)
SET @sql3 = dbo.fn136_GetSqlDropConstraintKey('ReadingListReaders', 'FK_ReadingListReaders_ReadingList') 
IF @sql3 IS NOT NULL
BEGIN
    EXEC(@sql3)
END
GO

ALTER TABLE ReadingListReaders ADD CONSTRAINT FK_ReadingListReaders_ReadingList FOREIGN KEY (ReadingListId)
    REFERENCES ReadingList (ReadingListId)
GO

DECLARE @sql4 NVARCHAR(MAX)
SET @sql4 = dbo.fn136_GetSqlDropConstraintKey('ReadingListReaders', 'FK_ReadingListReaders_luReaderTypes') 
IF @sql4 IS NOT NULL
BEGIN
    EXEC(@sql4)
END
GO

ALTER TABLE ReadingListReaders ADD CONSTRAINT FK_ReadingListReaders_luReaderTypes FOREIGN KEY (ReaderTypeId)
    REFERENCES luReaderTypes (Id)
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ReadingListDocumentItems' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[ReadingListDocumentItems] AS TABLE
    (
        ReadingListId INT,
        DocumentId INT
    )
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'ReadingListReaderItems' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[ReadingListReaderItems] AS TABLE
    (
        ReadingListId INT,
        ReaderTypeId SMALLINT,
        ReaderId INT
    )
GO

------------------------------------------------ End to create structure for tables -----------------------------------------

------------------------------------------------ Begin to create procedures -----------------------------------------

IF OBJECT_ID('[dbo].[be_GetUndeletedReadingLists]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_GetUndeletedReadingLists] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[be_GetUndeletedReadingLists]
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
        IsDeleted = 0
    ORDER BY Name
END
GO

IF OBJECT_ID('[dbo].[be_CreateReadingList]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_CreateReadingList] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[be_CreateReadingList]
    @Name NVARCHAR(100),
    @Description NVARCHAR(400),
    @IsInactive BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
        INSERT INTO
            ReadingList
                (Name, Description, IsInactive)
            VALUES
                (@Name, @Description, @IsInactive);
            
        SELECT SCOPE_IDENTITY()
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK
END CATCH
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
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    Rollback
END CATCH
END
GO

IF OBJECT_ID('[dbo].[be_DeleteReadingLists]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[be_DeleteReadingLists] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[be_DeleteReadingLists]
    @ReadingListIds AS [dbo].[Item] READONLY
AS
BEGIN
    UPDATE
        ReadingList
    SET
        IsDeleted = 1
    WHERE
        ReadingListId IN (SELECT Id FROM @ReadingListIds)
END
GO

------------------------------------------------ End to create procedures -----------------------------------------