INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetLatestApprovedSubscriptions], [dbo].[m136_GetDocumentsApprovedWithinXDays] for getting HasAttachment.')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				iLevelType as LevelType,
				iDepartmentId as DepartmentId
		FROM	m136_tblHandbook
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL;
		
		SELECT	d.iDocumentId as Id,
				d.strName,
				dt.iDocumentTypeId as TemplateId,
				dt.Type as DocumentType,
				d.iVersion as Version,
				NULL as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path,
				CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
					ELSE 0
				END AS BIT) as HasAttachment
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			LEFT JOIN m136_relInfo ri 
				ON ri.iEntityId = d.iEntityId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
			
	UNION
	
		SELECT	v.iDocumentId as Id,
				d.strName,
				dt.iDocumentTypeId as TemplateId,
				dt.Type as DocumentType,
				d.iVersion as Version,
				NULL as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				1 as Virtual,
				v.iSort,
				h.strName as ParentFolderName,
				dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
				CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
					ELSE 0
				END AS BIT) as HasAttachment
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
			LEFT JOIN m136_relInfo ri 
				ON ri.iEntityId = d.iEntityId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				NULL as TemplateId,
				-1 as DocumentType,
				NULL as Version,
				iLevelType as LevelType,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path,
				0 as HasAttachment
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
			
	ORDER BY d.iSort ASC, 
			 d.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetLatestApprovedSubscriptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions] AS SELECT 1 a')
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Get List Of Documents By Latest Approved Subscriptions
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions] 
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iUserDepId INT, @iHandbookId INT, @iMin INT, @iMax INT, @iLevel INT, @Now DATETIME = GETDATE();
	
	SELECT @iUserDepId = iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId ;  
	
    DECLARE @subTableSubscribe TABLE(iHandbookId INT NOT NULL PRIMARY KEY, iMin INT, iMax INT, iLevel INT);
    
    DECLARE cur CURSOR FOR SELECT iHandbookId, iMin, iMax, iLevel FROM m136_tblHandbook 
		WHERE iDeleted = 0 AND iHandbookId IN (SELECT iHandbookId FROM m136_tblSubscribe 
			WHERE iEmployeeId = @iSecurityId AND iFrontpage = 1 
				AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1);
    OPEN cur;
    
    FETCH NEXT FROM cur INTO @iHandbookId, @iMin, @iMax, @iLevel;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        INSERT INTO @subTableSubscribe(iHandbookId, iMin, iMax, iLevel)
            SELECT iHandbookId, iMin, iMax, iLevel FROM m136_tblHandbook 
				WHERE iDeleted = 0 AND iMin >= @iMin AND iMax <= @iMax 
					AND iHandbookId NOT IN (SELECT iHandbookId FROM @subTableSubscribe);
		FETCH NEXT FROM cur INTO @iHandbookId, @iMin, @iMax, @iLevel;
    END
    
    CLOSE cur;
    DEALLOCATE cur;
    
    DECLARE @subTableRelation table(iDocumentId INT not null PRIMARY KEY);
	INSERT into @subTableRelation
		SELECT DISTINCT iDocumentId FROM m136_relVirtualRelation WHERE iHandbookId IN 
			(SELECT iHandbookId FROM @subTableSubscribe);
			
	INSERT INTO @subTableRelation
		SELECT iDocumentId FROM m136_tblSubscriberDocument WHERE iEmployeeId = @iSecurityId 
			AND iDocumentId NOT IN (SELECT iDocumentId FROM @subTableRelation);
			
    DECLARE @tmpBooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY)
    INSERT into @tmpBooks
		SELECT iHandbookId FROM m136_tblHandbook WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 32) = 32 
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1 AND iDeleted = 0;
			
	SELECT TOP (@iApprovedDocumentCount) 0 AS Virtual, d.iDocumentId AS Id, d.iEntityId, d.strName, 
        dbo.fnSecurityGetPermission(136, 462, 1, d.iHandbookId) AS iAccess, d.iHandbookId, 
        d.dtmApproved, h.strName AS ParentFolderName, d.iVersion AS [Version], 
        ISNULL(t.Type, 0) AS DocumentType, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId,
		CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
			ELSE 0
		END AS BIT) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
		FROM  m136_tblDocument d
			JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
			JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
			LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
			LEFT JOIN m136_relInfo ri 
			ON ri.iEntityId = d.iEntityId
		WHERE d.iLatestApproved = 1 AND d.iApproved = 1 AND d.dtmApproved <= @Now AND h.iDeleted = 0
			AND ((d.iHandbookId IN (SELECT iHandbookId FROM @subTableSubscribe))
				OR (h.iDepartmentId=@iUserDepId) OR d.iDocumentId IN (SELECT iDocumentId FROM @subTableRelation)
				OR  d.iHandbookId IN (SELECT iHandbookId FROM @tmpBooks)
			)
		ORDER BY d.dtmApproved DESC;
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentsApprovedWithinXDays]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays] AS SELECT 1 a')
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Gets List Of All Documents Approved Within X Days] 
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays] 
	@iApprovedWithinXDays int = 0,
	@iSecurityId int = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	DECLARE @Now DATETIME = GETDATE();
	
	INSERT INTO @HandbookPermissions
		SELECT iHandbookId FROM m136_tblHandbook 
			WHERE iDeleted = 0 AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1;
		
	SELECT 0 AS Virtual, d.iDocumentId AS Id, d.iEntityId, d.strName, 
		dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
        d.iHandbookId, d.dtmApproved, h.strName AS ParentFolderName, d.iVersion AS [Version], 
        ISNULL(t.[type], 0) AS DocumentType, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId,
		CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
			ELSE 0
		END AS BIT) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
	FROM m136_tblDocument d
        JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
        LEFT JOIN m136_relInfo ri 
			ON ri.iEntityId = d.iEntityId
   	WHERE d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookPermissions)
		AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iApprovedWithinXDays
		ORDER BY d.dtmApproved DESC
END