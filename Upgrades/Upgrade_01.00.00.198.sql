INSERT INTO #Description VALUES('Modify stored procedures m136_GetMenuGroups')
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMenuGroups]
    @UserId INT
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
                --iItemId IN (@iLeftItemId, @iRightItemId)
				(iItemId = @iLeftItemId AND dbo.fnSecurityGetPermission(99, 99, @UserId, @iLeftItemId) & 1 = 1)
                OR (iItemId = @iRightItemId AND dbo.fnSecurityGetPermission(99, 99, @UserId, @iRightItemId) & 1 = 1)
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
            WHERE
                dbo.fnSecurityGetPermission(99, 99, @UserId, m.iItemId) & 1 = 1
	)
	
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, iPosition 
	FROM 
		Children
	WHERE GETDATE() BETWEEN dtmDisplay AND dtmRemove 
			OR (dtmRemove IS NULL AND dtmDisplay IS NULL)
			OR (GETDATE()> dtmDisplay AND dtmRemove IS NULL)
			OR (dtmDisplay IS NULL AND GETDATE() < dtmRemove)
	ORDER BY iLevel, strName
END
GO