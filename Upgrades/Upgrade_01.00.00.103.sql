INSERT INTO #Description VALUES('Create stored procedure for staff management.')
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
		f.strEmployeeNo 
    FROM #Filters f
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetParentsIncludeSelf]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetParentsIncludeSelf] AS SELECT 1')
GO
ALTER  PROCEDURE [dbo].[m136_be_GetParentsIncludeSelf]
	@iItemId INT,
	@isFolder BIT
AS
BEGIN
	DECLARE @idTable table(iHandbookId int not null)
	DECLARE @seedId int;
	IF(@isFolder = 1)
		BEGIN
			SET @seedId = @iItemId;
			INSERT INTO @idTable 
			VALUES (@iItemId)
		END 
	ELSE
		BEGIN
			SELECT 
				@seedId = doc.iHandbookId
			FROM
				m136_tblDocument doc
			WHERE
				doc.iDocumentId = @iItemId
			INSERT INTO @idTable
			VALUES(@seedId) 
		END
	INSERT INTO 
		@idTable 
	SELECT
		*
	FROM
		[dbo].[m136_GetParentIdsInTbl](@seedId)
	SELECT
		hb.iParentHandbookId AS [iHandbookId],
		hb.strName,
		hb.iHandbookId AS Id,
		hb.iLevelType AS [LevelType],
		-1 AS [iDocumentTypeId],
		NULL AS [Version],
		NULL AS [dtmApproved],
		NULL AS [dtmPublishUntil],
		hb.iDepartmentId AS DepartmentId
	FROM
		m136_tblHandbook hb
	WHERE
		hb.iHandbookId IN (SELECT * FROM @idTable)
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchSecurityGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SearchSecurityGroups]
	@iUserID INT, 
	@strName VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    SET NOCOUNT ON;
    SELECT DISTINCT sg.iSecGroupId
		   ,sg.strName
		   ,sg.strDescription 
	FROM [dbo].[tblSecGroup] sg
	LEFT JOIN [dbo].[relEmployeeSecGroup] esg ON esg.iSecGroupId = sg.iSecGroupId
	WHERE (esg.iEmployeeId = @iUserId OR @iUserId IS NULL)
	AND (@strName IS NULL OR @strName = '' OR sg.strName LIKE '%' + @strName + '%');
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'ADIdentifier' AND Object_ID = Object_ID(N'dbo.tblDepartment'))
BEGIN
    ALTER TABLE dbo.tblDepartment
	ADD ADIdentifier UNIQUEIDENTIFIER;
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDepartment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDepartment] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDepartment] 
	@iDepartmentId INT,
	@strName VARCHAR(80),
	@bCompanyId BIT,
	@iDepartmentParentId INT,
	@iTargetId INT,
	@strDescription VARCHAR(4000),
	@strOrgNo VARCHAR(50),
	@strPhone VARCHAR(20),
	@strFax VARCHAR(20),
	@strEmail VARCHAR(150),
	@strURL VARCHAR(200),
	@iCountryId INT,
	@strVisitAddress1 VARCHAR(150),
	@strVisitAddress2 VARCHAR(150),
	@strVisitAddress3 VARCHAR(150),
	@strAddress1 VARCHAR(150),
	@strAddress2 VARCHAR(150),
	@strAddress3 VARCHAR(150)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iMaxDepartmentId INT;
	SELECT @iMaxDepartmentId = MAX(dpt.iDepartmentId) FROM dbo.tblDepartment dpt;
	DECLARE @NewDerparmentId INT = @iMaxDepartmentId + 1, @iParentLevel INT = 0, @bParentCompany BIT, @iParentCompanyId INT, @iNewCompanyId INT;
	
	SELECT @iParentLevel = dpt.iLevel, @bParentCompany = dpt.bCompany, @iParentCompanyId = dpt.iCompanyId 
		FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentParentId;
	
	IF (@bParentCompany = 1)
	BEGIN
		SET @iNewCompanyId = @iDepartmentParentId;
	END
	ELSE
	BEGIN
		SET @iNewCompanyId = @iParentCompanyId;
	END
	
	SET IDENTITY_INSERT dbo.tblDepartment ON;
	INSERT INTO dbo.tblDepartment
	(
       iDepartmentId,
       iDepartmentParentId,
       iCompanyId,
       iMin,
       iMax,
       iLevel,
       strName,
       strDescription,
       strContactInfo,
       bCompany,
       strPhone,
       strFax,
       strEmail,
       strURL,
       iCountryId,
       strOrgNo,
       strVisitAddress1,
       strVisitAddress2,
       strVisitAddress3,
       strAddress1,
       strAddress2,
       strAddress3,
       strFileURL,
       iChildCount,
       ADIdentifier
   )
   VALUES
   (
       @NewDerparmentId,-- iDepartmentId - int
       @iDepartmentParentId, -- iDepartmentParentId - int
       @iNewCompanyId, -- iCompanyId - int
       0, -- iMin - int
       0, -- iMax - int
       (@iParentLevel + 1), -- iLevel - int
       @strName, -- strName - varchar
       @strDescription, -- strDescription - varchar
       '', -- strContactInfo - varchar
       @bCompanyId, -- bCompany - bit
       @strPhone, -- strPhone - varchar
       @strFax, -- strFax - varchar
       @strEmail, -- strEmail - varchar
       @strURL, -- strURL - varchar
       @iCountryId, -- iCountryId - int
       @strOrgNo, -- strOrgNo - varchar
       @strVisitAddress1, -- strVisitAddress1 - varchar
       @strVisitAddress2, -- strVisitAddress2 - varchar
       @strVisitAddress3, -- strVisitAddress3 - varchar
       @strAddress1, -- strAddress1 - varchar
       @strAddress2, -- strAddress2 - varchar
       @strAddress3, -- strAddress3 - varchar
       '', -- strFileURL - varchar
       0, -- iChildCount - int
       '00000000-0000-0000-0000-000000000000' -- ADIdentifier - uniqueidentifier
   );
   
   SELECT @NewDerparmentId;
