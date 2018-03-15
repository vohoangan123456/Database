INSERT INTO #Description VALUES('Add reversed columns for title and description to m136_tblDocument. Add trigger to autofill these new columns. Add to full-text')
GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[m136_tblDocument]') 
         AND name = 'strNameReversed'
)
 BEGIN
 /*Column does not exist*/
	ALTER TABLE [dbo].[m136_tblDocument]
	ADD [strNameReversed] VARCHAR (200)
 END
 GO

IF NOT EXISTS (
  SELECT * 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'[dbo].[m136_tblDocument]') 
         AND name = 'strDescriptionReversed'
)
 BEGIN
 /*Column does not exist */
	ALTER TABLE [dbo].[m136_tblDocument]
	ADD [strDescriptionReversed] VARCHAR (2000)
 END
 GO

update m136_tblDocument 
set strNameReversed = REVERSE(strName) ,strDescriptionReversed = REVERSE(strDescription) 
where iLatestApproved = 1
GO


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DocumentNameAndDescriptionReversal]') AND type in (N'TR'))
	EXEC ('CREATE TRIGGER [dbo].[DocumentNameAndDescriptionReversal]  ON  [dbo].[m136_tblDocument] AFTER UPDATE, INSERT AS SELECT 2')
GO

ALTER TRIGGER [dbo].[DocumentNameAndDescriptionReversal]
   ON  [dbo].[m136_tblDocument]
   AFTER UPDATE, INSERT
AS 
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	IF UPDATE (strName) 
    begin

        UPDATE [dbo].[m136_tblDocument] 
        SET strNameReversed = REVERSE(D.strName)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
    
    IF UPDATE (strDescription) 
    begin

        UPDATE [dbo].[m136_tblDocument] 
        SET strDescriptionReversed = REVERSE(D.strDescription)
        FROM [dbo].[m136_tblDocument] D JOIN inserted I ON D.iEntityId = I.iEntityId
    end 
END
GO

