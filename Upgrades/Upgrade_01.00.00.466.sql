INSERT INTO #Description VALUES (' Alter table AnnualCycles - add columns AnnualCycles, UpdatedDate and UpdatedBy')
GO

IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Calendar].[AnnualCycles]') 
         AND name = 'CreatedDate'
)
 BEGIN
	  ALTER TABLE [Calendar].[AnnualCycles] ADD CreatedDate DATETIME NULL
 END
 GO
 
IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Calendar].[AnnualCycles]') 
         AND name = 'UpdatedBy'
)
 BEGIN
	  ALTER TABLE [Calendar].[AnnualCycles] ADD UpdatedBy INT NULL
 END
 
 IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[Calendar].[AnnualCycles]') 
         AND name = 'UpdatedDate'
)
 BEGIN
	  ALTER TABLE [Calendar].[AnnualCycles] ADD UpdatedDate DATETIME NULL
 END
 GO
 
