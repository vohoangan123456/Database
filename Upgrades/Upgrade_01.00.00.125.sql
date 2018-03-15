INSERT INTO #Description VALUES('Modify procedure m136_be_GetUserWithApprovePermissionOnDocument, create procedure m136_be_GetUserApprovedOnLatestDocument')
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserWithApprovePermissionOnDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetUserWithApprovePermissionOnDocument]
	@DocumentId INT,
	@IsInternetDocumentMode BIT
AS
BEGIN
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
		e.iEmployeeId,
		strFirstName,
		strLastName,
		strEmail
	FROM
		dbo.tblEmployee AS e
	WHERE
		(@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
		OR (@IsInternetDocumentMode = 1 AND @IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, @HandBookId) & 16 = 16)
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserApprovedOnLatestDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserApprovedOnLatestDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetUserApprovedOnLatestDocument]
	@DocumentId INT
AS
BEGIN
	SELECT
		e.iEmployeeId,
		strFirstName,
		strLastName,
		strEmail
	FROM
		dbo.tblEmployee AS e
	WHERE
		e.iEmployeeId = (
			SELECT
				iApprovedById 
			FROM 
				m136_tblDocument
			WHERE iDocumentId = @DocumentId AND iLatestApproved = 1)	
END
GO