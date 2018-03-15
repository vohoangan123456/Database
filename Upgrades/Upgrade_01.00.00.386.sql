INSERT INTO #Description VALUES ('Insert permissions for all news categories and apply news categories permissions.')
GO

-- Delete all permissions on news categories
DELETE tblAcl
WHERE iPermissionSetId IN (110, 111)
GO

-- Insert administrator as default permission role for all news categories
INSERT INTO tblAcl
    (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
SELECT iCategoryId, 110, 1, 110, 0, 1
FROM m123_tblCategory
GO

IF OBJECT_ID('[dbo].[CanUserAccessToNewsCategory]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[CanUserAccessToNewsCategory]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[CanUserAccessToNewsCategory]
(
	@UserId INT,
	@NewsCategoryId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
        
    IF EXISTS
    (
        SELECT 1
        FROM m123_tblCategory c
        WHERE
            c.iCategoryId = @NewsCategoryId
            AND 
            (
                c.iOwnerId = @UserId
                OR EXISTS(
                    SELECT 1
                    FROM
                        tblAcl acl
                    WHERE
                        acl.iApplicationId = 110
                        AND acl.iEntityId = c.iCategoryId
                        AND
                        (
                            acl.iPermissionSetId = 110 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId)
                            OR (acl.iPermissionSetId = 111 AND acl.iSecurityId IN (SELECT Id FROM @UserDepartmentId))
                        )
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetNewsForStartpage]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetNewsForStartpage] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetNewsForStartpage]
    @UserId INT,
    @CategoryId INT,
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
        AND dbo.CanUserAccessToNewsCategory(@UserId, c.iCategoryId) = 1
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

IF OBJECT_ID('[dbo].[CanUserAccessToActivity]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[CanUserAccessToActivity]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[CanUserAccessToActivity]
(
	@UserId INT,
	@ActivityId INT
)
RETURNS BIT
AS
BEGIN
    DECLARE @Result BIT = 0;
    DECLARE @UserDepartmentId TABLE(Id INT);
    DECLARE @UserRoleId TABLE(Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
    INSERT INTO @UserRoleId(Id)
    SELECT
        iSecGroupId
    FROM
        relEmployeeSecGroup
    WHERE
        iEmployeeId = @UserId
        
    IF EXISTS
    (
        SELECT 1
        FROM Calendar.Activities a
        WHERE
            a.ActivityId = @ActivityId
            AND 
            (
                a.IsPermissionControlled = 0
                OR
                (
                    CreatedBy = @UserId             -- Check creator permission
                    OR ResponsibleId = @UserId      -- Check main responsible permission
                    OR EXISTS(                      -- Check co-responsible permission
                        SELECT 1
                        FROM
                            Calendar.ActivityResponsibles ar
                        WHERE
                            ar.ActivityId = a.ActivityId
                            AND
                            (
                                (ar.ResponsibleTypeId = 701 AND ar.ResponsibleId = @UserId)
                                OR (ar.ResponsibleTypeId = 702 AND ar.ResponsibleId IN (SELECT Id FROM @UserDepartmentId))
                                OR (ar.ResponsibleTypeId = 703 AND ar.ResponsibleId IN (SELECT Id FROM @UserRoleId))
                            )
                    )
                    OR EXISTS(                      -- Check read permission
                        SELECT 1
                        FROM
                            tblAcl acl
                        WHERE
                            acl.iApplicationId = 160
                            AND acl.iEntityId = a.ActivityId
                            AND
                            (
                                (acl.iPermissionSetId = 701 AND acl.iSecurityId = @UserId)
                                OR (acl.iPermissionSetId = 702 AND acl.iSecurityId IN (SELECT Id FROM @UserDepartmentId))
                                OR (acl.iPermissionSetId = 703 AND acl.iSecurityId IN (SELECT Id FROM @UserRoleId))
                            )
                    )
                )
            )
    )
    BEGIN
        SET @Result = 1;
    END
    
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[m136_GetMenuGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetMenuGroups] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetMenuGroups] 
    @UserId INT,
    @MenuId INT
AS
BEGIN
	DECLARE @CurrentDate DATETIME = GETDATE();
    DECLARE @UserDepartmentId TABLE (Id INT);
    
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId
        
    INSERT INTO @UserDepartmentId(Id)
    SELECT
        iDepartmentId
    FROM
        relEmployeeDepartment
    WHERE iEmployeeId = @UserId
    
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
                bExpanded,
				iSort
			FROM 
				[dbo].[tblMenu] 
			WHERE
				iItemId IN (SELECT iItemId FROM #Groups)
                AND
                (
                    dbo.fnSecurityGetPermission(99, 99, @UserId, iItemId) & 1 = 1
                    OR EXISTS (
                        SELECT 1 
                        FROM tblAcl 
                        WHERE 
                            iEntityId = iItemId
                            AND iApplicationId = 99 
                            AND iPermissionSetId = 100 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId) 
                            AND iBit & 1 = 1
                    )
                )
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
                m.bExpanded,
				m.iSort
			FROM 
				[dbo].[tblMenu] m
                    INNER JOIN Children 
                        ON	m.iItemParentId = Children.iItemId 
            WHERE
                dbo.fnSecurityGetPermission(99, 99, @UserId, m.iItemId) & 1 = 1
                OR EXISTS (
                        SELECT 1 
                        FROM tblAcl 
                        WHERE 
                            iEntityId = iItemId
                            AND iApplicationId = 99 
                            AND iPermissionSetId = 100 
                            AND iSecurityId IN (SELECT Id FROM @UserDepartmentId) 
                            AND iBit & 1 = 1
                    )
	)
	SELECT 
		iItemId, iItemParentId, strName, strDescription, iLevel, strURL, dtmDisplay, dtmRemove, bNewWindow, bExpanded, iSort
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