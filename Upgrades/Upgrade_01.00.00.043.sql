
IF OBJECT_ID('[dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively]', 'if') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively]() RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO
ALTER FUNCTION [dbo].[m136_fnGetAllFavoritesFoldersWithContentsAccessRecursively]
(
	@iSecurityId INT = 0,
	@TreatDepartmentFoldersAsFavorites BIT,
	@iUserDepId INT = 0
)
RETURNS TABLE
AS
RETURN
(
	WITH RecursiveFavoriteHandbooksWithReadContents AS
	(
		SELECT
			iHandbookId
		FROM 
			[dbo].[m136_fnGetFavoriteFolders](@iSecurityId, @TreatDepartmentFoldersAsFavorites, @iUserDepId)
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
			
		UNION ALL
		-- recursive to get all the child handbook
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN RecursiveFavoriteHandbooksWithReadContents 
				ON	iParentHandbookId = RecursiveFavoriteHandbooksWithReadContents.iHandbookId 
					AND h.iDeleted = 0
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, h.iHandbookId) = 1
	)
	SELECT DISTINCT iHandbookId FROM RecursiveFavoriteHandbooksWithReadContents
);
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
			d.dtmApproved > e.PreviousLogin THEN 1
		ELSE 0
		END AS IsNew,
		d.iCreatedById
	FROM  
		m136_tblDocument d
		JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
		LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
	WHERE 
		d.iLatestApproved = 1
		AND ((d.iHandbookId IN (SELECT rp.iHandbookId FROM @FavoriteHandbooksWithReadContents rp))
			OR	(@TreatDepartmentFoldersAsFavorites = 1 AND h.iDepartmentId = @iUserDepId) 
			OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents)
		)
	ORDER BY d.dtmApproved DESC;
END
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptionsCount]', 'p') IS NOT NULL
	DROP PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount]
GO
IF OBJECT_ID('[dbo].[m136_GetNewLatestApprovedSubscriptionsCount]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewLatestApprovedSubscriptionsCount] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewLatestApprovedSubscriptionsCount]
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0,
	@TreatDepartmentFoldersAsFavorites INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @iUserDepId INT;
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId;
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
		COUNT(*)
	FROM  
		m136_tblDocument d
		JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
		LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
	WHERE 
		d.iLatestApproved = 1 
		AND ((d.iHandbookId IN (SELECT rp.iHandbookId FROM @FavoriteHandbooksWithReadContents rp))
			OR	(@TreatDepartmentFoldersAsFavorites = 1 AND h.iDepartmentId = @iUserDepId) 
			OR	d.iDocumentId IN (SELECT iDocumentId FROM Documents)
		)
		AND d.dtmApproved > e.PreviousLogin
END