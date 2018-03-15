---------- FILE: Upgrade_01.00.00.001.sql ----------

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





---------- FILE: Upgrade_01.00.00.002.sql ----------


INSERT INTO #Description VALUES('Create stored procedure to get chapter items,
 read access,
 document information,
 list of document approved within x days, 
 approved subscription,
 most view document,
 my favourite,
 recent documents')
GO

----------------------------------------
----------------------------------------
		
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRelatedAttachments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRelatedAttachments]
GO

CREATE  PROCEDURE [dbo].[m136_GetRelatedAttachments]
	@iEntityId int,
	@iSecurityId int,
	@RelationTypes int
AS
BEGIN

	IF @RelationTypes = 2
		BEGIN
			SELECT r.iItemId, dbo.fnArchiveGetFileName(@iSecurityId, r.iItemId, '') strName
				  ,r.iPlacementId,r.iProcessrelationTypeId,isnull(b.strExtension,'ukjent') AS strExtension
				FROM m136_relInfo r 
				LEFT JOIN tblBlob b ON r.iItemId=b.iItemId 
				WHERE iEntityId = @iEntityId AND r.iRelationTypeId = 2 
		END
	ELSE IF @RelationTypes = 20
		BEGIN
			SELECT r.iItemId,b.strName
				FROM m136_relInfo r JOIN m136_tblBlob b ON r.iItemId = b.iItemId
				WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20 
		END
	ELSE IF @RelationTypes = 50
		BEGIN
			SELECT r.iItemId,dbo.fnArchiveGetImageName(@iSecurityId, r.iItemId, '') AS strName
					,ISNULL(r.iPlacementId,0) AS iPlacementId,r.iProcessrelationTypeId
					,ISNULL(r.iScaleDirId,0) AS iScaleDirId
					,ISNULL(r.iVJustifyId,0) AS iVJustifyId ,ISNULL(r.iHJustifyId,0) AS iHJustifyId
					,ISNULL(r.iSize,0) AS iSize, ISNULL(r.strCaption,'') AS strCaption
					,ISNULL(r.iSort,0) AS iSort, ISNULL(r.strURL,'') AS strURL,ISNULL(r.iWidth,0) AS iWidth
					,ISNULL(r.iHeight,0) AS iHeight, ISNULL(r.iNewWindow,0) AS iNewWindow
					,ISNULL(r.iThumbWidth,0) AS iThumbWidth, ISNULL(r.iThumbHeight,0) AS iThumbHeight, r.iRelationTypeId
				FROM m136_relInfo r 
				JOIN m136_tblBlob b on r.iItemId = b.iItemId 
				WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 50 
		END
	ELSE IF @RelationTypes = 5
		BEGIN
			SELECT r.iItemId, r.iScaleDirId, r.iPlacementId, r.iVJustifyId, 
					r.iHJustifyId, r.iSize, r.strCaption, r.iSort, r.strURL, 
					r.iWidth, r.iHeight, r.iNewWindow,
					dbo.fnArchiveGetImageName(@iSecurityId, r.iItemId, '') strName,
					r.iThumbWidth, r.iThumbHeight, r.iRelationTypeId
				FROM m136_relInfo r 
				WHERE iEntityId = @iEntityId AND r.iRelationTypeId = 5 
		END				
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRelatedDocuments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRelatedDocuments]
GO

CREATE PROCEDURE [dbo].[m136_GetRelatedDocuments]
	@iEntityId int,
	@ExtendRelatedDoc bit = 1
AS
BEGIN
	SELECT  d.strName, d.iDocumentId
	FROM m136_relInfo r
	JOIN m136_tblDocument d 
		ON r.iItemId = d.iDocumentId 
		AND d.iVersion = (SELECT ISNULL(MAX(iVersion), 0)
			FROM m136_tblDocument
			WHERE iDocumentId = r.iItemId
				AND (@ExtendRelatedDoc = 0 OR (@ExtendRelatedDoc = 1 AND iApproved in (1,4)))
				AND iDeleted = 0)
		AND ((@ExtendRelatedDoc = 0 AND d.iApproved <> 4) OR (@ExtendRelatedDoc = 1 AND d.iApproved = 1))
	JOIN m136_tblDocumentType dtype on d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 136
	order by r.iSort
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentFieldContents]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentFieldContents]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentFieldContents]
	@DocumentTypeId int,
	@iEntityId int
AS
BEGIN
	SELECT	mi.iInfoTypeId, mi.strName strFieldName, mi.strDescription strFieldDescription,
            InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
            NumberValue = mii.value, DateValue = mid.value, TextValue = mit.value, RichTextValue = mir.value,                            
            mi.iMetaInfoTemplateRecordsId, mi.iFieldProcessType, rdi.iMaximized
    FROM		[dbo].m136_tblMetaInfoTemplateRecords mi
                JOIN [dbo].m136_relDocumentTypeInfo rdi ON rdi.iDocumentTypeId = @DocumentTypeId AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoDate mid ON mid.iEntityId = @iEntityId AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoNumber mii ON mii.iEntityId = @iEntityId AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoText mit ON mit.iEntityId = @iEntityId AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
                LEFT JOIN [dbo].m136_tblMetaInfoRichText mir ON mir.iEntityId = @iEntityId AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
    WHERE rdi.iDeleted = 0
    ORDER BY	rdi.iSort
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetFieldContentsCompareToVersion]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetFieldContentsCompareToVersion]
GO

CREATE PROCEDURE [dbo].[m136_GetFieldContentsCompareToVersion]
	@documentEntityId int 
AS 
BEGIN

	DECLARE @EntityIdcompareToVersion int = null	
	DECLARE @DocumetTypeIdcompareToVersion int = null	
	DECLARE @documentId int
	DECLARE @currentVersion INT

	SELECT @EntityIdcompareToVersion = iCompareToVersion, @DocumetTypeIdcompareToVersion = iDocumentTypeId, @currentVersion = iVersion, @documentId = iDocumentId 
	FROM dbo.m136_tblDocument WHERE iEntityId = @documentEntityId
	
	IF @EntityIdcompareToVersion IS NULL AND EXISTS(SELECT * FROM dbo.m136_tblDocument WHERE iDocumentId = @documentId AND iVersion < @currentVersion AND iDeleted = 0 AND iApproved = 1)
	BEGIN
		SELECT TOP 1 @EntityIdcompareToVersion = iEntityId , @DocumetTypeIdcompareToVersion = iDocumentTypeId 
		FROM dbo.m136_tblDocument 
		WHERE iDocumentId = @documentId AND iVersion < @currentVersion AND iDeleted = 0 AND iApproved = 1
		ORDER BY iVersion DESC
	END

	IF @EntityIdcompareToVersion IS NOT NULL
	BEGIN
		exec dbo.m136_GetDocumentFieldContents @DocumetTypeIdcompareToVersion , @EntityIdcompareToVersion
	END
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_InsertOrUpdateDocAccessLog]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_InsertOrUpdateDocAccessLog]
GO
-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.11.2013
-- Description:	Insert Or Update Document Access Log
-- =============================================
CREATE procedure [dbo].[m136_InsertOrUpdateDocAccessLog]
	-- Add the parameters for the stored procedure here
	@iSecurityId int,
	@iDocumentId int,
	@dtmAccessed smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF EXISTS (SELECT * FROM [dbo].[m136_tblDocAccessLog]
				 WHERE iSecurityId = @iSecurityId AND iDocumentId = @iDocumentId)

        UPDATE [dbo].[m136_tblDocAccessLog]
        SET iAccessedCount = iAccessedCount + 1, dtmAccessed = @dtmAccessed
        WHERE iSecurityId = @iSecurityId AND iDocumentId = @iDocumentId

    ELSE    

        INSERT INTO [dbo].[m136_tblDocAccessLog]
        (
			iSecurityId, iDocumentId, dtmAccessed, iAccessedCount
		)
        VALUES
        (
			@iSecurityId, @iDocumentId, @dtmAccessed, 1
		)
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_IncreaseReadCountDocument]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_IncreaseReadCountDocument]
GO


CREATE procedure [dbo].[m136_IncreaseReadCountDocument]
	-- Add the parameters for the stored procedure here
	@iSecurityId int,
	@iDocumentId int,
	@iEntityId int,
	@dtmAccessed smalldatetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	UPDATE dbo.m136_tblDocument set iReadCount=iReadcount+1 where iEntityId= @iEntityId
	
	exec [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @dtmAccessed
END

GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
 -- Add the parameters for the stored procedure here
 @iHandbookId int = NULL
AS
BEGIN
 -- SET NOCOUNT ON added to prevent extra result sets from
 -- interfering with SELECT statements.
 SET NOCOUNT ON;
  SELECT strName as FolderName,
    iParentHandbookId as ParentId,
    dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
    iLevelType as [Level],
    iViewTypeId as ViewType
  FROM m136_tblHandbook
  WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
  SELECT d.iDocumentId as Id,
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
  FROM m136_tblDocument d
   INNER JOIN m136_tblDocumentType dt 
    ON d.iDocumentTypeId = dt.iDocumentTypeId
   INNER JOIN tblEmployee e
    ON d.iCreatedbyId = e.iEmployeeId
  WHERE d.iHandbookId = @iHandbookId
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
  WHERE v.iHandbookId = @iHandbookId
    AND d.iDeleted = 0
    AND d.iLatestApproved = 1
 UNION
  SELECT h.iHandbookId as Id,
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
  WHERE (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
    AND h.iDeleted = 0
 ORDER BY d.iSort ASC, 
    d.strName ASC 
END
GO

---------- FILE: Upgrade_01.00.00.003.sql ----------

INSERT INTO #Description VALUES('Change iLevelType as Level --> iLevel as Level')
GO

----------------------------------------
----------------------------------------
		
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

-- =============================================
-- Author:		Ilya Chernomordik
-- Create date: 17.10.2014
-- Description:	Get chapter contents irrespective of ACL
-- =============================================
CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
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

---------- FILE: Upgrade_01.00.00.004.sql ----------
INSERT INTO #Description VALUES('Removed comparison procedure. ')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetFieldContentsCompareToVersion]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetFieldContentsCompareToVersion]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_IncreaseReadCountDocument]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_IncreaseReadCountDocument]
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_LogDocumentRead]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_LogDocumentRead]
GO

CREATE PROCEDURE [dbo].[m136_LogDocumentRead]
	@iSecurityId int,
	@iEntityId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iDocumentId int
	DECLARE @now smalldatetime

	SET @now = GetUtcDate()
	SET @iDocumentId = 
	(SELECT iDocumentId 
	FROM [dbo].[m136_tblDocument]
	WHERE iEntityId = @iEntityId)

	UPDATE [dbo].[m136_tblDocument]
	SET iReadCount = iReadcount + 1
	WHERE iEntityId = @iEntityId

	EXEC [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @now
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
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
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
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
			   dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
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

IF NOT EXISTS(SELECT * FROM sys.columns 
            WHERE Name = N'iLatestVersion' AND Object_ID = Object_ID(N'm136_tblDocument'))
BEGIN
    ALTER TABLE dbo.m136_tblDocument
	ADD iLatestVersion INT
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN

	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestVersion = 1

END
GO

---------- FILE: Upgrade_01.00.00.005.sql ----------

INSERT INTO #Description VALUES('Adding level type to the GetChapterItems')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetChapterItems]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetChapterItems]
GO

CREATE PROCEDURE [dbo].[m136_GetChapterItems] 
	-- Add the parameters for the stored procedure here
	@iHandbookId int = NULL
AS
BEGIN

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
				NULL as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				null as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	
	UNION

		SELECT v.iDocumentId as Id,
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
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
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
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0

	ORDER BY d.iSort ASC, 
			 d.strName ASC	
END
GO

---------- FILE: Upgrade_01.00.00.006.sql ----------

INSERT INTO #Description VALUES('update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dt.[strName] AS DocumentTypeName
	FROM m136_tblDocument d
	JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId AND dt.iDeleted = 0
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentFieldsAndRelates]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
GO

CREATE  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId int,
@DocumentTypeId int
AS
BEGIN

	SELECT r.iItemId,b.strName
	FROM m136_relInfo r JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20 

	SELECT  d.strName, d.iDocumentId
	FROM m136_relInfo r
	JOIN m136_tblDocument d 
		ON r.iItemId = d.iDocumentId 
		AND d.iLatestApproved = 1
		AND  d.iApproved = 1
	JOIN m136_tblDocumentType dtype on d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 136
	ORDER BY r.iSort

	SELECT	mi.iInfoTypeId, mi.strName strFieldName, mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, DateValue = mid.value, TextValue = mit.value, RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, mi.iFieldProcessType, rdi.iMaximized
	FROM		[dbo].m136_tblMetaInfoTemplateRecords mi
				JOIN [dbo].m136_relDocumentTypeInfo rdi ON rdi.iDocumentTypeId = @DocumentTypeId AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoDate mid ON mid.iEntityId = @iEntityId AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoNumber mii ON mii.iEntityId = @iEntityId AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoText mit ON mit.iEntityId = @iEntityId AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
				LEFT JOIN [dbo].m136_tblMetaInfoRichText mir ON mir.iEntityId = @iEntityId AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort

END
GO


---------- FILE: Upgrade_01.00.00.007.sql ----------

INSERT INTO #Description VALUES('Adding field [responsible]')
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
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId,
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
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId
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



---------- FILE: Upgrade_01.00.00.008.sql ----------

INSERT INTO #Description VALUES('Adding field IsNew')
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
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
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



---------- FILE: Upgrade_01.00.00.009.sql ----------

INSERT INTO #Description VALUES('Checking last login for getting what new count')
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
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
    WHERE
		d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId in (SELECT iHandbookId FROM @HandbookPermissions)
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), GETDATE()) < @iApprovedWithinXDays 
        AND (d.dtmApproved > e.PreviousLogin)
END
GO



---------- FILE: Upgrade_01.00.00.010.sql ----------

INSERT INTO #Description VALUES('update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN

	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
			
END
GO 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetFileContents]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetFileContents]
GO

CREATE PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId int
AS
BEGIN

	SELECT strFilename, strContentType, imgContent, strExtension
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO
 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetLatestConfirmInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetLatestConfirmInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetLatestConfirmInformation]
	@SecurityId int,
	@EntityId int
AS
BEGIN

	SELECT ISNULL(strFirstName, '') + ISNULL(' ' + strLastName, '') AS FullName
	FROM  dbo.tblEmployee
	WHERE iEmployeeId = @SecurityId

	SELECT top 1 dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEmployeeId=@SecurityId 
		AND iEntityId=@EntityId 
	ORDER BY dtmConfirm DESC

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_InsertReadConfirm]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_InsertReadConfirm]
GO

CREATE PROCEDURE [dbo].[m136_InsertReadConfirm]
	@EntityId INT,
	@EmployeeId INT,
	@EmployeeName VARCHAR(100)
AS
BEGIN

	INSERT INTO m136_tblConfirmRead(iEntityId, iEmployeeId, dtmConfirm, strEmployeeName)
	VALUES(@EntityId, @EmployeeId , GETDATE(), @EmployeeName)

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_ProcessFeedback]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_ProcessFeedback]
GO


CREATE PROCEDURE [dbo].[m136_ProcessFeedback]
	@SecurityId INT,
	@EntityId INT,
	@FeedbackMsg VARCHAR(4000),
	@RecipientsForMailFeedback INT
AS
BEGIN

	--Insert feedback
	INSERT INTO m136_tblFeedback(iEntityId, iEmployeeId, dtmFeedback, strFeedback)
		VALUES(@EntityId, @SecurityId , GETDATE(), @FeedbackMsg)
	
	DECLARE @CreatedById INT, @ApprovedId INT, @FolderId INT, @DocumentName VARCHAR(200), @DocumentId INT, @Version INT
	DECLARE @FromEmailAdress varchar(100)
	DECLARE @ToEmailAdress TABLE (email varchar(100))
	
	--Get document Infomation
	SELECT	@DocumentId = d.iDocumentId, 
			@DocumentName = d.strName,
			@FolderId = d.iHandbookId,
			@Version = d.iVersion,
			@CreatedById = d.iCreatedbyId,
			@ApprovedId = d.iApprovedById
	FROM	m136_tblDocument d
	WHERE	d.iEntityId = @EntityId	AND 
			d.iDeleted = 0
			
	--Get Email from
	SELECT @FromEmailAdress = isNull(strEmail, '') FROM tblEmployee WHERE iEmployeeId = @SecurityId	
	
	INSERT INTO @ToEmailAdress 
			SELECT  isNull(strEmail, '') FROM tblEmployee WHERE iEmployeeId = @CreatedById	
			
	--Get Email To
	IF @RecipientsForMailFeedback = 1
		BEGIN
			INSERT INTO @ToEmailAdress 
				SELECT  isNull(strEmail, '') 
				FROM tblEmployee 
				WHERE iEmployeeId = @ApprovedId	
		END
	ELSE
		BEGIN
			-- Get email of user have permisson approved
			INSERT INTO @ToEmailAdress 
			SELECT DISTINCT e.strEmail
				FROM tblEmployee e JOIN relEmployeeSecGroup s ON e.iEmployeeId = s.iEmployeeId
				JOIN tblACL a ON s.iSecGroupId = a.iSecurityId AND
				a.iEntityId = @FolderId AND a.iApplicationId = 136 AND
				a.iPermissionSetId = 462 AND (a.iBit & 0x10) = 0x10
				AND e.strEmail IS NOT NULL AND e.strEmail <> ''
		END
	
	--return data
	SELECT @DocumentId AS DocumentId, @DocumentName AS Name, @Version AS Version, @FromEmailAdress AS FromEmailAdress
	
	SELECT DISTINCT email AS Email FROM @ToEmailAdress
	
