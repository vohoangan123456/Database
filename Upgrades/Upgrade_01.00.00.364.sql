INSERT #Description VALUES ('This is used to support for ''notification setup'' feature')
GO

-- Insert new message template

MERGE [dbo].[MessageTemplate] AS t
USING (VALUES 
	(17, 'Email: Task/Action - Evaluate', 151)
	) AS src([TemplateId], [Name], [ModuleId])
ON (t.[TemplateId] = src.[TemplateId] AND t.[ModuleId] = src.[ModuleId])

WHEN NOT MATCHED BY TARGET THEN 
	INSERT ([TemplateId], [Name], [ModuleId]) 
	VALUES(src.[TemplateId], src.[Name], src.[ModuleId])
WHEN MATCHED THEN
	UPDATE
	SET [Name] = src.[Name];
GO

INSERT INTO
    MessageTemplateLanguage
        (Language, TemplateId, Subject, Body)
    VALUES
        (1, 17, 'Evalueringsvarsel for tiltak', N'Et tiltak ''{TaskActionTitle}'' har nådd sin oppfølgingsdato.<br />
Vennligst følg opp og evaluer tiltaket.<br />
<br />
Avvik: {Title}<br />
Beskrivelse: {Description}<br />
<br />
<a href="{PublicUrl}" target="_blank">(Lenke til tiltak)</a>'),
        (2, 17, 'Evaluation notification for action', N'An action ''{TaskActionTitle}'' has reached its follow up date.<br />
Please follow up and evaluate the action.<br />
<br />
Deviation: {Title}<br />
Description: {Description}<br />
<br />
<a href="{PublicUrl}" target="_blank">(Link to action)</a>');
GO

-- Create new table & new type

IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NotificationSetup]') AND type in (N'U'))
	CREATE TABLE [dbo].[NotificationSetup](
        TemplateId INT PRIMARY KEY,
        Registrator BIT,
        Responsibles BIT,
        AssignedDeviationResponsible BIT,
        AssignedActionResponsible BIT,
        CategoryAlerts BIT
	)
GO

ALTER TABLE [dbo].[NotificationSetup] ADD CONSTRAINT FK_NotificationSetup_MessageTemplate FOREIGN KEY (TemplateId)
    REFERENCES [dbo].[MessageTemplate] (TemplateId)
GO
        
INSERT INTO
    NotificationSetup
        (TemplateId, Registrator, Responsibles, AssignedDeviationResponsible, AssignedActionResponsible, CategoryAlerts)
    VALUES
        (1, 1, 1, 1, NULL, 1),
        (2, 1, 1, 1, NULL, 1),
        (3, 1, 1, 1, NULL, 1),
        (4, 1, 1, 1, NULL, 1),
        (5, 1, 1, 1, 1, 1),
        (6, 1, 1, 1, 1, 1),
        (7, 1, 1, 1, NULL, 1),
        (8, 1, 1, 1, NULL, 1),
        (9, 1, 1, 1, NULL, 1),
        (10, 1, 1, 1, NULL, 1),
        (11, 1, 1, 1, NULL, 1),
        (12, 1, 1, 1, NULL, 1),
        (13, 1, 1, 1, NULL, 1),
        (14, 1, 1, 1, 1, 1),
        (15, 1, 1, 1, NULL, 1),
        (17, 1, 1, 1, 1, 1);
GO

IF  NOT EXISTS (SELECT * FROM sys.types st JOIN sys.schemas ss ON st.schema_id = ss.schema_id WHERE st.name = N'NotificationSetupItems' AND ss.name = N'dbo')
    CREATE TYPE [dbo].[NotificationSetupItems] AS TABLE
    (
        TemplateId INT,
        Registrator BIT,
        Responsibles BIT,
        AssignedDeviationResponsible BIT,
        AssignedActionResponsible BIT,
        CategoryAlerts BIT
    )
GO      

-- Create procedures

IF OBJECT_ID('[dbo].[GetNotificationSetupByTemplateId]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[GetNotificationSetupByTemplateId]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetNotificationSetupByTemplateId]
    @TemplateId INT
AS
BEGIN
    SELECT 
        TemplateId,
        Registrator,
        Responsibles,
        AssignedDeviationResponsible,
        AssignedActionResponsible,
        CategoryAlerts
    FROM
        NotificationSetup
    WHERE
        TemplateId = @TemplateId
END
GO

IF OBJECT_ID('[dbo].[GetAllNotificationSetup]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[GetAllNotificationSetup]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[GetAllNotificationSetup]
AS
BEGIN
    SELECT 
        ns.TemplateId,
        mt.Name AS TemplateName,
        ns.Registrator,
        ns.Responsibles,
        ns.AssignedDeviationResponsible,
        ns.AssignedActionResponsible,
        ns.CategoryAlerts
    FROM
        NotificationSetup ns
            INNER JOIN MessageTemplate mt
                ON ns.TemplateId = mt.TemplateId
END
GO

IF OBJECT_ID('[dbo].[UpdateAllNotificationSetup]', 'p') IS NULL
	EXEC ('CREATE PROCEDURE [dbo].[UpdateAllNotificationSetup]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[UpdateAllNotificationSetup]
    @NotificationSetupItems AS [dbo].[NotificationSetupItems] READONLY
AS
BEGIN
    UPDATE
        NotificationSetup
    SET
        Registrator = nsi.Registrator,
        Responsibles = nsi.Responsibles,
        AssignedDeviationResponsible = nsi.AssignedDeviationResponsible,
        AssignedActionResponsible = nsi.AssignedActionResponsible,
        CategoryAlerts = nsi.CategoryAlerts
    FROM
        NotificationSetup ns
            INNER JOIN @NotificationSetupItems nsi
                ON ns.TemplateId = nsi.TemplateId
END
GO

INSERT INTO dbo. SchemaChanges
VALUES('01','00', '00', '364','Upgrade_01.00.00.364.sql', 'This is used to support for ''notification setup'' feature')

COMMIT TRANSACTION ;
GO

SET IMPLICIT_TRANSACTIONS OFF;
GO

ALTER FULLTEXT INDEX ON [dbo].[m136_tblDocument] SET STOPLIST = OFF
GO
