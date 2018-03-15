INSERT INTO #Description VALUES ('[B-16165] Risk - Report - Options and add Matrix (cont)')
GO

MERGE [dbo].[MessageTemplate] AS t
USING (VALUES 
	(101, 'Email: ROS report', 170)
	) AS src([TemplateId], [Name], [ModuleId])
ON (t.[TemplateId] = src.[TemplateId] AND t.[ModuleId] = src.[ModuleId])

WHEN NOT MATCHED BY TARGET THEN 
	INSERT ([TemplateId], [Name], [ModuleId]) 
	VALUES(src.[TemplateId], src.[Name], src.[ModuleId])
WHEN MATCHED THEN
	UPDATE
	SET [Name] = src.[Name];
GO


MERGE [dbo].[MessageTemplateLanguage] AS t
USING (VALUES 
	(1, 101, 'ROS rapport {Title}', 'Se vedlagt ROS rapport for: "{Title}" <br/><br/> Med vennlig hilsen <br/> {Creator}'),
	(2, 101, 'ROS report {Title}', 'See attached ROS report for: "{Title}" <br/><br/> Best regards <br/> {Creator}')
	) AS src([Language], [TemplateId], [Subject], [Body])
ON (t.[Language] = src.[Language] AND t.[TemplateId] = src.[TemplateId])

WHEN NOT MATCHED BY TARGET THEN 
	INSERT ([Language], [TemplateId], [Subject], [Body]) 
	VALUES(src.[Language], src.[TemplateId], src.[Subject], src.[Body])
WHEN MATCHED THEN
	UPDATE
	SET [Subject] = src.[Subject],
		[Body] = src.[Body];
GO