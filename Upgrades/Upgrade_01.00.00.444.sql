INSERT INTO #Description VALUES ('Simplified m136_be_GetUserWithApprovePermissionOnDocument')
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
			AND iLatestVersion = 1
	 SET @IsInternetDocument = ISNULL(@IsInternetDocument,0);	
	 SELECT
	  e.iEmployeeId,
	  strFirstName,
	  strLastName,
	  strEmail,
	  e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
	 FROM
	  dbo.tblEmployee AS e
	 WHERE
			dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16
			AND
				(@IsInternetDocument = 0 
				OR 
				@IsInternetDocumentMode = 0
				OR
				(@IsInternetDocument = 1 AND @IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, 0) & 16 = 16)) 
END
GO