INSERT INTO #Description VALUES('Modify procedure m136_be_UserCanApproveDocument')
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
			((@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
			OR (@IsInternetDocumentMode = 1 AND @IsInternetDocument = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, @HandBookId) & 16 = 16))
			
	SELECT @Result
END
GO