END
GO


---------- FILE: Upgrade_01.00.00.011.sql ----------
INSERT INTO #Description VALUES('create new stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
edit stored procedure
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
	VALUES (@iSecurityId, @HandbookId,0,1,0,0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookOffFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookOffFavorites] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookOffFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscribe]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iHandbookId] = @HandbookId
END
GO

IF OBJECT_ID('[dbo].[m136_AddDocumentToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddDocumentToFavorites] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_AddDocumentToFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscriberDocument] ([iEmployeeId], [iDocumentId], [iSort]) 
	VALUES (@iSecurityId, @DocumentId, 0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentOffFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentOffFavorites] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentOffFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscriberDocument]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iDocumentId] = @DocumentId
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DECLARE @IsFavourite bit
	IF EXISTS(SELECT 1 FROM m136_tblSubscribe WHERE iHandbookId = @iHandbookId AND iEmployeeId = @iSecurityId)
		SET @IsFavourite = 1
	ELSE
		SET @IsFavourite = 0
		
	SELECT	strName as FolderName,
				iParentHandbookId as ParentId,
				dbo.fn136_GetParentPathEx(@iHandbookId) as Path,
				iLevel as Level,
				iViewTypeId as ViewType,
				@IsFavourite as IsFavourite
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
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
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	UNION
		SELECT v.iDocumentId as Id,
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
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
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
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1 a')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DECLARE @IsFavourite bit
	IF EXISTS(SELECT 1 FROM m136_tblSubscriberDocument WHERE iDocumentId = @DocumentId AND iEmployeeId = @iSecurityId)
		SET @IsFavourite = 1
	ELSE
		SET @IsFavourite = 0
		
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			@IsFavourite as IsFavourite
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO


---------- FILE: Upgrade_01.00.00.012.sql ----------
INSERT INTO #Description VALUES('Update m136_GetChapterReadAccess to not contain HandbookTest')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterReadAccess]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterReadAccess] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterReadAccess] 
	-- Add the parameters for the stored procedure here
	@SecurityId int
AS
BEGIN
	SELECT	[iEntityId] AS ChapterId,
			Sum(CASE iPermissionSetId
				 WHEN 461 THEN 1
				 WHEN 462 THEN 2
				 END) as AccessRights
	FROM [dbo].[tblACL]
	WHERE	iSecurityId = @SecurityId 
		AND iApplicationId = 136
		AND (iBit & 1) = 1 
		AND (iPermissionSetId = 461 OR iPermissionSetId = 462)
	GROUP BY iEntityId
END
GO

---------- FILE: Upgrade_01.00.00.013.sql ----------

INSERT INTO #Description VALUES('update store procedure for review code')
GO

IF OBJECT_ID('[dbo].[m136_InsertReadingConfirmation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertReadingConfirmation] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_InsertReadingConfirmation]
	@EntityId INT,
	@EmployeeId INT
AS
BEGIN

	INSERT INTO m136_tblConfirmRead(iEntityId, iEmployeeId, dtmConfirm, strEmployeeName)
	VALUES(@EntityId, @EmployeeId , GETDATE(), [dbo].[fnOrgGetUserName](@EmployeeId,'No Name',0))

END
GO

IF OBJECT_ID('[dbo].[m136_ProcessFeedback]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessFeedback] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_ProcessFeedback]
	@SecurityId INT,
	@EntityId INT,
	@FeedbackMessage VARCHAR(4000),
	@RecipientsForMailFeedback INT
AS
BEGIN

	--Insert feedback
	INSERT INTO m136_tblFeedback(iEntityId, iEmployeeId, dtmFeedback, strFeedback)
		VALUES(@EntityId, @SecurityId , GETDATE(), @FeedbackMessage)
	
	DECLARE @CreatedById INT, @ApprovedId INT, @FolderId INT, @DocumentName VARCHAR(200), @DocumentId INT, @Version INT
	DECLARE @FromEmailAdress varchar(100)
	DECLARE @ToEmailAdress TABLE (email varchar(100))
	
	--Get document Infomation
	SELECT	@DocumentId = d.iDocumentId, 
			@DocumentName = d.strName,
			@FolderId = d.iHandbookId,
			@Version = d.iVersion,
			@CreatedById = d.iCreatedbyId,
			@ApprovedId = d.iApprovedById
	FROM	m136_tblDocument d
	WHERE	d.iEntityId = @EntityId	AND 
			d.iDeleted = 0
			
	--Get Email from
	SELECT @FromEmailAdress = isNull(strEmail, '') 
	FROM tblEmployee 
	WHERE iEmployeeId = @SecurityId	
	
	INSERT INTO @ToEmailAdress 
			SELECT  isNull(strEmail, '') 
			FROM tblEmployee 
			WHERE iEmployeeId = @CreatedById	
			
	--Get Email To
	IF @RecipientsForMailFeedback = 1
		BEGIN
			INSERT INTO @ToEmailAdress 
				SELECT  isNull(strEmail, '') 
				FROM tblEmployee 
				WHERE iEmployeeId = @ApprovedId	
		END
	ELSE
		BEGIN
			-- Get email of user have permisson approved
			INSERT INTO @ToEmailAdress 
			SELECT DISTINCT e.strEmail
				FROM tblEmployee e 
				JOIN relEmployeeSecGroup s ON e.iEmployeeId = s.iEmployeeId
				JOIN tblACL a ON s.iSecGroupId = a.iSecurityId AND
				a.iEntityId = @FolderId AND a.iApplicationId = 136 AND
				a.iPermissionSetId = 462 AND (a.iBit & 0x10) = 0x10
				AND e.strEmail IS NOT NULL AND e.strEmail <> ''
		END
	
	--return data
	SELECT @DocumentId AS DocumentId, @DocumentName AS Name, @Version AS Version, @FromEmailAdress AS FromEmailAdress
	
	SELECT DISTINCT email AS Email 
	FROM @ToEmailAdress
	
END
GO

IF OBJECT_ID('[dbo].[m136_GetFileContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileContents] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId int
AS
BEGIN

	SELECT strFilename, strContentType, imgContent
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentConfirmationDate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentConfirmationDate] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentConfirmationDate]
	@SecurityId int,
	@EntityId int
AS
BEGIN
	
	SELECT top 1 dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEmployeeId=@SecurityId 
		AND iEntityId=@EntityId 
	
END
GO


---------- FILE: Upgrade_01.00.00.014.sql ----------
INSERT INTO #Description VALUES('edit stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
	VALUES (@iSecurityId, @HandbookId,0,1,0,0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookOffFavorites]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_RemoveHandbookOffFavorites];
GO
IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscribe]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iHandbookId] = @HandbookId
END
GO

IF OBJECT_ID('[dbo].[m136_AddDocumentToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddDocumentToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddDocumentToFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	INSERT INTO [dbo].[m136_tblSubscriberDocument] ([iEmployeeId], [iDocumentId], [iSort]) 
	VALUES (@iSecurityId, @DocumentId, 0)
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentOffFavorites]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_RemoveDocumentOffFavorites];
GO
IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscriberDocument]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iDocumentId] = @DocumentId
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
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
				iViewTypeId as ViewType
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
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
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	UNION
		SELECT v.iDocumentId as Id,
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
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
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
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO


---------- FILE: Upgrade_01.00.00.015.sql ----------
INSERT INTO #Description VALUES('edit stored procedure [dbo].[m136_GetFileContents] and [dbo].[m136_GetDocumentConfirmationDate]')
GO

IF OBJECT_ID('[dbo].[m136_GetFileContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileContents] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId INT
AS
BEGIN

	SELECT strFilename,
		   strContentType,
		   imgContent
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentConfirmationDate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentConfirmationDate] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentConfirmationDate]
	@SecurityId INT,
	@EntityId INT
AS
BEGIN
	
	SELECT TOP 1 dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEmployeeId=@SecurityId 
		AND iEntityId=@EntityId 
	
END
GO


---------- FILE: Upgrade_01.00.00.016.sql ----------
INSERT INTO #Description VALUES('edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1 a')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT,
@DocumentTypeId INT
AS
BEGIN

	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND (r.iRelationTypeId = 20 OR r.iRelationTypeId = 2)
	
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
				AND  d.iApproved = 1
		JOIN m136_tblDocumentType dtype 
			ON d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
END
GO


---------- FILE: Upgrade_01.00.00.017.sql ----------
INSERT INTO #Description VALUES('edit stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
	BEGIN
		INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
		VALUES (@iSecurityId, @HandbookId,0,1,0,0)
	END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
	BEGIN
		DELETE FROM [dbo].[m136_tblSubscribe]
		WHERE [iEmployeeId] = @iSecurityId
		AND [iHandbookId] = @HandbookId
	END
END
GO

IF OBJECT_ID('[dbo].[m136_AddDocumentToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddDocumentToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddDocumentToFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscriberDocument] WHERE [iDocumentId] = @DocumentId AND [iEmployeeId] = @iSecurityId)
	BEGIN
		INSERT INTO [dbo].[m136_tblSubscriberDocument] ([iEmployeeId], [iDocumentId], [iSort]) 
		VALUES (@iSecurityId, @DocumentId, 0)
	END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscriberDocument] WHERE [iDocumentId] = @DocumentId AND [iEmployeeId] = @iSecurityId)
	BEGIN
		DELETE FROM [dbo].[m136_tblSubscriberDocument]
		WHERE [iEmployeeId] = @iSecurityId
		AND [iDocumentId] = @DocumentId
	END
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
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
		FROM m136_tblHandbook
		WHERE iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
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
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
	UNION
		SELECT v.iDocumentId as Id,
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
			   dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
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
				NULL as Path
		FROM m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
				AND h.iDeleted = 0
	ORDER BY d.iSort ASC, 
			 d.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dt.Type as DocumentType
	FROM m136_tblDocument d
	INNER JOIN m136_tblDocumentType dt ON d.iDocumentTypeId = dt.iDocumentTypeId
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO


---------- FILE: Upgrade_01.00.00.018.sql ----------
INSERT INTO #Description VALUES('Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1 a')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	-- Add the parameters for the stored procedure here
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	
    DECLARE @min INT, @max INT;
    SELECT @min = iMin, 
		   @max = iMax 
		FROM m136_tblHandbook WHERE iHandbookId = @iHandbookId;

    DECLARE @tmp TABLE(handbookId INT NOT NULL PRIMARY KEY);
    INSERT INTO @tmp(handbookId)
        SELECT iHandbookId FROM m136_tblHandbook WHERE iDeleted = 0 AND ((iMin > @min AND iMax < @max) OR iHandbookId = @iHandbookId);

	
	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY)
    
	INSERT INTO @HandbookPermissions
		SELECT handbookId FROM @tmp 
		WHERE (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, handbookId) & 1) = 1;
		
    SELECT * FROM (
        SELECT distinct 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId, 
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            0 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
        WHERE
			d.iApproved = 1
			AND d.iDraft = 0
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId in (select iHandbookId from @HandbookPermissions)
			AND 
			(
				(@iHandbookId = 0 OR d.iHandbookId = @iHandbookId)
				OR 
				(
					@iHandbookId > 0
					AND
					d.iHandbookId IN (SELECT handbookId FROM @tmp)
				)
			)
    UNION       
        SELECT 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId,
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            1 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			JOIN m136_relVirtualRelation virt ON virt.iDocumentId = d.iDocumentId
			LEFT JOIN @tmp tmp ON tmp.handbookId = virt.iHandbookId
        WHERE
			@iHandbookId > 0
			AND d.iApproved = 1
			AND d.iDraft = 0
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) & 1) = 1
	) 
	r ORDER BY r.iSort, r.strName
END
GO


---------- FILE: Upgrade_01.00.00.019.sql ----------
INSERT INTO #Description VALUES('edit stored procedure 
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
format the stored
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscribe]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iHandbookId] = @HandbookId
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveDocumentFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveDocumentFromFavorites]
	@DocumentId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	DELETE FROM [dbo].[m136_tblSubscriberDocument]
	WHERE [iEmployeeId] = @iSecurityId
	AND [iDocumentId] = @DocumentId
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dt.Type as DocumentType
	FROM	m136_tblDocument d
		INNER JOIN m136_tblDocumentType dt 
			ON d.iDocumentTypeId = dt.iDocumentTypeId
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
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
		WHERE	iHandbookId = @iHandbookId AND @iHandbookId IS NOT NULL
	
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
				NULL as Path
		FROM	m136_tblDocument d
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
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
				dbo.fn136_GetParentPathEx(h.iHandbookId) as Path
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblDocumentType dt 
				ON d.iDocumentTypeId = dt.iDocumentTypeId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
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
				NULL as Path
		FROM	m136_tblHandbook as h
		WHERE	(h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
			AND h.iDeleted = 0
			
	ORDER BY d.iSort ASC, 
			 d.strName ASC
END
GO


---------- FILE: Upgrade_01.00.00.020.sql ----------
INSERT INTO #Description VALUES('Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
GO

IF OBJECT_ID('[dbo].[fnHandbookHasReadContentsAccess]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnHandbookHasReadContentsAccess]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 09, 2014
-- Description:	Check the permission read content of handbook
-- =============================================
ALTER FUNCTION [dbo].[fnHandbookHasReadContentsAccess]
(
	@iSecurityId INT,
	@iHandbookId INT
)
RETURNS BIT
AS
BEGIN
	IF (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, @iHandbookId) & 1 = 1) RETURN 1;
	RETURN 0;
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1 a')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	-- Add the parameters for the stored procedure here
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- INTerfering with SELECT statements.
	SET NOCOUNT ON;
	
    DECLARE @min INT, @max INT;
    SELECT @min = iMin, 
		   @max = iMax FROM m136_tblHandbook WHERE iHandbookId = @iHandbookId;

	WITH Children AS
	(
		SELECT iHandbookId FROM [dbo].[m136_tblHandbook] 
			WHERE iHandbookId = @iHandbookId AND iDeleted = 0
		UNION ALL
		SELECT h.iHandbookId FROM [dbo].[m136_tblHandbook] h
			INNER JOIN Children ON iParentHandbookId = Children.iHandbookId AND h.iDeleted = 0
	)
	SELECT iHandbookId INTO #Children FROM Children WHERE [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, @iHandbookId) = 1;

    SELECT * FROM (
        SELECT distinct 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId, 
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            0 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
        WHERE
			d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId IN (SELECT iHandbookId FROM #Children)
    UNION       
        SELECT 
            d.iDocumentId AS Id, 
            h.iHandbookId,
            d.strName, 
            d.iDocumentTypeId AS TemplateId,
            ISNULL(t.Type, 0) AS DocumentType,
            d.iVersion AS [Version],
            h.iLevelType AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
            NULL AS DepartmentId,
            1 AS Virtual,
            d.iSort,
			h.strName AS ParentFolderName,
        dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			JOIN m136_relVirtualRelation virt ON virt.iDocumentId = d.iDocumentId
        WHERE
			d.iDeleted = 0
			AND d.iLatestApproved = 1
			AND d.iHandbookId IN (SELECT iHandbookId FROM #Children)
	) 
	r ORDER BY r.iSort, r.strName;
	
	DROP TABLE #Children;
END
GO


---------- FILE: Upgrade_01.00.00.021.sql ----------
INSERT INTO #Description VALUES('edit stored procedure
[dbo].[m136_GetDocumentInformation]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
END
GO


---------- FILE: Upgrade_01.00.00.022.sql ----------
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
GO

---------- FILE: Upgrade_01.00.00.023.sql ----------
INSERT INTO #Description VALUES('Updated m136_GetApprovedDocumentsByHandbookIdRecursive')
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);

    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
    
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId AS TemplateId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1

	UNION       

		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId AS TemplateId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblHandbook h 
					ON virt.iHandbookId = h.iHandbookId
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	
		ORDER BY 
			iSort, 
			d.strName
END
GO


---------- FILE: Upgrade_01.00.00.024.sql ----------
--[m136_GetApprovedDocumentsByHandbookIdRecursive]
--[m136_GetChapterItems]
--[m136_GetLatestApprovedSubscriptions]
--[m136_GetDocumentsApprovedWithinXDays]
--[m136_GetDocumentFieldsAndRelates] script 16 - not sure why it join here
--[m136_GetDocumentsApprovedWithinXDaysCount] script 9
--[m136_GetRelatedDocuments] script 2 - not sure why it join here
--[m136_GetLatestApprovedSubscriptionsCount] script 1 - not sure why it join here
--[m136_GetMostViewedDocuments] script 1
--[m136_GetMyFavorites] script 1
--[m136_GetRecentDocuments] script 1

INSERT INTO #Description VALUES('Modify stored procedure to remove the join to the documenttype table.')
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
				d.iDocumentTypeId,
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
			LEFT JOIN m136_relInfo ri 
				ON ri.iEntityId = d.iEntityId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
			
	UNION
	
		SELECT	v.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
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
				-1 as iDocumentTypeId,
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
			
	SELECT TOP (@iApprovedDocumentCount) 
		0 AS Virtual, 
		d.iDocumentId AS Id, 
		d.iEntityId, 
		d.strName, 
        dbo.fnSecurityGetPermission(136, 462, 1, d.iHandbookId) AS iAccess, 
		d.iHandbookId, 
        d.dtmApproved, 
		h.strName AS ParentFolderName, 
		d.iVersion AS [Version], 
        d.iDocumentTypeId,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, 
		CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
			ELSE 0
		END AS BIT) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
		FROM  m136_tblDocument d
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
        d.iDocumentTypeId, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		CAST(CASE WHEN ri.iItemId IS NOT NULL THEN 1
			ELSE 0
		END AS BIT) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
	FROM m136_tblDocument d
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
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1 a')
GO
ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT,
@DocumentTypeId INT
AS
BEGIN

	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
				AND  d.iApproved = 1
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
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
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId 
    WHERE
		d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId in (SELECT iHandbookId FROM @HandbookPermissions)
        AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), GETDATE()) < @iApprovedWithinXDays 
        AND (d.dtmApproved > e.PreviousLogin)
