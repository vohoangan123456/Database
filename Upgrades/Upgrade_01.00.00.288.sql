INSERT INTO #Description VALUES('Support edit message template.')
GO


IF OBJECT_ID('[dbo].[GetMessageTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetMessageTemplates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetMessageTemplates]
	@Language INT
AS
BEGIN
	SET NOCOUNT ON;
    SELECT mt.TemplateId, 
		mt.Name, 
		mt.ModuleId, 
		mtl.[Language], 
		mtl.[Subject], 
		mtl.[Body]
    FROM dbo.MessageTemplate mt
    INNER JOIN dbo.MessageTemplateLanguage mtl ON mtl.TemplateId = mt.TemplateId
    WHERE mtl.[Language] = @Language;
END
GO


IF OBJECT_ID('[dbo].[SearchMessageTemplates]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[SearchMessageTemplates] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[SearchMessageTemplates] 
	@Keyword NVARCHAR(150)
AS
BEGIN
	SET NOCOUNT ON;
    SELECT 
		mt.TemplateId, 
		mt.Name, 
		mt.ModuleId, 
		mtl.[Language], 
		mtl.[Subject], 
		mtl.Body
    FROM dbo.MessageTemplate mt JOIN 
		dbo.MessageTemplateLanguage mtl ON mtl.TemplateId = mt.TemplateId
    WHERE (@Keyword IS NULL
		OR mtl.[Subject] LIKE '%' + @Keyword + '%'
		OR mtl.Body LIKE '%' + @Keyword + '%')
    ORDER BY mt.Name;
END
GO


IF OBJECT_ID('[dbo].[UpdateMessageTemplate]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[UpdateMessageTemplate] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[UpdateMessageTemplate] 
	@TemplateId INT,
	@Language INT,
	@Subject NVARCHAR(100),
	@Body NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE dbo.MessageTemplateLanguage
    SET
        [Subject] = @Subject,
        Body = @Body
    WHERE TemplateId = @TemplateId AND [Language] = @Language;
END
GO


IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 1 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'<p>Et avvik ''{Title}'' er registrert av bruker ''{Creator}''.<br />
		Rapport type: {ReportType}<br />
		Kategori: {CategoryName}<br />
		Beskrivelse: {Description}<br />
		<br />
		Intranett/Innenfor organisasjon<br />
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br />
		<br />
		Internett/Utenfor organisasjon<br />
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></p>
		'
	WHERE TemplateId = 1 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 1 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is registered by user ''{Creator}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		<br />
		Intranet / Within the organization<br />
		<a href="{Url}" target="_blank">(Link to deviation)</a><br />
		<br />
		Internet / Outside Organization<br />
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a></p>
		'
	WHERE TemplateId = 1 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 2 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er akseptert av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 2 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 2 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is accepted by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 2 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 3 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er videresendt av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 3 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 3 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is forwarded by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 3 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 4 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er lukket av bruker ''{Owner}''.<br/>
			Rapport type: {ReportType}<br/>
			Kategori: {CategoryName}<br/>
			Beskrivelse: {Description}<br/><br/>
			Intranett/Innenfor organisasjon<br/>
			<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
			Internett/Utenfor organisasjon<br/>
			<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 4 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 4 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is closed by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 4 AND [Language] = 2;
END
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

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 7 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er gjenåpnet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 7 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 7 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is reopened by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 7 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 8 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er slettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 8 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 8 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is reopened by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 8 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 9 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er gjenopprettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 9 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 9 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is restored by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 9 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 10 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Følgende avvik er utløpt:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til avvik)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 10 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 10 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'The following deviations are expired:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to deviation)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to deviation)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 10 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 11 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Et avvik ''{Title}'' er endret kategori av bruker ''{User}''.<br/>
		Rapport type: {ReportType}<br/>
		Beskrivelse: {Description}<br/>
		Gamle kategorien: {OldCategoryName}<br/>
		Ny kategori: {NewCategoryName}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>'
	WHERE TemplateId = 11 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 11 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'A deviation ''{Title}'' is changed category by ''{User}''.<br/>
		Report type: {ReportType}<br/>
		Description: {Description}<br/>
		Old category: {OldCategoryName}<br/>
		New category: {NewCategoryName}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>'
	WHERE TemplateId = 11 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 12 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Følgende oppgaver / handlinger er utløpt:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 12 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 12 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'The following Tasks/Actions are expired:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to task/action)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to task/action)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 12 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 13 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Følgende avvik utløper i dag:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til avvik)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 13 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 13 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'The following deviations are expiring today:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to deviation)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to deviation)</a></td></tr></tbody>
		</table></div>'
	WHERE TemplateId = 13 AND [Language] = 2;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 14 AND [Language] = 1)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'Følgende oppgaver / handlinger er utløper i dag: <div><table border="1"><thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>
	Internett/Utenfor organisasjon</th></tr></thead><tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a></td></tr></tbody></table></div>'
	WHERE TemplateId = 14 AND [Language] = 1;
END
GO

IF EXISTS(SELECT * FROM dbo.MessageTemplateLanguage WHERE TemplateId = 14 AND [Language] = 2)
BEGIN
	UPDATE MessageTemplateLanguage SET Body = N'The following Tasks/Actions are expiring today: <div><table border="1"><thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>
	Internett/Utenfor organisasjon</th></tr></thead><tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to task/action)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to task/action)</a></td></tr></tbody></table></div>'
	WHERE TemplateId = 14 AND [Language] = 2;
END
GO



