INSERT INTO #Description VALUES('Modify procedure m136_ProcessFeedback')
GO

IF OBJECT_ID('[dbo].[m136_ProcessFeedback]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_ProcessFeedback] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_ProcessFeedback] 
	@SecurityId INT,
	@EntityId INT,
	@FeedbackMessage VARCHAR(4000),
	@RecipientsForMailFeedback INT,
    @SendAlsoToApprover BIT
AS
BEGIN
	--Insert feedback
	INSERT INTO m136_tblFeedback(iEntityId, iEmployeeId, dtmFeedback, strFeedback)
		VALUES(@EntityId, @SecurityId , GETDATE(), @FeedbackMessage);
		
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
			d.iDeleted = 0;
			
	--Get Email from
	SELECT @FromEmailAdress = isNull(strEmail, '') 
	FROM tblEmployee 
	WHERE iEmployeeId = @SecurityId;
		
	INSERT INTO @ToEmailAdress 
		SELECT  isNull(strEmail, '') 
			FROM tblEmployee 
			WHERE iEmployeeId = @CreatedById
    
    IF @SendAlsoToApprover = 1
    BEGIN
        INSERT INTO @ToEmailAdress
        SELECT isNull(strEmail, '')
        FROM tblEmployee
        WHERE iEmployeeId = @ApprovedId
            AND strEmail NOT IN (SELECT email FROM @ToEmailAdress);
    END
	
	--Get Email To
	IF (@RecipientsForMailFeedback = 1)
	BEGIN
		INSERT INTO @ToEmailAdress 
			SELECT  isNull(strEmail, '') 
				FROM tblEmployee 
				WHERE iEmployeeId = @ApprovedId;	
	END
	ELSE IF (@RecipientsForMailFeedback = 0)
	BEGIN
		-- Get email of user have permisson approved
		INSERT INTO @ToEmailAdress 
			SELECT DISTINCT e.strEmail
				FROM tblEmployee e 
				JOIN relEmployeeSecGroup s ON e.iEmployeeId = s.iEmployeeId
				JOIN tblACL a ON s.iSecGroupId = a.iSecurityId AND
				a.iEntityId = @FolderId AND a.iApplicationId = 136 AND
				a.iPermissionSetId = 462 AND (a.iBit & 0x10) = 0x10
				AND e.strEmail IS NOT NULL AND e.strEmail <> '';
	END
	
	--return data
	SELECT @DocumentId AS DocumentId, @DocumentName AS Name, @Version AS [Version], @FromEmailAdress AS FromEmailAdress
	SELECT DISTINCT email AS Email 
	FROM @ToEmailAdress;
END
GO