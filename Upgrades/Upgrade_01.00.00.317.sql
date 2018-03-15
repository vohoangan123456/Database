INSERT INTO #Description VALUES ('Modify procedures m136_be_GetMyWorkingDocuments, m136_be_GetDocumentsAwaitingMyApproval')
GO

IF OBJECT_ID('[dbo].[fnGetAllDepartmentName]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fnGetAllDepartmentName]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnGetAllDepartmentName] (@iUser int)  
RETURNS varchar(5000) AS  
BEGIN 

	DECLARE @var VARCHAR(5000), @iDepartmentName varchar(80)

	SELECT @var = d.strName 
	FROM dbo.tblEmployee e
	JOIN dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId AND e.iEmployeeId = @iUser

	DECLARE cur CURSOR FOR SELECT d.strName 
								FROM dbo.relEmployeeDepartment r
								JOIN dbo.tblDepartment d ON r.iDepartmentId = d.iDepartmentId
								WHERE iEmployeeId = @iUser
	OPEN cur;
	FETCH NEXT FROM cur INTO @iDepartmentName
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF  @iDepartmentName IS NOT NULL AND @iDepartmentName != ''
		BEGIN
			SET @var = @var + ' / ' + @iDepartmentName
		END
		FETCH NEXT FROM cur INTO @iDepartmentName
	END
	CLOSE cur;
	DEALLOCATE cur;

return isnull(@var,'')
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchRoleMembers] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SearchRoleMembers]
	@iDepartmentId INT,
	@iRoleId INT,
	@strKeyword VARCHAR(100),
	@recursive BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET @strKeyword = ISNULL(@strKeyword, '');
	SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strLoginName, td.strName AS strDepartment, td.iDepartmentId, 
		   te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName
	FROM dbo.tblEmployee te
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
		WHERE (((@recursive = 0) AND (te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL OR @iDepartmentId = 0)) 
			OR (@recursive = 1 AND te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		AND (te.strLoginName LIKE '%' + @strKeyword + '%' 
			OR te.strFirstName LIKE '%' + @strKeyword + '%' 
			OR te.strLastName LIKE '%' + @strKeyword + '%')
		AND (@iRoleId IS NULL OR te.iEmployeeId NOT IN (SELECT resg.iEmployeeId 
			FROM dbo.relEmployeeSecGroup resg WHERE resg.iSecGroupId = @iRoleId));
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: NOV 19, 2015
-- Description:	Get all user who have permission write on all document which is selected
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]
 @DocumentIds AS [dbo].[Item] READONLY,
 @Permission INT
AS
BEGIN
 SET NOCOUNT ON;
	DECLARE @Folders TABLE
	(
		Id int PRIMARY KEY
	)
 INSERT INTO @Folders 
 SELECT DISTINCT iHandbookId
 FROM dbo.m136_tblDocument doc
 JOIN @DocumentIds doc1 ON doc.iDocumentId = doc1.Id
 WHERE doc.iLatestVersion = 1
 DECLARE @iFolderId INT;
 DECLARE @Employee TABLE
	(
		iEmployeeId int PRIMARY KEY
	)
 DECLARE @Employee1 TABLE
	(
		iEmployeeId int PRIMARY KEY
	)
 DECLARE Folders CURSOR FOR 
  SELECT Id
  FROM @Folders;
 OPEN Folders; 
 FETCH NEXT FROM Folders INTO @iFolderId;
	 INSERT INTO @Employee
	 SELECT te.iEmployeeId
	 FROM dbo.tblEmployee te 
	 WHERE dbo.fnSecurityGetPermission (136, 462, te.iEmployeeId, @iFolderId) &  @Permission = @Permission
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO @Employee1
		SELECT e.iEmployeeId
		FROM @Employee e
		WHERE dbo.fnSecurityGetPermission (136, 462, e.iEmployeeId, @iFolderId) &  @Permission = @Permission;
		DELETE @Employee
		INSERT INTO	@Employee
		SELECT 	iEmployeeId
		FROM @Employee1	
		DELETE @Employee1
		FETCH NEXT FROM Folders INTO @iFolderId;
	 END
 CLOSE Folders;
 DEALLOCATE Folders;
 SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strEmail, te.strLoginName, te.iDepartmentId,
 te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName
 FROM dbo.tblEmployee te
 JOIN @Employee e ON e.iEmployeeId = te.iEmployeeId
END
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
		
	SELECT
		e.iEmployeeId,
		strFirstName,
		strLastName,
		strEmail,
		e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
	FROM
		dbo.tblEmployee AS e
	WHERE
        (@IsInternetDocument = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
        OR (@IsInternetDocument = 1 AND 
            ((@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
            OR (@IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, 0) & 16 = 16)))
            
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetUserWithApprovePermission]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithApprovePermission]')
GO
ALTER  PROCEDURE [dbo].[m136_be_GetUserWithApprovePermission]
AS
BEGIN
	SELECT e.iEmployeeId, e.iDepartmentId, e.strLoginName, e.strEmail, e.strFirstName, e.strLastName, e.strLoginName,
	e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
	FROM tblEmployee e
	WHERE iEmployeeId IN (SELECT iEntityId 
						  FROM tblACL 
						  WHERE iPermissionSetId = 462 AND iBit & 16 = 16) -- 16: approval permission
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
		strEmail,
		e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
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

IF OBJECT_ID('[dbo].[m136_be_GetUserWithCreatePermission]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUserWithCreatePermission]')
GO
ALTER  PROCEDURE [dbo].[m136_be_GetUserWithCreatePermission]
AS
BEGIN
	SELECT e.iEmployeeId, e.iDepartmentId, e.strLoginName, e.strEmail, e.strFirstName, e.strLastName, e.strLoginName,
	e.strFirstName + ' ' + e.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](e.iEmployeeId) AS FullNameAndDepartmentName
	FROM tblEmployee e
	WHERE iEmployeeId IN (SELECT iEntityId 
						  FROM tblACL 
						  WHERE iPermissionSetId = 462 AND iBit & 2 = 2)
