INSERT INTO #Description VALUES('Support MessageTemplate')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MessageTemplate]') AND type in (N'U'))
	CREATE TABLE [dbo].[MessageTemplate](
		[TemplateId] [int] NOT NULL,
		[Name] [nvarchar](100) NOT NULL,
		[ModuleId] [int] NULL
	 CONSTRAINT [MessageTemplate_Framework_PK] PRIMARY KEY CLUSTERED 
	(
		[TemplateId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[MessageTemplateLanguage]') AND type in (N'U'))
	CREATE TABLE [dbo].[MessageTemplateLanguage](
		[MessageTemplateLanguageId] [int] IDENTITY(1,1) NOT NULL,
		[Language] [int] NULL,
		[TemplateId] [int] NULL,
		[Subject] [nvarchar](100) NULL,
		[Body] [ntext] NULL
	 CONSTRAINT [MessageTemplateLanguage_Framework_PK] PRIMARY KEY CLUSTERED 
	(
		[MessageTemplateLanguageId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='MessageTemplate_Framework_MessageTemplateLanguage_FK1')
BEGIN
	ALTER TABLE [dbo].[MessageTemplateLanguage]  WITH CHECK ADD  CONSTRAINT [MessageTemplate_Framework_MessageTemplateLanguage_FK1] FOREIGN KEY([TemplateId])
	REFERENCES [dbo].[MessageTemplate] ([TemplateId])
END
GO

ALTER TABLE [dbo].[MessageTemplateLanguage] CHECK CONSTRAINT [MessageTemplate_Framework_MessageTemplateLanguage_FK1]
GO



IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 1)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (1, N'Email: Deviation - Register', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 2)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (2, N'Email: Deviation - Accept', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 3)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (3, N'Email: Deviation - Forward', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 4)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (4, N'Email: Deviation - Close', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 5)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (5, N'Email: Task/Action - Assign', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 6)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (6, N'Email: Task/Action - Close', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 7)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (7, N'Email: Deviation - Reopen', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 8)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (8, N'Email: Deviation - Delete', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 9)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (9, N'Email: Deviation - Restore', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 10)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (10, N'Email: Deviation - Expired', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 11)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (11, N'Email: Deviation - CategoryChanged', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 12)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (12, N'Email: Deviation Tasks/Actions - Expired', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 13)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (13, N'Email: Deviation - Expiring', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 14)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (14, N'Email: Deviation Tasks/Actions - Expiring', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 1 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (1, 1, 1, N'Avvik er registrert', N'Et avvik ''{Title}'' er registrert av bruker ''{Creator}''.<br/>
				Rapport type: {ReportType}<br/>
				Kategori: {CategoryName}<br/>
				Beskrivelse: {Description}<br/><br/>
				{Local}<br/>
				<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
				{Public}<br/>
				<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 1 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (2, 2, 1, N'Deviation is registered', N'A deviation ''{Title}'' is registered by user ''{Creator}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 2 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON	
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (3, 1, 2, N'Avvik er akseptert', N'Et avvik ''{Title}'' er akseptert av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 2 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (4, 2, 2, N'Deviation is accepted', N'A deviation ''{Title}'' is accepted by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 3 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON	
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (5, 1, 3, N'Avvik er videresendt', N'Et avvik ''{Title}'' er videresendt av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 3 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (6, 2, 3, N'Deviation is forwarded', N'A deviation ''{Title}'' is forwarded by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 4 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (7, 1, 4, N'Avvik er lukket', N'Et avvik ''{Title}'' er lukket av bruker ''{Owner}''.<br/>
			Rapport type: {ReportType}<br/>
			Kategori: {CategoryName}<br/>
			Beskrivelse: {Description}<br/><br/>
			{Local}<br/>
			<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
			{Public}<br/>
			<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 4 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (8, 2, 4, N'Deviation is closed', N'A deviation ''{Title}'' is closed by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')		
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 5 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON		
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (9, 1, 5, N'Oppgaver/Tiltak er tilordnet', N'Et oppgaver/tiltak ''{Title}'' er tilordnet av bruker ''{Creator}''.<br/>
		Avvik: {DeviationName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 5 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (10, 2, 5, N'Task/Action is assigned', N'A task/action ''{Title}'' is assigned by user ''{Creator}''.<br/>
		Deviation: {DeviationName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')	
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 6 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (11, 1, 6, N'Oppgaver/Tiltak er lukket', N'Et oppgaver/tiltak ''{Title}'' er lukket av bruker ''{Creator}''.<br/>
		Avvik: {DeviationName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 6 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (12, 2, 6, N'Task/Action is closed', N'A task/action ''{Title}'' is closed by user ''{Creator}''.<br/>
		Deviation: {DeviationName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')	
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 7 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (13, 1, 7, N'Avvik er gjenåpning', N'Et avvik ''{Title}'' er gjenåpnet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 7 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (14, 2, 7, N'Deviation is reopened', N'A deviation ''{Title}'' is reopened by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')		
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 8 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (15, 1, 8, N'Avvik er slettet', N'Et avvik ''{Title}'' er slettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 8 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (16, 2, 8, N'Deviation is deleted', N'A deviation ''{Title}'' is deleted by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 9 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (17, 1, 9, N'Avvik er gjenopprettet', N'Et avvik ''{Title}'' er gjenopprettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 9 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (18, 2, 9, N'Deviation is restored', N'A deviation ''{Title}'' is restored by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 10 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (19, 1, 10, N'Avvik er utløpt', N'Følgende avvik er utløpt:
		<div><table border="1">
		<tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>{Local}</th><th>{Public}</th></tr>
		{DeviationInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 10 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (20, 2, 10, N'Deviations expired', N'The following deviations are expired:
		<div><table border="1">
		<tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Url</th></tr>
		{DeviationInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 11 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (21, 1, 11, N'Avvik ''{Title}'' er endret kategori', N'Et avvik ''{Title}'' er endret kategori av bruker ''{User}''.<br/>
		Rapport type: {ReportType}<br/>
		Beskrivelse: {Description}<br/>
		Gamle kategorien: {OldCategoryName}<br/>
		Ny kategori: {NewCategoryName}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 11 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (22, 2, 11, N'Deviation ''{Title}'' is changed category', N'A deviation ''{Title}'' is changed category by ''{User}''.<br/>
		Report type: {ReportType}<br/>
		Description: {Description}<br/>
		Old category: {OldCategoryName}<br/>
		New category: {NewCategoryName}<br/><br/>
		{Local}<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		{Public}<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')	
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 12 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (23, 1, 12, N'Avvik Oppgaver / Handlinger Utløpt', N'Følgende oppgaver / handlinger er utløpt:
		<div><table border="1">
		<tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>{Local}</th><th>{Public}</th></tr>
		{ActionInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 12 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (24, 2, 12, N'Deviation Tasks/Actions Expired', N'The following Tasks/Actions are expired:
		<div><table border="1">
		<tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Url</th></tr>
		{ActionInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 13 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (25, 1, 13, N'Avvik er utløper', N'Følgende avvik utløper i dag:
		<div><table border="1">
		<tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>{Local}</th><th>{Public}</th></tr>
		{DeviationInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 13 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (26, 2, 13, N'Deviations Expiring', N'The following deviations are expiring today:
		<div><table border="1">
		<tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Url</th></tr>
		{DeviationInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 14 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (27, 1, 14, N'Avvik Oppgaver / Handlinger Utløper', N'Følgende oppgaver / handlinger er utløper i dag:
		<div><table border="1">
		<tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>{Local}</th><th>{Public}</th></tr>
		{ActionInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 14 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (28, 2, 14, N'Deviation Tasks/Actions Expiring', N'The following Tasks/Actions are expiring today:
		<div><table border="1">
		<tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Url</th></tr>
		{ActionInfo}
		</table></div>')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END
GO



IF OBJECT_ID('[dbo].[GetMessageTemplateById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetMessageTemplateById] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetMessageTemplateById]
	@TemplateId INT,
	@Language INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT mt.TemplateId, 
		mt.Name, 
		mt.ModuleId, 
		mtl.[Language], 
		mtl.[Subject], 
		mtl.Body 
    FROM dbo.MessageTemplate mt
    INNER JOIN dbo.MessageTemplateLanguage mtl ON mtl.TemplateId = mt.TemplateId
    WHERE mt.TemplateId = @TemplateId AND mtl.[Language] = @Language;
END
GO
