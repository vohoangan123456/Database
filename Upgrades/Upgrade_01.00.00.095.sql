INSERT INTO #Description VALUES('Create stored procedures roles management.')
GO

IF OBJECT_ID('[dbo].[m136_be_InsertSecurityGroup]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_InsertSecurityGroup] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.VAN.LAM.MAI
-- Create date: JULY 22, 2015
-- Description:	Insert new security group
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_InsertSecurityGroup]
	@strName VARCHAR(50),
	@strDescription VARCHAR(1000)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @iMaxSecGroupId INT;
	SELECT @iMaxSecGroupId = MAX(tsg.iSecGroupId) FROM  dbo.tblSecGroup tsg;
	DECLARE @NewSecGroupId INT = (@iMaxSecGroupId + 1);
	
	INSERT INTO dbo.tblSecGroup
	(
	    iSecGroupId,
	    strName,
	    strDescription
	)
	VALUES
	(
	    @NewSecGroupId, -- iSecGroupId - int
	    @strName, -- strName - varchar
	    @strDescription -- strDescription - varchar
	);
	
	SELECT @NewSecGroupId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetRoleMembers] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 23, 2015
-- Description:	Get role members 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetRoleMembers]
	@RoleId INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT te.iEmployeeId
		, te.strFirstName
		, te.strLastName
		, te.strLoginName
		, td.strName AS strDepartment
    FROM dbo.tblEmployee te 
		INNER JOIN dbo.relEmployeeSecGroup resg
			ON resg.iEmployeeId = te.iEmployeeId
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
	WHERE resg.iSecGroupId = @RoleId;
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteSecurityGroups]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteSecurityGroups] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Delete roles
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteSecurityGroups]
	@SecurityGroupIds AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DELETE dbo.relEmployeeSecGroup WHERE dbo.relEmployeeSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
	
    DELETE dbo.tblSecGroup WHERE dbo.tblSecGroup.iSecGroupId IN (SELECT Id FROM @SecurityGroupIds);
    
END
GO

IF OBJECT_ID('[dbo].[m136_be_SearchRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchRoleMembers] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Search member by name, username....
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_SearchRoleMembers] 
	@iDepartmentId INT,
	@iRoleId INT,
	@strKeyword VARCHAR(100)
AS
BEGIN
	SET NOCOUNT ON;

	SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strLoginName, td.strName AS strDepartment 
	FROM dbo.tblEmployee te
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
		--LEFT JOIN dbo.relEmployeeSecGroup resg ON resg.iEmployeeId = te.iEmployeeId
		WHERE (te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL OR @iDepartmentId = 0)
		AND (te.strLoginName LIKE '%' + @strKeyword + '%' 
			OR te.strFirstName LIKE '%' + @strKeyword + '%' 
			OR te.strLastName LIKE '%' + @strKeyword + '%')
		AND (@iRoleId IS NULL OR te.iEmployeeId NOT IN (SELECT resg.iEmployeeId 
			FROM dbo.relEmployeeSecGroup resg WHERE resg.iSecGroupId = @iRoleId));
END
GO

IF OBJECT_ID('[dbo].[m136_be_AddRoleMember]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_AddRoleMember] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Adding role members
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_AddRoleMember]
	@iEmployeeId INT,
	@iRoleId INT
AS
BEGIN
	SET NOCOUNT ON;

	INSERT INTO dbo.relEmployeeSecGroup
	(
	    iEmployeeId,
	    iSecGroupId
	)
	SELECT @iEmployeeId, @iRoleId
	    WHERE NOT EXISTS (SELECT resg.* FROM dbo.relEmployeeSecGroup resg WHERE resg.iEmployeeId = @iEmployeeId AND resg.iSecGroupId = @iRoleId);
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteRoleMembers] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: JULY 24, 2015
-- Description:	Delete employee security groups
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteRoleMembers]
	@iRoleId INT,
	@MemberIds AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	DELETE dbo.relEmployeeSecGroup WHERE iEmployeeId IN (SELECT Id FROM @MemberIds)
	AND (iSecGroupId = @iRoleId);
END
GO