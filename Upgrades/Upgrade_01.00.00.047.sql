INSERT INTO #Description VALUES('Some fixes to the updated favorites')
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptionsCount]', 'p') IS NOT NULL
	DROP PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount]
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
	DECLARE @FavoriteHandbooksWithReadContents TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
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
		AND (		(d.iHandbookId IN (SELECT iHandbookId FROM @FavoriteHandbooksWithReadContents))
				OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents))
	ORDER BY d.dtmApproved DESC
END
GO

IF OBJECT_ID('[dbo].[m136_IsForcedDocument]', 'fn') IS NOT NULL
	DROP FUNCTION [dbo].[m136_IsForcedDocument]
GO

IF OBJECT_ID('[dbo].[m136_IsForcedHandbook]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_IsForcedHandbook]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[m136_IsForcedHandbook]
(
	@EmployeeId INT,
	@HandbookId INT
)
RETURNS BIT
AS
BEGIN
	DECLARE @isForced BIT
	SET @isForced = 0
	IF((dbo.fnSecurityGetPermission(136, 461, @EmployeeId, @HandbookId)&0x20) = 0x20)
	BEGIN
		SET @isForced = 1
	END
	RETURN @isForced
END
GO

IF OBJECT_ID('[dbo].[m136_fnGetFavoriteFolders]', 'if') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_fnGetFavoriteFolders]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[m136_fnGetFavoriteFolders]
(
	@EmployeeId INT, 
	@TreatDepartmentFoldersAsFavorites BIT,
	@DepartmentId INT
)
RETURNS TABLE
AS
RETURN
(
	SELECT
		h.iHandbookId,
		CASE
			WHEN [dbo].[m136_IsForcedHandbook](@EmployeeId, h.iHandbookId) = 1 THEN 1
			ELSE 0
		END AS isForced,
		CASE
			WHEN @DepartmentId = h.iDepartmentId THEN 1
			ELSE 0
		END AS isDepartment,
		sd.iSort
	FROM
		m136_tblHandbook h
		LEFT JOIN m136_tblSubscribe sd 
			ON sd.iHandbookId = h.iHandbookId AND sd.iEmployeeId = @EmployeeId
	WHERE
		h.iDeleted = 0 
		AND ((sd.iEmployeeId = @EmployeeId AND sd.iFrontpage = 1)
			OR	([dbo].[m136_IsForcedHandbook](@EmployeeId, h.iHandbookId) = 1)
			OR	( @TreatDepartmentFoldersAsFavorites = 1 AND h.iDepartmentId = @DepartmentId))
);
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
    -- Getting the last logon
	DECLARE @LastLogin datetime
	SET @LastLogin =
	(
		SELECT
			CONVERT(date, [LastLogin])
		FROM
			[dbo].[tblEmployee]
		WHERE 
			iEmployeeId = @EmployeeId
	)
	-- Return the required data for the user
	SELECT
		[iEmployeeId], 
		[iDepartmentId], 
		[strFirstName], 
		[strLastName],
		[LastLogin]
	FROM
		[dbo].[tblEmployee]
	WHERE 
		iEmployeeId = @EmployeeId
	-- Update last logon time only if not the same day
	IF @EmployeeId IS NOT NULL AND @LastLogin < CONVERT(date, GetDate())
	BEGIN
		EXEC [dbo].[m136_UpdateEmployeeLoginTime] @EmployeeId
	END
END

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
		[iDepartmentId], 
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