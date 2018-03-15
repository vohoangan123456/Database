
IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id = OBJECT_ID('tempdb..#Description')) DROP TABLE #Description
GO
CREATE TABLE #Description ([Description] NVARCHAR(500))
GO
----------------------------------------
----------------------------------------
INSERT INTO #Description VALUES('Create stored procedure to get chapter items,
 read access,
 document information,
 list of document approved within x days, 
 approved subscription,
 most view document,
 my favourite, 
 recent documents')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'iViewTypeId' AND [object_id] = OBJECT_ID(N'dbo.m136_tblHandbook'))
BEGIN
	-- This columns is merged from DB5 database structure. It is used for fodler about page.
	-- So we can consider use or not?
    ALTER TABLE dbo.m136_tblHandbook ADD iViewTypeId DATETIME
END
GO


IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'LastLogin' AND [object_id] = OBJECT_ID(N'dbo.tblEmployee'))
BEGIN
    ALTER TABLE dbo.tblEmployee ADD LastLogin DATETIME
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [name] = N'PreviousLogin' AND [object_id] = OBJECT_ID(N'dbo.tblEmployee'))
BEGIN
    ALTER TABLE dbo.tblEmployee ADD PreviousLogin DATETIME
END

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND TYPE IN (N'P', N'PC'))
	EXEC('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems] 
	-- Add the parameters for the stored procedure here
	@iHandbookId int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL

		SELECT	d.iDocumentId as Id,
				d.strName,
				dt.iDocumentTypeId as TemplateId,
				dt.Type as DocumentType,
				d.iVersion as Version,
				d.dtmApproved,
				d.strApprovedBy,
				e.strFirstName + ' ' + e.strLastName as Responsible, -- TODO - function??
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN tblEmployee e
				ON d.iCreatedbyId = e.iEmployeeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	
	UNION

		SELECT v.iDocumentId as Id,
			   d.strName,
			   dt.iDocumentTypeId as TemplateId,
			   dt.Type as DocumentType,
			   d.iVersion as Version,
			   d.dtmApproved,
			   d.strApprovedBy,
			   e.strFirstName + ' ' + e.strLastName as Responsible, -- TODO - function??
			   null as DepartmentId,
			   1 as Virtual,
			   v.iSort,
			   h.strName as ParentFolderName,
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
			INNER JOIN tblEmployee e
				ON d.iCreatedbyId = e.iEmployeeId
		WHERE	v.iHandbookId = @iHandbookId
				AND d.iDeleted = 0
				AND d.iLatestApproved = 1
    
	UNION
		
		SELECT	h.iHandbookId as Id,
				h.strName,
				NULL as TemplateId,
				-1 as DocumentType,
				NULL as Version,
				NULL as dtmApproved,
				NULL as strApprovedBy,
				NULL as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				-2147483648 + h.iMin as iSort, -- Little trick with putting all the folders on top of documents sorted by iMin TODO - there can be a better way with the constant more importantly
				NULL as ParentFolderName,
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0

	ORDER BY d.iSort ASC, 
			 d.strName ASC	
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterReadAccess]') AND TYPE IN (N'P', N'PC'))
	EXEC('CREATE PROCEDURE [dbo].[m136_GetChapterReadAccess] AS BEGIN SET NOCOUNT ON; END')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterReadAccess] 
	-- Add the parameters for the stored procedure here
	@SecurityId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT   [iEntityId] AS ChapterId
			--,[iPermissionSetId]
			--,[iBit]
			,Sum(CASE iPermissionSetId
				 WHEN 461 THEN 1
				 WHEN 462 THEN 2
				 END) as AccessRights
	FROM [HandbookTest].[dbo].[tblACL]
	WHERE	iSecurityId = @SecurityId 
		AND iApplicationId = 136
		AND (iBit & 1) = 1 
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462)
	GROUP BY iEntityId
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO
CREATE  PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN
	SELECT d.iEntityId, d.iDocumentId, d.iVersion, d.iDocumentTypeId, d.iHandbookId, 
		d.strName, d.strDescription, d.iCreatedById, d.dtmCreated, d.strAuthor, 
		d.iAlterId, d.dtmAlter, d.strAlterer, d.iApprovedById, d.dtmApproved, d.strApprovedBy, 
		d.dtmPublish, d.dtmPublishUntil, d.iStatus, d.iSort, d.iDeleted, d.iApproved, d.iDraft,
		h.strName strChapterName, dt.strName strDocumentTypeName, d.iLevelType,
		d.strHash, dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
		d.iReadCount, ISNULL(d.[UrlOrFileName],'') as [UrlOrFileName], ISNULL(d.[UrlOrFileProperties], '') as [UrlOrFileProperties], ISNULL(dt.[Type], 0) as DocumentFileType,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS ParentPath
	FROM m136_tblDocument d INNER 
	JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
	JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId
	WHERE d.iDocumentId = @DocumentId AND iApproved = 1
	AND d.iVersion =(
				SELECT max(iVersion) 
				FROM m136_tblDocument 
				WHERE iDocumentId = d.iDocumentId
					and iDeleted = 0 
					and iApproved = 1
					AND dtmPublish <= getDate() 
					and iDraft = 0)
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDays]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays]
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Gets List Of All Documents Approved Within X Days] 
-- =============================================
CREATE PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays] 
	-- Add the parameters for the stored procedure here
	@iApprovedWithinXDays int = 0,
	@iSecurityId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	DECLARE @Now DATETIME = GETDATE();
	
	INSERT INTO @HandbookPermissions
	SELECT iHandbookId FROM m136_tblHandbook 
		WHERE iDeleted = 0 AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1

	SELECT 0 AS Virtual, d.iDocumentId AS Id, d.iEntityId, d.strName, 
		dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
        d.iHandbookId, d.dtmApproved, h.strName AS ParentFolderName, d.iVersion AS [Version], 
        ISNULL(t.[type], 0) AS DocumentType, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, t.iDocumentTypeId AS TemplateId
	FROM m136_tblDocument d
        JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
   	WHERE d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookPermissions)
		AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iApprovedWithinXDays
		ORDER BY d.dtmApproved DESC
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDaysCount]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDaysCount]
GO
CREATE PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDaysCount] 
	-- Add the parameters for the stored procedure here
	@iApprovedWithinXDays int = 0,
	@iSecurityId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY)

	INSERT INTO @HandbookPermissions
	SELECT iHandbookId FROM m136_tblHandbook 
		WHERE iDeleted = 0 AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1

	SELECT COUNT(1)
	FROM 
		m136_tblDocument d
        JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
        JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
    WHERE
		d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId in (SELECT iHandbookId FROM @HandbookPermissions)
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), GETDATE()) < @iApprovedWithinXDays 
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetLatestApprovedSubscriptions]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions]
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Get List Of Documents By Latest Approved Subscriptions
-- =============================================
CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptions] 
	-- Add the parameters for the stored procedure here
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
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
    
    DECLARE @subTableRelation table(iDocumentId INT not null PRIMARY KEY)
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
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, t.iDocumentTypeId AS TemplateId,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
		FROM  m136_tblDocument d
			JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
			JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
			LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
		WHERE d.iLatestApproved = 1 AND d.iApproved = 1 AND d.dtmApproved <= @Now AND h.iDeleted = 0
			AND ((d.iHandbookId IN (SELECT iHandbookId FROM @subTableSubscribe))
				OR (h.iDepartmentId=@iUserDepId) OR d.iDocumentId IN (SELECT iDocumentId FROM @subTableRelation)
				OR  d.iHandbookId IN (SELECT iHandbookId FROM @tmpBooks)
			)
		ORDER BY d.dtmApproved DESC;
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetLatestApprovedSubscriptionsCount]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount]
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Get List Of Documents By Latest Approved Subscriptions
-- =============================================
CREATE PROCEDURE [dbo].[m136_GetLatestApprovedSubscriptionsCount] 
	-- Add the parameters for the stored procedure here
	@iSecurityId INT = 0,
	@iApprovedDocumentCount INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
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
    
    DECLARE @subTableRelation table(iDocumentId INT not null PRIMARY KEY)
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
	
	SELECT COUNT(1) FROM (
	SELECT TOP (@iApprovedDocumentCount) d.iDocumentId
		FROM  m136_tblDocument d
			JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
			JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
			LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
		WHERE d.iLatestApproved = 1 AND d.iApproved = 1 AND d.dtmApproved <= @Now AND h.iDeleted = 0
			AND ((d.iHandbookId IN (SELECT iHandbookId FROM @subTableSubscribe))
				OR (h.iDepartmentId=@iUserDepId) OR d.iDocumentId IN (SELECT iDocumentId FROM @subTableRelation)
				OR  d.iHandbookId IN (SELECT iHandbookId FROM @tmpBooks)
			) 
			AND (d.dtmApproved > e.PreviousLogin)
		) a;
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetMostViewedDocuments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetMostViewedDocuments]
GO
CREATE procedure [dbo].[m136_GetMostViewedDocuments]
 -- Add the parameters for the stored procedure here
 @iSecurityId int,
 @iAccessedWithinXDays int,
 @iItemCount int
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
 
 SELECT TOP (@iItemCount) 
  d.iDocumentId, doc.iHandbookId, d.iAccessedCount, doc.strName, t.Type as DocumentType
 FROM 
  m136_tblDocAccessLog AS d 
  INNER JOIN m136_tblDocument doc 
     ON d.iDocumentId = doc.iDocumentId
  INNER JOIN m136_tblDocumentType t 
     ON doc.iDocumentTypeId = t.iDocumentTypeId
 WHERE     
  d.iSecurityId = @iSecurityId 
  AND (doc.iLatestApproved = 1) 
  AND 
   ( (@iAccessedWithinXDays = 0) 
   OR
            (d.iSecurityId = @iSecurityId) AND (DATEDIFF(d, ISNULL(d.dtmAccessed, CONVERT(datetime, '01.01.1970', 104)), GETDATE()) < @iAccessedWithinXDays))
 ORDER BY 
  d.iAccessedCount DESC
  

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetMyFavorites]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetMyFavorites]
GO
CREATE PROCEDURE [dbo].[m136_GetMyFavorites] 
 -- Add the parameters for the stored procedure here
 @EmployeeId int = 0
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;

 --Forced chapters
 SELECT 1 as FavoriteType,
   h.iHandbookId,
   h.iDepartmentId, 
   h.strName, 
   h.iLevelType, 
   0 as iDocumentId,
   0 as DocumentType, 
   --dbo.m136_fnChapterHasChildren(iHandbookId)  as HasChildren,
   0 as iSort
  FROM m136_tblHandbook h 
  WHERE 
   h.iDeleted = 0  
   AND (dbo.fnSecurityGetPermission(136, 461, @EmployeeId, iHandbookId)&0x20) = 0x20
 UNION  
 --My department chapters
 SELECT 2 as FavoriteType,
   h.iHandbookId, 
   h.iDepartmentId, 
   h.strName, 
   h.iLevelType, 
   0 as iDocumentId,  
   0 as DocumentType,
   --dbo.m136_fnChapterHasChildren(iHandbookId)  as HasChildren,
   0 as iSort
   FROM m136_tblHandbook h WHERE h.iDeleted = 0 AND 
   iDepartmentId in (SELECT iDepartmentId FROM tblEmployee WHERE iEmployeeId =@EmployeeId)
   and ilevelType = 2
 UNION      
 --[m136_GetSubscriberChaptersForFrontpage]
 SELECT 
 3 as FavoriteType,
 h.iHandbookId, 
 h.iDepartmentId, 
 h.strName, 
 h.iLevelType, 
 0 as iDocumentId,
 0 as DocumentType,
 --dbo.m136_fnChapterHasChildren(h.iHandbookId)  as HasChildren,
   sh.iSort   k 
      FROM 
      m136_tblSubscribe sh
      join m136_tblHandbook h on (sh.iHandbookId = h.iHandbookId)
      WHERE h.iDeleted = 0 AND 
     sh.iEmployeeId = @EmployeeId and sh.iFrontpage = 1
 UNION 
 --[m136_GetSubscriberDocuments]
 select 
 0 as FavoriteType,
 d.iHandbookId, 
 0 as iDepartmentId, 
 d.strName, 
 0 as iLevelType, 
 d.iDocumentId, 
 t.Type as DocumentType,
 --0 as HasChildren,
 sd.iSort
   from m136_tblSubscriberDocument sd
      join m136_tblDocument d on (sd.iDocumentId = d.iDocumentId and d.iLatestApproved=1)
      join m136_tblDocumentType t on (d.iDocumentTypeId = t.iDocumentTypeId)
     where sd.iEmployeeId = @EmployeeId
 order by FavoriteType, iSort 
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRecentDocuments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRecentDocuments]
GO
CREATE procedure [dbo].[m136_GetRecentDocuments]
 -- Add the parameters for the stored procedure here
 @iSecurityId int,
 @iItemCount int
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
 
 SELECT TOP (@iItemCount) 
  d.iDocumentId, doc.iHandbookId, doc.strName, t.Type as DocumentType
 FROM 
  m136_tblDocAccessLog AS d 
  INNER JOIN m136_tblDocument doc 
     ON d.iDocumentId = doc.iDocumentId
  INNER JOIN m136_tblDocumentType t 
     ON doc.iDocumentTypeId = t.iDocumentTypeId
 WHERE     
  d.iSecurityId = @iSecurityId 
  AND (doc.iLatestApproved = 1) 
 ORDER BY 
  d.dtmAccessed DESC
  

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_UpdateEmployeeLoginTime]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime]
GO

CREATE PROCEDURE [dbo].[m136_UpdateEmployeeLoginTime]
	@iEmployeeId int
AS
BEGIN

UPDATE [dbo].[tblEmployee]
SET 
	PreviousLogin = LastLogin,
	LastLogin = GetUtcDate()
WHERE iEmployeeId = @iEmployeeId

END
GO