END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetRelatedDocuments]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetRelatedDocuments]
GO
CREATE PROCEDURE [dbo].[m136_GetRelatedDocuments]
	@iEntityId int,
	@ExtendRelatedDoc bit = 1
AS
BEGIN
	SELECT  d.strName, d.iDocumentId
	FROM m136_relInfo r
	JOIN m136_tblDocument d 
		ON r.iItemId = d.iDocumentId 
		AND d.iVersion = (SELECT ISNULL(MAX(iVersion), 0)
			FROM m136_tblDocument
			WHERE iDocumentId = r.iItemId
				AND (@ExtendRelatedDoc = 0 OR (@ExtendRelatedDoc = 1 AND iApproved in (1,4)))
				AND iDeleted = 0)
		AND ((@ExtendRelatedDoc = 0 AND d.iApproved <> 4) OR (@ExtendRelatedDoc = 1 AND d.iApproved = 1))
	WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 136
	order by r.iSort
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
				d.iDocumentId, 
				doc.iHandbookId, 
				d.iAccessedCount, 
				doc.strName, 
				doc.iDocumentTypeId
	FROM		m136_tblDocAccessLog AS d 
		INNER JOIN m136_tblDocument doc 
			ON d.iDocumentId = doc.iDocumentId
	WHERE		d.iSecurityId = @iSecurityId 
		AND (doc.iLatestApproved = 1) 
		AND ((@iAccessedWithinXDays = 0) 
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
		SELECT	1 AS FavoriteType,
				h.iHandbookId,
				h.iDepartmentId, 
				h.strName, 
				h.iLevelType, 
				0 AS iDocumentId,
				-1 AS iDocumentTypeId, 
				--dbo.m136_fnChapterHasChildren(iHandbookId)  as HasChildren,
				0 AS iSort
		FROM	m136_tblHandbook h 
		WHERE	h.iDeleted = 0  
			AND (dbo.fnSecurityGetPermission(136, 461, @EmployeeId, iHandbookId)&0x20) = 0x20
		
	UNION  
		--My department chapters
		SELECT	2 AS FavoriteType,
				h.iHandbookId, 
				h.iDepartmentId, 
				h.strName, 
				h.iLevelType, 
				0 AS iDocumentId,  
				-1 AS iDocumentTypeId,
				0 AS iSort
		FROM	m136_tblHandbook h 
		WHERE	h.iDeleted = 0 
			AND iDepartmentId IN (SELECT iDepartmentId FROM tblEmployee WHERE iEmployeeId =@EmployeeId)
			AND ilevelType = 2
		
	UNION      
		--[m136_GetSubscriberChaptersForFrontpage]
		SELECT	3 AS FavoriteType,
				h.iHandbookId, 
				h.iDepartmentId, 
				h.strName, 
				h.iLevelType, 
				0 AS iDocumentId,
				-1 AS iDocumentTypeId,
				sh.iSort k 
		FROM	m136_tblSubscribe sh
			JOIN m136_tblHandbook h 
				ON (sh.iHandbookId = h.iHandbookId)
		WHERE	h.iDeleted = 0 
			AND sh.iEmployeeId = @EmployeeId 
			AND sh.iFrontpage = 1
		
	UNION 
		--[m136_GetSubscriberDocuments]
		SELECT	0 AS FavoriteType,
				d.iHandbookId, 
				0 AS iDepartmentId, 
				d.strName, 
				0 AS iLevelType, 
				d.iDocumentId, 
				d.iDocumentTypeId,
				sd.iSort
		FROM	m136_tblSubscriberDocument sd
			JOIN m136_tblDocument d 
				ON (sd.iDocumentId = d.iDocumentId AND d.iLatestApproved=1)
		WHERE sd.iEmployeeId = @EmployeeId
	
	ORDER BY FavoriteType, iSort 
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
				d.iDocumentId, 
				doc.iHandbookId, 
				doc.strName, 
				doc.iDocumentTypeId
	FROM		m136_tblDocAccessLog AS d 
		INNER JOIN m136_tblDocument doc 
			ON d.iDocumentId = doc.iDocumentId
	WHERE		d.iSecurityId = @iSecurityId 
		AND (doc.iLatestApproved = 1)
		 
	ORDER BY	d.dtmAccessed DESC
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);

    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
    
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1

	UNION       

		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path]
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblHandbook h 
					ON virt.iHandbookId = h.iHandbookId
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	
		ORDER BY 
			iSort, 
			d.strName
END
GO


---------- FILE: Upgrade_01.00.00.025.sql ----------
INSERT INTO #Description VALUES('Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

-- =============================================
-- Author:  si.manh.nguyen
-- Created date: DEC 11, 2014
-- Description: get fields and related of document
-- =============================================
ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT,
@DocumentTypeId INT,
@IsProcess BIT
AS
BEGIN
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
		  	  
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
				AND  d.iApproved = 1
		JOIN m136_tblDocumentType dtype 
			ON d.iDocumentTypeId=dtype.iDocumentTypeId
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort

	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort

	IF @IsProcess = 1
	BEGIN
		
		SELECT
			d.iDocumentId,
			d.strName,
			d.iHandbookId,
			h.strName AS strFolderName
		FROM
			m136_relInfo rel
			JOIN m136_tblDocument d 
				ON rel.iItemId = iDocumentId 
			JOIN m136_tblHandbook h 
				ON d.iHandbookId=h.iHandbookId
		WHERE
			rel.iEntityId=@iEntityId
			AND rel.iRelationTypeId = 136
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
		ORDER BY
			h.strName, d.strName
			
	END
END
GO


---------- FILE: Upgrade_01.00.00.026.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetLatestApprovedSubscriptions], [dbo].[m136_GetDocumentsApprovedWithinXDays] for getting HasAttachment.')
GO

IF OBJECT_ID('[dbo].[fnHasDocumentAttachment]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnHasDocumentAttachment]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 11, 2014
-- Description:	Check a document has attachment
-- =============================================
ALTER FUNCTION [dbo].[fnHasDocumentAttachment]
(
	@iEntityId	INT
)
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.m136_relInfo r WHERE r.iEntityId = @iEntityId AND (r.iRelationTypeId = 20 OR r.iRelationTypeId = 2)) RETURN 1;
	RETURN 0;
END
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
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_tblDocument d
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			AND d.iDeleted = 0
			
	UNION
	
		SELECT	v.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iDeleted = 0
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
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
			
	SELECT TOP (@iApprovedDocumentCount) 
		0 AS Virtual, 
		d.iDocumentId AS Id, 
		d.iEntityId, 
		d.strName, 
        dbo.fnSecurityGetPermission(136, 462, 1, d.iHandbookId) AS iAccess, 
		d.iHandbookId, 
        d.dtmApproved, 
		h.strName AS ParentFolderName, 
		d.iVersion AS [Version], 
        d.iDocumentTypeId,
		dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, 
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
		FROM  m136_tblDocument d
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
        d.iDocumentTypeId, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
		[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
	FROM m136_tblDocument d
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
   	WHERE d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookPermissions)
		AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iApprovedWithinXDays
		ORDER BY d.dtmApproved DESC
END
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);

    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
    
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1

	UNION       

		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblHandbook h 
					ON virt.iHandbookId = h.iHandbookId
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	
		ORDER BY 
			iSort, 
			d.strName
END
GO


---------- FILE: Upgrade_01.00.00.027.sql ----------
INSERT INTO #Description VALUES('Modify function [dbo].[fnHasDocumentAttachment]: only check iRelationTypeId = 20.')
GO

IF OBJECT_ID('[dbo].[fnHasDocumentAttachment]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnHasDocumentAttachment]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 11, 2014
-- Description:	Check a document has attachment
-- =============================================
ALTER FUNCTION [dbo].[fnHasDocumentAttachment]
(
	@iEntityId	INT
)
RETURNS BIT
AS
BEGIN
	IF EXISTS (SELECT 1 FROM dbo.m136_relInfo r WHERE r.iEntityId = @iEntityId AND r.iRelationTypeId = 20) RETURN 1;
	RETURN 0;
END
GO


---------- FILE: Upgrade_01.00.00.028.sql ----------
INSERT INTO #Description VALUES('Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

-- =============================================
-- Author:  si.manh.nguyen
-- Created date: DEC 15, 2014
-- Description: get fields and related of document
-- =============================================
ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT,
@DocumentTypeId INT
AS
BEGIN
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	
	-- Get related Document of document view.
	SELECT d.strName, 
		   d.iDocumentId,
		   r.iPlacementId,
		   d.iHandbookId,
		   h.strName AS strFolderName
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
				AND  d.iApproved = 1
				AND d.iDeleted = 0
		JOIN m136_tblDocumentType dtype 
			ON d.iDocumentTypeId = dtype.iDocumentTypeId
		JOIN m136_tblHandbook h 
			ON d.iHandbookId = h.iHandbookId
	WHERE	r.iEntityId = @iEntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort

	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
END
GO


---------- FILE: Upgrade_01.00.00.029.sql ----------
INSERT INTO #Description VALUES('create stored
[dbo].[m136_NormalSearch]')
GO

IF OBJECT_ID('[dbo].[m136_NormalSearch]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_NormalSearch] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_NormalSearch]
	@keyword NVARCHAR(MAX) = NULL,
	@searchInContent BIT,
	@iSecurityId INT,
	@iDocumentId INT
AS
SET NOCOUNT ON
BEGIN
	IF(@searchInContent = 0)
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment 
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
			WHERE			doc.iDeleted=0
				AND			iDraft=0
				AND			iApproved=1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND			iLatestApproved = 1
				AND			(Doc.strName LIKE '%' + @keyword + '%'
					OR		Doc.iDocumentId = @iDocumentId)
		END
	ELSE
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
				LEFT JOIN	m136_tblMetaInfoRichText RichTextInfo 
					ON RichTextInfo.iEntityId = doc.iEntityId
				LEFT JOIN	m136_tblMetaInfoText TextInfo 
					ON TextInfo.iEntityId = doc.iEntityId
			WHERE			doc.iDeleted=0
				AND			iDraft=0
				AND			iApproved=1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND			iLatestApproved = 1
				AND			(RichTextInfo.value LIKE '%' + @keyword + '%'
					OR		TextInfo.value LIKE '%' + @keyword + '%'
					OR		Doc.strName LIKE '%' + @keyword + '%'
					OR		Doc.iDocumentId = @iDocumentId)
		END
END
GO


---------- FILE: Upgrade_01.00.00.030.sql ----------
INSERT INTO #Description VALUES('Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

-- =============================================
-- Author:  si.manh.nguyen
-- Created date: DEC 15, 2014
-- Description: get fields and related of document
-- =============================================
ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
	
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		
		END
	ELSE
		BEGIN
		
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
			
		END

	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
END
GO


---------- FILE: Upgrade_01.00.00.031.sql ----------
INSERT INTO #Description VALUES('repalce stored
[dbo].[m136_NormalSearch]
with stored
[dbo].[m136_SearchDocuments ]
add fulltext index search for tblDocument and tblTextIndex
add stored procedure m136_SearchDocumentsById
add stored
[dbo].[m136_SearchDocumentsById]')
GO

IF NOT EXISTS(SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'[dbo].[m136x_tblTextIndex]'))
	BEGIN
		DECLARE @indexKey NVARCHAR(200);
		DECLARE @sqlString NVARCHAR(MAX);
		
		SET @indexKey = (SELECT CONSTRAINT_NAME 
						 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
						 WHERE TABLE_NAME = 'm136x_tblTextIndex' AND CONSTRAINT_TYPE = 'PRIMARY KEY')
		SET @sqlString = N'CREATE FULLTEXT INDEX ON [dbo].[m136x_tblTextIndex](totalvalue) KEY INDEX ' 
						 + @indexKey 
						 + N' ON Handbook WITH CHANGE_TRACKING AUTO;';
		
		EXEC(@sqlString)
	END
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'SearchTermTable' AND ss.name = N'dbo')
 CREATE TYPE [dbo].[SearchTermTable] AS TABLE(
  [Term] [varchar](900) NULL
 )
GO

IF OBJECT_ID('[dbo].[m136_NormalSearch]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_NormalSearch]
GO
IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@keyword VARCHAR(900),
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY
AS
SET NOCOUNT ON
BEGIN
	IF(@searchInContent = 0)
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment 
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
			WHERE			iLatestApproved = 1
				AND			doc.iEntityId in (SELECT	iEntityId
											  FROM		m136_tblDocument d 
												INNER JOIN @searchTermTable st
													ON	d.strName LIKE '%' + st.Term + '%'
											  WHERE		d.iLatestApproved = 1)
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
		END
	ELSE
		BEGIN
			SELECT DISTINCT	doc.iDocumentId AS Id,
							doc.iHandbookId,
							doc.strName,
							doc.iDocumentTypeId,
							doc.iVersion AS [Version],
							handbook.iLevelType AS LevelType,
							doc.dtmApproved,
							doc.strApprovedBy,
							dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
							NULL AS DepartmentId,
							0 AS Virtual,
							doc.iSort,
							dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
							handbook.strName AS ParentFolderName,
							[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment
			FROM			m136_tblDocument doc
				INNER JOIN	m136_tblHandbook handbook 
					ON handbook.iHandbookId = doc.iHandbookId
				LEFT JOIN	m136x_tblTextIndex textIndex 
					ON textIndex.iEntityId = doc.iEntityId
			WHERE			iLatestApproved = 1
				AND			(doc.iEntityId in (SELECT	iEntityId
											  FROM		m136_tblDocument d 
												INNER JOIN @searchTermTable st
													ON	d.strName LIKE '%' + st.Term + '%'
											  WHERE		d.iLatestApproved = 1)
					OR		CONTAINS(totalvalue,@keyword))
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				
		END
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100)
AS
SET NOCOUNT ON
BEGIN
	SELECT DISTINCT	doc.iDocumentId AS Id,
					doc.iHandbookId,
					doc.strName,
					doc.iDocumentTypeId,
					doc.iVersion AS [Version],
					handbook.iLevelType AS LevelType,
					doc.dtmApproved,
					doc.strApprovedBy,
					dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
					NULL AS DepartmentId,
					0 AS Virtual,
					doc.iSort,
					dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
					handbook.strName AS ParentFolderName,
					[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment 
	FROM			m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			iLatestApproved = 1
		AND			Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
END
GO


---------- FILE: Upgrade_01.00.00.032.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] for getting all documents of sub folders.')
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
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_tblDocument d
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	v.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
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

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);

    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		
		UNION ALL
		
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
    
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1

	UNION       

		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	
		ORDER BY 
			iSort, 
			d.strName
END
GO


---------- FILE: Upgrade_01.00.00.033.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems] for setting tree content level.')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1 a')
GO

