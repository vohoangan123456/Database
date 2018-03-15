INSERT INTO #Description VALUES ('RoleLogs - update store procedure AddRoleLog')
GO
IF OBJECT_ID('[dbo].[AddRoleLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddRoleLog]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[AddRoleLog] 
    @RoleId INT,
    @EmployeeId INT,
    @Time DATETIME,
    @Type INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
	DECLARE @RoleLogId INT;
	INSERT INTO
        RoleLogs
            (RoleId, EmployeeId, Time, Type, Description)
        VALUES
            (@RoleId, @EmployeeId, @Time, @Type, @Description);
    SET @RoleLogId = SCOPE_IDENTITY();  
    SELECT @RoleLogId
END

GO