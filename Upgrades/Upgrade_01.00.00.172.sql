INSERT INTO #Description VALUES('Created tables for department management')
GO


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[luResponsibleTypes]') AND type in (N'U'))
	CREATE TABLE [dbo].[luResponsibleTypes](
		[Id] [tinyint] NOT NULL,
		[Name] [nvarchar](50) NOT NULL,
	 CONSTRAINT [PK_luResponsibleTypes] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * FROM [dbo].[luResponsibleTypes] WHERE Id = 1)
BEGIN
	INSERT [dbo].[luResponsibleTypes] ([Id], [Name]) VALUES (1, N'Leder')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[luResponsibleTypes] WHERE Id = 2)
BEGIN
	INSERT [dbo].[luResponsibleTypes] ([Id], [Name]) VALUES (2, N'Saksbehandler')
END
GO


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DepartmentResponsibles]') AND type in (N'U'))
BEGIN
	CREATE TABLE [dbo].[DepartmentResponsibles](
		[Id] [int] NOT NULL,
		[DepartmentId] [int] NOT NULL,
		[EmployeeId] [int] NOT NULL,
		[ResponsibleTypeId] [tinyint] NOT NULL,
	 CONSTRAINT [PK_DepartmentResponsibles] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
	
	
	ALTER TABLE [dbo].[DepartmentResponsibles]  WITH CHECK ADD  CONSTRAINT [FK_DepartmentResponsibles_ResponsibleTypes] FOREIGN KEY([ResponsibleTypeId])
	REFERENCES [dbo].[luResponsibleTypes] ([Id])

	ALTER TABLE [dbo].[DepartmentResponsibles] CHECK CONSTRAINT [FK_DepartmentResponsibles_ResponsibleTypes]

	ALTER TABLE [dbo].[DepartmentResponsibles]  WITH CHECK ADD  CONSTRAINT [FK_DepartmentResponsibles_tblDepartment1] FOREIGN KEY([DepartmentId])
	REFERENCES [dbo].[tblDepartment] ([iDepartmentId])

	ALTER TABLE [dbo].[DepartmentResponsibles] CHECK CONSTRAINT [FK_DepartmentResponsibles_tblDepartment1]

	ALTER TABLE [dbo].[DepartmentResponsibles]  WITH CHECK ADD  CONSTRAINT [FK_DepartmentResponsibles_tblEmployee1] FOREIGN KEY([EmployeeId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])

	ALTER TABLE [dbo].[DepartmentResponsibles] CHECK CONSTRAINT [FK_DepartmentResponsibles_tblEmployee1]
END
GO



IF OBJECT_ID('[dbo].[m136_be_SearchRoleMembers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SearchRoleMembers] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SearchRoleMembers]
	@iDepartmentId INT,
	@iRoleId INT,
	@strKeyword VARCHAR(100),
	@recursive BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET @strKeyword = ISNULL(@strKeyword, '');
	
	SELECT te.iEmployeeId, te.strFirstName, te.strLastName, te.strLoginName, td.strName AS strDepartment, td.iDepartmentId 
	FROM dbo.tblEmployee te
		LEFT JOIN dbo.tblDepartment td ON td.iDepartmentId = te.iDepartmentId
		WHERE (((@recursive = 0) AND (te.iDepartmentId = @iDepartmentId OR @iDepartmentId IS NULL OR @iDepartmentId = 0)) 
			OR (@recursive = 1 AND te.iDepartmentId IN (SELECT iDepartmentId FROM [dbo].[m136_GetDepartmentsRecursive](@iDepartmentId))))
		AND (te.strLoginName LIKE '%' + @strKeyword + '%' 
			OR te.strFirstName LIKE '%' + @strKeyword + '%' 
			OR te.strLastName LIKE '%' + @strKeyword + '%')
		AND (@iRoleId IS NULL OR te.iEmployeeId NOT IN (SELECT resg.iEmployeeId 
			FROM dbo.relEmployeeSecGroup resg WHERE resg.iSecGroupId = @iRoleId));
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetDepartmentReponsibles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetDepartmentReponsibles] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 15, 2015
-- Description:	Get all department responsibles by departmentId
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetDepartmentReponsibles]
	@iDepartmentId INT = 0,
	@iResponsibleType INT = 0,
	@PageSize INT = 0, -- If @PageSize = 0 we will get all available records.
	@PageIndex INT = 0
