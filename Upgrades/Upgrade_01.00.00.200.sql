INSERT INTO #Description VALUES('Updated script for getting menus.')
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMenuGroups] 
    @UserId INT,
    @MenuId INT
AS
BEGIN
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @CurrentDate DATETIME = GETDATE();
	SELECT iItemId INTO #Groups FROM tblMenu WHERE iItemParentId = @MenuId;
	
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
				iSort
			FROM 
				[dbo].[tblMenu] 
			WHERE
				iItemId IN (SELECT iItemId FROM #Groups) AND
				dbo.fnSecurityGetPermission(99, 99, @UserId, iItemId) & 1 = 1
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
				m.iSort
			FROM 
				[dbo].[tblMenu] m
                    INNER JOIN Children 
                        ON	m.iItemParentId = Children.iItemId 
            WHERE
                dbo.fnSecurityGetPermission(99, 99, @UserId, m.iItemId) & 1 = 1
	)
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, iSort
	FROM 
		Children
	WHERE @CurrentDate BETWEEN dtmDisplay AND dtmRemove 
			OR (dtmRemove IS NULL AND dtmDisplay IS NULL)
			OR (@CurrentDate> dtmDisplay AND dtmRemove IS NULL)
			OR (dtmDisplay IS NULL AND @CurrentDate < dtmRemove)
	ORDER BY iSort, strName;
	DROP TABLE #Groups;
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsForStartpage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsForStartpage]
	@CategoryId AS INT,
	@Access INT
AS
BEGIN
	DECLARE @today DATETIME;
	DECLARE @NewsIdTable TABLE (iInfoId INT);
	SET @today = GETDATE();
	DECLARE @total INT = 3;
	INSERT INTO @NewsIdTable (iInfoId)
    SELECT TOP(@total)
        i.iInfoId
    FROM 
        dbo.m123_tblInfo i
            INNER JOIN 
                m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
            INNER JOIN dbo.m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
    WHERE
        i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
        AND 
            (
                (ri.iCategoryId = @CategoryId AND c.iAccess & @Access = @Access)
                OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory WHERE iParentCategoryId = @CategoryId AND iAccess & @Access = @Access)
            )
    ORDER BY i.dtmCreated DESC;

	SELECT TOP(@total)
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	FROM 
		dbo.m123_tblInfo i
	WHERE
    iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
	ORDER BY i.dtmCreated DESC;
	
    SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT iInfoId FROM @NewsIdTable)
END
GO


IF OBJECT_ID('[dbo].[m136_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsWithPaging] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT,
	@Access INT
AS
BEGIN
	DECLARE @today Date;
	SET @today = GETDATE();
	
	SELECT
		rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmCreated DESC),
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated
	INTO #Paging
	FROM 
		dbo.m123_tblInfo i
		JOIN dbo.m123_relInfoCategory ri ON ri.iInfoId = i.iInfoId
		JOIN dbo.m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
	WHERE
		i.iDraft = 0
	AND	i.dtmPublish < @today
	AND i.dtmExpire > @today
	AND c.iAccess & @Access = @Access;
		
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated		
	FROM 
		#Paging i
	WHERE 
		(@PageSize=0 OR rownumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1))
	ORDER BY RowNumber
	
	SELECT
		COUNT(*) AS Total
	FROM 
		#Paging i
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
	
	
	SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId = @InfoId
    SELECT b.iItemId,
        b.strName,
        b.strExtension,
        b.strDescription
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
        i.iInfoId = @InfoId
    ORDER BY b.strName
END
GO