INSERT INTO #Description VALUES ('Fixed new list. Replace createdDate by publishedDate. Fixed metadata with virtual docs')
GO

IF OBJECT_ID('[dbo].[m136_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsWithPaging] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT,
	@Access INT,
	@ShowInModule INT,
	@CategoryId INT
AS
BEGIN
	DECLARE @today Date;
	SET @today = GETDATE();
	SELECT
		rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmPublish DESC),
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.dtmPublish
	INTO #Paging
	FROM 
		dbo.m123_tblInfo i
		JOIN dbo.m123_relInfoCategory ri ON ri.iInfoId = i.iInfoId
		JOIN dbo.m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
	WHERE
		i.iDraft = 0
	AND	i.dtmPublish < @today
	AND i.dtmExpire > @today
	AND c.iAccess & @Access = @Access
	AND (c.iShownIn & @ShowInModule = @ShowInModule)
	AND c.iParentCategoryId = @CategoryId;
	
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.dtmPublish		
	FROM 
		#Paging i
	WHERE 
		(@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	ORDER BY RowNumber;
	
	SELECT
		COUNT(*) AS Total
	FROM 
		#Paging i
END
GO




IF OBJECT_ID('[dbo].[m136_be_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsWithPaging] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT,
	@CategoryId AS INT,
	@ShowInModule INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	WITH info AS(	
		SELECT
			rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmPublish DESC),
			i.iInfoId,
			i.strTopic,
			i.strTitle,
			i.strIngress,
			i.strBody,
			i.dtmCreated,
			i.dtmPublish
		FROM 
			dbo.m123_tblInfo i
                INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
		WHERE
			i.iDraft = 0
		AND	i.dtmPublish <= @today
		AND i.dtmExpire >= @today
		AND (ri.iCategoryId = @CategoryId
            OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory 
                                  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule))
	)
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.dtmPublish
	FROM 
		info i
	WHERE 
		(@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))
	ORDER BY RowNumber;
	
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
        AND (ri.iCategoryId = @CategoryId
            OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory
                                  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule));
END
GO


IF OBJECT_ID('[dbo].[m136_GetDocumentMetatags]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentMetatags] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentMetatags]
	@iHandbookId int = 0,
	@iRegisterItemId int = 0,
	@bRecursive BIT = 0,
	@bIncludeLevel1 BIT = 0
AS
BEGIN
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
	
	IF (@bIncludeLevel1 = 1)
	BEGIN
		DECLARE @TmpHandbooks TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
		INSERT INTO @TmpHandbooks
		SELECT iHandbookId 
			FROM @AvailableHandbooks
		INSERT INTO @AvailableHandbooks 
			SELECT iHandbookId 
			FROM [dbo].[m136_tblHandbook] 
			WHERE iLevelType = 1 
				  AND iDeleted = 0
				  AND iHandbookId NOT IN (SELECT iHandbookId FROM @TmpHandbooks)
	END
	
	SELECT * 
	INTO #resultTable
	FROM (
		SELECT
			d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
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
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			h.iParentHandbookId,
			0 AS iChildCount,
            1 AS IsDocument,
			d.iHandbookId AS VirtualHandbookId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_tblDocument d
            JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136)
		WHERE d.iLatestApproved = 1
			AND d.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	UNION
		SELECT 
			d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
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
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			h.iParentHandbookId,
			0 AS iChildCount,
            1 AS IsDocument,
			virt.iHandbookId AS VirtualHandbookId,
			dbo.m136_fnGetItemValue(dt.iAutoId) AS MetatagValue
		FROM 
			m136_relVirtualRelation virt
			JOIN m136_tblDocument d on virt.iDocumentId = d.iDocumentId
			JOIN m136_tblHandbook h on d.iHandbookId = h.iHandbookId AND h.iHandbookId <> @iHandbookId
			JOIN m147_relRegisterItemItem dt ON d.iDocumentId = dt.iItemId 
				AND (dt.iRegisterItemId = @iRegisterItemId AND dt.iModuleId = 136) 					
		WHERE 	
			d.iLatestApproved = 1
			AND virt.iHandbookId in (SELECT iHandbookId FROM @AvailableHandbooks)
	) r
	ORDER BY r.MetatagValue DESC, r.iSort
	SELECT * FROM #resultTable
	SELECT d.Id AS iDocumentId,
        r.iItemId,
		b.strName,
		r.iPlacementId,
		r.iProcessrelationTypeId,
		b.strExtension,
		b.strDescription,
		r.iSort 
	FROM m136_relInfo r 
		JOIN (SELECT DISTINCT iEntityId, Id FROM #resultTable) d ON r.iEntityId = d.iEntityId
		JOIN m136_tblBlob b ON r.iItemId = b.iItemId
	WHERE r.iRelationTypeId = 20
	ORDER BY r.iSort, b.strName;
END
GO