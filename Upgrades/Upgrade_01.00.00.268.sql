INSERT INTO #Description VALUES('Create SP for PBI hearing startpage')
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_luHearingResponses]') AND type in (N'U'))
BEGIN

	ALTER TABLE dbo.m136_HearingMembers
	DROP CONSTRAINT m136_luHearingResponses_m136_HearingMembers_FK1
	
	DROP TABLE [dbo].[m136_luHearingResponses]
	
	CREATE TABLE [dbo].[m136_luHearingResponses](
	[Id] [INT] NOT NULL,
	[Name] [NVARCHAR](100) NOT NULL,
	 CONSTRAINT [PK_m136_luHearingResponses] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	
	IF NOT EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
		WHERE CONSTRAINT_NAME ='m136_luHearingResponses_m136_HearingMembers_FK1')
	BEGIN
		TRUNCATE TABLE [dbo].[m136_HearingMembers]
		ALTER TABLE [dbo].[m136_HearingMembers]  WITH CHECK ADD  CONSTRAINT [m136_luHearingResponses_m136_HearingMembers_FK1] FOREIGN KEY([HearingResponse])
		REFERENCES [dbo].[m136_luHearingResponses] ([Id])
	END
END
GO

IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 1)
BEGIN
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (1, N'Recommended')
END
GO

IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 2)
BEGIN
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (2, N'Not Recommended')
END
GO

IF NOT EXISTS(SELECT 1 FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 3)
BEGIN
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (3, N'Neutral')
END
GO