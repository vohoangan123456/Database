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