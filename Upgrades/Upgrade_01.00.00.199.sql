INSERT INTO #Description VALUES('Updated script for getting documents recursive.')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsByHandbookIdRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] AS SELECT 1')
GO

-- =============================================
-- Author:  EM.LAM.VAN.MAI
-- Created date: OCT 27, 2015
-- Description: Get documents by handbookId and all documents of sub chapters.
-- Modified on: FEB 16, 2016
-- Modified description: Get iDeleted, dtmCreated, dtmAlter 
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDocumentsByHandbookIdRecursive] 
	@iHandbookId INT = 0,
	@iSecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, 1);
		SELECT DISTINCT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId, 
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			0 AS Virtual,
			d.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter
		FROM 
			m136_tblDocument d
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON d.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	UNION       
		SELECT 
			d.iDocumentId AS Id, 
			h.iHandbookId,
			d.strName, 
			d.iDocumentTypeId,
			d.iVersion AS [Version],
			h.iLevelType AS LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId AS DepartmentId,
			1 AS Virtual,
			virt.iSort,
			h.strName AS ParentFolderName,
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) as iAccess,
			d.iCreatedbyId,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			0 AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter			
		FROM 
			m136_relVirtualRelation virt 
				JOIN m136_tblDocument d
					ON virt.iDocumentId = d.iDocumentId
				JOIN m136_tblHandbook h 
					ON d.iHandbookId = h.iHandbookId
				JOIN @AvailableChildren ac
					ON virt.iHandbookId = ac.iHandbookId
		WHERE
			d.iLatestVersion = 1
	ORDER BY 
		iSort, 
		strName
END
GO


IF OBJECT_ID('[dbo].[m136_rptGetPersonChapterConfirmsSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_rptGetPersonChapterConfirmsSums] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_rptGetPersonChapterConfirmsSums]
(
	@iSecurityId INT = 0,
	@iHandbookId INT = 0,
	@fromDate DATETIME = NULL,
	@toDate DATETIME = NULL,
	@iEmployeeId INT = 0,
	@iLatestVersions BIT = 1,
	@recursive BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	IF @toDate <> NULL
	BEGIN
		set @toDate = DATEADD(DAY, 1, @toDate)
	END

	DECLARE @empTable TABLE(iEmployeeId INT NULL)
	--Seg selv
	IF @iEmployeeId = @iSecurityId
		INSERT INTO @empTable(iEmployeeId) SELECT @iEmployeeId


	--Modul-administrator
	IF (SELECT COUNT(iEmployeeId) FROM @empTable)=0
	BEGIN
		IF (dbo.fnSecurityGetPermission(136, 460, @iSecurityId,0) & 2) = 2
		BEGIN
			INSERT INTO @emptable SELECT @iEmployeeId
		END
	END

	--Kan lese kvitteringer på egen org-enhet
	IF (SELECT COUNT(iEmployeeId) FROM @empTable) = 0
	BEGIN
		IF (dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0) & 4) = 4
		BEGIN
			INSERT INTO @emptable
			SELECT iEmployeeId FROM tblEmployee WHERE iDepartmentId 
			IN (SELECT iDepartmentId FROM tblEmployee WHERE iEmployeeId = @iSecurityId) AND iEmployeeId = @iEmployeeId
		END
	END


	IF (SELECT COUNT(iEmployeeId) FROM @empTable) > 0
	BEGIN

		--Mappeutdrag:
		DECLARE @bookTable TABLE(iHandbookId INT NOT NULL, 
			strChapterName VARCHAR(400) NULL, 
			strParentPath VARCHAR(1000) NULL, 
			confirmPercent FLOAT NULL, iMin INT )
		INSERT INTO @bookTable
		SELECT
			iHandbookId,
			strName,
			dbo.fn136_GetParentPath(iHandbookId),
			dbo.m136_fnPersonHandbookConfirmPercentage(@iEmployeeId, iHandbookId, @fromDate, @toDate),
			iMin
		FROM
			m136_tblHandbook
		WHERE
			(iHandbookId = @iHandbookId OR 
			(@recursive = 1 AND iHandbookId IN (SELECT iHandbookId FROM dbo.m136_GetHandbookRecursive(@iHandbookId, @iSecurityId, 1))))
			AND iDeleted = 0
			AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01) > 0 


		--Dokumentutdrag:
		DECLARE @docTable TABLE(iEntityId INT NULL, 
			iDocumentId INT NULL, 
			strName varchar(200) NULL, 
			iVersion INT NULL, 
			iHandbookId INT NULL, 
			iSort INT NULL, 
			iVirt INT not NULL);
			
		INSERT INTO @docTable
		SELECT	doc.iEntityId,
			doc.iDocumentId,
			doc.strName,
			doc.iVersion,
			doc.iHandbookId,
			doc.iSort,
			0
		FROM
			@bookTable book
			RIGHT JOIN m136_tblDocument doc ON doc.iHandbookId = book.iHandbookId
		WHERE
			doc.iHandbookId = book.iHandbookId
			AND iLatestApproved = 1;

		--virtual
		INSERT INTO @docTable
		SELECT 	doc.iEntityId,
			virt.iDocumentId,
			doc.strName,
			doc.iVersion,
			virt.iHandbookId,
			virt.iSort,
			1
		FROM
			m136_relVirtualRelation virt
			left join m136_tblDocument doc on doc.iDocumentId=virt.iDocumentId
			right join @bookTable book on book.iHandbookId=virt.iHandbookId
		WHERE
			doc.iLatestApproved = 1;

		SELECT
			doc.iDocumentId,
			doc.iEntityId,
			doc.strName,
			doc.iVersion,
			doc.iHandbookId,
			book.strChapterName,
			book.strParentPath,
			book.confirmPercent,
			CASE WHEN (ISDATE(cr.dtmConfirm) = 1 AND cr.iEmployeeId = @iEmployeeId) THEN 1 ELSE 0 END AS iReadStatus,
			cr.dtmConfirm,
			doc.iVirt,
			dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, 
				details.dtmPublish, details.dtmPublishUntil, GETDATE(), details.iDraft, details.iApproved) AS iVersionStatus,
			details.iApproved,
			details.iDraft
		FROM
			@empTable emp
			CROSS JOIN @docTable doc 
			LEFT JOIN m136_tblDocument details ON details.iEntityId = doc.iEntityId
			LEFT OUTER JOIN m136_tblConfirmRead cr ON doc.iEntityId = cr.iEntityId
				AND emp.iEmployeeId = cr.iEmployeeId
				AND (dtmConfirm > @fromDate OR @fromDate IS NULL OR dtmConfirm IS NULL)
				AND (dtmConfirm < @toDate OR @toDate IS NULL OR dtmConfirm IS NULL)
			LEFT OUTER JOIN @bookTable book ON doc.iHandbookId=book.iHandbookId
		ORDER BY
			doc.iSort,
			doc.iDocumentId,
			doc.iVersion DESC,
			cr.dtmConfirm DESC
	END
END
GO