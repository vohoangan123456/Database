INSERT INTO #Description VALUES ('Check news permissions for category')
GO

IF OBJECT_ID('[dbo].[m123_be_GetNewsDetailsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsDetailsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_GetNewsDetailsById]
	@UserId INT,
	@InfoId INT
AS
BEGIN

	SELECT
		i.iInfoId,
        ic.iCategoryId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
        i.dtmPublish,
        i.dtmExpire,
        i.iDraft,
        i.bIngress
    INTO #tempTable
	FROM 
		dbo.m123_tblInfo i
            INNER JOIN dbo.m123_relInfoCategory ic ON i.iInfoId = ic.iInfoId
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ic.iCategoryId
	WHERE
		i.iInfoId  = @InfoId
		AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
		
	SELECT * FROM #tempTable
		
    SELECT TOP 1
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT iInfoId FROM #tempTable)
        
    SELECT
        b.iItemId,
        b.strName,
        b.strExtension
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
        i.iInfoId IN (SELECT iInfoId FROM #tempTable)
        
    IF(OBJECT_ID('#tempTable') IS NOT NULL)
	BEGIN
		DROP TABLE #tempTable
	END
END

GO

IF OBJECT_ID('[dbo].[m123_be_GetNewsOfCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_GetNewsOfCategory] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_GetNewsOfCategory]
	@UserId INT,
    @CategoryId INT
AS
BEGIN
    SELECT
        i.iInfoId,
        i.iAuthorId,
        e.strFirstName + ' ' + e.strLastName AS strAuthorName,
        i.strTitle,
        i.dtmPublish,
        i.dtmExpire,
        i.iReadCount,
        i.iDraft,
        i.bIngress
    FROM
        m123_tblInfo i
            INNER JOIN m123_relInfoCategory ic
                ON i.iInfoId = ic.iInfoId
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ic.iCategoryId
            LEFT JOIN tblEmployee e
				ON i.iAuthorId = e.iEmployeeId
    WHERE
        ic.iCategoryId = @CategoryId
        AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsByCategoryId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsByCategoryId] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetNewsByCategoryId]
	@UserId INT,
	@PageIndex INT,
	@PageSize INT,
	@CategoryId AS INT,
	@ShowInModule INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	DECLARE @TempTable TABLE (rownumber INT, iInfoId INT)
	
	INSERT INTO @TempTable(rownumber, iInfoId)
	SELECT
		rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmPublish DESC),
		i.iInfoId
	FROM 
		dbo.m123_tblInfo i
        INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId
        INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
	WHERE
		i.iDraft = 0
	AND	i.dtmPublish <= @today
	AND i.dtmExpire >= @today
	AND ((ri.iCategoryId = @CategoryId AND c.iShownIn & @ShowInModule = @ShowInModule) 
			OR ri.iCategoryId IN (SELECT iCategoryId 
							      FROM m123_tblCategory   
								  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule)) 
	 AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
	 
    SELECT
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.dtmPublish,
		i.bIngress
	FROM 
		@TempTable t
		INNER JOIN dbo.m123_tblInfo i ON i.iInfoId = t.iInfoId
	WHERE 
		(@PageSize = 0 OR t.rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))
	ORDER BY t.RowNumber;
	SELECT
		COUNT(*) AS Total
	FROM @TempTable
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetNewsById]
	@UserId INT,
	@InfoId INT
AS
BEGIN
	DECLARE @Today Datetime
	SET @Today = GETDATE();
	
	SELECT
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.bIngress
	INTO #tempTable
	FROM 
		dbo.m123_tblInfo i
			INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId  
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
	WHERE
		i.iInfoId  = @InfoId
		AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
		
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.bIngress
	FROM #tempTable i
		
    SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
        InfoId IN (SELECT iInfoId FROM #tempTable)
        
    SELECT b.iItemId,
        b.strName,
        b.strExtension,
        b.strDescription
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
        i.iInfoId IN (SELECT iInfoId FROM #tempTable)
    ORDER BY b.strName
    
    IF(OBJECT_ID('#tempTable') IS NOT NULL)
	BEGIN
		DROP TABLE #tempTable
	END
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsWithPaging] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetNewsWithPaging]
	@UserId INT,
	@PageIndex INT,
	@PageSize INT,
	@CategoryId AS INT,
	@ShowInModule INT
