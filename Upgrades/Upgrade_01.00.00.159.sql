INSERT INTO #Description VALUES('Add new [m136_be_VerifyUserHavePermissionsOnDocuments]')
GO

IF OBJECT_ID('[m136_be_VerifyUserHavePermissionsOnDocuments]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [m136_be_VerifyUserHavePermissionsOnDocuments] AS SELECT 1')
GO

-- =============================================
-- Author:		SI.MANH.NGUYEN
-- Create date: DEC 07, 2015
-- Description:	Verify documents with specified permission
-- =============================================
ALTER PROCEDURE [m136_be_VerifyUserHavePermissionsOnDocuments]
 @DocumentIds AS [dbo].[Item] READONLY,
 @Permission INT,
 @UserId INT
AS
BEGIN
 SET NOCOUNT ON;
 
 DECLARE @CountDocumentPermissions INT, @CountDocuments INT
 
 SELECT @CountDocumentPermissions = COUNT(iHandbookId)
 FROM dbo.m136_tblDocument doc
 JOIN @DocumentIds doc1 ON doc.iDocumentId = doc1.Id
 WHERE doc.iLatestVersion = 1
	   AND dbo.fnSecurityGetPermission (136, 462, @UserId, doc.iHandbookId) &  @Permission = @Permission
 
 SELECT @CountDocuments = COUNT(Id)
 FROM @DocumentIds
 
 IF @CountDocumentPermissions = @CountDocuments
	 BEGIN
		SELECT 1;
	 END
 ELSE
 	 BEGIN
		SELECT 0;
	 END
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
			SELECT @EmailApprover = e.strEmail
			FROM dbo.m136_tblDocument doc
			JOIN dbo.tblEmployee e ON doc.iApprovedById = e.iEmployeeId
			WHERE iDocumentId IN (SELECT Id FROM @DocumentIds)
				  AND iLatestApproved = 1
		END
	
	SELECT @EmailApprover
END

GO