END
GO

IF OBJECT_ID('[dbo].[GetLeaderUsers]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[GetLeaderUsers]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetLeaderUsers]
AS
BEGIN
    SELECT
        iEmployeeId,
        strFirstName,
        strLastName,
		strFirstName + ' ' + strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](iEmployeeId) AS FullNameAndDepartmentName
    FROM
        tblEmployee
    WHERE
        iEmployeeId IN (SELECT EmployeeId FROM DepartmentResponsibles WHERE ResponsibleTypeId = 1)
END
GO

IF OBJECT_ID('[dbo].[GetUsersByPermission]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUsersByPermission] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUsersByPermission] 
	@Permission INT,
	@ApplicationIds AS dbo.[Item] READONLY,
	@PermissionSetIds AS dbo.[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

    SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		te.strFirstName, 
		te.strLastName, 
		te.strEmail,
		te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.relEmployeeSecGroup resg ON resg.iEmployeeId = te.iEmployeeId
    WHERE resg.iSecGroupId IN (
		SELECT ta.iSecurityId FROM dbo.tblACL ta 
			WHERE ta.iApplicationId IN (SELECT Id FROM @ApplicationIds)
			AND ta.iPermissionSetId IN (SELECT Id FROM @PermissionSetIds)
			AND (ta.iBit & @Permission) = @Permission
		);
    
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployees] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetEmployees] 
	@iEmployeeId INT,
	@iDepartmentId INT,
	@bRecursive BIT,
	@strFirstName VARCHAR(50),
	@strLastName VARCHAR(50),
	@strLoginName VARCHAR(100),
	@iPageSize INT,
	@iPageIndex INT,
	@roleId INT = NULL,
	@ExcludedEmployeeId AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RoleEmployees TABLE(iEmployeeId INT NOT NULL PRIMARY KEY);
	IF(@roleId IS NOT NULL)
		INSERT INTO @RoleEmployees(iEmployeeId)
		SELECT 
			iEmployeeId 
		FROM 
			dbo.relEmployeeSecGroup
		WHERE iSecGroupId = @roleId;
	
	DECLARE @Departments TABLE(iDepartmentId INT NOT NULL PRIMARY KEY);
	INSERT INTO @Departments(iDepartmentId)
		SELECT 
			iDepartmentId 
		FROM 
			[dbo].[m136_GetDepartmentsRecursive](@iDepartmentId);
	SET @iPageIndex = @iPageIndex - 1;
    SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		td.strName AS strDepartment,
		te.strFirstName, 
		te.strLastName, 
		te.strTitle, 
		CASE WHEN te.strAddress1 IS NULL OR te.strAddress1 = '' THEN 
				(CASE WHEN te.strAddress2 IS NULL OR te.strAddress2 = '' THEN 
						te.strAddress3 
					ELSE te.strAddress2 
				END)
			ELSE te.strAddress1 
		END AS [strAddress],
		te.iCountryId, 
		tc.strName AS strCountry,
		te.strPhoneHome, 
		te.strPhoneInternal, 
		te.strPhoneWork, 
		te.strPhoneMobile, 
		te.strBeeper, 
		te.strCallNumber, 
		te.strFax, 
		te.strEmail, 
		te.strLoginName, 
		te.strLoginDomain, 
		te.strComment,
		te.LastLogin,
		te.strExpDep,
		te.strEmployeeNo,
		te.strPassword,
		ROW_NUMBER() OVER (ORDER BY te.strFirstName ASC, te.strLastName ASC) AS RowNumber,
		te.strFirstName + ' ' + te.strLastName + ' - ' + [dbo].[fnGetAllDepartmentName](te.iEmployeeId) AS FullNameAndDepartmentName
	INTO #Filters
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = te.iCountryId
    LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
    WHERE (@iEmployeeId IS NULL OR te.iEmployeeId = @iEmployeeId)
    AND (@strFirstName IS NULL OR @strFirstName = '' OR te.strFirstName LIKE '%' + @strFirstName + '%')
    AND (@strLastName IS NULL OR @strLastName = '' OR te.strLastName LIKE '%' + @strLastName + '%')
    AND (@strLoginName IS NULL OR @strLoginName = '' OR te.strLoginName LIKE '%' + @strLoginName + '%')
    AND ((@bRecursive = 1 AND (te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		  OR (@bRecursive = 0 AND te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL))
	AND (@roleId IS NULL OR (@roleId IS NOT NULL AND te.iEmployeeId IN (SELECT iEmployeeId FROM @RoleEmployees)))
	AND te.iEmployeeId NOT IN (SELECT Id FROM @ExcludedEmployeeId);
    SELECT f.iEmployeeId, 
		f.iDepartmentId, 
		f.strDepartment, 
		f.strFirstName, 
		f.strLastName, 
		f.strTitle, 
		f.strAddress, 
		f.iCountryId, 
		f.strCountry, 
		f.strPhoneHome, 
		f.strPhoneInternal, 
		f.strPhoneWork, 
		f.strPhoneMobile, 
		f.strBeeper, 
		f.strCallNumber, 
		f.strFax, 
		f.strEmail, 
		f.strLoginName, 
		f.strLoginDomain, 
		f.strComment, 
		f.LastLogin,
		f.strExpDep, 
		f.strEmployeeNo,
		f.strPassword,
		f.FullNameAndDepartmentName  
    FROM #Filters f
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber;
END
GO