INSERT INTO #Description VALUES ('Add View [m136_DocumentCanApprove] And modify SP')
GO

IF EXISTS(select * FROM sys.views where name = '[m136_DocumentCanApprove]')
BEGIN
	DROP VIEW [m136_DocumentCanApprove];
END
GO

CREATE VIEW [m136_DocumentCanApprove] AS
SELECT d.iEntityId, d.iMetaInfoTemplateRecordsId, COUNT(mi.iEntityId) AS d1,COUNT(mit.iEntityId) AS d2, COUNT(mir.iEntityId) AS d3,COUNT(mid.iEntityId) AS d4 
FROM (SELECT
	d.iEntityId,
	dti.iMetaInfoTemplateRecordsId
FROM
	m136_tblDocument d
		INNER JOIN m136_tblDocumentType dt
			ON d.iDocumentTypeId = dt.iDocumentTypeId
		INNER JOIN m136_relDocumentTypeInfo dti
			ON dt.iDocumentTypeId = dti.iDocumentTypeId
WHERE
		dti.iDeleted = 0
	AND dti.iMandatory = 1) AS d
LEFT JOIN m136_tblMetaInfoNumber mi ON mi.iEntityId = d.iEntityId
		AND mi.iMetaInfoTemplateRecordsId = d.iMetaInfoTemplateRecordsId
		AND mi.[value] IS NOT NULL
LEFT JOIN m136_tblMetaInfoText mit ON  mit.iEntityId = d.iEntityId
		AND mit.iMetaInfoTemplateRecordsId = d.iMetaInfoTemplateRecordsId
		AND mit.[value] <> '' 
LEFT JOIN m136_tblMetaInfoRichText mir ON  mir.iEntityId = d.iEntityId
		AND mir.iMetaInfoTemplateRecordsId = d.iMetaInfoTemplateRecordsId
		AND cast(mir.[value] as nvarchar(max)) <> ''
LEFT JOIN m136_tblMetaInfoDate mid ON  mid.iEntityId = d.iEntityId
		AND mid.iMetaInfoTemplateRecordsId = d.iMetaInfoTemplateRecordsId
		AND mid.[value] IS NOT NULL
GROUP BY d.iEntityId, d.iMetaInfoTemplateRecordsId
GO

IF OBJECT_ID('[dbo].[fnDocumentCanBeApproved]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnDocumentCanBeApproved]() RETURNS BIT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnDocumentCanBeApproved] 
(
	@EntityId INT = NULL
) RETURNS BIT
AS
BEGIN
	DECLARE @Result BIT;
    DECLARE @NumberOfRequiredRecordsInDocumentTemplate INT;
    DECLARE @NumberOfValidRecordsInDocument INT;
    IF @EntityId = NULL
    BEGIN
        SET @Result = 0;
    END
    ELSE
    BEGIN
		SELECT @NumberOfRequiredRecordsInDocumentTemplate = COUNT(*),
		@NumberOfValidRecordsInDocument = ISNULL(SUM(d1), 0) + ISNULL(SUM(d2), 0) + ISNULL(SUM(d3), 0) + ISNULL(SUM(d4), 0)
		FROM [dbo].[m136_DocumentCanApprove]
		WHERE iEntityId = @EntityId
		
        IF @NumberOfRequiredRecordsInDocumentTemplate = @NumberOfValidRecordsInDocument 
        BEGIN
            SET @Result = 1;
        END
        ELSE
        BEGIN
            SET @Result = 0;
        END
    END
    RETURN @Result;
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetBreadCrumbsSubfolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetBreadCrumbsSubfolders] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetBreadCrumbsSubfolders]
	@iHandbookId INT = NULL,
	@iSecurityId INT,
	@bShowDocumentsInTree BIT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT	
        h.iHandbookId as Id,
        -1 as iEntityId,
        h.iHandbookId,
        h.strName,
        -1 as iDocumentTypeId,
        iLevelType as LevelType,
        h.iDepartmentId as DepartmentId,
        0 as Virtual,
        h.iSort,
        dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
        0 as HasAttachment,
        dbo.fnSecurityGetPermission(136, 462, @iSecurityId, h.iHandbookId) as iAccess,
        h.iCreatedbyId,
        0 as iInternetDoc,
        h.iParentHandbookId,
        [dbo].[fn136_be_GetChildCount] (@iSecurityId, h.iHandbookId, @bShowDocumentsInTree) AS iChildCount,
        h.iDeleted,
        h.iHandbookId AS VirtualHandbookId
    FROM
        m136_tblHandbook as h
    WHERE
        (h.iParentHandbookId = @iHandbookId OR (h.iParentHandbookId IS NULL AND @iHandbookId IS NULL))
        AND h.iDeleted = 0
	ORDER BY iSort, h.strName;
END
GO

