INSERT INTO #Description VALUES ('Create table m136_CompendiaDocuments, type CompendiaDocumentItems, procedures ReaddCompediaDocuments, SearchCompediaDocumentByTitle')
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES  WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'm136_CompendiaDocuments'))
BEGIN
    CREATE TABLE [dbo].[m136_CompendiaDocuments]
    (
        Title NVARCHAR(255),
        Description NVARCHAR(MAX),
        Link NVARCHAR(255),
        LanguageCode VARCHAR(2)
	)
END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'CompendiaDocumentItems' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[CompendiaDocumentItems] AS TABLE
    (
        Title NVARCHAR(255),
        Description NVARCHAR(MAX),
        Link NVARCHAR(255),
        LanguageCode VARCHAR(2)
    )
GO

IF OBJECT_ID('[dbo].[ReaddCompediaDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[ReaddCompediaDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[ReaddCompediaDocuments]
	@Documents AS [dbo].[CompendiaDocumentItems] READONLY
AS
BEGIN
    TRUNCATE TABLE m136_CompendiaDocuments;
    
    INSERT INTO m136_CompendiaDocuments
        (Title, Description, Link, LanguageCode)
    SELECT
        Title,
        Description,
        Link,
        LanguageCode
    FROM
        @Documents
END
GO

IF OBJECT_ID('[dbo].[SearchCompediaDocumentByTitle]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[SearchCompediaDocumentByTitle] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[SearchCompediaDocumentByTitle]
	@Keyword NVARCHAR(255)
AS
BEGIN
    SELECT
        Title,
        Description,
        Link,
        LanguageCode
    FROM
        m136_CompendiaDocuments
    WHERE
        Title LIKE '%' + @Keyword + '%'
END
GO