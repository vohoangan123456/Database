INSERT INTO #Description VALUES ('Implement PBI [B-13683] PoC - Forms Authentication with Active Directory in Multiple Domains')
GO

IF NOT (EXISTS (SELECT * 
                 FROM INFORMATION_SCHEMA.TABLES 
                 WHERE TABLE_SCHEMA = 'dbo' 
                 AND  TABLE_NAME = 'luDomains'))
BEGIN
    CREATE TABLE [dbo].[luDomains](
		[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[Domain] [nvarchar](100) NOT NULL,
		[MembershipProvider] [nvarchar](250) NOT NULL
	 CONSTRAINT [PK_dbo_luDomains_PK] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF OBJECT_ID('[dbo].[GetDomainProviders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetDomainProviders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetDomainProviders] 

AS
BEGIN
	SET NOCOUNT ON;
	SELECT * FROM dbo.luDomains ld
END
GO