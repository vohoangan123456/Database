INSERT INTO #Description VALUES ('Create tables, types and procedures to support for feature Event Logs on User, Role, Department')
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UserLogs]') AND type in (N'U'))
	CREATE TABLE [dbo].[UserLogs](
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        UpdatedEmployeeId INT NOT NULL,
        EmployeeId INT NOT NULL,
        Time DATETIME NOT NULL,
        Type INT NOT NULL,
        Description NVARCHAR(MAX) NOT NULL
	)
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_UserLogs_Employee_UpdatedEmployeeId')
BEGIN
	ALTER TABLE [dbo].[UserLogs] ADD CONSTRAINT FK_UserLogs_Employee_UpdatedEmployeeId FOREIGN KEY (UpdatedEmployeeId)
        REFERENCES [dbo].[tblEmployee] (iEmployeeId)
END
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_UserLogs_Employee_EmployeeId')
BEGIN
	ALTER TABLE [dbo].[UserLogs] ADD CONSTRAINT FK_UserLogs_Employee_EmployeeId FOREIGN KEY (EmployeeId)
        REFERENCES [dbo].[tblEmployee] (iEmployeeId)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DepartmentLogs]') AND type in (N'U'))
	CREATE TABLE [dbo].[DepartmentLogs](
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        DepartmentId INT NOT NULL,
        EmployeeId INT NOT NULL,
        Time DATETIME NOT NULL,
        Type INT NOT NULL,
        Description NVARCHAR(MAX) NOT NULL
	)
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_DepartmentLogs_Department')
BEGIN
	ALTER TABLE [dbo].[DepartmentLogs] ADD CONSTRAINT FK_DepartmentLogs_Department FOREIGN KEY (DepartmentId)
        REFERENCES [dbo].[tblDepartment] (iDepartmentId)
END
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_DepartmentLogs_Employee')
BEGIN
	ALTER TABLE [dbo].[DepartmentLogs] ADD CONSTRAINT FK_DepartmentLogs_Employee FOREIGN KEY (EmployeeId)
        REFERENCES [dbo].[tblEmployee] (iEmployeeId)
END
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[RoleLogs]') AND type in (N'U'))
	CREATE TABLE [dbo].[RoleLogs](
        Id INT IDENTITY(1, 1) PRIMARY KEY,
        RoleId INT NOT NULL,
        EmployeeId INT NOT NULL,
        Time DATETIME NOT NULL,
        Type INT NOT NULL,
        Description NVARCHAR(MAX) NOT NULL
	)
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_RoleLogs_SecGroup')
BEGIN
	ALTER TABLE [dbo].[RoleLogs] ADD CONSTRAINT FK_RoleLogs_SecGroup FOREIGN KEY (RoleId)
        REFERENCES [dbo].[tblSecGroup] (iSecGroupId)
END
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='FK_RoleLogs_Employee')
BEGIN
	ALTER TABLE [dbo].[RoleLogs] ADD CONSTRAINT FK_RoleLogs_Employee FOREIGN KEY (EmployeeId)
        REFERENCES [dbo].[tblEmployee] (iEmployeeId)
END
GO

-- Types
IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'RoleLogType' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[RoleLogType] AS TABLE
    (
        RoleId INT, 
        EmployeeId INT,
        Time DATETIME,
        Type INT,
        Description NVARCHAR(MAX)
    )
GO

