INSERT INTO #Description VALUES('Create procedure m136_be_EmployeePermissionsToFolder')
GO

IF OBJECT_ID('[dbo].[m136_be_EmployeePermissionsToFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EmployeePermissionsToFolder] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_EmployeePermissionsToFolder]
    @FolderId INT = 0,
    @UserId INT = 0,
    @iBit INT = 0
AS
BEGIN
	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	-- Do we have a specified root or do we assume we will list everything?
	IF ISNULL(@FolderId, 0) = 0
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_tblHandbook WHERE iDeleted = 0 
		END
	ELSE
		BEGIN
			INSERT INTO @HandbookIdTable
			SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive (@FolderId, @UserId, 0)
		END 

    SELECT iLevelType as LevelType,
        dbo.fn136_GetParentPathEx(iHandbookId) as ParentPath
    FROM
        m136_tblHandbook
    WHERE
        ihandbookId in (SELECT iHandbookId from @HandbookIdTable)
        AND iHandbookId in (
            SELECT
                distinct tblACL.iEntityId
            FROM
                tblACL 
                    INNER JOIN tblSecGroup sg ON sg.iSecGroupId = tblACL.iSecurityId
                    INNER JOIN relEmployeeSecGroup resg ON resg.iSecGroupId = sg.iSecGroupId 
            WHERE 
                resg.iEmployeeId = @UserId
                AND tblACL.iApplicationId = 136
                AND tblACL.iPermissionSetId = 462
                AND (tblACL.iBit & @iBit) = @iBit)
    ORDER BY ParentPath
END
GO