AS
BEGIN
	DECLARE @today Datetime;
	SET @today = GETDATE();
	
	 DECLARE @TempTable TABLE (rownumber INT, iInfoId INT)  
	 INSERT INTO @TempTable(rownumber, iInfoId)  
	 SELECT  
	  rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmPublish DESC),  
	  i.iInfoId  
	 FROM   
	  dbo.m123_tblInfo i  
			INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId 
			INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId   
	 WHERE  
	  i.iDraft = 0  
	 AND i.dtmPublish <= @today  
	 AND i.dtmExpire >= @today  
	 AND ((ri.iCategoryId = @CategoryId AND c.iShownIn & @ShowInModule = @ShowInModule) 
			OR ri.iCategoryId IN (SELECT iCategoryId 
							      FROM m123_tblCategory   
								  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule)) 
	 AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
	
	SELECT  
	  i.iInfoId,  
	  i.strTopic,  
	  i.strTitle,  
	  i.strIngress,  
	  i.strBody,  
	  i.dtmCreated,  
	  i.dtmPublish,
	  i.bIngress
	 FROM   
	  @TempTable t  
	  INNER JOIN dbo.m123_tblInfo i ON i.iInfoId = t.iInfoId  
	 WHERE   
	  (@PageSize = 0 OR t.rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))  
	 ORDER BY t.RowNumber; 
	 
	  SELECT  
	  COUNT(*) AS Total  
	 FROM @TempTable 
	
END
GO

IF OBJECT_ID('[dbo].[m136_GetActiveNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetActiveNewsById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetActiveNewsById]
	@UserId INT,
	@InfoId INT
AS
BEGIN
	DECLARE @today Datetime
	SET @today = GETDATE();
	
	SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.bIngress
	INTO #tempTable
	FROM 
		dbo.m123_tblInfo i
			INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId  
            INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId
	WHERE
		i.iInfoId  = @InfoId
        AND i.iDraft = 0
        AND	i.dtmPublish <= @today
        AND i.dtmExpire >= @today
        AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1  
       
    SELECT 
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.bIngress
	FROM #tempTable i
       
	SELECT
        Id,
        InfoId,
        Name,
        MimeType,
        Value
    FROM
        m123_tblNewsMedia
    WHERE
		InfoId IN (SELECT iInfoId FROM #tempTable)
        
    SELECT b.iItemId,
        b.strName,
        b.strExtension,
        b.strDescription
    FROM
        m123_relInfo i
            INNER JOIN m136_tblBlob b
                ON i.iEntityId = b.iItemId
    WHERE
		i.iInfoId IN (SELECT iInfoId FROM #tempTable)
    ORDER BY b.strName
    
    IF(OBJECT_ID('#tempTable') IS NOT NULL)
	BEGIN
		DROP TABLE #tempTable
	END
END
GO

IF OBJECT_ID('[dbo].[m136_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetNewsForStartpage] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetNewsForStartpage]
	@UserId INT,
	@CategoryId AS INT
AS
BEGIN
	DECLARE @Today DATETIME;
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
        AND ((ri.iCategoryId = @CategoryId AND c.iShownIn & 1 = 1) 
			OR ri.iCategoryId IN (SELECT iCategoryId 
							      FROM m123_tblCategory   
								  WHERE iParentCategoryId = @CategoryId AND iShownIn & 1 = 1)) 
		AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
        
    ORDER BY i.dtmPublish DESC;
	
	SELECT TOP 3
		iInfoId,
		strTopic,
		strTitle,
		strIngress,
		strBody,
		dtmPublish,
		bIngress
	FROM 
		dbo.m123_tblInfo
	WHERE
        iInfoId IN (SELECT iInfoId FROM @NewsIdTable)
	ORDER BY dtmPublish DESC;
    
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
	@UserId INT,
	@PageIndex INT,
	@PageSize INT,
	@ShowInModule INT,
	@CategoryId INT
AS
BEGIN
	DECLARE @today Date;
	SET @today = GETDATE();
	
	DECLARE @TempTable TABLE (rownumber INT, iInfoId INT)  
	 INSERT INTO @TempTable(rownumber, iInfoId)  
	 SELECT  
	  rownumber = ROW_NUMBER() OVER (ORDER BY i.dtmPublish DESC),  
	  i.iInfoId  
	 FROM   
	  dbo.m123_tblInfo i  
			INNER JOIN m123_relInfoCategory ri ON i.iInfoId = ri.iInfoId 
			INNER JOIN m123_tblCategory c ON c.iCategoryId = ri.iCategoryId   
	 WHERE  
	  i.iDraft = 0  
	 AND i.dtmPublish <= @today  
	 AND i.dtmExpire >= @today  
	 AND ((ri.iCategoryId = @CategoryId AND c.iShownIn & @ShowInModule = @ShowInModule) 
			OR ri.iCategoryId IN (SELECT iCategoryId 
							      FROM m123_tblCategory   
								  WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule)) 
	 AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
	
	SELECT  
	  i.iInfoId,  
	  i.strTopic,  
	  i.strTitle,  
	  i.strIngress,  
	  i.strBody,  
	  i.dtmCreated,  
	  i.dtmPublish,
	  i.bIngress 
	 FROM   
	  @TempTable t  
	  INNER JOIN dbo.m123_tblInfo i ON i.iInfoId = t.iInfoId  
	 WHERE   
	  (@PageSize = 0 OR t.rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1))  
	 ORDER BY t.RowNumber; 
	
	SELECT  
	  COUNT(*) AS Total  
	 FROM @TempTable
END
