INSERT INTO #Description VALUES ('Create procedure CheckUserPassword')
GO

IF OBJECT_ID('[dbo].[CheckUserPassword]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[CheckUserPassword] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[CheckUserPassword]
	@EmployeeId [int],
	@Password [varchar](32)
AS
BEGIN
    IF EXISTS (SELECT 1 FROM tblEmployee WHERE iEmployeeId = @EmployeeId AND strPassword = @Password)
    BEGIN
        SELECT 1
    END
    ELSE
    BEGIN
        SELECT 0
    END
END
GO