INSERT INTO #Description VALUES('Create stored procedure for security.')
GO

IF OBJECT_ID('[dbo].[fn136_GetDepartmentPath]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetDepartmentPath] () RETURNS NVARCHAR(4000) AS BEGIN RETURN 1 END;')
GO
ALTER FUNCTION [dbo].[fn136_GetDepartmentPath](@DepartmentId INT)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Path varchar(4000);
	
	WITH Parents AS
	(
		SELECT 
			td.iDepartmentParentId,
			strName
		FROM 
			[dbo].[tblDepartment] td 
		WHERE
			td.iDepartmentId = @DepartmentId
		UNION ALL
		SELECT 
			d.iDepartmentParentId,
			d.strName
		FROM 
			[dbo].[tblDepartment] d
			INNER JOIN Parents
				ON	d.iDepartmentId = Parents.iDepartmentParentId 
			WHERE (d.iLevel <> 0)
	)
	SELECT
		@Path = strName + COALESCE('/' + @Path, '')
	FROM
		Parents;

	IF (@DepartmentId IS NOT NULL AND @DepartmentId <> 0)
	BEGIN
		DECLARE @Root varchar(4000);	
		SELECT @Root = td.strName FROM dbo.tblDepartment td WHERE td.iDepartmentId = 0; 
	
		SET @Path = @Root + COALESCE('/' + @Path, '');
	END
	
	RETURN @Path;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentStatistics]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentStatistics] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 12, 2015
-- Description:	Get department home page.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentStatistics]
	
AS
BEGIN
	SET NOCOUNT ON;

    SELECT COUNT(1) AS TotalDepartments FROM [dbo].[tblDepartment];
  
	SELECT COUNT(1) AS TotalEmployees FROM dbo.tblEmployee te;
	
	SELECT td.iDepartmentId
		, td.strDescription
		, td.strName
		, [dbo].[fn136_GetDepartmentPath](td.iDepartmentId) AS [Path]
		, (SELECT COUNT(1) FROM dbo.tblEmployee te WHERE te.iDepartmentId = td.iDepartmentId) AS TotalEmployees
	FROM dbo.tblDepartment td
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentById] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 13, 2015
-- Description:	Get department by id
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentById]
	@iDepartmentId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT	dpt.iDepartmentId, 
			dpt.strName, 
			dpt.strDescription,
			dpt.iDepartmentParentId, 
			dpt.iLevel,
			dpt.bCompany,
			dpt.strOrgNo,
			tc.strName AS Country,
			[dbo].[fn136_GetDepartmentPath](dpt.iDepartmentId) AS [Path],
			dpt.strVisitAddress1, 
			dpt.strVisitAddress2, 
			dpt.strVisitAddress3, 
			dpt.strAddress1, 
			dpt.strAddress2, 
			dpt.strAddress3,
			dpt.strPhone, 
			dpt.strFax, 
			dpt.strEmail, 
			dpt.strURL,
			dpt.iCountryId
		FROM dbo.tblDepartment dpt
		LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = dpt.iCountryId
		WHERE dpt.iDepartmentId = @iDepartmentID;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JUNE 24, 2015