ALTER PROCEDURE [dbo].[m136_GetChapterItems]
	@iHandbookId INT = NULL,
	@TreeContentLevel INT /* 0: all (folders and documents); 1: folders only */
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
		
		DECLARE @Documents TABLE
		(
			Id INT,
			strName VARCHAR(200),
			iDocumentTypeId INT,
			[Version] INT,
			LevelType INT,
			dtmApproved DATETIME,
			strApprovedBy VARCHAR(200),
			Responsible VARCHAR(200),
			DepartmentId INT,
			Virtual INT,
			iSort INT,
			ParentFolderName VARCHAR(200),
			[Path] VARCHAR(200),
			HasAttachment BIT
		);
		
		IF (@TreeContentLevel = 0) 
		BEGIN
			INSERT INTO @Documents
				SELECT	d.iDocumentId as Id,
						d.strName,
						d.iDocumentTypeId,
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
						[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
				FROM	m136_tblDocument d
				WHERE	d.iHandbookId = @iHandbookId
					AND d.iLatestApproved = 1
			UNION
				SELECT	v.iDocumentId as Id,
						d.strName,
						d.iDocumentTypeId,
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
						[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
				FROM	m136_relVirtualRelation v
					INNER JOIN m136_tblDocument d 
						ON d.iDocumentId = v.iDocumentId
					INNER JOIN m136_tblHandbook h
						ON d.iHandbookId = h.iHandbookId
				WHERE	v.iHandbookId = @iHandbookId
					AND d.iLatestApproved = 1;
		END
		
		SELECT * FROM @Documents
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
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
			
	ORDER BY iSort ASC, 
			 strName ASC
END
GO


---------- FILE: Upgrade_01.00.00.034.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure [dbo].[m136_GetChapterItems] revert back to script 32.')
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
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_tblDocument d
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	v.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
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
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
			
	UNION
	
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
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


---------- FILE: Upgrade_01.00.00.035.sql ----------
INSERT INTO #Description VALUES('Stored procedure [m136_GetDocumentLatestApproved] added')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentLatestApproved]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentLatestApproved] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentLatestApproved]
	@DocumentId INT,
	@Version INT
AS
SET NOCOUNT ON
BEGIN

	SELECT
		iLatestApproved
	FROM
		m136_tblDocument
	WHERE
			iDocumentId = @DocumentId
		AND iVersion = @Version

END

GO


---------- FILE: Upgrade_01.00.00.036.sql ----------
INSERT INTO #Description VALUES('add stored
[dbo].[m136_AddHandbookToEmailSubscription],
[dbo].[m136_RemoveHandbookFromEmailSubscription],
[dbo].[m136_GetUserEmailSubsciptions]
update stored
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites]')
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
		BEGIN
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
			VALUES (@iSecurityId, @HandbookId,1,0,0,0)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iEmail] = 1
			WHERE	[iHandbookId] = @HandbookId 
				AND [iEmployeeId] = @iSecurityId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromEmailSubscription]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromEmailSubscription] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromEmailSubscription]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND iFrontpage <> 0)
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iEmail] = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iHandbookId] = @HandbookId
		END
	ELSE
		BEGIN
			DELETE FROM	[dbo].[m136_tblSubscribe]
			WHERE		[iEmployeeId] = @iSecurityId
				AND		[iHandbookId] = @HandbookId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_AddHandbookToFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AddHandbookToFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_AddHandbookToFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iHandbookId] = @HandbookId AND [iEmployeeId] = @iSecurityId)
		BEGIN
			INSERT INTO [dbo].[m136_tblSubscribe] ([iEmployeeId], [iHandbookId], [iEmail], [iFrontpage], [iPDA], [iSort]) 
			VALUES (@iSecurityId, @HandbookId,0,1,0,0)
		END
	ELSE
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iFrontpage] = 1
			WHERE	[iHandbookId] = @HandbookId 
				AND [iEmployeeId] = @iSecurityId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_RemoveHandbookFromFavorites]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_RemoveHandbookFromFavorites]
	@HandbookId INT = NULL,
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	IF EXISTS(SELECT 1 FROM [dbo].[m136_tblSubscribe] WHERE [iEmployeeId] = @iSecurityId AND [iHandbookId] = @HandbookId AND iEmail <> 0)
		BEGIN
			UPDATE	[dbo].[m136_tblSubscribe]
			SET		[iFrontpage] = 0
			WHERE	[iEmployeeId] = @iSecurityId
				AND	[iHandbookId] = @HandbookId
		END
	ELSE
		BEGIN
			DELETE FROM	[dbo].[m136_tblSubscribe]
			WHERE		[iEmployeeId] = @iSecurityId
				AND		[iHandbookId] = @HandbookId
		END
END
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptions] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptions]
	@iSecurityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
		SELECT	sh.iHandbookId
		FROM	m136_tblSubscribe sh
		WHERE	sh.iEmployeeId = @iSecurityId 
			AND sh.iEmail = 1
END
GO


---------- FILE: Upgrade_01.00.00.037.sql ----------
INSERT INTO #Description VALUES('add stored procedure [dbo].[m136_AuthenticateDomainUser]')
GO

IF OBJECT_ID('[dbo].[m136_AuthenticateDomainUser]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_AuthenticateDomainUser] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_AuthenticateDomainUser]
	@LoginName varchar(100),
	@Domain varchar(100)
AS
BEGIN
	SELECT
		[iEmployeeId], 
		[strFirstName], 
		[strLastName]
	FROM
		[dbo].[tblEmployee]
	WHERE
			strLoginName = @LoginName
		AND ',' + strLoginDomain + ',' LIKE '%,' + @Domain + ',%' -- A trick to support the multiple domains in the field (domain1,domain2)
END

GO


---------- FILE: Upgrade_01.00.00.038.sql ----------
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
GO


---------- FILE: Upgrade_01.00.00.039.sql ----------
INSERT INTO #Description VALUES('Init upgrade script for GastroHandbook App')
GO

--Add new tables
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_Apps]') AND type in (N'U'))
DROP TABLE [dbo].[m136_Apps]
GO

CREATE TABLE [dbo].[m136_Apps](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AppName] [varchar](100) NOT NULL,
	[DefaultAppUserId] [int] NULL,
 CONSTRAINT [PK_m136_Apps] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_AppSessions]') AND type in (N'U'))
DROP TABLE [dbo].[m136_AppSessions]
GO

CREATE TABLE [dbo].[m136_AppSessions](
	[PhoneId] [varchar](200) NOT NULL,
	[SessionTime] [datetime] NOT NULL,
	[AppId] [int] NOT NULL,
	[UserId] [int] NOT NULL
) ON [PRIMARY]

GO

--Insert default record to table [dbo].[m136_Apps] 
INSERT INTO [dbo].[m136_Apps] VALUES('GastroHandbook', 3)
GO

