INSERT INTO #Description VALUES('Modify stored procedure folders/documents management.')
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateFolderDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateFolderDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 07, 2015
-- Description:	Update folder documents
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateFolderDocuments]
	@Documents AS [dbo].[Documents] READONLY
AS
BEGIN
	
	SET NOCOUNT ON;

	UPDATE doc
	SET doc.iSort = doc1.iSort
	FROM [dbo].[m136_tblDocument] doc
		INNER JOIN @Documents doc1
		ON doc.iDocumentId = doc1.iDocumentId; 
		
    UPDATE doc
	SET doc.iSort = doc1.iSort
	FROM [dbo].[m136_relVirtualRelation] doc
		INNER JOIN @Documents doc1
		ON doc.iDocumentId = doc1.iDocumentId;
		 
	SELECT doc.iHandbookId, doc.iDocumentId, doc.iSort INTO #VirtualDocuments
		FROM @Documents doc
		WHERE doc.iVirtual = 1 
			AND doc.iDocumentId NOT IN (SELECT iDocumentId
				FROM [dbo].[m136_relVirtualRelation] doc1 WHERE doc1.iHandbookId = doc.iHandbookId);
				
	INSERT INTO [dbo].[m136_relVirtualRelation]
		SELECT iHandbookId, iDocumentId, iSort FROM #VirtualDocuments;
		
	DECLARE @iHandbookId INT;
	SELECT @iHandbookId = iHandbookId FROM @Documents WHERE iVirtual = 0; 
		
	DELETE [dbo].[m136_relVirtualRelation] 
		WHERE iHandbookId = @iHandbookId AND iDocumentId NOT IN (SELECT doc1.iDocumentId 
			FROM @Documents doc1 WHERE iVirtual = 1 AND doc1.iHandbookId = @iHandbookId);
			
	DROP TABLE #VirtualDocuments;
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployees] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 21, 2015
-- Description:	Get employees. It was paging because the number of employees too much.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetEmployees] 
	@iEmployeeId INT,
	@iDepartmentId INT,
	@bRecursive BIT,
	@strFirstName VARCHAR(50),
	@strLastName VARCHAR(50),
	@strLoginName VARCHAR(100),
	@iPageSize INT,
	@iPageIndex INT
