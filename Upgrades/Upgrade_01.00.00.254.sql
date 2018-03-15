INSERT INTO #Description VALUES('Fix flow chart load existed image.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetChartJsonContent]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChartJsonContent] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetChartJsonContent] 
	@ItemId INT
AS
BEGIN
    SELECT
        JsonContent
    FROM
        m136_FlowChart
    WHERE
        Id = @ItemId
END
GO