
INSERT INTO #Description VALUES('update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetDocumentInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetDocumentInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetDocumentInformation]
	@DocumentId int
AS
BEGIN

	SELECT	d.iEntityId, 
			d.iDocumentId, 
			d.iVersion, 
			d.iDocumentTypeId, 
			d.iHandbookId, 
			d.strName, 
			d.strDescription, 
			d.strApprovedBy, 
			dbo.fnOrgGetUserName(d.iCreatedById, '', 0) strCreatedBy, 
			dbo.fn136_GetParentPathEx(d.iHandbookId) AS Path
	FROM m136_tblDocument d
	WHERE	d.iDocumentId = @DocumentId	AND 
			d.iApproved = 1				AND
			d.iLatestApproved = 1		AND
			d.iDeleted = 0
			
END
GO 

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetFileContents]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetFileContents]
GO

CREATE PROCEDURE [dbo].[m136_GetFileContents]
	@ItemId int
AS
BEGIN

	SELECT strFilename, strContentType, imgContent, strExtension
	FROM [dbo].m136_tblBlob 
	WHERE iItemId = @ItemId
	
END
GO
 
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_GetLatestConfirmInformation]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_GetLatestConfirmInformation]
GO

CREATE PROCEDURE [dbo].[m136_GetLatestConfirmInformation]
	@SecurityId int,
	@EntityId int
AS
BEGIN

	SELECT ISNULL(strFirstName, '') + ISNULL(' ' + strLastName, '') AS FullName
	FROM  dbo.tblEmployee
	WHERE iEmployeeId = @SecurityId

	SELECT top 1 dtmConfirm 
	FROM m136_tblConfirmRead 
	WHERE iEmployeeId=@SecurityId 
		AND iEntityId=@EntityId 
	ORDER BY dtmConfirm DESC

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_InsertReadConfirm]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_InsertReadConfirm]
GO

CREATE PROCEDURE [dbo].[m136_InsertReadConfirm]
	@EntityId INT,
	@EmployeeId INT,
	@EmployeeName VARCHAR(100)
AS
BEGIN

	INSERT INTO m136_tblConfirmRead(iEntityId, iEmployeeId, dtmConfirm, strEmployeeName)
	VALUES(@EntityId, @EmployeeId , GETDATE(), @EmployeeName)

END
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_ProcessFeedback]') AND type in (N'P', N'PC'))
	DROP PROCEDURE [dbo].[m136_ProcessFeedback]
GO


CREATE PROCEDURE [dbo].[m136_ProcessFeedback]
	@SecurityId INT,
	@EntityId INT,
	@FeedbackMsg VARCHAR(4000),
	@RecipientsForMailFeedback INT
AS
BEGIN

	--Insert feedback
	INSERT INTO m136_tblFeedback(iEntityId, iEmployeeId, dtmFeedback, strFeedback)
		VALUES(@EntityId, @SecurityId , GETDATE(), @FeedbackMsg)
	
	DECLARE @CreatedById INT, @ApprovedId INT, @FolderId INT, @DocumentName VARCHAR(200), @DocumentId INT, @Version INT
	DECLARE @FromEmailAdress varchar(100)
	DECLARE @ToEmailAdress TABLE (email varchar(100))
	
	--Get document Infomation
	SELECT	@DocumentId = d.iDocumentId, 
			@DocumentName = d.strName,
			@FolderId = d.iHandbookId,
			@Version = d.iVersion,
			@CreatedById = d.iCreatedbyId,
			@ApprovedId = d.iApprovedById
	FROM	m136_tblDocument d
	WHERE	d.iEntityId = @EntityId	AND 
			d.iDeleted = 0
			
	--Get Email from
	SELECT @FromEmailAdress = isNull(strEmail, '') FROM tblEmployee WHERE iEmployeeId = @SecurityId	
	
	INSERT INTO @ToEmailAdress 
			SELECT  isNull(strEmail, '') FROM tblEmployee WHERE iEmployeeId = @CreatedById	
			
	--Get Email To
	IF @RecipientsForMailFeedback = 1
		BEGIN
			INSERT INTO @ToEmailAdress 
				SELECT  isNull(strEmail, '') 
				FROM tblEmployee 
				WHERE iEmployeeId = @ApprovedId	
		END
	ELSE
		BEGIN
			-- Get email of user have permisson approved
			INSERT INTO @ToEmailAdress 
			SELECT DISTINCT e.strEmail
				FROM tblEmployee e JOIN relEmployeeSecGroup s ON e.iEmployeeId = s.iEmployeeId
				JOIN tblACL a ON s.iSecGroupId = a.iSecurityId AND
				a.iEntityId = @FolderId AND a.iApplicationId = 136 AND
				a.iPermissionSetId = 462 AND (a.iBit & 0x10) = 0x10
				AND e.strEmail IS NOT NULL AND e.strEmail <> ''
		END
	
	--return data
	SELECT @DocumentId AS DocumentId, @DocumentName AS Name, @Version AS Version, @FromEmailAdress AS FromEmailAdress
	
	SELECT DISTINCT email AS Email FROM @ToEmailAdress
	
END
GO