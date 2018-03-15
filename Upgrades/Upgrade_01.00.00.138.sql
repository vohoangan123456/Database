INSERT INTO #Description VALUES('CREATE stored procedures [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]')
GO

IF OBJECT_ID('[dbo].[m136_be_GetDocumentsByDocumentIds]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDocumentsByDocumentIds]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetDocumentsByDocumentIds] 
	@DocumentIds AS [dbo].[Item] READONLY
AS
BEGIN
	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.UrlOrFileName,
			d.strApprovedBy,
			d.iApproved,
			d.iDraft, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path,
			dbo.m136_fnGetVersionStatus(d.iEntityId, d.iDocumentId, d.iVersion, d.dtmPublish, d.dtmPublishUntil, getDate(), d.iDraft, d.iApproved) iVersionStatus,
			h.iLevelType,
			d.dtmPublish,
			d.dtmPublishUntil,
			d.iReadCount,
			h.iLevel,
			te.strEmail AS strCreatedByEmail,
			d.strAuthor,
			d.UrlOrFileName,
			d.UrlOrFileProperties,
			d.[File],
			d.iCompareToVersion	,
			d.iInternetDoc,
			d.iDeleted					
	FROM	@DocumentIds d1
	JOIN	m136_tblDocument d ON d.iDocumentId = d1.Id
	JOIN    dbo.m136_tblHandbook h ON h.iHandbookId = d.iHandbookId
	LEFT JOIN dbo.tblEmployee te ON d.iCreatedbyId = te.iEmployeeId 
	WHERE d.iLatestVersion = 1
END
GO 

IF OBJECT_ID('[dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]  AS SELECT 1')
GO
-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: NOV 19, 2015
-- Description:	Get all user who have permission write on all document which is selected
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]
 @DocumentIds AS [dbo].[Item] READONLY,
 @Permission INT
AS
BEGIN
 SET NOCOUNT ON;
	DECLARE @Folders TABLE
	(
		Id int PRIMARY KEY
	)
	
 INSERT INTO @Folders 
 SELECT DISTINCT iHandbookId
 FROM dbo.m136_tblDocument doc
 JOIN @DocumentIds doc1 ON doc.iDocumentId = doc1.Id
 WHERE doc.iLatestVersion = 1

 DECLARE @iFolderId INT;
 DECLARE @Employee TABLE
	(
		iEmployeeId int PRIMARY KEY
	)
 
 DECLARE @Employee1 TABLE
	(
		iEmployeeId int PRIMARY KEY
	)
 DECLARE Folders CURSOR FOR 
  SELECT Id
  FROM @Folders;
  
 OPEN Folders; 
 FETCH NEXT FROM Folders INTO @iFolderId;
 
	 INSERT INTO @Employee
	 SELECT te.iEmployeeId
	 FROM dbo.tblEmployee te 
	 WHERE dbo.fnSecurityGetPermission (136, 462, te.iEmployeeId, @iFolderId) &  @Permission = @Permission
	 
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO @Employee1
		SELECT e.iEmployeeId
		FROM @Employee e
		WHERE dbo.fnSecurityGetPermission (136, 462, e.iEmployeeId, @iFolderId) &  @Permission = @Permission;
		
		DELETE @Employee
		
		INSERT INTO	@Employee
		SELECT 	iEmployeeId
		FROM @Employee1	
		
		DELETE @Employee1
		
		FETCH NEXT FROM Folders INTO @iFolderId;
	 END
 CLOSE Folders;
 DEALLOCATE Folders;
 
 SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strEmail, te.strLoginName, te.iDepartmentId
 FROM dbo.tblEmployee te
 JOIN @Employee e ON e.iEmployeeId = te.iEmployeeId
END
GO

IF OBJECT_ID('[dbo].[m136_be_ChangeDocumentResponsible]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ChangeDocumentResponsible]  AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: NOV 23, 2015
-- Description:	Change Document Responsible
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_ChangeDocumentResponsible] 
	@DocumentIds AS [dbo].[Item] READONLY,
	@TypeUpdate AS INT,
	@SendEmailApprover AS BIT,
	@ResponsibleId as INT
AS
BEGIN
	IF @TypeUpdate = 1
		BEGIN
			UPDATE dbo.m136_tblDocument
			SET iCreatedbyId = @ResponsibleId
			WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
			      AND (iLatestVersion = 1 OR iLatestApproved = 1)
		END
	ELSE
		BEGIN 
			IF @TypeUpdate = 2
				BEGIN
					UPDATE dbo.m136_tblDocument
					SET iCreatedbyId = @ResponsibleId
					WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
						  AND iLatestApproved = 1
				END
			ELSE
				BEGIN
					UPDATE dbo.m136_tblDocument
					SET iCreatedbyId = @ResponsibleId
					WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
						  AND iLatestVersion = 1
				END
		END
	DECLARE @EmailApprover VARCHAR(200) = '';
	DECLARE @ApproverId INT = null;
	IF @SendEmailApprover = 1
		BEGIN
			SELECT @ApproverId = iApprovedById 
			FROM dbo.m136_tblDocument
			WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
				  AND iLatestApproved = 1
		END
	IF @ApproverId IS NOT NULL
	BEGIN 
		SELECT @EmailApprover = strEmail
		FROM dbo.tblEmployee
		WHERE iEmployeeId = @ApproverId
	END
	
	SELECT @EmailApprover
END
GO