INSERT INTO #Description VALUES('Modify procedure m136_be_ChangeInternetDocument')
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeInternetDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeInternetDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ChangeInternetDocument]
    @UserId INT,
    @DocumentIds AS [dbo].[Item] READONLY,
    @IsInternetDocument BIT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);

    SELECT
        @FullName = strFirstName + ' ' + strLastName
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
    
    UPDATE
        m136_tblDocument
    SET
        iInternetDoc = @IsInternetDocument,
        iAlterId = @UserId,
		strAlterer = @FullName
    WHERE
        iDocumentId IN (SELECT Id FROM @DocumentIds)
        AND iLatestVersion = 1
END
GO