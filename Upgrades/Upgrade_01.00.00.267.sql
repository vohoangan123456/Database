INSERT INTO #Description VALUES('Create SP for PBI hearing startpage')
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentAwaitingHearings]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentAwaitingHearings] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_GetDocumentAwaitingHearings]
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
	JOIN    dbo.m136_HearingMembers m ON he.Id = m.HearingsId AND m.EmployeeId = @UserId
	JOIN	m136_tblDocument d ON he.EntityId = d.iEntityId
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	WHERE	he.IsActive = 1 
			
END
GO

IF OBJECT_ID('[dbo].[m136_GetDocumentPublicHearings]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_GetDocumentPublicHearings] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_GetDocumentPublicHearings]
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
	JOIN	m136_tblDocument d ON he.EntityId = d.iEntityId
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId
	WHERE	he.IsActive = 1 
			AND he.IsPublic	= 1
END
GO