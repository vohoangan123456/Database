INSERT INTO #Description VALUES ('RoleLogs - create table detail RoleLogs')
GO

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'DetailRoleLogs') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[DetailRoleLogs](
		[ID] [int] IDENTITY(1,1) NOT NULL,
		[RoleLogID] [int] NOT NULL,
		[HandbookId] [int] NULL,
		[Recursive] [bit] NULL,
	 CONSTRAINT [PK_DetailRoleLogs] PRIMARY KEY CLUSTERED 
	(
		[ID] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[DetailRoleLogs]  WITH CHECK ADD  CONSTRAINT [FK_DetailRoleLogs_DetailRoleLogs] FOREIGN KEY([RoleLogID])
	REFERENCES [dbo].[RoleLogs] ([Id])

	ALTER TABLE [dbo].[DetailRoleLogs] CHECK CONSTRAINT [FK_DetailRoleLogs_DetailRoleLogs]
END

GO
IF NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'DetailRoleLogType' AND ss.name = N'dbo')
BEGIN
/****** Object:  UserDefinedTableType [dbo].[DetailRoleLogType]    Script Date: 12/19/2017 17:08:26 ******/
CREATE TYPE [dbo].[DetailRoleLogType] AS TABLE(
	[RoleLogId] [int] NULL,
	[HandbookId] [int] NULL,
	[Recursive] [bit] NULL
)
END
GO
