INSERT INTO #Description VALUES('Modify procedure m136_ProcessFeedback')
GO

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplate] WHERE [TemplateId] = 15)
BEGIN
	INSERT [dbo].[MessageTemplate] ([TemplateId], [Name], [ModuleId]) VALUES (15, N'Reminder - Expired Deviation/Task/Action', 151)
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 15 AND [Language] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (29, 1, 15, N'Påminnelse - Utløpt {0}', N'Vennligst følg opp, "{0}", som er utløpt.<br/><br/>Med vennlig hilsen<br/>{1}')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END

IF NOT EXISTS(SELECT * FROM [dbo].[MessageTemplateLanguage] WHERE [TemplateId] = 15 AND [Language] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] ON
	INSERT [dbo].[MessageTemplateLanguage] ([MessageTemplateLanguageId], [Language], [TemplateId], [Subject], [Body]) VALUES (30, 2, 15, N'Reminder - Expired {0}', N'Please follow up, "{0}", which is expired.<br/><br/>Best regards<br/>{1}')
	SET IDENTITY_INSERT [dbo].[MessageTemplateLanguage] OFF
END
GO