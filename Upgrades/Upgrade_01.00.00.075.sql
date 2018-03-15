INSERT INTO #Description VALUES('Update seed to insert new data for feedback and readConfirm table')
GO

DECLARE @maxRecordsInTblFeedback INT
SELECT @maxRecordsInTblFeedback = COUNT(*) FROM m136_tblFeedback
SET  @maxRecordsInTblFeedback = @maxRecordsInTblFeedback + 1;
DBCC CHECKIDENT('[dbo].[m136_tblFeedback]', RESEED, @maxRecordsInTblFeedback);

DECLARE @maxRecordsInTblConfirmRead INT
SELECT @maxRecordsInTblConfirmRead = COUNT(*) FROM m136_tblConfirmRead
SET  @maxRecordsInTblConfirmRead = @maxRecordsInTblConfirmRead + 1;
DBCC CHECKIDENT('[dbo].[m136_tblConfirmRead]', RESEED, @maxRecordsInTblConfirmRead);