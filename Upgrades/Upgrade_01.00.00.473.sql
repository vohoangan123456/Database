INSERT INTO #Description VALUES ('Add SP [dbo].[m136_be_GetDocumentInformationByIds]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentInformationByIds]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentInformationByIds] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentInformationByIds]
	@DocumentIds as dbo.Item Readonly
AS
BEGIN
	
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iHandbookId,
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iApproved,
			d.iDraft,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.iInternetDoc,
			d.iDeleted,
			d.iCreatedbyId,
			rel.iEmployeeId AS empApproveOnBehalfId
			
	FROM	m136_tblDocument d
        JOIN dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
        LEFT JOIN dbo.m136_relSentEmpApproval rel 
            ON d.iEntityId = rel.iEntityId 
            AND rel.dtmSentToApproval = (SELECT MAX(dtmSentToApproval) FROM dbo.m136_relSentEmpApproval WHERE iEntityId = d.iEntityId)
	WHERE	d.iLatestVersion = 1
			AND d.iDocumentId IN (SELECT Id FROM @DocumentIds)
END
GO