END
GO


IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'ADIdentifier' AND Object_ID = Object_ID(N'dbo.tblEmployee'))
BEGIN
    ALTER TABLE dbo.tblEmployee
	ADD ADIdentifier UNIQUEIDENTIFIER;
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
        NULL, -- ADIdentifier - uniqueidentifier
        NULL, -- LastLogin - datetime
        NULL -- PreviousLogin - datetime
    );

	SELECT @NewEmployeeId;
END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'EmployeePosition' AND ss.name = N'dbo')
	CREATE TYPE [dbo].[EmployeePosition] AS TABLE(
		[iEmployeeId] [int] NOT NULL,
		[iDepartmentId] [int] NOT NULL,
		[iPositionId] [int] NOT NULL
	)
GO

IF OBJECT_ID('[dbo].[m136_be_GetEmployeePostions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployeePostions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 27, 2015
-- Description:	Get employee positions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetEmployeePostions]
	@iEmployeeId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT tp.* FROM dbo.tblPosition tp
		INNER JOIN dbo.relEmployeePosition rep ON rep.iPositionId = tp.iPositionId
		WHERE rep.iEmployeeId = @iEmployeeId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateEmployeePositions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateEmployeePositions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateEmployeePositions]
	@iEmployeeId INT,
	@iDepartmentId INT,
	@Positions AS[dbo].[EmployeePosition] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @tEmployeeId INT, @tDepartmentId INT, @tPositionId INT;
	DECLARE PositionSet CURSOR FOR 
		SELECT iEmployeeId
			, iDepartmentId
			, iPositionId
		FROM @Positions;
		
	OPEN PositionSet; 
	FETCH NEXT FROM PositionSet INTO @tEmployeeId, @tDepartmentId, @tPositionId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF NOT EXISTS(SELECT * FROM [dbo].[relEmployeePosition] 
			WHERE iEmployeeId = @tEmployeeId 
				AND iDepartmentId = @tDepartmentId 
				AND iPositionId = @tPositionId)
		BEGIN
			INSERT INTO dbo.relEmployeePosition
			(
			    iEmployeeId,
			    iDepartmentId,
			    iPositionId,
			    iExecutiveLevel
			)
			VALUES
			(
			    @tEmployeeId, -- iEmployeeId - int
			    @tDepartmentId, -- iDepartmentId - int
			    @tPositionId, -- iPositionId - int
			    0 -- iExecutiveLevel - int
			)
		END
		FETCH NEXT FROM PositionSet INTO @tEmployeeId, @tDepartmentId, @tPositionId;
	END
	CLOSE PositionSet;
	DEALLOCATE PositionSet;
		
	DELETE dbo.relEmployeePosition WHERE iEmployeeId = @iEmployeeId AND iDepartmentId = @iDepartmentId
	AND iPositionId NOT IN (SELECT iPositionId FROM @Positions);
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateEmployeeRoles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateEmployeeRoles] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateEmployeeRoles]
	@iEmployeeId INT,
	@EmployeeSecGroups AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @tEmployeeId INT, @tSecGroupId INT;
	DECLARE EmployeeSecGroups CURSOR FOR 
		SELECT Id
			, Value
		FROM @EmployeeSecGroups;
		
	OPEN EmployeeSecGroups; 
	FETCH NEXT FROM EmployeeSecGroups INTO @tEmployeeId, @tSecGroupId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF NOT EXISTS(SELECT * FROM [dbo].[relEmployeeSecGroup] resg 
			WHERE resg.iEmployeeId = @tEmployeeId 
				AND resg.iSecGroupId = @tSecGroupId)
		BEGIN
			INSERT INTO [dbo].[relEmployeeSecGroup]
			(
			    iEmployeeId,
			    iSecGroupId
			)
			VALUES
			(
			    @tEmployeeId,
			    @tSecGroupId
			)
		END
		FETCH NEXT FROM EmployeeSecGroups INTO @tEmployeeId, @tSecGroupId;
	END
	CLOSE EmployeeSecGroups;
	DEALLOCATE EmployeeSecGroups;
		
	DELETE [dbo].[relEmployeeSecGroup] WHERE iEmployeeId = @iEmployeeId
	AND iSecGroupId NOT IN (SELECT Value FROM @EmployeeSecGroups);
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetEmployeeRoles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployeeRoles] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetEmployeeRoles]
	@iEmployeeId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT tsg.* FROM dbo.tblSecGroup tsg
    INNER JOIN dbo.relEmployeeSecGroup resg ON resg.iSecGroupId = tsg.iSecGroupId
    WHERE resg.iEmployeeId = @iEmployeeId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDepartmentPositions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDepartmentPositions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI	
