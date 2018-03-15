INSERT INTO #Description VALUES('Create stored procedures for department management.')
GO

IF OBJECT_ID('[dbo].[m136_be_CheckDepartmentsTobeDeleted]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CheckDepartmentsTobeDeleted] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CheckDepartmentsTobeDeleted]
	@iDepartmentId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT COUNT(1) FROM dbo.tblEmployee te WHERE te.iDepartmentId = @iDepartmentId;
END
GO