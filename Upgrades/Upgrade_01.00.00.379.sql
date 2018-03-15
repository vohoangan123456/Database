INSERT INTO #Description VALUES ('Modify SP [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] to get internet document')
GO

IF OBJECT_ID('[dbo].[m147_GetRegisterAndRegisterItems]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_GetRegisterAndRegisterItems] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m147_GetRegisterAndRegisterItems]
(
	@iSecurityId int
)
AS
BEGIN

	SELECT a.iRegisterItemId,a.iRegisterItemParentId, a.iRegisterId,
		r.strName + ' : ' + a.strName AS strName, a.strDescription, a.eTypeId, a.bMandatory, a.bAllowMultiple,
		b.strName AS strEtype 
	FROM dbo.m147_tblRegister r
	INNER JOIN m147_tblRegisterItem a ON r.iRegisterId = a.iRegisterId
	INNER JOIN m147_tblEtype b ON a.eTypeId = b.eTypeId
	WHERE a.iRegisterItemId IS NOT NULL
	 AND (dbo.fnSecurityGetPermission(147, 571, @iSecurityId, a.iRegisterId) & 1) = 1
END
GO