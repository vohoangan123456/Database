INSERT INTO #Description VALUES ('RoleLogs - update details')
GO
IF OBJECT_ID('[dbo].[AddDetailRoleLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddDetailRoleLog]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[AddDetailRoleLog] 
    @RoleLogID INT,
    @HandbookId INT,
    @Recursive BIT
AS
BEGIN
	INSERT INTO
        DetailRoleLogs
            (RoleLogId, HandbookId, Recursive)
        VALUES
            (@RoleLogId, @HandbookId, @Recursive);
END

GO

IF OBJECT_ID('[dbo].[AddDetailRoleLogs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddDetailRoleLogs]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[AddDetailRoleLogs] 
    @DetailRoleLogs as dbo.DetailRoleLogType READONLY
AS
BEGIN
	INSERT INTO
        DetailRoleLogs
            (RoleLogId, HandbookId, Recursive)
        SELECT RoleLogId, HandbookId, Recursive
        FROM @DetailRoleLogs
END

GO

IF OBJECT_ID('[dbo].[GetRoleLogsByRoleId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetRoleLogsByRoleId]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetRoleLogsByRoleId] 
    @RoleId INT
AS
BEGIN
	SELECT dl.Id, RoleId, 
        EmployeeId, strFirstName + ' ' + strLastName AS EmployeeName, strLoginName AS LoginName, Time, Type, Description
    FROM RoleLogs dl
        INNER JOIN tblEmployee e ON dl.EmployeeId = e.iEmployeeId
    WHERE dl.RoleId = @RoleId
    ORDER BY Time DESC
    
    SELECT d.ID, d.HandbookId, d.RoleLogID, d.Recursive, h.strName as HandbookName
    FROM DetailRoleLogs d
    LEFT JOIN RoleLogs dl ON d.RoleLogID = dl.Id
    LEFT JOIN dbo.m136_tblHandbook h ON d.HandbookId = h.iHandbookId
    WHERE dl.RoleId = @RoleId
    
END

GO
