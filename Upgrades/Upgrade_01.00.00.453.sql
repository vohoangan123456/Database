INSERT INTO #Description VALUES ('Update message template for task/action. The url should say task/action instead of saying deviation.')
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 5 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et oppgaver/tiltak ''{TaskActionTitle}'' er tilordnet av bruker ''{Creator}''.<br/>
		Avvik: {Title}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a>'
	WHERE TemplateId = 5 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 5 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A task/action ''{TaskActionTitle}'' is assigned by user ''{Creator}''.<br/>
		Deviation: {Title}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to task/action)</a>'
	WHERE TemplateId = 5 AND [Language] = 2;
END
GO


IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 6 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et oppgaver/tiltak ''{TaskActionTitle}'' er lukket av bruker ''{Creator}''.<br/>
		Avvik: {Title}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a>'
	WHERE TemplateId = 6 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 6 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A task/action ''{TaskActionTitle}'' is closed by user ''{Creator}''.<br/>
		Deviation: {Title}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to task/action)</a>'
	WHERE TemplateId = 6 AND [Language] = 2;
END
GO


IF EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'Deviation.Cost') 
         AND name = 'ReferenceNumber'
)
 BEGIN
	ALTER TABLE Deviation.Cost ALTER COLUMN ReferenceNumber NVARCHAR(20) NULL
 END
 GO