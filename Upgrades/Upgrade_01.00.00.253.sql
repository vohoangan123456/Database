INSERT INTO #Description VALUES('Add table and SP for document hearing action')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_luHearingResponses]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_luHearingResponses](
	[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
 CONSTRAINT [PK_m136_luHearingResponses] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF NOT EXISTS(SELECT * FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] ON
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (1, N'Recommended')
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] OFF
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] ON
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (2, N'Not Recommended')
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] OFF
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[m136_luHearingResponses] WHERE [Id] = 3)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] ON
	INSERT [dbo].[m136_luHearingResponses] ([Id], [Name]) VALUES (3, N'Neutral')
	SET IDENTITY_INSERT [dbo].[m136_luHearingResponses] OFF
END
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_Hearings]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_Hearings](
		[Id] [INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[EntityId] [INT] NULL,
		[IsPublic] [BIT] NULL,
		[CreatedDate] [DATETIME] NULL,
		[CreatedBy] [INT] NULL,
		[DueDate] [DATETIME] NULL,
		[IsActive] [BIT] NULL,
	 CONSTRAINT [m136_Hearings_PK] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='m136_tblDocument_m136_Hearings_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_Hearings]  WITH CHECK ADD  CONSTRAINT [m136_tblDocument_m136_Hearings_FK1] FOREIGN KEY([EntityId])
	REFERENCES [dbo].[m136_tblDocument] ([iEntityId])
END
GO

ALTER TABLE [dbo].[m136_Hearings] CHECK CONSTRAINT [m136_tblDocument_m136_Hearings_FK1]
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_HearingMembers]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_HearingMembers](
		[Id] [INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[HearingsId] [INT] NULL,
		[EmployeeId] [INT] NULL,
		[HasRead] [BIT] NULL,
		[HearingResponse] [INT] NULL,
	 CONSTRAINT [m136_HearingMembers_PK] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='m136_Hearings_m136_HearingMembers_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_HearingMembers]  WITH CHECK ADD  CONSTRAINT [m136_Hearings_m136_HearingMembers_FK1] FOREIGN KEY([HearingsId])
	REFERENCES [dbo].[m136_Hearings] ([Id])
END
GO

ALTER TABLE [dbo].[m136_HearingMembers] CHECK CONSTRAINT [m136_Hearings_m136_HearingMembers_FK1]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='tblEmployee_m136_HearingMembers_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_HearingMembers]  WITH CHECK ADD  CONSTRAINT [tblEmployee_m136_HearingMembers_FK1] FOREIGN KEY([EmployeeId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])
END
GO

ALTER TABLE [dbo].[m136_HearingMembers] CHECK CONSTRAINT [tblEmployee_m136_HearingMembers_FK1]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='m136_luHearingResponses_m136_HearingMembers_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_HearingMembers]  WITH CHECK ADD  CONSTRAINT [m136_luHearingResponses_m136_HearingMembers_FK1] FOREIGN KEY([HearingResponse])
	REFERENCES [dbo].[m136_luHearingResponses] ([Id])
END
GO

ALTER TABLE [dbo].[m136_HearingMembers] CHECK CONSTRAINT [m136_luHearingResponses_m136_HearingMembers_FK1]
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[m136_HearingComments]') AND type in (N'U'))
	CREATE TABLE [dbo].[m136_HearingComments](
		[Id] [INT] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[HearingsId] [INT] NULL,
		[iMetaInfoTemplateRecordsId] [INT] NULL,
		[CreatedDate] [DateTime] NULL,
		[CreatedBy] [INT] NULL,
		[Comment] [nvarchar](MAX) NULL,
	 CONSTRAINT [m136_HearingComments_PK] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='m136_Hearings_m136_HearingComments_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_HearingComments]  WITH CHECK ADD  CONSTRAINT [m136_Hearings_m136_HearingComments_FK1] FOREIGN KEY([HearingsId])
	REFERENCES [dbo].[m136_Hearings] ([Id])
END
GO

ALTER TABLE [dbo].[m136_HearingComments] CHECK CONSTRAINT [m136_Hearings_m136_HearingComments_FK1]
GO

IF NOT EXISTS(SELECT * 
    FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS 
    WHERE CONSTRAINT_NAME ='m136_tblMetaInfoTemplateRecords_m136_HearingComments_FK1')
BEGIN
	ALTER TABLE [dbo].[m136_HearingComments]  WITH CHECK ADD  CONSTRAINT [m136_tblMetaInfoTemplateRecords_m136_HearingComments_FK1] FOREIGN KEY([iMetaInfoTemplateRecordsId])
	REFERENCES [dbo].[m136_tblMetaInfoTemplateRecords] ([iMetaInfoTemplateRecordsId])
END
GO

ALTER TABLE [dbo].[m136_HearingComments] CHECK CONSTRAINT [m136_tblMetaInfoTemplateRecords_m136_HearingComments_FK1]
GO

IF OBJECT_ID('[dbo].[m136_be_GetEmployees]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetEmployees] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetEmployees] 
	@iEmployeeId INT,
	@iDepartmentId INT,
	@bRecursive BIT,
	@strFirstName VARCHAR(50),
	@strLastName VARCHAR(50),
	@strLoginName VARCHAR(100),
	@iPageSize INT,
	@iPageIndex INT,
	@roleId INT = NULL,
	@ExcludedEmployeeId AS [dbo].[Item] READONLY
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @RoleEmployees TABLE(iEmployeeId INT NOT NULL PRIMARY KEY);
	IF(@roleId IS NOT NULL)
		INSERT INTO @RoleEmployees(iEmployeeId)
		SELECT 
			iEmployeeId 
		FROM 
			dbo.relEmployeeSecGroup
		WHERE iSecGroupId = @roleId;
	
	DECLARE @Departments TABLE(iDepartmentId INT NOT NULL PRIMARY KEY);
	INSERT INTO @Departments(iDepartmentId)
		SELECT 
			iDepartmentId 
		FROM 
			[dbo].[m136_GetDepartmentsRecursive](@iDepartmentId);
	SET @iPageIndex = @iPageIndex - 1;
    SELECT te.iEmployeeId, 
		te.iDepartmentId, 
		td.strName AS strDepartment,
		te.strFirstName, 
		te.strLastName, 
		te.strTitle, 
		CASE WHEN te.strAddress1 IS NULL OR te.strAddress1 = '' THEN 
				(CASE WHEN te.strAddress2 IS NULL OR te.strAddress2 = '' THEN 
						te.strAddress3 
					ELSE te.strAddress2 
				END)
			ELSE te.strAddress1 
		END AS [strAddress],
		te.iCountryId, 
		tc.strName AS strCountry,
		te.strPhoneHome, 
		te.strPhoneInternal, 
		te.strPhoneWork, 
		te.strPhoneMobile, 
		te.strBeeper, 
		te.strCallNumber, 
		te.strFax, 
		te.strEmail, 
		te.strLoginName, 
		te.strLoginDomain, 
		te.strComment,
		te.LastLogin,
		te.strExpDep,
		te.strEmployeeNo,
		te.strPassword,
		ROW_NUMBER() OVER (ORDER BY te.strFirstName ASC, te.strLastName ASC) AS RowNumber 
	INTO #Filters
    FROM dbo.tblEmployee te
    LEFT JOIN dbo.tblCountry tc ON tc.iCountryId = te.iCountryId
    LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
    WHERE (@iEmployeeId IS NULL OR te.iEmployeeId = @iEmployeeId)
    AND (@strFirstName IS NULL OR @strFirstName = '' OR te.strFirstName LIKE '%' + @strFirstName + '%')
    AND (@strLastName IS NULL OR @strLastName = '' OR te.strLastName LIKE '%' + @strLastName + '%')
    AND (@strLoginName IS NULL OR @strLoginName = '' OR te.strLoginName LIKE '%' + @strLoginName + '%')
    AND ((@bRecursive = 1 AND (te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		  OR (@bRecursive = 0 AND te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL))
	AND (@roleId IS NULL OR (@roleId IS NOT NULL AND te.iEmployeeId IN (SELECT iEmployeeId FROM @RoleEmployees)))
	AND te.iEmployeeId NOT IN (SELECT Id FROM @ExcludedEmployeeId);
    SELECT f.iEmployeeId, 
		f.iDepartmentId, 
		f.strDepartment, 
		f.strFirstName, 
		f.strLastName, 
		f.strTitle, 
		f.strAddress, 
		f.iCountryId, 
		f.strCountry, 
		f.strPhoneHome, 
		f.strPhoneInternal, 
		f.strPhoneWork, 
		f.strPhoneMobile, 
		f.strBeeper, 
		f.strCallNumber, 
		f.strFax, 
		f.strEmail, 
		f.strLoginName, 
		f.strLoginDomain, 
		f.strComment, 
		f.LastLogin,
		f.strExpDep, 
		f.strEmployeeNo,
		f.strPassword  
    FROM #Filters f
    WHERE (@iPageSize = 0 OR f.RowNumber BETWEEN (@iPageSize * @iPageIndex + 1) AND @iPageSize * (@iPageIndex + 1))
    ORDER BY f.RowNumber;
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateDocumentHearing] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateDocumentHearing] 
	@EntityId			INT,
	@IsPublic			BIT,
	@CreateBy		    INT,
	@DueDate			DATETIME,
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
    
	SET NOCOUNT ON;
	DECLARE @HearingId INT;
	
	INSERT INTO dbo.m136_Hearings(EntityId,IsPublic,CreatedDate,CreatedBy,DueDate,IsActive)
	VALUES(@EntityId, @IsPublic, GETDATE(), @CreateBy, @DueDate, 1)
	
	SET @HearingId = SCOPE_IDENTITY();
	
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead, HearingResponse)
	SELECT @HearingId, Id, 0, @CreateBy
	FROM @Employees
	
	UPDATE dbo.m136_tblDocument 
		SET iApproved = 3, iStatus = 1
	WHERE iEntityId = @EntityId
	
	SELECT @HearingId
	
COMMIT TRANSACTION;    
END TRY
BEGIN CATCH
    ROLLBACK
    
    DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
    SELECT @ErrorMessage = N'Error %d, Line %d, Message: ' + ERROR_MESSAGE(), @ErrorNumber = ERROR_NUMBER(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE(), @ErrorLine = ERROR_LINE();
    RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
END CATCH
END
GO