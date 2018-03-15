
INSERT INTO #Description VALUES('Adding field IsNew')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentsApprovedWithinXDays]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays]
GO

-- =============================================
-- Author:		Atle Solberg
-- Create date: 22.10.2013
-- Description:	Gets List Of All Documents Approved Within X Days] 
-- =============================================
CREATE PROCEDURE [dbo].[m136_GetDocumentsApprovedWithinXDays] 
	-- Add the parameters for the stored procedure here
	@iApprovedWithinXDays int = 0,
	@iSecurityId int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @HandbookPermissions TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	DECLARE @Now DATETIME = GETDATE();
	INSERT INTO @HandbookPermissions
	SELECT iHandbookId FROM m136_tblHandbook 
		WHERE iDeleted = 0 AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 1) = 1
	SELECT 0 AS Virtual, d.iDocumentId AS Id, d.iEntityId, d.strName, 
		dbo.fnSecurityGetPermission(136, 462, @iSecurityId, d.iHandbookId) AS iAccess, 
        d.iHandbookId, d.dtmApproved, h.strName AS ParentFolderName, d.iVersion AS [Version], 
        ISNULL(t.[type], 0) AS DocumentType, dbo.fn136_GetParentPathEx(d.iHandbookId) AS [Path],
        (e.strLastName + ' ' + e.strFirstName) AS strApprovedBy, 
        dbo.fnOrgGetUserName(d.iCreatedById, '', 0) as Responsible, t.iDocumentTypeId AS TemplateId,
        CASE WHEN d.dtmApproved > e.PreviousLogin THEN 1
			ELSE 0
		END AS IsNew
	FROM m136_tblDocument d
        JOIN m136_tblDocumentType t ON d.iDocumentTypeId = t.iDocumentTypeId
        JOIN m136_tblHandbook h ON d.iHandbookId = h.iHandbookId
        LEFT JOIN tblEmployee e ON e.iEmployeeId = d.iCreatedbyId
   	WHERE d.iDraft = 0
		AND d.iLatestApproved = 1
		AND d.iHandbookId IN (SELECT iHandbookId FROM @HandbookPermissions)
		AND DATEDIFF(d, ISNULL(d.dtmApproved, CONVERT(DATETIME, '01.01.1970', 104)), @Now) <  @iApprovedWithinXDays
		ORDER BY d.dtmApproved DESC
END
GO
