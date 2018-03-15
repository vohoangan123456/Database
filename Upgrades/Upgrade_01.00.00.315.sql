INSERT INTO #Description VALUES ('Create procedure [dbo].[m136_be_GetMyDocumentsToHearing]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetMyDocumentsToHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetMyDocumentsToHearing] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetMyDocumentsToHearing]
	@UserId INT = NULL
AS
BEGIN
	SELECT	d.iDocumentId as Id,
			d.iEntityId,
			d.iHandbookId,
			d.strName,
			d.iDocumentTypeId,
			d.iVersion as Version,
			h.iLevelType as LevelType,
			d.dtmApproved,
			d.strApprovedBy,
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			d.iSort,
			h.strName as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as Path,
			[dbo].[fnHasDocumentAttachment](d.iEntityId) as HasAttachment,
			d.iApproved,
			d.iDraft,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iCreatedbyId,
            d.iInternetDoc,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iHandbookId AS iParentHandbookId,
			CAST(0 as INT) AS iChildCount,
			d.iDeleted,
			d.dtmCreated,
			d.dtmAlter,
			1 AS IsDocument,
			d.iHandbookId AS VirtualHandbookId,
			d.iReadCount AS ReadCount,
			he.DueDate,
			he.IsPublic
	FROM	dbo.m136_Hearings he
	JOIN	m136_tblDocument d ON he.EntityId = d.iEntityId AND (d.iCreatedbyId = @UserId OR d.iAlterId = @UserId)
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	WHERE	he.IsActive = 1 AND (d.iCreatedbyId = @UserId OR d.iAlterId = @UserId)
END
GO