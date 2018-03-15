INSERT INTO #Description VALUES('Create stored procedures for News backend.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: OCT 22, 2015
-- Description:	Get News for start page
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
@CategoryId AS INT
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
		iCategoryId IN ( @CategoryId )
	
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
		AND ri.iCategoryId IN ( @CategoryId )
		ORDER BY i.dtmCreated DESC
	END
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsById] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: OCT 22, 2015
-- Description:	Get New information for start page
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetNewsById]
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

IF OBJECT_ID('[dbo].[m136_be_GetNewsWithPaging]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsWithPaging] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: OCT 22, 2015
-- Description:	Get News for start page with paging
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetNewsWithPaging]
	@PageIndex INT,
	@PageSize INT,
	@CategoryId AS INT
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
		AND ri.iCategoryId IN ( @CategoryId )
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
	AND ri.iCategoryId IN ( @CategoryId )
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateNewsReadCount]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateNewsReadCount] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: OCT 22, 2015
-- Description:	update read count for New
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateNewsReadCount]
	@iInfoId INT
AS
SET NOCOUNT ON
BEGIN
	UPDATE dbo.m123_tblInfo
	SET iReadCount = iReadCount + 1
	WHERE iInfoId = @iInfoId
END
GO