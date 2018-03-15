INSERT INTO #Description VALUES ('Increase size of dbo.tblSecGroup.strName from 50 to 250')
GO

ALTER TABLE dbo.tblSecGroup ALTER COLUMN strName varchar(250)
GO





