INSERT INTO #Description VALUES ('Modify function m136_fnGetDocumentExpiryDate')
GO

IF OBJECT_ID('[dbo].[m136_fnGetDocumentExpiryDate]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[m136_fnGetDocumentExpiryDate]() RETURNS DATETIME AS BEGIN RETURN NULL; END')
GO
ALTER function [dbo].[m136_fnGetDocumentExpiryDate](@documentId int) 
returns datetime
as
begin
	declare @r datetime
	select @r = dtmPublishUntil from m136_tblDocument where iLatestApproved = 1 and iDocumentId = @documentId
	return @r
end
GO