--Procedure to check object exist
IF (OBJECT_ID('[dbo].[MakeSureObjectExists]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[MakeSureObjectExists] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[MakeSureObjectExists]	
    @ObjectName sysname
    , @ObjectType varchar(5) = 'P' -- P: procedure, V: view
		-- FN: scalar-valued function, IF: inline table-valued function, TF: multi-statement table-valued function
    , @Permission varchar(255) = null
    , @RoleOrUser varchar(255) = null
AS
BEGIN	
	SET NOCOUNT ON;
	DECLARE @ObjectTypeStr varchar(50), @ObjectBody NVarChar(200), @Sql NVarChar(max);
	IF (@ObjectType = 'P')
		SELECT @ObjectTypeStr = 'PROCEDURE', @ObjectBody = 'AS SET NOCOUNT ON;';
	ELSE IF (@ObjectType = 'FN')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS Int AS BEGIN RETURN 1 END;';
	ELSE IF (@ObjectType = 'IF')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS TABLE AS RETURN (SELECT 0 AS [id]);';
	ELSE IF (@ObjectType = 'TF')
		SELECT @ObjectTypeStr = 'FUNCTION', @ObjectBody = '() RETURNS @Result TABLE([id] Int) AS BEGIN RETURN END;';
	ELSE IF (@ObjectType = 'V')
		SELECT @ObjectTypeStr = 'VIEW', @ObjectBody = 'AS SELECT 1 AS [ABC]';
	SELECT @Sql = 'IF (OBJECT_ID(N''' + @ObjectName + ''', ''' + @ObjectType + ''') IS NULL) '
		+ 'EXEC(''' + 'CREATE ' + @ObjectTypeStr + ' ' + @ObjectName + ' ' + @ObjectBody + ''')';
	PRINT @Sql;
	EXEC (@Sql);
	IF (@Permission IS NOT NULL AND @RoleOrUser IS NOT NULL)
	BEGIN
		SELECT @Sql = 'GRANT ' + @Permission + ' ON ' + @ObjectName + ' TO ' + @RoleOrUser;
		EXEC (@Sql);
		PRINT @Sql;
	END;
END
GO

--Add new procedure for GastroHandbook business

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m147_GetRegisterItems]'
GO
ALTER PROCEDURE [dbo].[m147_GetRegisterItems]
(
	@SecurityId INT,
	@RegisterId INT
)
AS
	SELECT RegisterItemId = a.iRegisterItemId, 
		Name = a.strName
	FROM m147_tblRegisterItem a 
	WHERE a.iRegisterId = @RegisterId 
		AND (dbo.fnSecurityGetPermission(147, 571, @SecurityId, a.iRegisterId) & 1) = 1
	ORDER BY Name
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetListOfApprovedMetataggedDocuments]'
GO
ALTER PROCEDURE [dbo].[m136_GetListOfApprovedMetataggedDocuments] 
	-- Add the parameters for the stored procedure here
	@SecurityId int = 0,
	@RegsterItemId int = 0,
	@MetatagValue VARCHAR(200) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT *
	FROM ( 
		SELECT
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iDocumentId, 
			d.iEntityId,
			d.strName, 
			d.iHandbookId, 
			h.strName AS strChapterName,
			d.iVersion,
			d.iSort
		FROM 
			m136_tblDocument d
			JOIN m136_tblHandbook h ON d.iHandbookId=h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt 
				ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @RegsterItemId AND dt.iModuleId=136) 				
		WHERE d.iLatestApproved = 1
			AND d.dtmPublish <= GETDATE()
			AND dt.iAutoId IS NOT NULL
			AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, d.iHandbookId)&1)=1
		
	) AS [Data]
	WHERE @MetatagValue IS NULL OR MetatagValue = @MetatagValue
	ORDER BY iSort, strName
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetPagedListOfApprovedMetataggedDocuments]'
GO
ALTER PROCEDURE [dbo].[m136_GetPagedListOfApprovedMetataggedDocuments]
(
	@PageSize INT,
	@PageIndex INT,
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN

	DECLARE @ApprovedMetataggedDocuments TABLE
	(
		MetatagValue VARCHAR(200) NOT NULL,
		DocumentId INT NOT NULL,
		EntityId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		HandbookId INT NOT NULL,
		ChapterName VARCHAR(100) NOT NULL,
		[Version] INT NOT NULL,
		Sort INT NOT NULL
	)
	
	
	INSERT INTO @ApprovedMetataggedDocuments
		EXEC [dbo].[m136_GetListOfApprovedMetataggedDocuments] @SecurityId, @RegisterItemId
		
	SELECT MetatagValue,
		DocumentId,
		EntityId,
		Name,
		HandbookId,
		ChapterName,
		[Version],
		Sort
	FROM (		
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY DocumentId)
		FROM @ApprovedMetataggedDocuments
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	
	SELECT COUNT(DocumentId) FROM @ApprovedMetataggedDocuments
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[fnSplit_Gastro]', 'TF'
GO

ALTER FUNCTION [dbo].[fnSplit_Gastro] 
    (   
    @DelimitedString    VARCHAR(8000),
    @Delimiter              VARCHAR(100) 
    )
RETURNS @tblArray TABLE
    (
    ElementID   INT IDENTITY(1,1),
    Element     VARCHAR(1000)
    )
AS
BEGIN

    -- Local Variable Declarations
    -- ---------------------------
    DECLARE @Index      SMALLINT,
                    @Start      SMALLINT,
                    @DelSize    SMALLINT

    SET @DelSize = LEN(@Delimiter)

    -- Loop through source string and add elements to destination table array
    -- ----------------------------------------------------------------------
    WHILE LEN(@DelimitedString) > 0
    BEGIN

        SET @Index = CHARINDEX(@Delimiter, @DelimitedString)

        IF @Index = 0
            BEGIN

                INSERT INTO
                    @tblArray 
                    (Element)
                VALUES
                    (LTRIM(RTRIM(@DelimitedString)))

                BREAK
            END
        ELSE
            BEGIN

                INSERT INTO
                    @tblArray 
                    (Element)
                VALUES
                    (LTRIM(RTRIM(SUBSTRING(@DelimitedString, 1,@Index - 1))))

                SET @Start = @Index + @DelSize
                SET @DelimitedString = SUBSTRING(@DelimitedString, @Start , LEN(@DelimitedString) - @Start + 1)

            END
    END

    RETURN
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_ValidateDocumentExistence]'
GO
ALTER PROCEDURE [dbo].[m136_ValidateDocumentExistence]
(
	@SecurityId INT,
	@DocumentIds VARCHAR(8000)
)
AS
BEGIN
 
	DECLARE @TblDocumentId TABLE    
	(
		Id  INT
	)

	INSERT INTO @TblDocumentId
	SELECT ELEMENT FROM [dbo].[fnSplit_Gastro](@DocumentIds,',')

	SELECT DocumentId =	s.iDocumentId, 
		[Version] = s.iVersion, 
		ApprovedDate = s.dtmApproved, 
		IsDeleted = s.iDeleted
	FROM @TblDocumentId t 
	INNER JOIN 
	(
		SELECT iDocumentId, iLatestVersion, iLatestApproved, iVersion, dtmApproved, iDeleted 
		FROM dbo.m136_tblDocument 
		WHERE iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, iHandbookId)&1)=1
		AND iDeleted = 0
		AND dtmPublish <= GETDATE()
	) s 
	ON s.iDocumentId = t.Id
 
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_SearchMetataggedDocuments]'
GO

ALTER PROCEDURE [dbo].[m136_SearchMetataggedDocuments]
	@strSearchString varchar(1024) = '',
	@likeSearchWords varchar(900) = '',
	@searchInContent BIT,
	@iSecurityId INT,
	@iRegisterId INT,
	@iRegsterItemId int = 0
AS
BEGIN
	
	SET NOCOUNT ON
	declare @searchHits table(iEntityId int not null PRIMARY KEY, RANK int not null)
		
	declare @KEYWORD table(strKeyWord varchar(900) not null)
	insert into @KEYWORD
	select distinct Value from fn_Split(@likeSearchWords, ',')
	
	DECLARE @KEYWORDCOUNT as INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @Keyword

	insert into @searchHits
    select distinct doc.iEntityId
        ,1000 AS RANK
    FROM
        m136_tblDocument doc	
		INNER JOIN	m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId				
		INNER JOIN m147_relRegisterItemItem dt ON doc.iDocumentId = dt.iItemId and (dt.iModuleId=136) 
    where
		iLatestApproved = 1
		AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
		AND (
				(@iRegsterItemId > 0 AND dt.iRegisterItemId=@iRegsterItemId)
				OR 
				(@iRegsterItemId = 0 AND dt.iRegisterItemId in (select iRegisterItemId from m147_tblRegisterItem where iRegisterId = @iRegisterId))
			)
		AND
		(
		  (@KEYWORDCOUNT = 0 )
		  OR 
		  (doc.iEntityId in (SELECT iEntityId
					FROM 
						m136_tblDocument doc 
						INNER JOIN @Keyword k
					   ON doc.strName like '%' + k.strKeyWord + '%'					 
					 GROUP BY 
					  iEntityId
					 HAVING COUNT(iEntityId) = @KEYWORDCOUNT))
		)
		
	IF(@searchInContent = 1)
		BEGIN		
			insert into @searchHits
            select SearchHits.iEntityId
                ,RANK
            FROM
                m136_tblDocument doc 	
				INNER JOIN	m136_tblHandbook handbook ON handbook.iHandbookId = doc.iHandbookId		
				INNER JOIN m147_relRegisterItemItem dt ON doc.iDocumentId = dt.iItemId and (dt.iModuleId=136) 
                RIGHT JOIN 
                m136x_tblTextIndex SearchHits on doc.iEntityId=SearchHits.iEntityId 
                INNER JOIN CONTAINSTABLE (m136x_tblTextIndex, totalvalue, @strSearchString) AS KEY_TBL
                on SearchHits.iEntityId=KEY_TBL.[KEY]
            where
				iLatestApproved = 1
				AND			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
				AND (
						(@iRegsterItemId > 0 AND dt.iRegisterItemId=@iRegsterItemId)
						OR 
						(@iRegsterItemId = 0 AND dt.iRegisterItemId in (select iRegisterItemId from m147_tblRegisterItem where iRegisterId = @iRegisterId))
					)
				AND doc.iEntityId not in (select iEntityId from @searchHits)
          END
                
	SELECT DISTINCT	SearchHits.Rank,
					doc.iDocumentId AS Id,
					doc.iHandbookId,
					doc.strName,
					doc.iDocumentTypeId,
					doc.iVersion AS [Version],
					handbook.iLevelType AS LevelType,
					doc.dtmApproved,
					doc.strApprovedBy,
					dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
					NULL AS DepartmentId,
					0 AS Virtual,
					doc.iSort,
					dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
					handbook.strName AS ParentFolderName,
					[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment
	FROM			m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId		
		INNER JOIN	@searchHits SearchHits on SearchHits.iEntityId=doc.iEntityId
	
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetMetatagsByRegisterItemId]'
GO
ALTER PROCEDURE [dbo].[m136_GetMetatagsByRegisterItemId]
(
	@SecurityId INT,
	@RegisterItemId INT
)
AS
BEGIN
	
	SET NOCOUNT ON;
	
	SELECT MetatagValue
	FROM 
	(
		SELECT DISTINCT dbo.m147_fnGetItemValue(relItemItem.iAutoId) as MetatagValue
		FROM 
			m136_tblDocument doc
			LEFT OUTER JOIN m147_relRegisterItemItem relItemItem 
				ON doc.iDocumentId = relItemItem.iItemId AND (relItemItem.iRegisterItemId = @RegisterItemId AND relItemItem.iModuleId=136) 							
		WHERE doc.iLatestApproved = 1
			AND doc.dtmPublish <= GETDATE()
			AND relItemItem.iAutoId IS NOT NULL
			AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
	)AS [Data]
	ORDER BY MetatagValue
	
END
GO


EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetPagedDocumentsByRegisterItemIdAndMetatag]'
GO
ALTER PROCEDURE [dbo].[m136_GetPagedDocumentsByRegisterItemIdAndMetatag]
(
	@PageIndex INT,
	@PageSize INT,
	@SecurityId INT,
	@RegisterItemId INT,
	@MetatagValue VARCHAR(200) = NULL
)
AS
BEGIN
	
	DECLARE @ApprovedMetataggedDocuments TABLE
	(
		MetatagValue VARCHAR(200) NOT NULL,
		DocumentId INT NOT NULL,
		EntityId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		HandbookId INT NOT NULL,
		ChapterName VARCHAR(100) NOT NULL,
		[Version] INT NOT NULL,
		Sort INT NOT NULL
	)
	
	INSERT INTO @ApprovedMetataggedDocuments
		EXEC [dbo].[m136_GetListOfApprovedMetataggedDocuments] @SecurityId, @RegisterItemId, @MetatagValue
		
	SELECT MetatagValue,
		DocumentId,
		EntityId,
		Name,
		HandbookId,
		ChapterName,
		[Version],
		Sort
	FROM (		
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY Sort, Name)
		FROM @ApprovedMetataggedDocuments
	) AS [PagedList]
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	
	SELECT COUNT(EntityId) FROM @ApprovedMetataggedDocuments
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetLatestDocumentById]'
GO
ALTER PROCEDURE [dbo].[m136_GetLatestDocumentById]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	SELECT EntityId = iEntityId, 
		DocumentId = iDocumentId,
		[Version] = iVersion,
		DocumentTypeId = iDocumentTypeId,
		HandbookId = iHandbookId,
		Name = strName,
		[Description] = strDescription,
		CreatedbyId = iCreatedbyId,
		CreatedDate = dtmCreated,
		Author = strAuthor,
		ApprovedById = iApprovedById,
		ApprovedDate = dtmApproved,
		ApprovedBy = strApprovedBy
		
	FROM dbo.m136_tblDocument doc
	
	WHERE iDocumentId = @DocumentId
		AND iLatestApproved = 1
		AND (dbo.fnSecurityGetPermission(136, 462, @SecurityId, doc.iHandbookId)&1)=1
		AND iDeleted = 0
		AND doc.dtmPublish <= GETDATE()
END
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetDocumentData]'
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN

	DECLARE @EntityId INT,
		@DocumentTypeId INT

	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL
	)

	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	
	--Get Document Content
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   PlacementId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId = 20
	
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   PlacementId = r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	
	--Get Document Info
	SELECT * FROM @Document
	
END
GO





---------- FILE: Upgrade_01.00.00.040.sql ----------
INSERT INTO #Description VALUES('Rename procedure [dbo].[m136_SearchDocuments]')
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_SearchDocuments_Gastro]'
GO

ALTER PROCEDURE [dbo].[m136_SearchDocuments_Gastro]
	@PageIndex INT,
	@PageSize INT,
	@SearchString varchar(1024) = '',
	@LikeSearchWords varchar(900) = '',
	@SearchInContent BIT,
	@SecurityId INT,
	@RegisterId INT,
	@RegisterItemId INT = 0
AS
BEGIN

	DECLARE @Documents TABLE
	(
		[Rank] INT NOT NULL,
		DocumentId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		DocumentTypeId INT NOT NULL,
		[Version] INT NOT NULL,
		LevelType INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL,
		Responsible VARCHAR(102) NOT NULL,
		DepartmentId INT NULL,
		Virtual INT NOT NULL,
		Sort INT NOT NULL,
		[Path] NVARCHAR(4000),
		ParentFolderName VARCHAR(100) NOT NULL,
		HasAttachment BIT NOT NULL
	)

	INSERT INTO @Documents
	EXEC [dbo].[m136_SearchMetataggedDocuments] @SearchString, @LikeSearchWords, @SearchInContent, @SecurityId, @RegisterId, @RegisterItemId
		
	SELECT [Rank],
		DocumentId,
		HandbookId,
		Name,
		DocumentTypeId,
		[Version],
		LevelType,
		ApprovedDate,
		ApprovedBy,
		Responsible,
		DepartmentId,
		Virtual,
		Sort,
		[Path],
		ParentFolderName,
		HasAttachment
	FROM (
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY Sort, Name)
		FROM @Documents
	) AS [PagedList]
	
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	
	SELECT COUNT(*) FROM @Documents
	
END
GO


---------- FILE: Upgrade_01.00.00.041.sql ----------
INSERT INTO #Description VALUES('Changed stored procedures to not use the UTC')
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


IF OBJECT_ID('[dbo].[m136_LogDocumentRead]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LogDocumentRead] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_LogDocumentRead]
	@iSecurityId int,
	@iEntityId int
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iDocumentId int
	DECLARE @now smalldatetime

	SET @now = GetDate()
	SET @iDocumentId = 
	(
		SELECT 
			iDocumentId 
		FROM
			[dbo].[m136_tblDocument]
		WHERE
			iEntityId = @iEntityId
	)

	UPDATE
		[dbo].[m136_tblDocument]
	SET
		iReadCount = iReadcount + 1
	WHERE
		iEntityId = @iEntityId

	EXEC [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @now
END
GO


---------- FILE: Upgrade_01.00.00.042.sql ----------
INSERT INTO #Description VALUES('Add reversed columns for title and description to m136_tblDocument. Add trigger to autofill these new columns. Add to full-text')
GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[m136_tblDocument]') 
         AND name = 'strNameReversed'
)
 BEGIN
 /*Column does not exist*/
	ALTER TABLE [dbo].[m136_tblDocument]
	ADD [strNameReversed] VARCHAR (200)
 END
 GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[m136_tblDocument]') 
         AND name = 'strDescriptionReversed'
)
 BEGIN
 /*Column does not exist */
	ALTER TABLE [dbo].[m136_tblDocument]
	ADD [strDescriptionReversed] VARCHAR (2000)
 END
 GO

update m136_tblDocument 
set strNameReversed = REVERSE(strName) ,strDescriptionReversed = REVERSE(strDescription) 
where iLatestApproved = 1
GO


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentNameAndDescriptionReversal]') AND type in (N'TR'))
	EXEC ('CREATE TRIGGER [dbo].[DocumentNameAndDescriptionReversal]  ON  [dbo].[m136_tblDocument] AFTER UPDATE, INSERT AS SELECT 2')
GO

ALTER TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
   ON  [dbo].[m136_tblDocument]
   AFTER UPDATE, INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE (strName) 
    begin

        UPDATE [dbo].[m136_tblDocument] 
        SET strNameReversed = REVERSE(D.strName)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
    
    IF UPDATE (strDescription) 
    begin

        UPDATE [dbo].[m136_tblDocument] 
        SET strDescriptionReversed = REVERSE(D.strDescription)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
END
GO




---------- FILE: Upgrade_01.00.00.043.sql ----------

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
GO

---------- FILE: Upgrade_01.00.00.044.sql ----------
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


---------- FILE: Upgrade_01.00.00.045.sql ----------
INSERT INTO #Description VALUES('Edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   isnull(b.strExtension,'ukjent') as strExtension
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
	
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		
		END
	ELSE
		BEGIN
		
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
			
		END

	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
END
GO


---------- FILE: Upgrade_01.00.00.046.sql ----------
INSERT INTO #Description VALUES('update stored m136_SearchDocuments, m136_SearchDocumentsById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@keyword VARCHAR(900),
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @KEYWORDCOUNT AS INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @searchTermTable
	
	SELECT DISTINCT
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO #searchResult
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN	m136x_tblTextIndex textIndex 
			ON textIndex.iEntityId = doc.iEntityId
	WHERE
		iLatestApproved = 1
		AND	(doc.iEntityId in (SELECT	iEntityId
							   FROM		m136_tblDocument d 
								 INNER JOIN @searchTermTable st
									ON	d.strName LIKE '%' + st.Term + '%'
							   WHERE		d.iLatestApproved = 1
							   GROUP BY	iEntityId
							   HAVING COUNT(iEntityId) = @KEYWORDCOUNT)
			OR	(@searchInContent = 1 AND CONTAINS(totalvalue,@keyword)))
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS Total 
	FROM 
		#searchResult
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	SELECT DISTINCT	
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO 
		#searchResult 
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS Total 
	FROM 
		#searchResult
END
GO

---------- FILE: Upgrade_01.00.00.047.sql ----------
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
GO

---------- FILE: Upgrade_01.00.00.048.sql ----------
INSERT INTO #Description VALUES('Edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
	
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		
		END
	ELSE
		BEGIN
		
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
			
		END

	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
END
GO


---------- FILE: Upgrade_01.00.00.049.sql ----------
INSERT INTO #Description VALUES('Edit type of dtmAccessed column and edit store procedure [dbo].[m136_InsertOrUpdateDocAccessLog], [dbo].[m136_LogDocumentRead]')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_InsertOrUpdateDocAccessLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertOrUpdateDocAccessLog] AS SELECT 1')
GO

ALTER procedure [dbo].[m136_InsertOrUpdateDocAccessLog]
	@iSecurityId INT,
	@iDocumentId INT,
	@dtmAccessed DATETIME
AS
BEGIN
	
	SET NOCOUNT ON;
	IF EXISTS (SELECT * FROM [dbo].[m136_tblDocAccessLog]
				 WHERE iSecurityId = @iSecurityId 
						AND iDocumentId = @iDocumentId)
        UPDATE [dbo].[m136_tblDocAccessLog]
			SET iAccessedCount = iAccessedCount + 1,
				dtmAccessed = @dtmAccessed
        WHERE iSecurityId = @iSecurityId 
			  AND iDocumentId = @iDocumentId
    ELSE    
        INSERT INTO [dbo].[m136_tblDocAccessLog]
        (
			iSecurityId, iDocumentId, dtmAccessed, iAccessedCount
		)
        VALUES
        (
			@iSecurityId, @iDocumentId, @dtmAccessed, 1
		)
END
GO

IF OBJECT_ID('[dbo].[m136_LogDocumentRead]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_LogDocumentRead] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_LogDocumentRead]
	@iSecurityId INT,
	@iEntityId INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @iDocumentId INT
	DECLARE @now DATETIME
	SET @now = GETDATE()
	
	SET @iDocumentId = 
	(
		SELECT 
			iDocumentId 
		FROM
			[dbo].[m136_tblDocument]
		WHERE
			iEntityId = @iEntityId
	)
	
	UPDATE
		[dbo].[m136_tblDocument]
	SET
		iReadCount = iReadcount + 1
	WHERE
		iEntityId = @iEntityId
		
	EXEC [dbo].[m136_InsertOrUpdateDocAccessLog] @iSecurityId , @iDocumentId, @now
END
GO





---------- FILE: Upgrade_01.00.00.050.sql ----------
INSERT INTO #Description VALUES('Updated GetDocumentInformation')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentInformation]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentInformation] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId INT = NULL
AS
SET NOCOUNT ON
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
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM	m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iLatestApproved = 1
END
GO


---------- FILE: Upgrade_01.00.00.051.sql ----------
INSERT INTO #Description VALUES('Loading file document')
GO

IF OBJECT_ID('[dbo].[m136_GetFileDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileDocument]
	@SecurityId INT = NULL,
	@EntityId INT = NULL
AS
SET NOCOUNT ON
BEGIN
	SELECT	
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File]
	FROM	
			m136_tblDocument d
	WHERE	
				d.iEntityId = @EntityId
			AND d.iLatestApproved = 1 
			AND [dbo].[fnHandbookHasReadContentsAccess](@SecurityId, d.iHandbookId) = 1
END
GO


---------- FILE: Upgrade_01.00.00.052.sql ----------
INSERT INTO #Description VALUES('update stored m136_SearchDocuments, m136_SearchDocumentsById fix Total to TotalCount')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@keyword VARCHAR(900),
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	DECLARE @KEYWORDCOUNT AS INT
	SELECT @KEYWORDCOUNT = COUNT(*) FROM @searchTermTable
	
	SELECT DISTINCT
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO #searchResult
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN	m136x_tblTextIndex textIndex 
			ON textIndex.iEntityId = doc.iEntityId
	WHERE
		iLatestApproved = 1
		AND	(doc.iEntityId in (SELECT	iEntityId
							   FROM		m136_tblDocument d 
								 INNER JOIN @searchTermTable st
									ON	d.strName LIKE '%' + st.Term + '%'
							   WHERE		d.iLatestApproved = 1
							   GROUP BY	iEntityId
							   HAVING COUNT(iEntityId) = @KEYWORDCOUNT)
			OR	(@searchInContent = 1 AND CONTAINS(totalvalue,@keyword)))
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS TotalCount 
	FROM 
		#searchResult
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@pageSize INT = 0
AS
SET NOCOUNT ON
BEGIN
	SELECT DISTINCT	
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	INTO 
		#searchResult 
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
	
	
	SELECT TOP(@pageSize) *
	FROM
		#searchResult
		
	SELECT 
		COUNT(1) AS TotalCount
	FROM 
		#searchResult
END
GO

---------- FILE: Upgrade_01.00.00.053.sql ----------
INSERT INTO #Description VALUES('Updated m136_GetDocumentFieldsAndRelates')
GO

ALTER TABLE dbo.m136_tblDocAccessLog
ALTER COLUMN dtmAccessed DATETIME NOT NULL
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
	ELSE
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
END
GO


---------- FILE: Upgrade_01.00.00.054.sql ----------
INSERT INTO #Description VALUES('m136_GetFileOrImageContents')
GO

IF OBJECT_ID('[dbo].[m136_GetFileOrImageContents]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetFileOrImageContents] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetFileOrImageContents]
	@ItemId INT,
	@Thumbnail BIT
AS
BEGIN
	SELECT
		CASE i.iInformationTypeId
			WHEN 5 THEN 0
			ELSE 1
		END as isFile,
		CASE i.iInformationTypeId
			WHEN 5 THEN 
					CASE @Thumbnail
						WHEN 1 THEN im.strThumbURL
						ELSE im.strPictureURL
					END
			ELSE f.strFileName
		END AS strFileName,
		b.strContentType,
		b.imgContent
	FROM 
		tblItem i 
	LEFT OUTER JOIN tblFile f 
		ON f.iItemId = i.iItemId
	LEFT OUTER JOIN tblImage im 
		ON im.iItemId = i.iItemId 
	INNER JOIN tblBlob b 
		ON b.iItemId = i.iItemId 
		AND (
				(i.iInformationTypeId = 2 AND b.iType = 20)
				OR
				(@Thumbnail = 1 AND b.iType = 51)
				OR
				(@Thumbnail = 0 AND b.iType = 50)
			)
	WHERE 
		i.iItemId = @ItemId
END
GO


---------- FILE: Upgrade_01.00.00.055.sql ----------
INSERT INTO #Description VALUES('Search update')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@maxCount INT,
	@getTotal BIT,
	@iDocumentTypeId INT = NULL,
	@fromDate DATE = NULL,
	@toDate DATE = NULL
AS
SET NOCOUNT ON
BEGIN

	DECLARE @SearchString varchar(100)
	SELECT @SearchString = COALESCE(@SearchString + ' OR ', '') + '"' + Term + '*"' FROM @searchTermTable

	DECLARE @ReversedSearchString varchar(100)
	SELECT @ReversedSearchString = COALESCE(@ReversedSearchString + ' OR ', '') + '"' + REVERSE(Term) + '*"' FROM @searchTermTable

	DECLARE @TermsCount AS INT
	SELECT @TermsCount = COUNT(*) FROM @searchTermTable

	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000

	IF @getTotal = 0
	SET @TopMaxDocs = @maxCount

	DECLARE @TitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @InitialTitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY,
		strName varchar(200),
		iHandbookId int
	)

	DECLARE @ContentsSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @SearchTable TABLE
	(
		iEntityId INT
	)

	--
	-- Initial Search in title
	--
	INSERT INTO @InitialTitleSearchTable
		SELECT
			doc.iEntityId,
			doc.strName,
			doc.iHandbookId
		FROM
			m136_tblDocument doc
		WHERE
				iLatestApproved = 1
			AND
				(
					CONTAINS(doc.strName, @SearchString) 
					OR 
					CONTAINS(doc.strNameReversed, @ReversedSearchString)
				)
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
	--
	-- Verification that title search contains only documents with title that has EACH search term
	--
	INSERT INTO @TitleSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			@InitialTitleSearchTable doc
			INNER JOIN @searchTermTable terms
				ON @TermsCount = 1 OR doc.strName LIKE '%' + terms.Term + '%'
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
		GROUP BY	
			iEntityId
		HAVING 
			COUNT(iEntityId) = @TermsCount
     --
     -- Search in Contents
	 --
	INSERT INTO @ContentsSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			m136_tblDocument doc
			LEFT JOIN m136x_tblTextIndex textIndex 
				ON textIndex.iEntityId = doc.iEntityId
		WHERE
				@searchInContent = 1
			AND
				iLatestApproved = 1
			AND	
				CONTAINS(totalvalue, @SearchString)
			AND
				[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
			
	
	--
	-- Union both results
	--
	INSERT INTO @SearchTable
		SELECT * FROM @TitleSearchTable
		UNION 
		SELECT * FROM @ContentsSearchTable
		
	-- Select the total number of search results
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable

	-- Select the data
	SELECT TOP (@maxCount) 
		iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
		--,title.iEntityId --Test only
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook
				ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN @TitleSearchTable title
				ON @searchInContent = 1 AND doc.iEntityId = title.iEntityId
	WHERE
		doc.iEntityId in (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		title.iEntityId DESC, -- Will be null if it's not title
		LevelType ASC,
		doc.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT
AS
SET NOCOUNT ON
BEGIN
	SELECT TOP (@maxCount)
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, handbook.iHandbookId) = 1
END
GO


---------- FILE: Upgrade_01.00.00.056.sql ----------
INSERT INTO #Description VALUES('Updated Clustered Indexes')
GO

IF OBJECT_ID('[dbo].[fn136_GetSqlDropConstraintKey]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetSqlDropConstraintKey]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[fn136_GetSqlDropConstraintKey]
(
	@TableName varchar(100),
	@ConstraintKeyName varchar(100)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX) = NULL
	SELECT TOP 1 @sql = N'ALTER TABLE dbo.' + @TableName + ' DROP CONSTRAINT ['+CONSTRAINT_NAME+N']'
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE CONSTRAINT_NAME like @ConstraintKeyName + '%'
	  AND TABLE_NAME = @TableName
	return @sql
END
GO

IF OBJECT_ID('[dbo].[m136_DropForeignKeyTable]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_DropForeignKeyTable] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_DropForeignKeyTable]
@TableName NVARCHAR(MAX),
@ForeignKeyName NVARCHAR(MAX)
AS
BEGIN
	DECLARE @FullForeignKey NVARCHAR(MAX)
	
	DECLARE meta_cursor CURSOR FOR
	SELECT CONSTRAINT_NAME 
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE CONSTRAINT_NAME LIKE @ForeignKeyName + '%'
		  AND TABLE_NAME = @TableName
	
	DECLARE @sql NVARCHAR(MAX)
	
	OPEN meta_cursor;
	FETCH NEXT FROM meta_cursor 
	INTO @FullForeignKey;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @FullForeignKey IS NOT NULL
		BEGIN
			SET @sql = N'ALTER TABLE dbo.' + @TableName + ' DROP CONSTRAINT ['+@FullForeignKey+N']'
			EXEC(@sql)
		END
		FETCH NEXT FROM meta_cursor 
		INTO @FullForeignKey;
	END 
	CLOSE meta_cursor;
	DEALLOCATE meta_cursor;
END
GO

---------- FILE: Upgrade_01.00.00.057.sql ----------
INSERT INTO #Description VALUES('Create stored procedure m136_GetMetadataGroups for getting metadata group.')
GO

IF OBJECT_ID('[dbo].[m136_GetMetadataGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroups] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroups]
(
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		DISTINCT rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookid = @iHandbookId AND d.iDeleted = 0)
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group recursive.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive]
(	
	@iSecurityId INT,
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		UNION ALL
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
			
	SELECT
		DISTINCT rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN (SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN (SELECT iHandbookId FROM @AvailableChildren))
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 04, 2014
-- Description:	Get List Of Approved Documents By MetatagId
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iSecurityId int = 0,
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
    WITH Children AS
	(
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @iHandbookId 
			AND iDeleted = 0
		UNION ALL
		SELECT 
			h.iHandbookId 
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Children 
				ON	iParentHandbookId = Children.iHandbookId 
					AND h.iDeleted = 0
					AND @bRecursive = 1
	)
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			Children
		WHERE 
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
	
	SELECT * FROM (
		SELECT
			d.iDocumentId AS Id, 
			d.strName, 
			d.iDocumentTypeId,
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			ISNULL(dt.iAutoId, -1) AS MetatagId,
            d.iVersion,
            NULL AS LevelType,
            d.dtmApproved,
            d.strApprovedBy,
            dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,         
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment			
		FROM 
			m136_tblDocument d
            JOIN m136_tblDocumentType t on d.iDocumentTypeId = t.iDocumentTypeId
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableChildren)
	UNION
		SELECT 
			virt.iDocumentId AS Id, 
			d.strName, 
			d.iDocumentTypeId,
			dbo.m147_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			ISNULL(dt.iAutoId, -1) AS MetatagId,
			d.iVersion,
			NULL AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path, 
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableChildren)
	) r
	ORDER BY r.iSort, r.strName
END
GO



---------- FILE: Upgrade_01.00.00.058.sql ----------
INSERT INTO #Description VALUES('create stored [dbo].[m136_GetUserEmailSubsciptionsFolder],
[m136_UpdateFavoritesSortOrder]
table value type UpdatedFavoriteItemsTable, 
update stored [dbo][m136_GetMyFavorites] to get iSort values')
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		h.iParentHandbookId as iHandbookId,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId,
		-1 as iDocumentTypeId
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND sb.iEmail = 1
END
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
		bf.isDepartment AS isDepartment,
		bf.iSort
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
		d.iDocumentTypeId,
		sd.iSort
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

IF TYPE_ID(N'UpdatedFavoriteItemsTable') IS NULL
	EXEC ('CREATE TYPE [dbo].[UpdatedFavoriteItemsTable] AS TABLE([Id] INT NULL, [iSort] INT NULL )')
GO

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT = 0,
	@IsFolder BIT =0,
	@ChangedFavoriteItems AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN
	IF(@IsFolder = 1)
		BEGIN
			UPDATE 
				dbo.m136_tblSubscribe 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscribe s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iHandbookId = c.Id
		END
	ELSE
		BEGIN
			UPDATE 
				dbo.m136_tblSubscriberDocument 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscriberDocument s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iDocumentId = c.Id
		END
END
GO


---------- FILE: Upgrade_01.00.00.059.sql ----------
INSERT INTO #Description VALUES('Update GetParentPathEx')
GO

IF OBJECT_ID('[dbo].[fn136_GetParentPathEx]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetParentPathEx]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fn136_GetParentPathEx](@chapterId INT)
RETURNS NVARCHAR(4000)
AS
BEGIN
	DECLARE @Path varchar(4000);
	
	WITH Parents AS
	(
		SELECT 
			iParentHandbookId,
			strName
		FROM 
			[dbo].[m136_tblHandbook] 
		WHERE
			iHandbookId = @chapterId
	
		UNION ALL
	
		SELECT 
			h.iParentHandbookId,
			h.strName
		FROM 
			[dbo].[m136_tblHandbook] h
			INNER JOIN Parents
				ON	h.iHandbookId = Parents.iParentHandbookId 
	)
	SELECT
		@Path = strName + COALESCE('/' + @Path, '')
	FROM
		Parents

	RETURN @Path
END

GO


---------- FILE: Upgrade_01.00.00.060.sql ----------
INSERT INTO #Description VALUES('update stored [dbo].[m136_SearchDocumentsById]')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT,
	@getTotal BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
		SET @TopMaxDocs = @maxCount
	
	DECLARE @SearchTable TABLE
	(
		iDocumentId int PRIMARY KEY
	)
	
	INSERT INTO @SearchTable
	SELECT TOP(@TopMaxDocs)
		doc.iDocumentId
	FROM			
		m136_tblDocument doc
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, doc.iHandbookId) = 1
		
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
	
	SELECT
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE			
		doc.iDocumentId IN (SELECT iDocumentId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END
GO


---------- FILE: Upgrade_01.00.00.061.sql ----------
INSERT INTO #Description VALUES('Update procedure [dbo].[m136_GetDocumentData]')
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_GetDocumentData]'
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentData]
(
	@SecurityId INT,
	@DocumentId INT
)
AS
BEGIN
	DECLARE @EntityId INT,
		@DocumentTypeId INT
	DECLARE @Document TABLE
	(
		EntityId INT NOT NULL,
		DocumentId INT NULL,
		[Version] INT NOT NULL,
		DocumentTypeId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		[Description] VARCHAR(2000) NOT NULL,
		CreatedbyId INT NOT NULL,
		CreatedDate DATETIME NOT NULL,
		Author VARCHAR(200) NOT NULL,
		ApprovedById INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL
	)
	INSERT INTO @Document
	EXEC [dbo].[m136_GetLatestDocumentById] @SecurityId, @DocumentId
	SELECT @EntityId = EntityId,
		@DocumentTypeId = DocumentTypeId
	FROM @Document
	--Get Document Content
	SELECT	InfoTypeId = mi.iInfoTypeId, 
			FieldName = mi.strName, 
			FieldDescription = mi.strDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			FieldId = mi.iMetaInfoTemplateRecordsId, 
			FieldProcessType = mi.iFieldProcessType, 
			Maximized = rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @EntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @EntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @EntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @EntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
	
	--Get Document Attachment
	SELECT ItemId = r.iItemId,
		   Name = b.strName,
		   FieldId = r.iPlacementId
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @EntityId 
		  AND r.iRelationTypeId IN (20, 2, 50)
	
	--Get Document Related
	SELECT Name = d.strName, 
		   DocumentId = d.iDocumentId,
		   FieldId = r.iPlacementId
	FROM m136_relInfo r
		JOIN m136_tblDocument d 
			ON	r.iItemId = d.iDocumentId 
				AND d.iLatestApproved = 1
	WHERE	r.iEntityId = @EntityId 
			AND r.iRelationTypeId = 136
	ORDER BY r.iSort
	
	--Get Document Info
	SELECT * FROM @Document
END
GO


---------- FILE: Upgrade_01.00.00.062.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure m136_GetMetadataGroupsRecursive and m136_GetDocumentMetatags for extracting a function that get handbook recursive.')
GO

IF OBJECT_ID('[dbo].[m136_fnGetItemValue]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_fnGetItemValue] () RETURNS VARCHAR(200) AS BEGIN RETURN 1 END;')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 05, 2015
-- Description:	Get all handbookId of sub folders.
-- =============================================
ALTER  FUNCTION [dbo].[m136_fnGetItemValue]
(
	@iAutoId INT
)
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @retval VARCHAR(200)
	IF @iAutoId IS NULL
	BEGIN
		SET @retval = NULL;
	END
	ELSE
	BEGIN
		SET @retval = (
			SELECT
			CASE regitem.eTypeId
				WHEN 1 THEN ''
				WHEN 2 THEN CAST(a.ValueTall AS VARCHAR)
				WHEN 3 THEN regval.RegisterValue
				WHEN 4 THEN CONVERT(VARCHAR, a.ValueDate, 104)
				WHEN 5 THEN a.ValueText
				WHEN 6 THEN regval.RegisterValue
				ELSE ''
			END
			FROM m147_relRegisterItemItem a
				INNER JOIN m147_tblRegisterItem regitem ON a.iRegisterItemId = regitem.iRegisterItemId
				INNER JOIN m147_tblRegister c ON c.iRegisterId = regitem.iRegisterId
				LEFT OUTER JOIN m147_tblRegisterItemValue regval ON regval.iRegisterItemValueId = a.iRegisterItemValueId
			WHERE 
				iAutoId = @iAutoId
		)
	END
	RETURN @retval
END
GO

IF OBJECT_ID('[dbo].[m136_GetHandbookRecursive]', 'IF') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_GetHandbookRecursive] () RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 05, 2015
-- Description:	Get all handbookId of sub folders.
-- =============================================
ALTER FUNCTION [dbo].[m136_GetHandbookRecursive]
(	
	@iHandbookId INT,
	@iSecurityId INT,
	@bRecursive BIT,
	@bCheckSecurity BIT
)
RETURNS TABLE
AS
RETURN 
(
    WITH Children AS
	(
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] 
			WHERE
				iHandbookId = @iHandbookId 
				AND iDeleted = 0
				
		UNION ALL
		
			SELECT 
				h.iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] h
				INNER JOIN Children 
					ON	iParentHandbookId = Children.iHandbookId 
						AND h.iDeleted = 0
						AND @bRecursive = 1
	)
	SELECT 
		iHandbookId 
	FROM 
		Children
	WHERE 
		(@bCheckSecurity = 0 OR [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1)
)
GO


IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group recursive.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive]
(	
	@iSecurityId INT,
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
   
	SELECT 
		iHandbookId 
	INTO #AvailableHandbooks
	FROM 
		[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1, 1)
	WHERE 
		[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
		
	SELECT DISTINCT 
		rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN 
			(SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN 
				(SELECT iHandbookId FROM #AvailableHandbooks))
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 04, 2014
-- Description:	Get List Of Approved Documents By MetatagId
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT iHandbookId INTO #AvailableHandbooks FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, @bRecursive, 0);
	
	SELECT * FROM (
		SELECT
			d.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM #AvailableHandbooks)
	UNION
		SELECT 
			virt.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM #AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue
END
GO



---------- FILE: Upgrade_01.00.00.063.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure m136_GetMetadataGroupsRecursive and m136_GetDocumentMetatags for extracting a function that get handbook recursive.')
GO

IF OBJECT_ID('[dbo].[m136_GetHandbookRecursive]', 'IF') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[m136_GetHandbookRecursive] () RETURNS TABLE AS RETURN (SELECT 0 AS [id]);')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 05, 2015
-- Description:	Get all handbookId of sub folders.
-- =============================================
ALTER FUNCTION [dbo].[m136_GetHandbookRecursive]
(	
	@iHandbookId INT,
	@iSecurityId INT,
	@bCheckSecurity BIT
)
RETURNS TABLE
AS
RETURN 
(
    WITH Children AS
	(
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] 
			WHERE
				iHandbookId = @iHandbookId 
				AND iDeleted = 0
				
		UNION ALL
		
			SELECT 
				h.iHandbookId 
			FROM 
				[dbo].[m136_tblHandbook] h
				INNER JOIN Children 
					ON	iParentHandbookId = Children.iHandbookId 
						AND h.iDeleted = 0
	)
	SELECT 
		iHandbookId 
	FROM 
		Children
	WHERE 
		(@bCheckSecurity = 0 OR [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1)
)
GO


IF OBJECT_ID('[dbo].[m136_GetMetadataGroupsRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 03, 2015
-- Description:	Create stored procedure for getting metadata-group recursive.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetMetadataGroupsRecursive]
(	
	@iSecurityId INT,
	@iHandbookId INT
) AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	INSERT INTO @AvailableHandbooks	
		SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		
	SELECT DISTINCT 
		rel.iRegisterItemId,
		regitem.strName AS strTagName,
		reg.strName AS strRegisterName
	FROM m147_relRegisterItemItem rel
		LEFT OUTER JOIN m147_tblRegisterItem regitem ON rel.iRegisterItemId = regitem.iRegisterItemId
		LEFT OUTER JOIN m147_tblRegister reg ON regitem.iRegisterId = reg.iRegisterId
	WHERE
		rel.iModuleId = 136
		AND rel.iRegisterItemId > 0
		AND iItemId IN 
			(SELECT iDocumentId FROM m136_tbldocument d WHERE iHandbookId IN 
				(SELECT iHandbookId FROM @AvailableHandbooks))
	ORDER BY
		strRegisterName ASC,
		strTagName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 04, 2014
-- Description:	Get List Of Approved Documents By MetatagId
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	IF (@bRecursive = 1)
	BEGIN
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, 0);
	END
	ELSE
	BEGIN
		INSERT INTO @AvailableHandbooks SELECT @iHandbookId
	END
		
	SELECT * FROM (
		SELECT
			d.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			virt.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue
END
GO



---------- FILE: Upgrade_01.00.00.064.sql ----------
INSERT INTO #Description VALUES('update stored [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentFieldsAndRelates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates] AS SELECT 1')
GO

ALTER  PROCEDURE [dbo].[m136_GetDocumentFieldsAndRelates]
@iEntityId INT
AS
BEGIN
	DECLARE @DocumentTypeId INT, @IsProcess BIT
	SELECT	@DocumentTypeId = d.iDocumentTypeId,
			@IsProcess = t.bIsProcess
	FROM m136_tblDocument d
		JOIN m136_tblDocumentType t 
			ON d.iDocumentTypeId = t.iDocumentTypeId
	WHERE	d.iEntityId = @iEntityId
	-- Get related attachment of document view.
	SELECT r.iItemId,
		   b.strName,
		   r.iPlacementId,
		   r.iProcessrelationTypeId,
		   b.strExtension 
	FROM m136_relInfo r 
		 JOIN m136_tblBlob b 
			ON r.iItemId = b.iItemId
	WHERE r.iEntityId = @iEntityId 
		  AND r.iRelationTypeId = 20
		  
	-- Get related Document of document view.
	IF @IsProcess = 1
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   d.iHandbookId,
				   h.strName AS strFolderName,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
	ELSE
		BEGIN
			SELECT d.strName, 
				   d.iDocumentId,
				   r.iPlacementId,
				   r.iProcessRelationTypeId,
				   d.iDocumentTypeId
			FROM m136_relInfo r
				JOIN m136_tblDocument d 
					ON	r.iItemId = d.iDocumentId 
						AND d.iLatestApproved = 1
			WHERE	r.iEntityId = @iEntityId 
					AND r.iRelationTypeId = 136
			ORDER BY r.iSort
		END
		
	--Get Related Image	of document view.	
	SELECT	r.iItemId,
			r.iPlacementId,
			r.iScaleDirId,
			r.iSize,
			r.iVJustifyId, 
			r.iHJustifyId,
			r.iWidth, 
			r.iHeight,
			r.strCaption,
			r.strURL, 
			r.iNewWindow
	FROM  m136_relInfo r 
	WHERE iEntityId = @iEntityId 
		  AND (r.iRelationTypeId = 5 OR r.iRelationTypeId = 50)
		  AND r.iPlacementId > 0
	ORDER BY r.iRelationTypeId, 
			 r.iSort
		
	--Get fields content of document view.
	SELECT	mi.iInfoTypeId, 
			mi.strName strFieldName, 
			mi.strDescription strFieldDescription,
			InfoId = COALESCE (mit.iMetaInfoTextId, mid.iMetaInfoDateId, mii.iMetaInfoNumberId, mir.iMetaInfoRichTextId),
			NumberValue = mii.value, 
			DateValue = mid.value, 
			TextValue = mit.value, 
			RichTextValue = mir.value,                            
			mi.iMetaInfoTemplateRecordsId, 
			mi.iFieldProcessType, rdi.iMaximized
	FROM [dbo].m136_tblMetaInfoTemplateRecords mi
		 JOIN [dbo].m136_relDocumentTypeInfo rdi 
			ON rdi.iDocumentTypeId = @DocumentTypeId 
			   AND rdi.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoDate mid 
			ON mid.iEntityId = @iEntityId 
			   AND mid.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoNumber mii 
			ON mii.iEntityId = @iEntityId 
			   AND mii.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoText mit 
			ON mit.iEntityId = @iEntityId 
			   AND mit.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
		 LEFT JOIN [dbo].m136_tblMetaInfoRichText mir 
			ON mir.iEntityId = @iEntityId 
			   AND mir.iMetaInfoTemplateRecordsId = mi.iMetaInfoTemplateRecordsId
	WHERE rdi.iDeleted = 0
	ORDER BY rdi.iSort
END

GO


---------- FILE: Upgrade_01.00.00.065.sql ----------
INSERT INTO #Description VALUES('Modify stored procedure m136_GetApprovedDocumentsByHandbookIdRecursive for reusing function [dbo].[m136_GetHandbookRecursive].')
GO

IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
    
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
			
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			NULL AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	ORDER BY 
		iSort, 
		d.strName
END
GO



---------- FILE: Upgrade_01.00.00.066.sql ----------
INSERT INTO #Description VALUES('update m136_SearchDocument and m136_SearchDocumentById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@maxCount INT,
	@getTotal BIT,
	@iDocumentTypeId INT = NULL,
	@fromDate DATE = NULL,
	@toDate DATE = NULL
AS
SET NOCOUNT ON
BEGIN

	DECLARE @SearchString varchar(100)
	DECLARE @ReversedSearchString varchar(100)
	
	DECLARE @TermsCount AS INT
	SELECT @TermsCount = COUNT(*) FROM @searchTermTable
	
	SELECT @SearchString = COALESCE(@SearchString + ' OR ', '') + '"' + Term + '*"' FROM @searchTermTable
	SELECT @ReversedSearchString = COALESCE(@ReversedSearchString + ' OR ', '') + '"' + REVERSE(Term) + '*"' FROM @searchTermTable
	
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000

	IF @getTotal = 0
	SET @TopMaxDocs = @maxCount

	DECLARE @TitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @InitialTitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY,
		strName varchar(200),
		iHandbookId int
	)

	DECLARE @ContentsSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @SearchTable TABLE
	(
		iEntityId INT
	)

	--
	-- Initial Search in title
	--
	INSERT INTO @InitialTitleSearchTable
		SELECT
			doc.iEntityId,
			doc.strName,
			doc.iHandbookId
		FROM
			m136_tblDocument doc
		WHERE
				iLatestApproved = 1
			AND
				(
					@SearchString = '"*"'
					OR 
					CONTAINS(doc.strName, @SearchString) 
					OR 
					CONTAINS(doc.strNameReversed, @ReversedSearchString)
				)
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
	--
	-- Verification that title search contains only documents with title that has EACH search term
	--
	INSERT INTO @TitleSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			@InitialTitleSearchTable doc
			INNER JOIN @searchTermTable terms
				ON @TermsCount = 1 OR doc.strName LIKE '%' + terms.Term + '%'
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
		GROUP BY	
			iEntityId
		HAVING 
			COUNT(iEntityId) = @TermsCount
     --
     -- Search in Contents
	 --
	INSERT INTO @ContentsSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			m136_tblDocument doc
			LEFT JOIN m136x_tblTextIndex textIndex 
				ON textIndex.iEntityId = doc.iEntityId
		WHERE
				@searchInContent = 1
			AND
				iLatestApproved = 1
			AND 
				@SearchString <> '"*"'
			AND	
				CONTAINS(totalvalue, @SearchString)
			AND
				[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
			AND
				(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
			AND
				(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
			AND
				(@toDate IS NULL OR doc.dtmApproved <= @toDate)
			
	
	--
	-- Union both results
	--
	INSERT INTO @SearchTable
		SELECT * FROM @TitleSearchTable
		UNION 
		SELECT * FROM @ContentsSearchTable
		
	-- Select the total number of search results
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable

	-- Select the data
	SELECT TOP (@maxCount) 
		iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
		--,title.iEntityId --Test only
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook
				ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN @TitleSearchTable title
				ON @searchInContent = 1 AND doc.iEntityId = title.iEntityId
	WHERE
		doc.iEntityId in (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		title.iEntityId DESC, -- Will be null if it's not title
		LevelType ASC,
		doc.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT,
	@getTotal BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
		SET @TopMaxDocs = @maxCount
		
	DECLARE @SearchTable TABLE
	(
		iEntityId INT PRIMARY KEY
	)
	
	INSERT INTO @SearchTable
	SELECT TOP(@TopMaxDocs)
		doc.iEntityId
	FROM			
		m136_tblDocument doc
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, doc.iHandbookId) = 1
		
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
		
	SELECT TOP(@maxCount)
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE
		doc.iDocumentId IN (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END
GO


---------- FILE: Upgrade_01.00.00.067.sql ----------
INSERT INTO #Description VALUES('Modified stored procedure m136_GetDocumentMetatags for reorder metatag value, unclassified group shoud be bottom.')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO

-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: Feb 04, 2014
-- Description:	Get List Of Approved Documents By MetatagId
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	-- Add the parameters for the stored procedure here
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @AvailableHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
	IF (@bRecursive = 1)
	BEGIN
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId FROM [dbo].[m136_GetHandbookRecursive] (@iHandbookId, NULL, 0);
	END
	ELSE
	BEGIN
		INSERT INTO @AvailableHandbooks SELECT @iHandbookId
	END
	
	SELECT DocumentId, MetatagValue FROM (
		SELECT
			d.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iSort
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			virt.iDocumentId AS DocumentId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue,
			d.iSort
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			LEFT OUTER JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue DESC, r.iSort
END
GO


---------- FILE: Upgrade_01.00.00.068.sql ----------
INSERT INTO #Description VALUES('Update stored m136_UpdateFavoriteSortOrder to m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolder')
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolder]', 'p') IS NOT NULL
    DROP PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolder]
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND sb.iEmail = 1
END
GO

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT,
	@IsFoldersOperation BIT,
	@ChangedFavoriteItems AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN
	IF(@IsFoldersOperation = 1)
		BEGIN
			UPDATE 
				dbo.m136_tblSubscribe 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscribe s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iHandbookId = c.Id
		END
	ELSE
		BEGIN
			UPDATE 
				dbo.m136_tblSubscriberDocument 
			SET 
				iSort = c.iSort
			FROM 
				dbo.m136_tblSubscriberDocument s 
				INNER JOIN @ChangedFavoriteItems c
					ON s.iEmployeeId = @iSecurityId AND s.iDocumentId = c.Id
		END
END
GO


---------- FILE: Upgrade_01.00.00.069.sql ----------
INSERT INTO #Description VALUES('update m136_SearchDocument')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@maxCount INT,
	@getTotal BIT,
	@iDocumentTypeId INT = NULL,
	@fromDate DATE = NULL,
	@toDate DATE = NULL
AS
SET NOCOUNT ON
BEGIN

	DECLARE @SearchString varchar(100)
	SELECT @SearchString = COALESCE(@SearchString + ' OR ', '') + '"' + Term + '*"' FROM @searchTermTable
	
	DECLARE @ReversedSearchString varchar(100)
	SELECT @ReversedSearchString = COALESCE(@ReversedSearchString + ' OR ', '') + '"' + REVERSE(Term) + '*"' FROM @searchTermTable
	
	DECLARE @TermsCount AS INT
	SELECT @TermsCount = COUNT(*) FROM @searchTermTable
	
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000

	IF @getTotal = 0
	SET @TopMaxDocs = @maxCount

	DECLARE @TitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @InitialTitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY,
		strName varchar(200),
		iHandbookId int
	)

	DECLARE @ContentsSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)

	DECLARE @SearchTable TABLE
	(
		iEntityId INT
	)

	--
	-- Initial Search in title
	--
	IF(LEN(@SearchString) = 3)
		-- search input is null
		BEGIN
			INSERT INTO @InitialTitleSearchTable
				SELECT
					doc.iEntityId,
					doc.strName,
					doc.iHandbookId
				FROM
					m136_tblDocument doc
				WHERE
						iLatestApproved = 1
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
		END
	ELSE
		BEGIN
			INSERT INTO @InitialTitleSearchTable
				SELECT
					doc.iEntityId,
					doc.strName,
					doc.iHandbookId
				FROM
					m136_tblDocument doc
				WHERE
						iLatestApproved = 1
					AND
						(
							CONTAINS(doc.strName, @SearchString) 
							OR 
							CONTAINS(doc.strNameReversed, @ReversedSearchString)
						)
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
						
			 --
			 -- Search in Contents
			 --
			INSERT INTO @ContentsSearchTable
				SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
					doc.iEntityId
				FROM
					m136_tblDocument doc
					LEFT JOIN m136x_tblTextIndex textIndex 
						ON textIndex.iEntityId = doc.iEntityId
				WHERE
						@searchInContent = 1
					AND
						iLatestApproved = 1
					AND	
						CONTAINS(totalvalue, @SearchString)
					AND
						[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
						
		END
	
	--
	-- Verification that title search contains only documents with title that has EACH search term
	--
	INSERT INTO @TitleSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			@InitialTitleSearchTable doc
			INNER JOIN @searchTermTable terms
				ON @TermsCount = 1 OR doc.strName LIKE '%' + terms.Term + '%'
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
		GROUP BY	
			iEntityId
		HAVING 
			COUNT(iEntityId) = @TermsCount
			
	--
	-- Union both results
	--
	INSERT INTO @SearchTable
		SELECT * FROM @TitleSearchTable
		UNION 
		SELECT * FROM @ContentsSearchTable
		
	-- Select the total number of search results
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable

	-- Select the data
	SELECT TOP (@maxCount) 
		iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
		--,title.iEntityId --Test only
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook
				ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN @TitleSearchTable title
				ON @searchInContent = 1 AND doc.iEntityId = title.iEntityId
	WHERE
		doc.iEntityId in (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		title.iEntityId DESC, -- Will be null if it's not title
		LevelType ASC,
		doc.strName ASC
END
GO


---------- FILE: Upgrade_01.00.00.070.sql ----------
INSERT INTO #Description VALUES('Update stored m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolders')
GO

IF OBJECT_ID('[dbo].[m136_UpdateFavoritesSortOrder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateFavoritesSortOrder]
	@iSecurityId INT,
	@NewSortOrderFolders AS [dbo].[UpdatedFavoriteItemsTable] READONLY,
	@NewSortOrderDocuments AS [dbo].[UpdatedFavoriteItemsTable] READONLY
AS
SET NOCOUNT ON
BEGIN

	UPDATE 
		dbo.m136_tblSubscribe 
	SET 
		iSort = f.iSort
	FROM 
		dbo.m136_tblSubscribe s 
		INNER JOIN @NewSortOrderFolders f
			ON s.iEmployeeId = @iSecurityId AND s.iHandbookId = f.Id
					
	UPDATE 
		dbo.m136_tblSubscriberDocument 
	SET 
		iSort = d.iSort
	FROM 
		dbo.m136_tblSubscriberDocument s 
		INNER JOIN @NewSortOrderDocuments d
			ON s.iEmployeeId = @iSecurityId AND s.iDocumentId = d.Id
END
GO

IF OBJECT_ID('[dbo].[m136_GetUserEmailSubsciptionsFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetUserEmailSubsciptionsFolders]
	@iSecurityId INT
AS
SET NOCOUNT ON
BEGIN
	SELECT
		h.iHandbookId as Id,	
		h.strName,
		iLevelType as LevelType,
		iDepartmentId as DepartmentId
	FROM	
		m136_tblHandbook h
		INNER JOIN m136_tblSubscribe sb
			ON h.iHandbookId = sb.iHandbookId
	WHERE
		h.iDeleted = 0
		AND sb.iEmployeeId = @iSecurityId
		AND sb.iEmail = 1
	ORDER BY
		h.strName
END
GO


---------- FILE: Upgrade_01.00.00.071.sql ----------
INSERT INTO #Description VALUES('Implement exportjob as background.')
GO

IF (NOT EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'm136_ExportJob'))
BEGIN
    CREATE TABLE [dbo].[m136_ExportJob](
	[Id] [uniqueidentifier] NOT NULL,
	[ChapterId] int NULL,
	[UserIdentityId] int NOT NULL,
	[CreatedDate] [datetime] NULL,
	[FilePath] [varchar](1000) NULL,
	[PrintTypeJob] [int] NULL,
	[PrintSubFolder] [bit] NULL,
	[ProcessStatus] [int] NULL,
	[Description] [nvarchar](max) NULL,
	[Method] [varchar](200) NULL,
	[TemplateName] [varchar](1000) NULL,
	CONSTRAINT [PK_PrintJob] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF OBJECT_ID('[dbo].[m136_GetExportJobs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetExportJobs] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetExportJobs] 
	@ProcessStatus INT
AS
BEGIN
	SELECT E.strFirstName + ' ' + E.strLastName AS Fullname, PJ.FilePath AS URL, E.strEmail AS Email, PJ.Method, PJ.TemplateName, PJ.ChapterId, 
		PJ.PrintSubFolder, PJ.Id, PJ.CreatedDate, PJ.UserIdentityId, HB.strName AS ChapterName
	FROM [dbo].[m136_ExportJob] PJ
		INNER JOIN dbo.tblEmployee E ON E.iEmployeeId = PJ.UserIdentityId
		INNER JOIN dbo.m136_tblHandbook HB ON HB.iHandbookId = PJ.ChapterId
		WHERE PJ.ProcessStatus = @ProcessStatus
END
GO

IF OBJECT_ID('[dbo].[m136_UpdateExportJob]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateExportJob] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateExportJob]
	@Id	UNIQUEIDENTIFIER,
	@ProcessStatus INT,
	@FilePath VARCHAR(500)
AS
BEGIN
	UPDATE [dbo].[m136_ExportJob] SET ProcessStatus = @ProcessStatus, FilePath = @FilePath WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m136_InsertExportJob]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_InsertExportJob] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_InsertExportJob]
	@ChapterId INT,
	@UserIdentityId INT,
	@PrintTypeJob INT,
	@PrintSubFolder BIT,
	@Method varchar(200),
	@TemplateName varchar(1000)
AS
BEGIN
	INSERT INTO [dbo].[m136_ExportJob]
	(Id, ChapterId, UserIdentityId, CreatedDate, FilePath, PrintTypeJob, PrintSubFolder, ProcessStatus, [Description], Method, TemplateName)
	VALUES (NEWID(), @ChapterId, @UserIdentityId, GETDATE(), NULL, @PrintTypeJob, @PrintSubFolder, 0, NULL, @Method, @TemplateName)
END
GO


---------- FILE: Upgrade_01.00.00.072.sql ----------
INSERT INTO #Description VALUES('Create procedure [dbo].[m136_DeleteExportJobs]')
GO

IF OBJECT_ID('[dbo].[m136_DeleteExportJobs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_DeleteExportJobs] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_DeleteExportJobs]
	@Minutes INT
AS
BEGIN

	DECLARE @Table TABLE (Col VARCHAR(1000));
	DECLARE @SomeHoursAgo DATETIME = DATEADD(MINUTE, -@Minutes, GETDATE());
	
	INSERT INTO @Table (Col) SELECT FilePath 
		FROM dbo.m136_ExportJob WHERE ProcessStatus = 2 AND @SomeHoursAgo >= CreatedDate;
		
	DELETE dbo.m136_ExportJob WHERE ProcessStatus = 2 AND @SomeHoursAgo >= CreatedDate;
	
	SELECT Col AS [FileName] FROM @Table;
END
GO



---------- FILE: Upgrade_01.00.00.073.sql ----------
INSERT INTO #Description VALUES('Create procedure [dbo].[m136_ProcessLatestApprovedDocuments] and [dbo].[m136_SetVersionFlags] for updating LatestApproved when dtmPublishDate in the future.')
GO

IF OBJECT_ID('[dbo].[m136_SetVersionFlags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SetVersionFlags] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SetVersionFlags] 
	-- Add the parameters for the stored procedure here
	@iDocumentId INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @MaxVersion INT
	SET @MaxVersion = 0
	
	--Reset version flags
	UPDATE  m136_tblDocument set iLatestVersion = 0, iLatestApproved  = 0 
		WHERE iDocumentId = @iDocumentId 
	
	--Get entity that should be flagged as latest approved version
	SELECT @MaxVersion = MAX(iVersion)
		FROM m136_tblDocument d 
		WHERE iDeleted = 0 AND iApproved IN (1 ,4) AND iDocumentId = @iDocumentId AND dtmPublish <= GETDATE() 
	
	--set iLatestApproved flag
	UPDATE m136_tblDocument 
	SET
		iLatestApproved = 1 
	WHERE
		iDocumentId = @iDocumentId AND iApproved = 1 AND iVersion = @MaxVersion AND iDeleted = 0 AND dtmPublish <= GETDATE()          
	
	--Get entity that should be flagged as latest version
	SELECT @MaxVersion = MAX(iVersion)
		FROM m136_tblDocument d 
		WHERE iDeleted = 0 AND iDocumentId = @iDocumentId

	--set iLatestVersion flag
	UPDATE  m136_tblDocument 
	SET  
		iLatestVersion = 1 
	WHERE 
		iDocumentId = @iDocumentId AND iVersion = @MaxVersion AND iDeleted = 0	 
END
GO

IF OBJECT_ID('[dbo].[m136_ProcessLatestApprovedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: March 04, 2015
-- Description:	Process approved documents that has publish date in the future.
-- =============================================
ALTER PROCEDURE [dbo].[m136_ProcessLatestApprovedDocuments]
	
AS
BEGIN
	DECLARE @iDocumentId INT;
	
	DECLARE Documents CURSOR FOR 
		SELECT d.iDocumentId FROM dbo.m136_tblDocument d 
			WHERE d.iDeleted = 0 AND d.dtmPublish >= GETDATE() AND d.iApproved = 1;

	OPEN Documents; 
	FETCH NEXT FROM Documents INTO @iDocumentId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		EXEC [dbo].[m136_SetVersionFlags] @iDocumentId;
		FETCH NEXT FROM Documents INTO @iDocumentId;
	END
	CLOSE Documents;
	DEALLOCATE Documents;
END
GO


---------- FILE: Upgrade_01.00.00.074.sql ----------
INSERT INTO #Description VALUES('Update stored m136_SearchDocumentsById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT,
	@getTotal BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
		SET @TopMaxDocs = @maxCount
		
	DECLARE @SearchTable TABLE
	(
		iEntityId INT PRIMARY KEY
	)
	
	INSERT INTO @SearchTable
	SELECT TOP(@TopMaxDocs)
		doc.iEntityId
	FROM			
		m136_tblDocument doc
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE '%' + @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, doc.iHandbookId) = 1
		
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
		
	SELECT TOP(@maxCount)
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE
		doc.iEntityId IN (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END
GO

---------- FILE: Upgrade_01.00.00.075.sql ----------
INSERT INTO #Description VALUES('Update seed to insert new data for feedback and readConfirm table')
GO

DECLARE @maxRecordsInTblFeedback INT
SELECT @maxRecordsInTblFeedback = COUNT(*) FROM m136_tblFeedback
SET  @maxRecordsInTblFeedback = @maxRecordsInTblFeedback + 1;
DBCC CHECKIDENT('[dbo].[m136_tblFeedback]', RESEED, @maxRecordsInTblFeedback);

DECLARE @maxRecordsInTblConfirmRead INT
SELECT @maxRecordsInTblConfirmRead = COUNT(*) FROM m136_tblConfirmRead
SET  @maxRecordsInTblConfirmRead = @maxRecordsInTblConfirmRead + 1;
DBCC CHECKIDENT('[dbo].[m136_tblConfirmRead]', RESEED, @maxRecordsInTblConfirmRead);


---------- FILE: Upgrade_01.00.00.076.sql ----------
INSERT INTO #Description VALUES('Create stored procedure [dbo].[m136_GetMenuGroups] for getting menu group in start page.')
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMenuGroups]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT 
		[iItemId]
		,[iItemParentId]
		,[iLevel]
		,[strName]
		,[strDescription]
		,[strURL]
	FROM [dbo].[tblMenu] m
	WHERE m.[ilevel] >= 3 ORDER BY strName
END
GO

---------- FILE: Upgrade_01.00.00.077.sql ----------
INSERT INTO #Description VALUES('update m136_SearchDocument, m136_SearchDocumentById')
GO

IF OBJECT_ID('[dbo].[m136_SearchDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocuments]
	@searchInContent BIT,
	@iSecurityId INT,
	@searchTermTable AS [dbo].[SearchTermTable] READONLY,
	@maxCount INT,
	@getTotal BIT,
	@iDocumentTypeId INT = NULL,
	@fromDate DATE = NULL,
	@toDate DATE = NULL
AS
SET NOCOUNT ON
BEGIN
	DECLARE @SearchString varchar(100)
	SELECT @SearchString = COALESCE(@SearchString + ' AND ', '') + '"' + Term + '*"' FROM @searchTermTable
	DECLARE @ReversedSearchString varchar(100)
	SELECT @ReversedSearchString = COALESCE(@ReversedSearchString + ' AND ', '') + '"' + REVERSE(Term) + '*"' FROM @searchTermTable
	DECLARE @TermsCount AS INT
	SELECT @TermsCount = COUNT(*) FROM @searchTermTable
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
	SET @TopMaxDocs = @maxCount
	DECLARE @TitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)
	DECLARE @InitialTitleSearchTable TABLE
	(
		iEntityId int PRIMARY KEY,
		strName varchar(200),
		iHandbookId int
	)
	DECLARE @ContentsSearchTable TABLE
	(
		iEntityId int PRIMARY KEY
	)
	DECLARE @SearchTable TABLE
	(
		iEntityId INT
	)
	--
	-- Initial Search in title
	--
	IF(LEN(@SearchString) = 3)
		-- search input is null
		BEGIN
			INSERT INTO @InitialTitleSearchTable
				SELECT
					doc.iEntityId,
					doc.strName,
					doc.iHandbookId
				FROM
					m136_tblDocument doc
				WHERE
						iLatestApproved = 1
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
		END
	ELSE
		BEGIN
			INSERT INTO @InitialTitleSearchTable
				SELECT
					doc.iEntityId,
					doc.strName,
					doc.iHandbookId
				FROM
					m136_tblDocument doc
				WHERE
						iLatestApproved = 1
					AND
						(
							CONTAINS(doc.strName, @SearchString) 
							OR 
							CONTAINS(doc.strNameReversed, @ReversedSearchString)
						)
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
			 --
			 -- Search in Contents
			 --
			INSERT INTO @ContentsSearchTable
				SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
					doc.iEntityId
				FROM
					m136_tblDocument doc
					LEFT JOIN m136x_tblTextIndex textIndex 
						ON textIndex.iEntityId = doc.iEntityId
				WHERE
						@searchInContent = 1
					AND
						iLatestApproved = 1
					AND	
						CONTAINS(totalvalue, @SearchString)
					AND
						[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
					AND
						(@iDocumentTypeId IS NULL OR @iDocumentTypeId = doc.iDocumentTypeId)
					AND
						(@fromDate IS NULL OR doc.dtmApproved >= @fromDate)
					AND
						(@toDate IS NULL OR doc.dtmApproved <= @toDate)
		END
	--
	-- Verification that title search contains only documents with title that has EACH search term
	--
	INSERT INTO @TitleSearchTable
		SELECT TOP (@TopMaxDocs) -- Simple limit in case we don't need the count (popup search)
			doc.iEntityId
		FROM
			@InitialTitleSearchTable doc
			INNER JOIN @searchTermTable terms
				ON @TermsCount = 1 OR doc.strName LIKE '%' + terms.Term + '%'
		WHERE
			[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
		GROUP BY	
			iEntityId
		HAVING 
			COUNT(iEntityId) = @TermsCount
	--
	-- Union both results
	--
	INSERT INTO @SearchTable
		SELECT * FROM @TitleSearchTable
		UNION 
		SELECT * FROM @ContentsSearchTable
	-- Select the total number of search results
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
	-- Select the data
	SELECT TOP (@maxCount) 
		iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		NULL AS DepartmentId,
		0 AS Virtual,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
		--,title.iEntityId --Test only
	FROM
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook
				ON handbook.iHandbookId = doc.iHandbookId
		LEFT JOIN @TitleSearchTable title
				ON @searchInContent = 1 AND doc.iEntityId = title.iEntityId
	WHERE
		doc.iEntityId in (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		title.iEntityId DESC, -- Will be null if it's not title
		LevelType ASC,
		doc.strName ASC
END
GO

IF OBJECT_ID('[dbo].[m136_SearchDocumentsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_SearchDocumentsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_SearchDocumentsById]
	@iSecurityId INT,
	@iDocumentId VARCHAR(100),
	@maxCount INT,
	@getTotal BIT
AS
SET NOCOUNT ON
BEGIN
	DECLARE @TopMaxDocs INT
	SET @TopMaxDocs = 20000
	IF @getTotal = 0
		SET @TopMaxDocs = @maxCount
	DECLARE @SearchTable TABLE
	(
		iEntityId INT PRIMARY KEY
	)
	INSERT INTO @SearchTable
	SELECT TOP(@TopMaxDocs)
		doc.iEntityId
	FROM			
		m136_tblDocument doc
	WHERE			
		iLatestApproved = 1
		AND	Doc.iDocumentId LIKE @iDocumentId + '%'
		AND	[dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, doc.iHandbookId) = 1
	SELECT
		COUNT(1) AS TotalCount 
	FROM 
		@SearchTable
	SELECT TOP(@maxCount)
		doc.iDocumentId AS Id,
		doc.iHandbookId,
		doc.strName,
		doc.iDocumentTypeId,
		doc.iVersion AS [Version],
		handbook.iLevelType AS LevelType,
		doc.dtmApproved,
		doc.strApprovedBy,
		dbo.fnOrgGetUserName(doc.iCreatedById, '', 0) as Responsible,
		doc.iSort,
		dbo.fn136_GetParentPathEx(doc.iHandbookId) as [Path],
		handbook.strName AS ParentFolderName,
		[dbo].[fnHasDocumentAttachment](doc.iEntityId) as HasAttachment,
		handbook.iLevel as ChapterLevel
	FROM			
		m136_tblDocument doc
		INNER JOIN	m136_tblHandbook handbook 
			ON handbook.iHandbookId = doc.iHandbookId
	WHERE
		doc.iEntityId IN (SELECT iEntityId FROM @SearchTable)
	ORDER BY
		doc.iDocumentId
END
GO


---------- FILE: Upgrade_01.00.00.078.sql ----------
INSERT INTO #Description VALUES('Update m136_GetChapterItems, m136_GetApprovedDocumentsByHandbookIdRecursive for adding folder icon into grid.')
GO

IF OBJECT_ID('[dbo].[m136_GetChapterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetChapterItems] AS SELECT 1')
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
				d.iDocumentTypeId,
				d.iVersion as Version,
				h.iLevelType as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				h.iDepartmentId as DepartmentId,
				0 as Virtual,
				d.iSort,
				NULL as ParentFolderName,
				NULL as Path,
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_tblDocument d
		LEFT JOIN m136_tblHandbook h 
			ON h.iHandbookId = d.iHandbookId
		WHERE	d.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	v.iDocumentId as Id,
				d.strName,
				d.iDocumentTypeId,
				d.iVersion as Version,
				h.iLevelType as LevelType,
				d.dtmApproved,
				d.strApprovedBy,
				dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
				h.iDepartmentId as DepartmentId,
				1 as Virtual,
				v.iSort,
				h.strName as ParentFolderName,
				dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
				[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM	m136_relVirtualRelation v
			INNER JOIN m136_tblDocument d 
				ON d.iDocumentId = v.iDocumentId
			INNER JOIN m136_tblHandbook h
				ON d.iHandbookId = h.iHandbookId
		WHERE	v.iHandbookId = @iHandbookId
			AND d.iLatestApproved = 1
	UNION
		SELECT	h.iHandbookId as Id,
				h.strName,
				-1 as iDocumentTypeId,
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


IF OBJECT_ID('[dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] AS SELECT 1')
GO
-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: DEC 05, 2014
-- Description: Get approved documents by handbookId and all documents of sub chapters.
-- =============================================
ALTER PROCEDURE [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestApproved = 1
	ORDER BY 
		iSort, 
		d.strName
END
GO


---------- FILE: Upgrade_01.00.00.079.sql ----------
INSERT INTO #Description VALUES('Updated m136_GetMenuGroups.')
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMenuGroups]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    DECLARE @iLeftItemId INT = 2, @iRightItemId INT = 3;    
    WITH Children AS
	(
			SELECT 
				iItemId, 
				iItemParentId, 
				strName, 
				strDescription,
				iLevel, 
				strURL, 
				CASE 
					WHEN iItemParentId = @iLeftItemId THEN 1 
					WHEN iItemParentId = @iRightItemId THEN 2
				END AS iPosition
			FROM 
				[dbo].[tblMenu] 
			WHERE
				iItemId IN (@iLeftItemId, @iRightItemId) 
		UNION ALL
			SELECT 
				m.iItemId, 
				m.iItemParentId, 
				m.strName, 
				m.strDescription,
				m.iLevel, 
				m.strURL, 
				CASE 
					WHEN m.iItemParentId = @iLeftItemId THEN 1 
					WHEN m.iItemParentId = @iRightItemId THEN 2 
				END AS iPosition 
			FROM 
				[dbo].[tblMenu] m
				INNER JOIN Children 
					ON	m.iItemParentId = Children.iItemId 
	)
	
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, iPosition 
	FROM 
		Children
	WHERE iItemId NOT IN (@iLeftItemId, @iRightItemId) ORDER BY strName
END
GO


---------- FILE: Upgrade_01.00.00.080.sql ----------
INSERT INTO #Description VALUES('Updated m136_GetMenuGroups for dtmRemove, dtmDisplay, bNewWindow.')
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetMenuGroups]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    DECLARE @iLeftItemId INT = 2, @iRightItemId INT = 3;    
    WITH Children AS
	(
			SELECT 
				iItemId, 
				iItemParentId, 
				strName, 
				strDescription,
				iLevel, 
				strURL, 
				dtmDisplay,
				dtmRemove,
				bNewWindow,
				CASE 
					WHEN iItemParentId = @iLeftItemId THEN 1 
					WHEN iItemParentId = @iRightItemId THEN 2
				END AS iPosition
			FROM 
				[dbo].[tblMenu] 
			WHERE
				iItemId IN (@iLeftItemId, @iRightItemId) 
		UNION ALL
			SELECT 
				m.iItemId, 
				m.iItemParentId, 
				m.strName, 
				m.strDescription,
				m.iLevel, 
				m.strURL, 
				m.dtmDisplay,
				m.dtmRemove,
				m.bNewWindow,
				CASE 
					WHEN m.iItemParentId = @iLeftItemId THEN 1 
					WHEN m.iItemParentId = @iRightItemId THEN 2 
				END AS iPosition 
			FROM 
				[dbo].[tblMenu] m
				INNER JOIN Children 
					ON	m.iItemParentId = Children.iItemId 
	)
	
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, iPosition 
	FROM 
		Children
	WHERE iItemId NOT IN (@iLeftItemId, @iRightItemId) 
		AND (GETDATE() BETWEEN dtmDisplay AND dtmRemove 
			OR (dtmRemove IS NULL AND dtmDisplay IS NULL)
			OR (GETDATE()> dtmDisplay AND dtmRemove IS NULL)
			OR (dtmDisplay IS NULL AND GETDATE() < dtmRemove))
	ORDER BY strName
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypes] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetDocumentTypes]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT dt.iDocumentTypeId
		, dt.strName
		, dt.strDescription
		, dt.iDeleted
		, dt.bIsProcess
		, dt.bInactive
		, dt.ViewMode
		, dt.[Type]
		, dt.HideFieldName
		, dt.HideFieldNumbering
		, dt.strIcon
	FROM [dbo].[m136_tblDocumentType] dt 
	WHERE dt.iDeleted = 0
		ORDER BY strName ASC;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentTypeById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentTypeById] AS SELECT 1')
GO
-- =============================================
-- Author:		em.lam.van.mai
-- Create date: July 09, 2015
-- Description:	Get a specified document type by Id
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentTypeById]
	@DocumentTypeId INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT  
        [iDocumentTypeId],
        [strName],
        [strDescription],
        [Type],
        [HideFieldNumbering],
        [HideFieldName],
        [bIsProcess],
        [bInactive],
        [ViewMode],
        [strIcon]                        
    FROM 
        [dbo].[m136_tblDocumentType] dt
    WHERE 
        [iDocumentTypeId] = @DocumentTypeId
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsForStartpage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsForStartpage]
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
	DECLARE @total INT = 3;
	SELECT	
		@total = iMainNews 
	FROM	
		dbo.m123_tblCategory
	WHERE
		iCategoryId = 1
	
	BEGIN	
		SELECT TOP(@total)
			i.iInfoId,
			i.strTopic,
			i.strTitle,
			i.strIngress,
			i.strBody,
			i.dtmCreated
		FROM 
			dbo.m123_tblInfo i
		INNER JOIN 
			m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
		WHERE
			i.iDraft = 0
		AND	i.dtmPublish <= @today
		AND i.dtmExpire >= @today
		AND ri.iCategoryId = 1
		ORDER BY i.dtmCreated DESC
	END
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsById]
	@InfoId INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
	SELECT
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	FROM 
		dbo.m123_tblInfo i
	WHERE
		i.iInfoId  = @InfoId
	AND i.iDraft = 0
	AND	i.dtmPublish <= @today
	AND i.dtmExpire >= @today
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsWithPaging] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
	WITH info AS(	
		SELECT
			rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmCreated DESC),
			i.iInfoId,
			i.strTopic,
			i.strTitle,
			i.strIngress,
			i.strBody,
			i.dtmCreated
		FROM 
			dbo.m123_tblInfo i
		INNER JOIN 
			m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
		WHERE
			i.iDraft = 0
		AND	i.dtmPublish <= @today
		AND i.dtmExpire >= @today
		AND ri.iCategoryId = 1
	)
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	FROM 
		info i
	WHERE 
		(@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	ORDER BY RowNumber
	
	SELECT
		COUNT(*) AS Total
	FROM 
		dbo.m123_tblInfo i
	INNER JOIN 
			m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
	WHERE
		i.iDraft = 0
	AND	i.dtmPublish <= @today
	AND i.dtmExpire >= @today
	AND ri.iCategoryId = 1
END
GO

IF OBJECT_ID('[dbo].[m136_UpdateNewsReadCount]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_UpdateNewsReadCount] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_UpdateNewsReadCount]
	@iInfoId INT
AS
SET NOCOUNT ON
BEGIN
	UPDATE dbo.m123_tblInfo
	SET iReadCount = iReadCount + 1
	WHERE iInfoId = @iInfoId
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