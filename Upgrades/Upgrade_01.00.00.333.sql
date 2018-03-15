INSERT INTO #Description VALUES ('Add SP get news by categoryId')
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsByCategoryId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsByCategoryId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsByCategoryId]
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
	WHERE
		i.iDraft = 0
	AND	i.dtmPublish <= @today
	AND i.dtmExpire >= @today
	AND ((ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory WHERE iCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule))
        OR ri.iCategoryId IN (SELECT iCategoryId FROM m123_tblCategory 
                              WHERE iParentCategoryId = @CategoryId AND iShownIn & @ShowInModule = @ShowInModule))
    
    SELECT
		i.iInfoId,
		i.strTopic,
		i.strTitle,
		i.strIngress,
		i.strBody,
		i.dtmCreated,
		i.dtmPublish
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