-- Procedures
IF OBJECT_ID('[dbo].[AddUserLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddUserLog] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[AddUserLog] 
    @UpdatedEmployeeId INT,
    @EmployeeId INT,
    @Time DATETIME,
    @Type INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
	INSERT INTO
        UserLogs
            (UpdatedEmployeeId, EmployeeId, Time, Type, Description)
        VALUES
            (@UpdatedEmployeeId, @EmployeeId, @Time, @Type, @Description);
END
GO

IF OBJECT_ID('[dbo].[GetUserLogsByEmployeeId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserLogsByEmployeeId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserLogsByEmployeeId] 
    @EmployeeId INT
AS
BEGIN
	SELECT Id, UpdatedEmployeeId, 
        EmployeeId, strFirstName + ' ' + strLastName AS EmployeeName, strLoginName AS LoginName, Time, Type, Description
    FROM UserLogs ul
        INNER JOIN tblEmployee e ON ul.EmployeeId = e.iEmployeeId
    WHERE ul.EmployeeId = @EmployeeId
    ORDER BY Time DESC
END
GO

IF OBJECT_ID('[dbo].[AddDepartmentLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddDepartmentLog] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[AddDepartmentLog] 
    @DepartmentId INT,
    @EmployeeId INT,
    @Time DATETIME,
    @Type INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
	INSERT INTO
        DepartmentLogs
            (DepartmentId, EmployeeId, Time, Type, Description)
        VALUES
            (@DepartmentId, @EmployeeId, @Time, @Type, @Description);
END
GO

IF OBJECT_ID('[dbo].[GetDepartmentLogsByDepartmentId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetDepartmentLogsByDepartmentId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetDepartmentLogsByDepartmentId] 
    @DepartmentId INT
AS
BEGIN
	SELECT Id, DepartmentId, 
        EmployeeId, strFirstName + ' ' + strLastName AS EmployeeName, strLoginName AS LoginName, Time, Type, Description
    FROM DepartmentLogs dl
        INNER JOIN tblEmployee e ON dl.EmployeeId = e.iEmployeeId
    WHERE dl.DepartmentId = @DepartmentId
    ORDER BY Time DESC
END
GO

IF OBJECT_ID('[dbo].[AddRoleLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddRoleLog] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[AddRoleLog] 
    @RoleId INT,
    @EmployeeId INT,
    @Time DATETIME,
    @Type INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
	INSERT INTO
        RoleLogs
            (RoleId, EmployeeId, Time, Type, Description)
        VALUES
            (@RoleId, @EmployeeId, @Time, @Type, @Description);
END
GO

IF OBJECT_ID('[dbo].[AddRoleLogs]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddRoleLogs] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[AddRoleLogs] 
    @RoleLogs as dbo.RoleLogType READONLY
AS
BEGIN
	INSERT INTO
        RoleLogs
            (RoleId, EmployeeId, Time, Type, Description)
        SELECT RoleId, EmployeeId, Time, Type, Description
        FROM @RoleLogs
END
GO

IF OBJECT_ID('[dbo].[GetRoleLogsByRoleId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetRoleLogsByRoleId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetRoleLogsByRoleId] 
    @RoleId INT
AS
BEGIN
	SELECT Id, RoleId, 
        EmployeeId, strFirstName + ' ' + strLastName AS EmployeeName, strLoginName AS LoginName, Time, Type, Description
    FROM RoleLogs dl
        INNER JOIN tblEmployee e ON dl.EmployeeId = e.iEmployeeId
    WHERE dl.RoleId = @RoleId
    ORDER BY Time DESC
END
GO

IF OBJECT_ID('[dbo].[AddUserLog]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[AddUserLog] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[AddUserLog] 
    @UpdatedEmployeeId INT,
    @EmployeeId INT,
    @Time DATETIME,
    @Type INT,
    @Description NVARCHAR(MAX)
AS
BEGIN
	INSERT INTO
        UserLogs
            (UpdatedEmployeeId, EmployeeId, Time, Type, Description)
        VALUES
            (@UpdatedEmployeeId, @EmployeeId, @Time, @Type, @Description);
END
GO

IF OBJECT_ID('[dbo].[GetUserLogsByEmployeeId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserLogsByEmployeeId] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetUserLogsByEmployeeId] 
    @UpdatedEmployeeId INT
AS
BEGIN
	SELECT Id, UpdatedEmployeeId, 
        EmployeeId, strFirstName + ' ' + strLastName AS EmployeeName, strLoginName AS LoginName, Time, Type, Description
    FROM UserLogs ul
        INNER JOIN tblEmployee e ON ul.EmployeeId = e.iEmployeeId
    WHERE ul.UpdatedEmployeeId = @UpdatedEmployeeId
    ORDER BY Time DESC
END
GO