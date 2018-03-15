INSERT INTO #Description VALUES('Create and modify some stored procedure to support feature Send Document To Approval and Approve Document')
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NOT NULL
	EXEC ('DROP PROCEDURE [dbo].[m136_be_ApproveDocument]')
GO

IF OBJECT_ID('[dbo].[m136_be_SendDocumentToApproval]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_SendDocumentToApproval] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_SendDocumentToApproval]
	@UserId INT,
	@DocumentId INT,
	@TransferReadingReceipts BIT
AS
BEGIN
	UPDATE
		m136_tblDocument
	SET
		iDraft = 0
	WHERE
		iDocumentId = @DocumentId
	
	INSERT INTO
		m136_relSentEmpApproval
			(iEmployeeId, iEntityId, dtmSentToApproval)
		VALUES
			(@UserId, @DocumentId, GETDATE())

	DELETE FROM
		m136_tblCopyConfirms
	WHERE
		iEntityId = @DocumentId
	
	IF @TransferReadingReceipts = 1
	BEGIN
		INSERT INTO
			m136_tblCopyConfirms
				(iEntityId)
			VALUES
				(@DocumentId)
	END
END
GO

IF OBJECT_ID('[dbo].[m136_doCopyConfirms]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_doCopyConfirms] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_doCopyConfirms]
(
	@iDocumentId INT
)
AS
BEGIN
	DECLARE @iEntityId INT;
	select
		@iEntityId=iEntityId
	FROM
		m136_tblDocument d
	WHERE
		d.iDocumentId = @iDocumentId
		AND d.iVersion = (SELECT
								MAX(iVersion) 
							FROM
								m136_tblDocument
							WHERE
								iDocumentId = @iDocumentId)
								
	IF @iEntityId IS NOT NULL
	BEGIN
		DECLARE @iPreviousVersionEntityId INT;
		SELECT
			@iPreviousVersionEntityId=iEntityId
		FROM
			m136_tblDocument d
		WHERE
			d.iDocumentId = @iDocumentId
			AND d.iVersion = (SELECT
									MAX(iVersion) 
								FROM
									m136_tblDocument
								WHERE
									iDocumentId = @iDocumentId
									AND iEntityId <> @iEntityId)
									
		IF @iPreviousVersionEntityId IS NOT NULL
		BEGIN
			INSERT INTO m136_tblConfirmRead(iEntityId, iEmployeeId, dtmConfirm, strEmployeeName)
				SELECT
					@iEntityId, iEmployeeId, dtmConfirm, strEmployeeName
				FROM
					m136_tblConfirmRead
				WHERE
					iEntityId=@iPreviousVersionEntityId
		END
	END
END
GO

IF OBJECT_ID('[dbo].[m136_SetCopyConfirms]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_SetCopyConfirms] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_SetCopyConfirms]
	@iDocumentId INT,
	@CopyConfirm INT
AS
BEGIN
	DECLARE @iEntityId INT;
	select
		@iEntityId=iEntityId
	FROM
		m136_tblDocument d
	WHERE
		d.iDocumentId = @iDocumentId
		AND d.iVersion = (SELECT
								MAX(iVersion) 
							FROM
								m136_tblDocument
							WHERE
								iDocumentId = @iDocumentId)
								
	IF @iEntityId IS NOT NULL
	BEGIN
		DELETE FROM m136_tblCopyConfirms WHERE iEntityId=@iEntityId
		IF @CopyConfirm = 1
		BEGIN
			INSERT INTO m136_tblCopyConfirms(iEntityId) VALUES (@iEntityId)
		END
	END
END
GO

IF OBJECT_ID('[dbo].[m136_insertEntityIntoTextIndex]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_insertEntityIntoTextIndex] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_insertEntityIntoTextIndex]
(
	@iEntityId INT
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @dstPtr			BINARY(16);
	DECLARE @insertOffset	INT;
	DECLARE @metaTable		NVARCHAR(20);
	DECLARE @iAutoId		INT;
	DECLARE @chunkSize		INT;
	SET		@chunkSize = 4000; --Should be multiples of 8040 for best performance
	DECLARE @charBlock1		NVARCHAR(4000);
	DECLARE @fetchProgress	INT;
	DECLARE @insertLength	INT;
	DECLARE @finalOffset	INT;
	DECLARE @documentInfo	VARCHAR(3000);
	
	IF EXISTS (SELECT iEntityId FROM m136x_tblTextIndex WHERE iEntityId = @iEntityId)
	BEGIN
		DELETE FROM m136x_tblTextIndex WHERE iEntityId = @iEntityId
	END 
	
	SELECT	@documentInfo = strName + ' ' + ISNULL(strDescription + ' ', '')
	FROM	m136_tblDocument
	WHERE	iEntityId = @iEntityId
	
	INSERT INTO	m136x_tblTextIndex(iEntityId, totalvalue)
	VALUES		(@iEntityId, @documentInfo)
	
	DECLARE theValues CURSOR FOR
	
	SELECT	'rich', DATALENGTH(value)/2, iMetaInfoRichTextId
	FROM	m136_tblMetaInfoRichText
	WHERE	iEntityId = @iEntityId
	
	UNION ALL
	
	SELECT	'text', DATALENGTH(value), iMetaInfoTextId
	FROM	m136_tblMetaInfoText
	WHERE	iEntityId = @iEntityId
	
	OPEN			theValues
	FETCH NEXT FROM	theValues
	INTO			@metaTable, @insertLength, @iAutoId
	IF @@FETCH_STATUS <> -1
	BEGIN
		BEGIN
			WHILE @@FETCH_STATUS = 0
			BEGIN
				-- Get pointer of value
				SELECT	@dstPtr = TEXTPTR(totalValue)
				FROM	m136x_tblTextIndex
				WHERE	iEntityId = @iEntityId
				
				-- Get the position to insert
				SELECT	@insertOffset = DATALENGTH(totalValue)/2
				FROM	m136x_tblTextIndex
				WHERE	iEntityId = @iEntityId
				
				SET	@fetchProgress = 0
				SET @finalOffset = @insertOffset + @insertLength
				
				-- Insert by chunk size
				WHILE @fetchProgress < @insertLength
				BEGIN
					-- Get the position
					SELECT	@insertOffset = DATALENGTH(totalValue)/2
					FROM	m136x_tblTextIndex
					WHERE	iEntityId = @iEntityId
					
					-- Get a part of value
					IF @metaTable = 'rich'
					BEGIN
						SELECT	@charBlock1 = SUBSTRING(value, @fetchProgress, @chunkSize)
						FROM	m136_tblMetaInfoRichText
						WHERE	iMetaInfoRichTextId = @iAutoId
					END
					ELSE
					BEGIN
						SELECT	@charBlock1 = ' ' + SUBSTRING(value, @fetchProgress, @chunkSize) + ' '
						FROM	m136_tblMetaInfoText
						WHERE	iMetaInfoTextId = @iAutoId
					END
					
					-- Update m136x_tblTextIndex
					UPDATETEXT m136x_tblTextIndex.totalvalue @dstPtr @insertOffset 0 @charBlock1
					
					-- Update new position to get new chunk size
					SET @fetchProgress = @fetchProgress + @chunkSize
				END
				FETCH NEXT FROM theValues
				INTO			@metaTable, @insertLength, @iAutoId
			END
		END
	END
	CLOSE theValues
	DEALLOCATE theValues
END
GO

IF OBJECT_ID('[dbo].[m136_be_ApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_ApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_ApproveDocument]
    @UserId INT,
    @DocumentId INT,
    @TransferReadingReceipts BIT,
    @PublishFrom DATETIME,
    @PublishUntil DATETIME,
    @IsInternetDocument BIT
AS
BEGIN
    DECLARE @FullName NVARCHAR(100);
    
    IF @TransferReadingReceipts = 1
    BEGIN
		EXEC m136_doCopyConfirms @DocumentId
    END
    ELSE
    BEGIN
		EXEC m136_SetCopyConfirms @DocumentId, 0
    END
    
    SELECT
        @FullName = strFirstName + ' ' + strLastName
    FROM
        tblEmployee
    WHERE
        iEmployeeId = @UserId

	UPDATE
        m136_tblDocument
    SET
        iApproved = 1,
        iApprovedById = @UserId,
        dtmApproved = GETDATE(),
        strApprovedBy = @FullName,
        dtmPublish = @PublishFrom,
        dtmPublishUntil = @PublishUntil,
        iInternetDoc = @isInternetDocument
    WHERE
		iDocumentId = @DocumentId
	
	EXEC m136_insertEntityIntoTextIndex @DocumentId
		
	EXEC dbo.m136_SetVersionFlags @DocumentId
	
END
GO

IF OBJECT_ID('[dbo].[m136_be_UserCanApproveDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_UserCanApproveDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_UserCanApproveDocument]
	@UserId INT,
	@DocumentId INT,
    @IsInternetDocumentMode INT
AS
BEGIN
	DECLARE @Result BIT = 0;
	DECLARE @HandBookId INT;
	DECLARE @IsInternetDocument BIT;
	
	SELECT
		@HandBookId = iHandBookId,
		@IsInternetDocument = iInternetDoc
	FROM
		dbo.m136_tblDocument
	WHERE
		iDocumentId = @DocumentId
	SELECT
		@Result = 1
	FROM
		dbo.tblEmployee AS e
	WHERE
		e.iEmployeeId = @UserId
		AND 
			((@IsInternetDocumentMode = 0 AND dbo.fnSecurityGetPermission(136, 462, e.iEmployeeId, @HandBookId) & 16 = 16)
			OR (@IsInternetDocumentMode = 1 AND @IsInternetDocumentMode = 1 AND dbo.fnSecurityGetPermission(136, 460, e.iEmployeeId, @HandBookId) & 16 = 16))
			
	SELECT @Result
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetAuthorEmailOfDocument]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetAuthorEmailOfDocument] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetAuthorEmailOfDocument]
	@DocumentId INT
AS
BEGIN
	SELECT
		TOP 1 e.strEmail
	FROM
		tblEmployee e
			INNER JOIN m136_tblDocument d
				ON e.iEmployeeId = d.iAlterId
	WHERE
		d.iDocumentId = @DocumentId
END
GO