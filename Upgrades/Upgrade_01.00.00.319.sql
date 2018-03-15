INSERT INTO #Description VALUES ('Add SP [dbo].[m136_be_AddRoleMembers]')
GO


IF OBJECT_ID('[dbo].[m136_be_AddRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_AddRoleMembers] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_AddRoleMembers]
	@EmployeeIds AS [dbo].[Item] READONLY,
	@iRoleId INT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO dbo.relEmployeeSecGroup
	(
	    iEmployeeId,
	    iSecGroupId
	)
	SELECT id, @iRoleId
	FROM @EmployeeIds t
	    WHERE NOT EXISTS (SELECT resg.* FROM dbo.relEmployeeSecGroup resg WHERE resg.iEmployeeId = t.Id AND resg.iSecGroupId = @iRoleId);
END
GO
