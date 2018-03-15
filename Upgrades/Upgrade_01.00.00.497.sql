INSERT INTO #Description VALUES ('Update CanUserAccessToActivityForCalendarView function')
GO

ALTER FUNCTION [dbo].[CanUserAccessToActivityForCalendarView]
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