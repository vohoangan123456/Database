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