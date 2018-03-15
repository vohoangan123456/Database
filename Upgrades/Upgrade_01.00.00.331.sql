INSERT INTO #Description VALUES ('Implement PBI [B-13683] PoC - Forms Authentication with Active Directory in Multiple Domains (cont)')
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'ConnectionString'
      AND Object_ID = Object_ID(N'dbo.luDomains'))
BEGIN
    ALTER TABLE dbo.luDomains ADD [ConnectionString] [nvarchar](250)
END
GO