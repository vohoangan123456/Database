INSERT INTO #Description VALUES('Update change name of role with id = 0')
GO

IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'tblSecGroup') AND type in (N'U'))
BEGIN
	UPDATE [dbo].[tblSecGroup] SET strName = 'Rollehendelser' WHERE iSecGroupId = 0
END

GO