AS
BEGIN
	SET NOCOUNT ON;
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
		ROW_NUMBER() OVER (ORDER BY te.strFirstName ASC, te.strLastName ASC) AS RowNumber 
	INTO #Filters
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = te.iCountryId
    LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
    WHERE (@iEmployeeId IS NULL OR te.iEmployeeId = @iEmployeeId)
    AND (@iDepartmentId IS NULL OR te.iDepartmentId = @iDepartmentId)
    AND (@strFirstName IS NULL OR @strFirstName = '' OR te.strFirstName LIKE '%' + @strFirstName + '%')
    AND (@strLastName IS NULL OR @strLastName = '' OR te.strLastName LIKE '%' + @strLastName + '%')
    AND (@strLoginName IS NULL OR @strLoginName = '' OR te.strLoginName LIKE '%' + @strLoginName + '%');
    
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
		f.strPassword  
    FROM #Filters f
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber;
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateEmployee]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateEmployee] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 26, 2015
-- Description:	Create employee
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_CreateEmployee]
	@strEmployeeNo		VARCHAR(20),
	@iDepartmentId		INT,
	@strExpDep			VARCHAR(20),
	@strFirstName		VARCHAR(50),
	@strLastName		VARCHAR(50),
	@strTitle			VARCHAR(200),
	@strAddress			VARCHAR(150),
	@iCountryId			INT,
	@strPhoneHome		VARCHAR(30),
	@strPhoneInternal	VARCHAR(30),
	@strPhoneWork		VARCHAR(30),
	@strPhoneMobile		VARCHAR(30),
	@strBeeper			VARCHAR(20),
	@strCallNumber		VARCHAR(20),
	@strFax				VARCHAR(30),
	@strEmail			VARCHAR(100),
	@strLoginName		VARCHAR(100),
	@strLoginDomain		VARCHAR(200),
	@strPassword		VARCHAR(32),
	@strComment			VARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iMaxEmployeeId INT;
	SELECT @iMaxEmployeeId = MAX(te.iEmployeeId) FROM dbo.tblEmployee te;
	DECLARE @NewEmployeeId INT = @iMaxEmployeeId + 1, @iParentCompanyId INT;
	SELECT @iParentCompanyId = dpt.iCompanyId FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentId;
	
	SET IDENTITY_INSERT dbo.tblEmployee ON;
    INSERT INTO dbo.tblEmployee
    (
        iEmployeeId,
        strEmployeeNo,
        iDepartmentId,
        strExpDep,
        dtmEmployed,
        strFirstName,
        strLastName,
        strTitle,
        strAddress1,
        strAddress2,
        strAddress3,
        iCountryId,
        strPhoneHome,
        strPhoneInternal,
        strPhoneWork,
        strPhoneMobile,
        strBeeper,
        strCallNumber,
        strFax,
        strEmail,
        strLoginName,
        strLoginDomain,
        strPassword,
        iCompanyId,
        bWizard,
        strComment,
        iImageId,
        bEmailConfirmed,
        strMailPassword,
        ADIdentifier,
        LastLogin,
        PreviousLogin
    )
    VALUES
    (
        @NewEmployeeId, -- iEmployeeId - int
        @strEmployeeNo, -- strEmployeeNo - varchar
        @iDepartmentId, -- iDepartmentId - int
        @strExpDep, -- strExpDep - varchar
        GETDATE(), -- dtmEmployed - smalldatetime
        @strFirstName, -- strFirstName - varchar
        @strLastName, -- strLastName - varchar
        @strTitle, -- strTitle - varchar
        @strAddress, -- strAddress1 - varchar
        '', -- strAddress2 - varchar
        '', -- strAddress3 - varchar
        @iCountryId, -- iCountryId - int
        @strPhoneHome, -- strPhoneHome - varchar
        @strPhoneInternal, -- strPhoneInternal - varchar
        @strPhoneWork, -- strPhoneWork - varchar
        @strPhoneMobile, -- strPhoneMobile - varchar
        @strBeeper, -- strBeeper - varchar
        @strCallNumber, -- strCallNumber - varchar
        @strFax, -- strFax - varchar
        @strEmail, -- strEmail - varchar
        @strLoginName, -- strLoginName - varchar
        @strLoginDomain, -- strLoginDomain - varchar
        @strPassword, -- strPassword - varchar
        @iParentCompanyId, -- iCompanyId - int
        0, -- bWizard - bit
        ISNULL(@strComment, ''), -- strComment - varchar
        0, -- iImageId - int
        0, -- bEmailConfirmed - bit
        '', -- strMailPassword - varchar
        '00000000-0000-0000-0000-000000000000', -- ADIdentifier - uniqueidentifier
        NULL, -- LastLogin - datetime
        NULL -- PreviousLogin - datetime
    );
	
    SET IDENTITY_INSERT dbo.tblEmployee OFF;
	
	SELECT @NewEmployeeId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateEmployee]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateEmployee] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateEmployee]
	@iEmployeeId		INT,
	@strEmployeeNo		VARCHAR(20),
	@iDepartmentId		INT,
	@strExpDep			VARCHAR(20),
	@strFirstName		VARCHAR(50),
	@strLastName		VARCHAR(50),
	@strTitle			VARCHAR(200),
	@strAddress			VARCHAR(150),
	@iCountryId			INT,
	@strPhoneHome		VARCHAR(30),
	@strPhoneInternal	VARCHAR(30),
	@strPhoneWork		VARCHAR(30),
	@strPhoneMobile		VARCHAR(30),
	@strBeeper			VARCHAR(20),
	@strCallNumber		VARCHAR(20),
	@strFax				VARCHAR(30),
	@strEmail			VARCHAR(100),
	@strLoginName		VARCHAR(100),
	@strLoginDomain		VARCHAR(200),
	@strPassword		VARCHAR(32),
	@strComment			VARCHAR(400)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @iParentCompanyId INT;
	SELECT @iParentCompanyId = dpt.iCompanyId FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentId;

    UPDATE dbo.tblEmployee
    SET
        strEmployeeNo = @strEmployeeNo,
        iDepartmentId = @iDepartmentId,
        strExpDep = @strExpDep,
        strFirstName = @strFirstName,
        strLastName = @strLastName,
        strTitle = @strTitle,
        strAddress1 = @strAddress,
        iCountryId = @iCountryId, -- int
        strPhoneHome = @strPhoneHome, -- varchar
        strPhoneInternal = @strPhoneInternal, -- varchar
        strPhoneWork = @strPhoneWork, -- varchar
        strPhoneMobile = @strPhoneMobile, -- varchar
        strBeeper = @strBeeper, -- varchar
        strCallNumber = @strCallNumber, -- varchar
        strFax = @strFax, -- varchar
        strEmail = @strEmail, -- varchar
        strLoginName = @strLoginName, -- varchar
        strLoginDomain = @strLoginDomain, -- varchar
        strPassword = @strPassword, -- varchar
        iCompanyId = @iParentCompanyId, 
        strComment = @strComment
    WHERE iEmployeeId = @iEmployeeId;
END
GO


IF OBJECT_ID('[dbo].[m136_be_DeleteEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteEmployees] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteEmployees]
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DELETE dbo.relEmployeePosition WHERE iEmployeeId IN (SELECT ee.Id FROM @Employees ee);
	
	DELETE dbo.relEmployeeSecGroup WHERE iEmployeeId IN (SELECT ee.Id FROM @Employees ee);
	
    DELETE dbo.tblEmployee WHERE dbo.tblEmployee.iEmployeeId IN (SELECT ee.Id FROM @Employees ee);
END
GO


IF OBJECT_ID('[dbo].[m136_be_DeleteDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteDepartments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteDepartments] 
	@iApplicationId		INT,
	@iPermissionSetId	INT,
	@Departments AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DELETE dbo.tblACL WHERE iApplicationId = @iApplicationId 
		AND iPermissionSetId = @iPermissionSetId
		AND iEntityId IN (SELECT dd.Id FROM @Departments dd);
	
	DELETE dbo.relDepartmentPosition WHERE iDepartmentId IN (SELECT dd.Id FROM @Departments dd);
	
    DELETE dbo.tblDepartment WHERE iDepartmentId IN (SELECT dd.Id FROM @Departments dd);
END
GO
