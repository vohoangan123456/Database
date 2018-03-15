INSERT INTO #Description VALUES('Modify procedure be_UpdateReadingList')
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