INSERT INTO #Description VALUES ('QMS Service: Create EmailPlugin to handle email sending')
GO

--Email
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'Email') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[Email](
		[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[Priority] [tinyint] NOT NULL,
		[From] [nvarchar](200) NOT NULL,
		[To] [nvarchar](max) NOT NULL,
		[Subject] [nvarchar](max) NOT NULL,
		[Timestamp] [datetime] NOT NULL,
		[MailMessage] [varbinary](max) NOT NULL,
		[DeliveryDate] [datetime] NULL,
		[Note] [nvarchar](max) NULL,
		[Status] [tinyint] NULL,
	 CONSTRAINT [PK_dbo_Email_PK] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END

GO

--EmailAttachment
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'EmailAttachment') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[EmailAttachment](
		[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[EmailId] [int] NOT NULL,
		[Content] [varbinary](max) NOT NULL,
		[FileName] [varchar](200) NOT NULL,
	 CONSTRAINT [PK_EmailAttachment] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]

	ALTER TABLE [dbo].[EmailAttachment]  WITH CHECK ADD  CONSTRAINT [FK_EmailAttachment_Email] FOREIGN KEY([EmailId])
	REFERENCES [dbo].[Email] ([Id])

	ALTER TABLE [dbo].[EmailAttachment] CHECK CONSTRAINT [FK_EmailAttachment_Email]
END

GO

--Add Email
IF (OBJECT_ID('[dbo].[AddEmail]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[AddEmail] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[AddEmail]
	@Priority INT,
    @From NVARCHAR(200),
    @To NVARCHAR(MAX),
    @Subject NVARCHAR(MAX),
    @MailMessage VARBINARY(MAX),
    @DeliveryDate DATETIME,
    @Note NVARCHAR(MAX),
    @Status INT
AS
BEGIN	
	DECLARE @EmailId INT;
	DECLARE @Now DATETIME = GETDATE();
	INSERT INTO [dbo].[Email]
           (Priority, [From], [To], [Subject], [Timestamp], MailMessage, DeliveryDate, Note, [Status])
     VALUES
			(@Priority, @From, @To, @Subject, @Now, @MailMessage, @DeliveryDate, @Note, @Status)
	SET @EmailId = SCOPE_IDENTITY(); 
	SELECT @EmailId 
END

GO

--Add Email Attachment
IF (OBJECT_ID('[dbo].[AddEmailAttachment]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[AddEmailAttachment] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[AddEmailAttachment]
	@EmailId INT,
    @Content VARBINARY(MAX),
    @FileName VARCHAR(200)
AS
BEGIN	
	INSERT INTO [dbo].[EmailAttachment]
           (EmailId, Content, [FileName])
     VALUES
			(@EmailId, @Content, @FileName)
END

GO

--Update Status Email
IF (OBJECT_ID('[dbo].[UpdateStatusEmail]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[UpdateStatusEmail] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[UpdateStatusEmail]    
    @Id INT,    
    @Status INT     
AS    
BEGIN    
    UPDATE [dbo].[Email]
   SET 
      [Status] = @Status
 WHERE   Id = @Id
END  

GO

--Get Email To Delivery
IF (OBJECT_ID('[dbo].[GetEmailToDelivery]', 'P') IS NULL)
	EXECUTE sp_executesql @statement=N'CREATE PROCEDURE [dbo].[GetEmailToDelivery] AS SELECT 1'
GO
ALTER PROCEDURE [dbo].[GetEmailToDelivery]
AS
BEGIN	
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
	WHERE Status = 1
	
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