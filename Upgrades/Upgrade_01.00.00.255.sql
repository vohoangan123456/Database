INSERT INTO #Description VALUES('Update SP for News')
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
	AND c.iAccess & @Access = @Access
	AND (c.iShownIn & @ShowInModule = @ShowInModule)
	AND c.iParentCategoryId = @CategoryId;
		
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
			rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmCreated DESC),
			i.iInfoId,
			i.strTopic,
			i.strTitle,
			i.strIngress,
			i.strBody,
			i.dtmCreated
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
		i.dtmCreated
	FROM 
		info i
	WHERE 
		(@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))
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
        AND (ri.iCategoryId = @CategoryId
            OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory
                                  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule))
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @CategoryId AS INT,
	@ShowInModule INT
AS
BEGIN
	DECLARE @Today Datetime;
    DECLARE @NewsIdTable TABLE (iInfoId INT);
    
	SET @Today = GETDATE();
    
	INSERT INTO @NewsIdTable (iInfoId)
    SELECT TOP 3
        i.iInfoId
    FROM 
        dbo.m123_tblInfo i
            INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
    WHERE
        i.iDraft = 0
        AND	i.dtmPublish <= @Today
        AND i.dtmExpire >= @Today
        AND 
        (
            (ri.iCategoryId = @CategoryId AND c.iShownIn & @ShowInModule = @ShowInModule)
            OR ri.iCategoryId IN (
                                 SELECT iCategoryId
                                 FROM m123_tblCategory
                                 WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule)
        )
    ORDER BY i.dtmPublish DESC
    
    SELECT TOP 3
        iInfoId,
        strTopic,
        strTitle,
        strIngress,
        strBody,
        dtmPublish
    FROM
        dbo.m123_tblInfo
    WHERE
        iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
    ORDER BY dtmPublish DESC
    
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