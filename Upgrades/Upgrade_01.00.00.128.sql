INSERT INTO #Description VALUES('Add one more document permission for managing documents')
GO

IF NOT EXISTS (SELECT COUNT(1) FROM [dbo].[tblPermissionBit] WHERE [iPermissionSetId] = 462 AND [iBitNumber] = 32)
BEGIN
	INSERT INTO [dbo].[tblPermissionBit]
           ([iBitNumber]
           ,[iPermissionSetId]
           ,[strName]
           ,[strDescription])
     VALUES
           (32
           ,462
           ,'A'
           ,'Administrere dokumenter')
END
GO


