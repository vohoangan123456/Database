INSERT INTO #Description VALUES ('Insert data into table tblPermissionSet and tblPermissionBit')
GO

IF NOT EXISTS (
  SELECT TOP 1 1
  FROM dbo.tblPermissionSet 
  WHERE iPermissionSetId = 96
)
BEGIN
	INSERT INTO dbo.tblPermissionSet (iPermissionSetId, iPermissionSetTypeId, strName, strDescription)
	VALUES (96, 1, 'scr.secgroup.admin.privileges', 'scr.perm.manage.secgroups')
END
GO
 
IF NOT EXISTS (
	SELECT TOP 1 1
	FROM dbo.tblPermissionBit 
	WHERE iPermissionSetId = 96 AND iBitNumber = 1
)
BEGIN
	INSERT INTO dbo.tblPermissionBit (iBitNumber, iPermissionSetId, strName, strDescription)
	VALUES (1, 96, 'scr.add.user', 'scr.add.user.secgroup')
END
GO

IF NOT EXISTS (
	SELECT TOP 1 1
	FROM dbo.tblPermissionBit 
	WHERE iPermissionSetId = 96 AND iBitNumber = 2
)
BEGIN
	INSERT INTO dbo.tblPermissionBit (iBitNumber, iPermissionSetId, strName, strDescription)
	VALUES (2, 96, 'scr.remove.user', 'scr.remove.user.secgroup')
END
GO