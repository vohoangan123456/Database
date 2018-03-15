INSERT INTO #Description VALUES ('Support Risk management module')
GO

IF NOT EXISTS(SELECT * FROM dbo.tblApplication ta WHERE ta.iApplicationId = 170)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) 
	VALUES (170, N'RiskManagement', N'Risk Management', 1, 0, 0, 0, 0, N'', N'')
END
GO

IF NOT EXISTS(SELECT * FROM dbo.tblPermissionSet tps WHERE tps.iPermissionSetId = 800)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) 
	VALUES (800, 2, N'RMRole', N'Risk management role')
END
GO