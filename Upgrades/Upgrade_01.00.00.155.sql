INSERT INTO #Description VALUES('Modify m136_be_GetUserWithApprovePermissionOnDocument')
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
        (@IsInternetDocument = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
        OR (@IsInternetDocument = 1 AND 
            ((@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
            OR (@IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, @HandBookId) & 16 = 16)))
            
END
GO