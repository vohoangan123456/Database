INSERT INTO #Description VALUES ('Create a page for sending email manually')
GO

--Get Email To Delivery
IF (OBJECT_ID('[dbo].[GetEmailToDelivery]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[GetEmailToDelivery] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[GetEmailToDelivery]
@Statuses AS [dbo].[Item] READONLY,
@MailIds AS [dbo].[Item] READONLY
AS
BEGIN	
	DECLARE @COUNT_MailIds INT
	DECLARE @COUNT_Statuses INT
	SET @COUNT_MailIds = (SELECT COUNT(*) FROM @MailIds)
	SET @COUNT_Statuses = (SELECT COUNT(*) FROM @Statuses)
	SELECT  Id,
			Priority,
			[From],
			[To],
			[Subject],
			[Timestamp],
			MailMessage,
			DeliveryDate,
			Note,
			[Status]
	INTO #tempTable
	FROM Email
	WHERE (@COUNT_Statuses = 0 OR [Status] IN (SELECT Id FROM @Statuses))
			AND ( @COUNT_MailIds = 0 OR Id IN (SELECT Id FROM @MailIds))
	
	SELECT * FROM #tempTable
	
	SELECT  a.Id,
			a.EmailId,
			a.Content,
			a.[FileName]
	FROM EmailAttachment a
	INNER JOIN Email e ON a.EmailId = e.Id
	WHERE a.EmailId IN (SELECT Id FROM #tempTable)
	
	IF(OBJECT_ID('#tempTable') IS NOT NULL)  
	BEGIN  
		DROP TABLE #tempTable  
	END
END

GO
--Update Email
IF (OBJECT_ID('[dbo].[UpdateEmail]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[UpdateEmail] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[UpdateEmail]  
 @EmailId INT,  
 @From NVARCHAR(200),
 @To NVARCHAR(MAX),
 @Subject NVARCHAR(MAX),
 @MailMessage VARBINARY(MAX)
AS  
BEGIN  
 UPDATE Email
 SET	[From] = @From,
		[To] = @To,
		[Subject] = @Subject,
		MailMessage = @MailMessage
 WHERE Id = @EmailId
END  

GO
--Get Email Attachment
IF (OBJECT_ID('[dbo].[GetEmailAttachment]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[GetEmailAttachment] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[GetEmailAttachment]  
 @MailId INT 
AS  
BEGIN  
 SELECT   
   a.Id,
   a.EmailId,
   a.Content,
   a.[FileName]
 FROM   
   EmailAttachment a
 WHERE   
    a.EmailId = @MailId  
END  

GO
--Delete Email
IF (OBJECT_ID('[dbo].[DeleteEmail]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[DeleteEmail] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[DeleteEmail]
    @MailIds AS [dbo].[Item] READONLY
AS
BEGIN
	DELETE FROM
        EmailAttachment
    WHERE
        EmailId IN (SELECT Id FROM @MailIds);
    
    DELETE FROM
        Email
    WHERE
        Id IN (SELECT Id FROM @MailIds);
END