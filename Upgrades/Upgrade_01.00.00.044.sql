INSERT INTO #Description VALUES('New way of getting latest documents (whats new); previous login removed; login is updated and returned in authenticate procedures')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDays]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDaysCount]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDaysCount]
GO

IF OBJECT_ID('[dbo].[m136_GetRecentlyApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments] 
	@iDaysLimit int,
	@maxCount int
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Now DATETIME = GETDATE();
	
	SELECT TOP (@maxCount)
		d.iDocumentId as Id,
		d.iHandbookId,
		d.strName,
		d.iDocumentTypeId,
		d.iVersion as [Version],
		d.dtmApproved,
		d.strApprovedBy,
		dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		h.strName as ParentFolderName,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
	FROM
		m136_tblDocument d
        INNER JOIN m136_tblHandbook h 
			ON d.iHandbookId = h.iHandbookId
   	WHERE 
			d.iLatestApproved = 1
		AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iDaysLimit
	ORDER BY
		d.dtmApproved DESC
END
GO

IF OBJECT_ID('[dbo].[m136_AuthenticateUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AuthenticateUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_AuthenticateUser]
	@Username varchar(100),
	@HashedPassword varchar(32)
AS
BEGIN

	DECLARE @EmployeeId int

	-- Check if the requested user exists with this password
	SELECT @EmployeeId =	
		(SELECT
			[iEmployeeId]
		FROM
			[dbo].[tblEmployee]
		WHERE
				strLoginName = @UserName
			AND	strPassword = @HashedPassword)

	-- Return the required data for the user
	SELECT
		[iEmployeeId], 
		[strFirstName], 
		[strLastName],
		[LastLogin]
	FROM
		[dbo].[tblEmployee]
	WHERE 
		iEmployeeId = @EmployeeId

	-- Update last logon time
	IF @EmployeeId IS NOT NULL
	BEGIN
		EXEC [dbo].[m136_UpdateEmployeeLoginTime] @EmployeeId
	END

END
GO

IF OBJECT_ID('[dbo].[m136_AuthenticateDomainUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AuthenticateDomainUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_AuthenticateDomainUser]
	@LoginName varchar(100),
	@Domain varchar(100)
AS
BEGIN

	DECLARE @EmployeeId int

	-- Check if the requested user exists with this password
	SELECT @EmployeeId =	
		(SELECT
			[iEmployeeId]
		FROM
			[dbo].[tblEmployee]
		WHERE
				strLoginName = @LoginName
			AND ',' + strLoginDomain + ',' LIKE '%,' + @Domain + ',%') -- A trick to support the multiple domains in the field (domain1,domain2)

	-- Return the required data for the user
	SELECT
		[iEmployeeId], 
		[strFirstName], 
		[strLastName],
		[LastLogin]
	FROM
		[dbo].[tblEmployee]
	WHERE 
		iEmployeeId = @EmployeeId

	-- Update last logon time
	IF @EmployeeId IS NOT NULL
	BEGIN
		EXEC [dbo].[m136_UpdateEmployeeLoginTime] @EmployeeId
	END
END
GO

IF OBJECT_ID('[dbo].[m136_UpdateEmployeeLoginTime]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime]
	@iEmployeeId int
AS
BEGIN
UPDATE 
	[dbo].[tblEmployee]
SET 
	PreviousLogin = LastLogin,
	LastLogin = GetDate()
WHERE 
	iEmployeeId = @iEmployeeId
END
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0,
	@TreatDepartmentFoldersAsFavorites INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	
	DECLARE @PreviousLogin Datetime;
	SELECT @PreviousLogin = PreviousLogin FROM tblEmployee WHERE iEmployeeId = @iSecurityId;

	-- get list of handbookId which is favorite and have read access
	DECLARE @FavoriteHandbooksWithReadContents TABLE(iHandbookId INT);
	INSERT INTO @FavoriteHandbooksWithReadContents(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively](@iSecurityId, @TreatDepartmentFoldersAsFavorites, @iUserDepId);
	-- get list of favorite document
	WITH Documents AS
	(
		SELECT
			iDocumentId
		FROM
			m136_relVirtualRelation
		WHERE iHandbookId IN (SELECT DISTINCT iHandbookId 
							  FROM @FavoriteHandbooksWithReadContents)
			
		UNION
		
		SELECT
			iDocumentId
		FROM
			m136_tblSubscriberDocument
		WHERE 
			iEmployeeId = @iSecurityId
	)
	SELECT DISTINCT 
		TOP(@iApprovedDocumentCount) 
		d.iDocumentId AS Id, 
		d.iEntityId, 
		d.strName, 
        dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
		d.iHandbookId, 
        d.dtmApproved, 
		h.strName AS ParentFolderName, 
		d.iVersion AS [Version], 
        d.iDocumentTypeId,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) AS Responsible, 
		[dbo].[fnHasDocumentAttachment](d.iEntityId) AS HasAttachment,
        CASE WHEN 
			d.dtmApproved > @PreviousLogin THEN 1
		ELSE 0
		END AS IsNew
	FROM  
		m136_tblDocument d
		JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
		LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iApprovedById
	WHERE 
		d.iLatestApproved = 1
		AND ((d.iHandbookId IN (SELECT rp.iHandbookId FROM @FavoriteHandbooksWithReadContents rp))
			OR	(@TreatDepartmentFoldersAsFavorites = 1 AND h.iDepartmentId = @iUserDepId AND h.iDeleted = 0) 
			OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents)
		)
	ORDER BY d.dtmApproved DESC;
END
GO