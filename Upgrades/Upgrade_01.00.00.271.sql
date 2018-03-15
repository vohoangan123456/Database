INSERT INTO #Description VALUES('Fix updated favorite and what"s new')
GO


IF OBJECT_ID('[dbo].[m136_GetRecentlyApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetRecentlyApprovedDocuments]  AS SELECT 1')
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
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
		h.iLevelType AS LevelType,
		h.iDepartmentId As DepartmentId
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


IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]  AS SELECT 1')
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
		h.iLevelType AS LevelType,
		h.iDepartmentId AS DepartmentId,
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