-- Description:	Get all departments. 
--				Because the list of department does not long, so we will get all and paging on client if any.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartments] 
	@iDepartmentId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT	dpt.iDepartmentId, 
			dpt.strName, 
			dpt.strDescription,
			dpt.iDepartmentParentId, 
			dpt.iLevel,
			dpt.bCompany,
			dpt.strOrgNo,
			tc.strName AS Country,
			[dbo].[fn136_GetDepartmentPath](dpt.iDepartmentId) AS [Path],
			dpt.strVisitAddress1, 
			dpt.strVisitAddress2, 
			dpt.strVisitAddress3, 
			dpt.strAddress1, 
			dpt.strAddress2, 
			dpt.strAddress3,
			dpt.strPhone, 
			dpt.strFax, 
			dpt.strEmail, 
			dpt.strURL,
			dpt.iCountryId
		FROM dbo.tblDepartment dpt
		LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = dpt.iCountryId
		WHERE ((@iDepartmentID IS NULL AND (dpt.iDepartmentParentId IS NULL OR dpt.iDepartmentParentId = 0)) 
			OR dpt.iDepartmentParentId = @iDepartmentID);
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchDepartments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchDepartments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 14, 2015
-- Description:	Search department by name.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_SearchDepartments]
	-- Add the parameters for the stored procedure here
	@strName VARCHAR(80)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    SELECT td.iDepartmentId, 
		td.iDepartmentParentId, 
		td.iLevel, 
		td.strName, 
		td.strDescription,
		td.bCompany,
		td.strOrgNo,
		NULL AS Country,
		[dbo].[fn136_GetDepartmentPath](td.iDepartmentId) AS [Path],
		td.strVisitAddress1, 
		td.strVisitAddress2, 
		td.strVisitAddress3, 
		td.strAddress1, 
		td.strAddress2, 
		td.strAddress3,
		td.strPhone, 
		td.strFax, 
		td.strEmail, 
		td.strURL,
		td.iCountryId 
    FROM dbo.tblDepartment td
    WHERE td.strName LIKE '%' + @strName + '%';
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetCountries]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetCountries] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 14, 2015
-- Description:	Get country
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetCountries]
	@iCountryId INT,
	@strName VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

    SELECT tc.* FROM dbo.tblCountry tc
    WHERE ((@iCountryId IS NULL) OR tc.iCountryId = @iCountryId)
    AND ((@strName IS NULL OR @strName = '') OR (tc.strName LIKE '%' + @strName + '%'));
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetPositions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetPositions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 14, 2015
-- Description:	Get positions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetPositions]
	@iPositionId INT,
	@strName VARCHAR(50)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT tp.* FROM dbo.tblPosition tp
	WHERE ((@iPositionId IS NULL) OR tp.iPositionId = @iPositionId)
	AND (@strName IS NULL OR @strName = '' OR (tp.strName LIKE '%' + @strName + '%'));
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentPostions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentPostions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 17, 2015
-- Description:	Get department positions
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentPostions]
	@iDepartmentId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT tp.* FROM dbo.tblPosition tp
		INNER JOIN dbo.relDepartmentPosition rdp ON rdp.iPositionId = tp.iPositionId
		WHERE rdp.iDepartmentId = @iDepartmentId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 17, 2015
-- Description:	Get permissions for a specified organization.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentPermissions]
	@iDepartmentId INT
AS
BEGIN
	SET NOCOUNT ON;
	
	SELECT iEntityId
		, iPermissionSetId AS iAccessRights
		,[iBit]
		,iSecurityId AS iGroupingId,
		sg.strName AS strGroupName
	FROM [dbo].[tblACL] acl
		LEFT JOIN [dbo].[tblSecGroup] sg ON acl.iSecurityId = sg.iSecGroupId
	WHERE iEntityId = @iDepartmentId
		AND iApplicationId = 97 -- organization
		AND (iPermissionSetId = 99);
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateDepartmentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDepartmentInformation] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: AUGUST 17, 2015
-- Description:	Update department information.
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDepartmentInformation]
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

	DECLARE @iLevel INT, @iMaxDepartment INT;
	SELECT @iLevel = td.iLevel FROM dbo.tblDepartment td WHERE td.iDepartmentId = @iDepartmentParentId;
	
    UPDATE dbo.tblDepartment
    SET
        iDepartmentParentId = @iDepartmentParentId,
        iCompanyId			= @iDepartmentParentId,
        strName				= @strName,
        strDescription		= @strDescription,
        bCompany			= @bCompanyId,
        strPhone			= @strPhone,
        strFax				= @strFax,
        strEmail			= @strEmail,
        strURL				= @strURL,
        iCountryId			= @iCountryId,
        strOrgNo			= @strOrgNo,
        strVisitAddress1	= @strVisitAddress1,
        strVisitAddress2	= @strVisitAddress2,
        strVisitAddress3	= @strVisitAddress3,
        strAddress1			= @strAddress1,
        strAddress2			= @strAddress2,
        strAddress3			= @strAddress3
    WHERE iDepartmentId = @iDepartmentId;
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

    INSERT INTO dbo.relDepartmentPosition
    SELECT @iDepartmentId, Id FROM @Positions
		WHERE Id NOT IN (SELECT rdp.iPositionId FROM dbo.relDepartmentPosition rdp WHERE rdp.iDepartmentId = @iDepartmentId);
		
	DELETE dbo.relDepartmentPosition WHERE iDepartmentId = @iDepartmentId 
	AND iPositionId NOT IN (SELECT Id FROM @Positions);
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformation] 
	@DocumentId INT = NULL
AS
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy,
			d.iApproved,
			d.iDraft, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount
	FROM	m136_tblDocument d
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestVersion = 1
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
	DECLARE @NewDerparmentId INT = @iMaxDepartmentId + 1, @iParentLevel INT = 0;
	
	SELECT @iParentLevel = dpt.iLevel FROM dbo.tblDepartment dpt WHERE dpt.iDepartmentId = @iDepartmentParentId;
	
	SET IDENTITY_INSERT dbo.tblDepartment ON;
	INSERT INTO dbo.tblDepartment
	(
       --iDepartmentId - this column value is auto-generated
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
       0, -- iCompanyId - int
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