-- Create date: AUGUST 18. 2015
-- Description:	Update position of department
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDepartmentPositions]
	@iDepartmentId INT,
	@Positions AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @tDepartmentId INT, @tPositionId INT;
	DECLARE PositionSet CURSOR FOR 
		SELECT @iDepartmentId
			, Id
		FROM @Positions;
		
	OPEN PositionSet; 
	FETCH NEXT FROM PositionSet INTO @tDepartmentId, @tPositionId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF NOT EXISTS(SELECT * FROM [dbo].[relDepartmentPosition] 
			WHERE iDepartmentId = @tDepartmentId
				AND iPositionId = @tPositionId)
		BEGIN
			INSERT INTO dbo.relDepartmentPosition
			(
			    iDepartmentId,
			    iPositionId
			)
			VALUES
			(
			    @tDepartmentId, -- iEmployeeId - int
			    @tPositionId -- iDepartmentId - int
			)
		END
		FETCH NEXT FROM PositionSet INTO @tDepartmentId, @tPositionId;
	END
	CLOSE PositionSet;
	DEALLOCATE PositionSet;
		
	DELETE dbo.relDepartmentPosition WHERE iDepartmentId = @iDepartmentId
	AND iPositionId NOT IN (SELECT Id FROM @Positions);
END
GO