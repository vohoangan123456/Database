INSERT INTO #Description VALUES ('Updated Sp [dbo].[m136_be_GetHearingsToEnded]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetHearingsToEnded]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHearingsToEnded] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetHearingsToEnded] 
AS
BEGIN
	SELECT *
	FROM dbo.m136_Hearings
	WHERE IsActive = 1
		  AND CONVERT(date, DueDate) < CONVERT(date, GETDATE())
END
GO
