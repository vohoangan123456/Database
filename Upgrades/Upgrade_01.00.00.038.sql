INSERT INTO #Description VALUES('update stored
[dbo][m136_GetMyFavorites],
[dbo][m136_GetLatestApprovedSubscriptions]
Create function
[dbo].[m136_fnGetFavoriteFolders],
[dbo].[m136_IsForcedHandbook]')
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
	EXEC ('CREATE FUNCTION [dbo].[m136_fnGetFavoriteFolders]() RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
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

IF OBJECT_ID('[dbo].[m136_GetMyFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMyFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMyFavorites]
	@EmployeeId INT = 0,
	@TreatDepartmentFoldersAsFavorites BIT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @EmployeeId;
	--chapter
	SELECT
		h.iHandbookId, 
		h.strName, 
		h.iLevelType,
		bf.isForced AS isForced,
		bf.isDepartment AS isDepartment
	FROM
		m136_tblHandbook h
		JOIN [dbo].[m136_fnGetFavoriteFolders](@EmployeeId, @TreatDepartmentFoldersAsFavorites,@iUserDepId) bf
			ON h.iHandbookId = bf.iHandbookId
	ORDER BY
		CASE WHEN (isDepartment = 1 AND isForced = 1) OR (isDepartment = 1) THEN h.strName
		END,
		isDepartment,
		isForced,
		CASE WHEN isDepartment = 0 AND isForced = 0 THEN bf.iSort
		END,
		h.strName
	--document
	SELECT
		d.iHandbookId,
		d.strName,
		d.iDocumentId, 
		d.iDocumentTypeId
	FROM
		m136_tblSubscriberDocument sd
		JOIN m136_tblDocument d 
			ON (sd.iDocumentId = d.iDocumentId AND d.iLatestApproved = 1)
	WHERE
		sd.iEmployeeId = @EmployeeId
	ORDER BY
		sd.iSort,
		strName
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
	DECLARE @Now DATETIME = GETDATE();
	
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
	
	DECLARE @tmpBooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY)
	INSERT INTO
		@tmpBooks
	SELECT
		iHandbookId 
	FROM
		m136_tblHandbook 
	WHERE 
		(dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 32) = 32 
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1 
		AND iDeleted = 0;
			
	WITH LastApprovedHandbookSubscription AS
	(
		SELECT
			iHandbookId
		FROM 
			[dbo].[m136_fnGetFavoriteFolders](@iSecurityId, @TreatDepartmentFoldersAsFavorites, @iUserDepId)
			
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN LastApprovedHandbookSubscription 
				ON	iParentHandbookId = LastApprovedHandbookSubscription.iHandbookId 
					AND h.iDeleted = 0
	), 
	Documents AS
	(
		SELECT
			iDocumentId
		FROM
			m136_relVirtualRelation
		WHERE iHandbookId IN (SELECT iHandbookId 
							  FROM LastApprovedHandbookSubscription)
			
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
		0 AS Virtual, 
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
			d.dtmApproved > e.PreviousLogin THEN 1
		ELSE 0
		END AS IsNew
		FROM  
			m136_tblDocument d
			JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
			LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
		WHERE 
			d.iLatestApproved = 1 
			AND d.iApproved = 1 
			AND d.dtmApproved <= @Now 
			AND h.iDeleted = 0
			AND ((d.iHandbookId IN (SELECT iHandbookId FROM LastApprovedHandbookSubscription))
				OR	(@TreatDepartmentFoldersAsFavorites = 1 AND h.iDepartmentId = @iUserDepId) 
				OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents)
				OR	d.iHandbookId IN (SELECT iHandbookId FROM @tmpBooks)
			)
		ORDER BY d.dtmApproved DESC;
END
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptionsCount]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount]
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0,
	@TreatDepartmentFoldersAsFavorites INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @LastedApprovedSubscription TABLE
	(
		Virtual INT,
		Id INT,
		iEntityId INT,
		strName VARCHAR(MAX),
		iAccess INT,
		iHandbookId INT,
		dtmApproved DATETIME,
		ParentFolderName VARCHAR(500),
		[Version] INT,
		iDocumentTypeId INT,
		[Path] NVARCHAR(4000),
		strApprovedBy NVARCHAR(1000),
		Responsible NVARCHAR(102),
		HasAttachment BIT,
		IsNew BIT
	)
	INSERT INTO @LastedApprovedSubscription
	EXEC [dbo].[m136_GetLatestApprovedSubscriptions] @iSecurityId, @iApprovedDocumentCount, @TreatDepartmentFoldersAsFavorites
	
	SELECT COUNT(1) FROM @LastedApprovedSubscription WHERE IsNew = 1
END