AS
BEGIN
	SET NOCOUNT ON;

    SELECT dr.Id,
		e.strLoginName,
		(e.strFirstName + ' ' + e.strLastName) AS strName,
		e.iEmployeeId,
		td.strName AS strDepartmentName,
		lrt.Name AS strResponsibleType,
		lrt.Id AS iResponsibleTypeId,
		dr.DepartmentId AS iDepartmentId,
		ROW_NUMBER() OVER (ORDER BY (e.strFirstName + ' ' + e.strLastName) ASC) AS rownumber
		INTO #Filters
    FROM dbo.DepartmentResponsibles dr
    INNER JOIN dbo.tblEmployee e ON e.iEmployeeId = dr.EmployeeId
    INNER JOIN dbo.tblDepartment td ON td.iDepartmentId = e.iDepartmentId
    INNER JOIN dbo.luResponsibleTypes lrt ON lrt.Id = dr.ResponsibleTypeId
    WHERE dr.DepartmentId = @iDepartmentId
		AND dr.ResponsibleTypeId = @iResponsibleType;
    
    SELECT f.* FROM #Filters f 
    WHERE (@PageSize = 0 OR rownumber BETWEEN @PageSize * @PageIndex + 1 AND @PageSize * (@PageIndex + 1)) ORDER BY rownumber;
	SELECT COUNT(*) FROM #Filters;
	DROP TABLE #Filters;            
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetResponsibleTypes]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetResponsibleTypes] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 16, 2015
-- Description:	Get responsible types
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_GetResponsibleTypes]
	@Id INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT lrt.* FROM dbo.luResponsibleTypes lrt WHERE lrt.Id = @Id OR @Id IS NULL;
END
GO


IF OBJECT_ID('[dbo].[m136_be_UpdateDepartmentResponsibles]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateDepartmentResponsibles] AS SELECT 1')
GO
-- =============================================
-- Author:		EM.LAM.VAN.MAI
-- Create date: DEC 17, 2015
-- Description:	Update department leaders
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_UpdateDepartmentResponsibles] 
	@iDepartmentId INT,
	@iResponsibleType INT,
	@DepartmentResponsibles AS [dbo].[Item] READONLY 
AS
BEGIN
	SET NOCOUNT ON;

    DECLARE @tDepartmentId INT, @tEmployeeId INT, @tResponsibleTypeId INT;
	DECLARE DepartmentResponsibles CURSOR FOR 
		SELECT Id,
			@iDepartmentId,
			@iResponsibleType
		FROM @DepartmentResponsibles;
		
	OPEN DepartmentResponsibles; 
	FETCH NEXT FROM DepartmentResponsibles INTO @tEmployeeId, @tDepartmentId, @tResponsibleTypeId;
	WHILE @@FETCH_STATUS = 0
    BEGIN
		IF NOT EXISTS(SELECT * FROM [dbo].[DepartmentResponsibles] 
			WHERE DepartmentId = @tDepartmentId
				AND EmployeeId = @tEmployeeId
				AND ResponsibleTypeId = @tResponsibleTypeId)
		BEGIN
			DECLARE @MaxId INT;
			SELECT @MaxId = MAX(dr.Id) FROM dbo.DepartmentResponsibles dr;
			
			SET @MaxId = ISNULL(@MaxId, 0);
			INSERT INTO dbo.DepartmentResponsibles
			(
				Id,
				DepartmentId,
				EmployeeId,
				ResponsibleTypeId
			)
			VALUES
			(
				(@MaxId + 1),
				@tDepartmentId,
				@tEmployeeId,
				@tResponsibleTypeId 
			)
		END
		FETCH NEXT FROM DepartmentResponsibles INTO @tEmployeeId, @tDepartmentId, @tResponsibleTypeId;
	END
	CLOSE DepartmentResponsibles;
	DEALLOCATE DepartmentResponsibles;
		
	DELETE dbo.DepartmentResponsibles WHERE DepartmentId = @iDepartmentId
	AND ResponsibleTypeId = @iResponsibleType
	AND EmployeeId NOT IN (SELECT Id FROM @DepartmentResponsibles);
END
GO