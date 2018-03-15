INSERT INTO #Description VALUES ('Add new notification setting - Due date changed.')
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES 
           WHERE TABLE_NAME = N'MessageTemplate')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM MessageTemplate WHERE TemplateId = 18)
	BEGIN
		INSERT INTO MessageTemplate(TemplateId, Name, ModuleId) VALUES('18','Email: Due date updated','151')
	END
	IF NOT EXISTS(SELECT 1 FROM MessageTemplateLanguage WHERE TemplateId = 18)
	BEGIN
		INSERT INTO MessageTemplateLanguage(Language, TemplateId, Subject,Body) VALUES(1,18,'Behandlingsfrist endret','Behandlingsfrist for avvik, ''{Title}'', er endret til ''{DueDate}''.<br /> Rapport type:&nbsp;{ReportType}<br /> Kategori:&nbsp;{CategoryName}<br /> Beskrivelse:&nbsp;{Description}<br /> <br /> <a href="{PublicUrl}" style="font-family: Calibri, sans-serif;" target="_blank">Lenke til avvik</a>')
		INSERT INTO MessageTemplateLanguage(Language, TemplateId, Subject,Body) VALUES(2,18,'Due date changed','Due date for deviation, ''{Title}'' is changed to ''{DueDate}''.<br /> Report type:&nbsp;{ReportType}<br /> Category:&nbsp;{CategoryName}<br /> Description:&nbsp;{Description}<br /> <br /> <a href="{PublicUrl}" target="_blank">(Link to deviation)</a><br /> &nbsp;')
	END
	IF NOT EXISTS(SELECT 1 FROM NotificationSetup WHERE TemplateId = 18)
	BEGIN
		INSERT INTO [NotificationSetup](TemplateId,Registrator,Responsibles,AssignedDeviationResponsible,AssignedActionResponsible,CategoryAlerts)
		VALUES (18,1,1,1,0,1)
	END
END