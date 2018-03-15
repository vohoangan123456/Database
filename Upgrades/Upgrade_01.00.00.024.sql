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
			strName
END
GO