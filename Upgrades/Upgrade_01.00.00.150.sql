INSERT INTO #Description VALUES('Modify procedures m136_be_UserCanApproveDocument, m136_be_ChangeInternetDocument')
GO

IF OBJECT_ID('[dbo].[m136_be_UserCanApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_UserCanApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UserCanApproveDocument]
	@UserId INT,
	@DocumentId INT,
    @IsInternetDocumentMode INT
AS
BEGIN
	DECLARE @Result BIT = 0;
	DECLARE @HandBookId INT;
	DECLARE @IsInternetDocument BIT;
	
	SELECT
		@HandBookId = iHandBookId,
		@IsInternetDocument = iInternetDoc
	FROM
		dbo.m136_tblDocument
	WHERE
		iDocumentId = @DocumentId
	SELECT
		@Result = 1
	FROM
		dbo.tblEmployee AS e
	WHERE
		e.iEmployeeId = @UserId
		AND 
			(((@IsInternetDocumentMode = 0 OR @IsInternetDocument = 0) AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
			OR (@IsInternetDocumentMode = 1 AND @IsInternetDocument = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, @HandBookId) & 16 = 16))
			
	SELECT @Result
END
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeInternetDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeInternetDocument]  AS SELECT 1')
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