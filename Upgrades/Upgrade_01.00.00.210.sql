INSERT INTO #Description VALUES('Get active metadata registers')
GO

IF OBJECT_ID('[dbo].[m147_be_GetActiveRegisters]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetActiveRegisters] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_be_GetActiveRegisters]
(
	@iSecurityId INT
)
AS
BEGIN
	SELECT * 
	FROM m147_tblRegister 
	WHERE (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, iRegisterId) & 1) = 1
		   AND bObsolete = 0 AND bKladd = 0
END
GO