INSERT INTO #Description VALUES ('Modify Sp for reopen multiple documents')
GO

IF OBJECT_ID('[dbo].[m136_be_GetChapterEmployeeSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetChapterEmployeeSums] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetChapterEmployeeSums] 
(
	@iSecurityId INT = 0,
	@iHandbookId INT = 0,
	@iDepartmentId INT = 0,
	@fromDate DATETIME = null,
	@toDate DATETIME = null,
	@iRecursive INT = 0,
	@iRecursiveDepartment INT = 0
)
AS
BEGIN

	IF @toDate IS NOT NULL
	BEGIN
		SET @toDate = dateadd(day, 1, @toDate)
	END

	DECLARE @HandbookIdTable TABLE(iHandbookId INT)
	
	IF @iHandbookId IS NOT NULL AND @iHandbookId <> 0
	BEGIN
		IF @iRecursive = 1
		BEGIN
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM 
				[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		END
		ELSE
			INSERT INTO @HandbookIdTable(iHandbookId) VALUES(@iHandbookId);
	END
	ELSE
	BEGIN
		IF @iRecursive = 1
		BEGIN
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1;
		END
		ELSE
			INSERT INTO @HandbookIdTable(iHandbookId)
			SELECT 
				iHandbookId 
			FROM dbo.m136_tblHandbook
			WHERE iDeleted = 0
				  AND [dbo].[fnHandbookHasReadContentsAccess](@iSecurityId, iHandbookId) = 1
				  AND iParentHandbookId IS NULL;
	END
	
	--Mappeutdrag:
	DECLARE @bookTable TABLE(iHandbookId INT NOT NULL, strChapterName VARCHAR(400) NULL, strParentPath VARCHAR(1000) NULL)
	INSERT INTO @bookTable
	SELECT
		iHandbookId,
		strName,
		dbo.fn136_GetParentPath(iHandbookId)
	FROM
		m136_tblHandbook
	WHERE
		iHandbookId IN (SELECT iHandbookId FROM @HandbookIdTable)
		AND iDeleted=0
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01)>0 

	--Dokumentutdrag:
	DECLARE @docTable TABLE(iEntityId INT NULL, iDocumentId INT NULL, strName VARCHAR(200) NULL, iVersion INT NULL,
							 iHandbookId INT NULL, iSort INT NULL, iVirt INT NOT NULL,
							 dtmPublish DATETIME NULL, dtmPublishUntil DATETIME NULL, iDraft INT NULL,iApproved INT NULL)
	INSERT INTO @docTable
	SELECT	doc.iEntityId,
		doc.iDocumentId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		doc.iSort,
		0,
		doc.dtmPublish,
		doc.dtmPublishUntil,
		doc.iDraft,
		doc.iApproved
	FROM
		@bookTable book
		RIGHT JOIN m136_tblDocument doc 
			ON doc.iHandbookId = book.iHandbookId
	WHERE
		doc.iHandbookId = book.iHandbookId
		AND iApproved = 1
		AND doc.iDeleted=0
		AND iLatestApproved = 1

	--virtual
	INSERT INTO @docTable
	SELECT 	doc.iEntityId,
		virt.iDocumentId,
		doc.strName,
		doc.iVersion,
		virt.iHandbookId,
		virt.iSort,
		1,
		doc.dtmPublish,
		doc.dtmPublishUntil,
		doc.iDraft,
		doc.iApproved
	FROM
		m136_relVirtualRelation virt
		LEFT JOIN m136_tblDocument doc ON doc.iDocumentId = virt.iDocumentId
		RIGHT JOIN @bookTable book ON book.iHandbookId = virt.iHandbookId
	WHERE
		doc.iApproved=1
		AND doc.iDeleted=0
		AND iLatestApproved = 1

	--Ansatt-utdrag
	DECLARE @empTable TABLE(iEmployeeId INT NULL, strFirstName VARCHAR(100) NULL, strLastName VARCHAR(100) NULL, iDepartmentId INT NULL)
	
	--Security, see own org-unit's reports?
	DECLARE @moduleAccess INT
	SET @moduleAccess = dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0)
	IF((@moduleAccess&4)=4)
	BEGIN
		DECLARE @iUserDepartmentId INT
		SELECT @iUserDepartmentId= iDepartmentId FROM tblEmployee WHERE iEmployeeId=@iSecurityId
		INSERT INTO @empTable
			SELECT
				iEmployeeId,
				strFirstName,
				strLastName,
				iDepartmentId
			FROM
				tblEmployee
			WHERE
				(iDepartmentId = @iDepartmentId 
				OR @iDepartmentId=0)
				AND iDepartmentId > 0
				AND iDepartmentId = @iUserDepartmentId
	END
	
	--Modul-administrator?
	IF((@moduleAccess&2)=2)
	BEGIN
		DELETE FROM @empTable
		DECLARE @Departments TABLE (iDepartmentId INT)
		IF (@iRecursiveDepartment = 0)
			BEGIN
				INSERT INTO @Departments SELECT @iDepartmentId;
			END
		ELSE
			BEGIN
				INSERT INTO @Departments SELECT iDepartmentId FROM dbo.m136_GetDepartmentsRecursive (@iDepartmentId);
			END
			
		INSERT INTO @empTable
		SELECT
			iEmployeeId,
			strFirstName,
			strLastName,
			iDepartmentId
		FROM
			tblEmployee
		WHERE
			iDepartmentId IN (SELECT iDepartmentId FROM @Departments) 
	END
	--Confirm-table utdrag
	DECLARE @cTable TABLE(iEntityId INT NOT NULL, iEmployeeId INT, dtmConfirm DATETIME)
	INSERT INTO @cTable
	SELECT
		iEntityId, 
		iEmployeeId, 
		dtmConfirm
	FROM
		m136_tblConfirmRead cr
	WHERE
		iEntityId in (SELECT iEntityId FROM @docTable)
		AND iEmployeeId IN (SELECT iEmployeeId FROM @empTable)
		AND (dtmConfirm >= @fromDate OR @fromDate IS NULL)
		AND (dtmConfirm <= @toDate OR @toDate IS NULL)
		AND dtmConfirm = (SELECT MAX(dtmConfirm) FROM m136_tblConfirmRead t 
						  WHERE cr.iEntityId = t.iEntityId AND cr.iEmployeeId = t.iEmployeeId AND (dtmConfirm >= @fromDate OR @fromDate IS NULL)
							     AND (dtmConfirm <= @toDate OR @toDate IS NULL))

	-- Return select
	SELECT
		doc.iDocumentId,
		doc.iEntityId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		book.strChapterName,
		book.strParentPath,
		dep.strName AS strDepName,
		dep.iDepartmentId,
		dep.iLevel,
		emp.strFirstName +' '+ emp.strLastName AS strEmployeeName,
		emp.iEmployeeId,
		(CASE WHEN ISNULL(cr.iEmployeeId, 0) = 0 THEN 0 ELSE 1 END) AS iReadStatus,
		cr.dtmConfirm,
		doc.iVirt,
		dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, doc.dtmPublish, doc.dtmPublishUntil, getDate(), doc.iDraft, doc.iApproved) iVersionStatus,
		doc.iDraft,
		doc.iApproved
	FROM
		@docTable doc
		FULL JOIN @empTable emp ON 1=1
		LEFT JOIN @cTable cr ON cr.iEmployeeId=emp.iEmployeeId AND cr.iEntityId=doc.iEntityId
		LEFT OUTER JOIN tblDepartment dep on dep.iDepartmentId=emp.iDepartmentId
		LEFT OUTER JOIN @bookTable book on doc.iHandbookId=book.iHandbookId
	WHERE
		ISNULL(doc.iEntityId, 0) > 0
	ORDER BY
		doc.iHandbookId ASC,
		doc.iSort ASC,
		doc.iDocumentId ASC,
		strDepName ASC,
		iReadStatus DESC,
		strEmployeeName ASC,
		dtmConfirm DESC
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetHandbookIdsFromArchivedDocuments]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHandbookIdsFromArchivedDocuments] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetHandbookIdsFromArchivedDocuments] 
	@DocumentIds dbo.Item READONLY
AS
BEGIN
	SELECT 
		a.DocumentId,
		a.HandbookId,
		CASE WHEN NOT EXISTS(SELECT 1 FROM dbo.m136_tblHandbook WHERE iHandbookId = a.HandbookId AND iDeleted = 0)
		THEN 1 ELSE 0
		END IsDeleted
	FROM dbo.m136_ArchivedDocuments a
	JOIN @DocumentIds d ON a.DocumentId = d.Id
END
GO
