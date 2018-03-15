INSERT INTO #Description VALUES ('modify SP [dbo].[m147_be_GetRegisterRegisterItemForDocument]')
GO

IF OBJECT_ID('[dbo].[m147_be_GetRegisterRegisterItemForDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m147_be_GetRegisterRegisterItemForDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m147_be_GetRegisterRegisterItemForDocument]
    @UserId INT,
    @Id INT,
    @IsHandbook BIT
AS
BEGIN
    DECLARE @HandbookId INT;
    IF @IsHandbook = 0
    BEGIN
		SET @HandbookId = (SELECT TOP 1 iHandbookId FROM m136_tblDocument WHERE iDocumentId = @Id);
	END
	ELSE
		SET @HandbookId = @Id
		
    SELECT
        r.strName + ' - ' + ri.strName AS strRegisterRegisterName,
        r.iRegisterId,
        ric.iRegisterItemId
    FROM
        m147_relRegisterItemCategory ric
            INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
    WHERE
        ric.iModuleId = 136
        AND ric.iInheritTypeId IN (1, 2, 3, 5)
        AND ric.iCategoryId IN (SELECT iHandbookId
                                FROM dbo.m136_GetParentidsInTbl(@HandbookId))
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
    UNION
    SELECT
        r.strName + ' - ' + ri.strname,
        r.iRegisterId,
        ric.iRegisterItemId
    FROM
        m147_relRegisterItemCategory ric
            INNER JOIN m147_tblRegisterItem ri ON ric.iRegisterItemId = ri.iRegisterItemId
            INNER JOIN m147_tblRegister r ON ri.iRegisterId = r.iRegisterId
    WHERE
        iModuleId = 136
        AND iCategoryId = @HandbookId
        AND ric.iInheritTypeId IN (1, 2, 3, 5)
        AND dbo.fnSecurityGetPermission(147, 571, @UserId, r.iRegisterId) & 0x01 = 0x01
END
GO
