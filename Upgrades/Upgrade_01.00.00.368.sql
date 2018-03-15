INSERT INTO #Description VALUES ('Reinsert default notification setup')
GO

DELETE FROM NotificationSetup
GO

INSERT INTO
    NotificationSetup
        (TemplateId, Registrator, Responsibles, AssignedDeviationResponsible, AssignedActionResponsible, CategoryAlerts)
    VALUES
        (1, 1, 1, NULL, NULL, 1),
        (4, 1, 0, 1, NULL, 1),
        (5, 0, 0, 0, 1, 0),
        (6, 0, 0, 1, 0, 0),
        (7, 1, 0, 1, NULL, 1),
        (8, 1, 0, 1, NULL, 1),
        (9, 1, 0, 1, NULL, 1),
        (10, 0, 0, 1, NULL, 1),
        (12, 0, 0, 1, 1, 0),
        (13, 0, 0, 1, NULL, 0),
        (14, 0, 0, 1, 1, 0);
GO