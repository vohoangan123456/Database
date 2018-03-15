INSERT INTO #Description VALUES ('[B-16216] Forms login - Forgot password')
GO

MERGE [dbo].[MessageTemplate] AS t
USING (VALUES 
	(100, 'Email: Recover password', 136)
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
	(1, 100, 'Passordgjenoppretting', 'Ditt nye passord for brukernavn, {UserName}, er: {Password}'),
	(2, 100, 'Password recovery', 'Your new password for user, {UserName}, is: {Password}')
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


IF OBJECT_ID('[dbo].[GetUserByEmail]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUserByEmail] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUserByEmail]
	@Email varchar(100)
AS
BEGIN
	SELECT e.*
	FROM
		[dbo].[tblEmployee] e
	WHERE 
		e.strEmail = @Email;
END
GO


IF OBJECT_ID('[dbo].[ChangeUserPassword]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[ChangeUserPassword] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[ChangeUserPassword]
	@EmployeeId [int],
	@NewPassword [varchar](32)
AS
BEGIN
	UPDATE e
	SET e.strPassword = @NewPassword
	FROM
		[dbo].[tblEmployee] e
	WHERE 
		e.iEmployeeId = @EmployeeId;
END
GO