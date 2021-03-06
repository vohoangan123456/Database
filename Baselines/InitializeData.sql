SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
/*CREATE FULLTEXT INDEX*/
IF NOT EXISTS(SELECT 1 FROM sys.fulltext_indexes WHERE object_id = OBJECT_ID(N'[dbo].[m136x_tblTextIndex]'))
BEGIN
	DECLARE @indexKey NVARCHAR(200);
	DECLARE @sqlString NVARCHAR(MAX);
	
	SET @indexKey = (SELECT CONSTRAINT_NAME 
					 FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS 
					 WHERE TABLE_NAME = 'm136x_tblTextIndex' AND CONSTRAINT_TYPE = 'PRIMARY KEY')
	SET @sqlString = N'CREATE FULLTEXT INDEX ON [dbo].[m136x_tblTextIndex](totalvalue) KEY INDEX ' 
					 + @indexKey 
					 + N' ON Handbook WITH CHANGE_TRACKING AUTO;';
	
	EXEC(@sqlString)
END
GO

/****** Object:  Table [dbo].[tblApplication]    Script Date: 02/24/2016 11:22:43 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 95)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (95, N'scr.files.images', N'scr.files.images', 0, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 96)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (96, N'SecGroup', N'Enhancement to old Dashboard security.', 0, 0, 0, 0, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 97)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (97, N'scr.organisation', N'scr.organisation', 0, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 98)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (98, N'Group', N'Old Dashboard security.', 0, 0, 0, 0, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 99)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (99, N'Menu', N'Old Dashboard security.', 0, 0, 0, 0, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 123)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (123, N'scr.publish', N'scr.publish.desc', 3, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 136)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (136, N'Håndbok', N'En web basert håndboksmodul', 3, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 147)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (147, N'Metadata', N'Metadatamodul', 1, 0, 0, 0, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 151)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (151, N'eDeviation', N'eDeviation', 1, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 160)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (160, N'AnnualCycle', N'Annual Cycle', 1, 0, 0, -1, 0, N'', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblApplication] WHERE [iApplicationId] = 170)
BEGIN
	INSERT [dbo].[tblApplication] ([iApplicationId], [strName], [strDescription], [iMajorVersion], [iMinorVersion], [iBuildVersion], [iActive], [iHasAdmin], [strAdminIconURL], [strAdminEntryPage]) VALUES (170, N'RiskManagement', N'Risk Management', 1, 0, 0, 0, 0, N'', N'')
END
GO
/****** Object:  Table [dbo].[tblSecGroup]    Script Date: 02/23/2016 18:12:39 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblSecGroup] WHERE [iSecGroupId] = 0)
BEGIN
	INSERT [dbo].[tblSecGroup] ([iSecGroupId], [strName], [strDescription]) VALUES (0, N'Root group', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblSecGroup] WHERE [iSecGroupId] = 1)
BEGIN
	INSERT [dbo].[tblSecGroup] ([iSecGroupId], [strName], [strDescription]) VALUES (1, N'Administrator rolle', N'')
END
GO

/****** Object:  Table [dbo].[tblCountry]    Script Date: 02/23/2016 18:12:39 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblCountry] WHERE [iCountryId] = 0)
BEGIN
	INSERT [dbo].[tblCountry] ([iCountryId], [strName], [strEmergency1Text], [strEmergency1Nr], [strEmergency2Text], [strEmergency2Nr], [strEmergency3Text], [strEmergency3Nr], [strEmergency4Text], [strEmergency4Nr], [strEmergency5Text], [strEmergency5Nr], [strMessage]) VALUES (0, N'Root country', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
END
GO

/****** Object:  Table [dbo].[tblDepartment]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblDepartment] WHERE [iDepartmentId] = 0)
BEGIN
	SET IDENTITY_INSERT [dbo].[tblDepartment] ON
	INSERT [dbo].[tblDepartment] ([iDepartmentId], [iDepartmentParentId], [iCompanyId], [iMin], [iMax], [iLevel], [strName], [strDescription], [strContactInfo], [bCompany], [strPhone], [strFax], [strEmail], [strURL], [iCountryId], [strOrgNo], [strVisitAddress1], [strVisitAddress2], [strVisitAddress3], [strAddress1], [strAddress2], [strAddress3], [strFileURL], [iChildCount], [ADIdentifier]) VALUES (0, 0, 0, 1, 14, 0, N'Root department', N'Root department', N'', 0, N'', N'', N'', N'', 0, N'', N'', N'', N'', N'', N'', N'', N'', 5, N'b3a84fa5-a146-4340-b20f-abbf7acafba3')
	SET IDENTITY_INSERT [dbo].[tblDepartment] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblDepartment] WHERE [iDepartmentId] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[tblDepartment] ON
	INSERT [dbo].[tblDepartment] ([iDepartmentId], [iDepartmentParentId], [iCompanyId], [iMin], [iMax], [iLevel], [strName], [strDescription], [strContactInfo], [bCompany], [strPhone], [strFax], [strEmail], [strURL], [iCountryId], [strOrgNo], [strVisitAddress1], [strVisitAddress2], [strVisitAddress3], [strAddress1], [strAddress2], [strAddress3], [strFileURL], [iChildCount], [ADIdentifier]) VALUES (1, 0, 0, 8, 9, 1, N'Systembrukere - ikke slett!', N'', N'', 1, N'', N'', N'', N'', 0, N'', N'', N'', N'', N'', N'', N'', N'', 0, N'00000000-0000-0000-0000-000000000000')
	SET IDENTITY_INSERT [dbo].[tblDepartment] OFF
END
GO

/****** Object:  Table [dbo].[tblInformationType]    Script Date: 02/24/2016 10:07:56 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblInformationType] WHERE [iInformationTypeId] = 0)
BEGIN
	INSERT [dbo].[tblInformationType] ([iInformationTypeId], [strName], [strDescription], [strURL], [strParameters]) VALUES (0, N'scr.dummy.info.type', N'scr.reserved.not.usable', N'dummy.asp', N'')
END
GO

/****** Object:  Table [dbo].[tblGroup]    Script Date: 02/24/2016 10:05:26 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblGroup] WHERE [iGroupId] = 0)
BEGIN
	INSERT [dbo].[tblGroup] ([iGroupId], [iGroupMasterId], [iInformationTypeId], [strName], [strDescription], [strPath], [bHidden], [bMaster], [bSubscribe], [iAvailabilityId], [iChildCount], [iGroupParentId]) VALUES (0, 0, 0, N'Root group', N'', N'', 1, 0, 0, 0, 15, 0)
END
GO

IF  EXISTS (SELECT * FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[FK__tblItem_iAuthorId__tblEmployee_iEmployeeId]') AND parent_object_id = OBJECT_ID(N'[dbo].[tblItem]'))
ALTER TABLE [dbo].[tblItem] DROP CONSTRAINT [FK__tblItem_iAuthorId__tblEmployee_iEmployeeId]
GO


/****** Object:  Table [dbo].[tblItem]    Script Date: 02/24/2016 08:31:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblItem] WHERE [iItemId] = 0)
BEGIN
	INSERT [dbo].[tblItem] ([iItemId], [iInformationTypeId], [iGroupId], [iAuthorId], [dtmRegistered], [iHits], [iAvailabilityId]) VALUES (0, 0, 0, 0, CAST(0x8D3F0000 AS SmallDateTime), 0, 0)
END
GO

/****** Object:  Table [dbo].[tblEmployee]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblEmployee] WHERE [iEmployeeId] = 0)
BEGIN
	SET IDENTITY_INSERT [dbo].[tblEmployee] ON
	INSERT [dbo].[tblEmployee] ([iEmployeeId], [strEmployeeNo], [iDepartmentId], [strExpDep], [dtmEmployed], [strFirstName], [strLastName], [strTitle], [strAddress1], [strAddress2], [strAddress3], [iCountryId], [strPhoneHome], [strPhoneInternal], [strPhoneWork], [strPhoneMobile], [strBeeper], [strCallNumber], [strFax], [strEmail], [strLoginName], [strLoginDomain], [strPassword], [iCompanyId], [bWizard], [strComment], [iImageId], [bEmailConfirmed], [strMailPassword], [ADIdentifier], [LastLogin], [PreviousLogin]) VALUES (0, N'', 0, N'', CAST(0x8D3F0000 AS SmallDateTime), N'Dummy', N'Employee', N'', N'', N'', N'', 0, N'', N'', N'', N'', N'', N'', N'', N'Atle Solberg <Atle.Solberg@netpower.no>', N'', N'', N'E47052A624B382FF88B4A135A12CBAE4', 4, 0, N'', 0, 0, N'', N'00000000-0000-0000-0000-000000000000', CAST(0x0000A56700A107C9 AS DateTime), CAST(0x0000A56700A0DA70 AS DateTime))
	SET IDENTITY_INSERT [dbo].[tblEmployee] OFF
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblEmployee] WHERE [iEmployeeId] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[tblEmployee] ON
	INSERT [dbo].[tblEmployee] ([iEmployeeId], [strEmployeeNo], [iDepartmentId], [strExpDep], [dtmEmployed], [strFirstName], [strLastName], [strTitle], [strAddress1], [strAddress2], [strAddress3], [iCountryId], [strPhoneHome], [strPhoneInternal], [strPhoneWork], [strPhoneMobile], [strBeeper], [strCallNumber], [strFax], [strEmail], [strLoginName], [strLoginDomain], [strPassword], [iCompanyId], [bWizard], [strComment], [iImageId], [bEmailConfirmed], [strMailPassword], [ADIdentifier], [LastLogin], [PreviousLogin]) VALUES (1, N'', 1, N'', CAST(0x8D3F0000 AS SmallDateTime), N'Administrator', N'', N'', N'', N'', N'', 0, N'', N'', N'', N'', N'', N'', N'', N'Atle Solberg <Atle.Solberg@netpower.no>', N'administrator', N'', N'E47052A624B382FF88B4A135A12CBAE4', 4, 0, N'', 0, 0, N'', N'00000000-0000-0000-0000-000000000000', CAST(0x0000A56700A107C9 AS DateTime), CAST(0x0000A56700A0DA70 AS DateTime))
	SET IDENTITY_INSERT [dbo].[tblEmployee] OFF
END
GO


ALTER TABLE [dbo].[tblItem]  WITH CHECK ADD  CONSTRAINT [FK__tblItem_iAuthorId__tblEmployee_iEmployeeId] FOREIGN KEY([iAuthorId])
REFERENCES [dbo].[tblEmployee] ([iEmployeeId])
GO

ALTER TABLE [dbo].[tblItem] CHECK CONSTRAINT [FK__tblItem_iAuthorId__tblEmployee_iEmployeeId]
GO

/****** Object:  Table [dbo].[relEmployeeSecGroup]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[relEmployeeSecGroup] WHERE [iEmployeeId] = 1 AND [iSecGroupId] = 1)
BEGIN
	INSERT [dbo].[relEmployeeSecGroup] ([iEmployeeId], [iSecGroupId]) VALUES (1, 1)
END
GO

/****** Object:  Table [dbo].[tblPermissionSetType]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSetType] WHERE [iPermissionSetTypeId] = 1)
BEGIN
	INSERT [dbo].[tblPermissionSetType] ([iPermissionSetTypeId], [strName], [strDescription]) VALUES (1, N'System', N'Used internally in SiteManager')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSetType] WHERE [iPermissionSetTypeId] = 2)
BEGIN
	INSERT [dbo].[tblPermissionSetType] ([iPermissionSetTypeId], [strName], [strDescription]) VALUES (2, N'Application', N'Used for application level security')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSetType] WHERE [iPermissionSetTypeId] = 3)
BEGIN
	INSERT [dbo].[tblPermissionSetType] ([iPermissionSetTypeId], [strName], [strDescription]) VALUES (3, N'Object', N'Used for security on applications object')
END
GO

/****** Object:  Table [dbo].[luResponsibleTypes]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[luResponsibleTypes]') AND type in (N'U'))
	CREATE TABLE [dbo].[luResponsibleTypes](
		[Id] [tinyint] NOT NULL,
		[Name] [nvarchar](50) NOT NULL,
	 CONSTRAINT [PK_luResponsibleTypes] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO
IF NOT EXISTS(SELECT * FROM [dbo].[luResponsibleTypes] WHERE [Id] = 1)
BEGIN
	INSERT [dbo].[luResponsibleTypes] ([Id], [Name]) VALUES (1, N'Leder')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[luResponsibleTypes] WHERE [Id] = 2)
BEGIN
	INSERT [dbo].[luResponsibleTypes] ([Id], [Name]) VALUES (2, N'Saksbehandler')
END
GO

/****** Object:  Table [dbo].[DepartmentResponsibles]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[DepartmentResponsibles]') AND type in (N'U'))
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
GO
IF NOT EXISTS(SELECT * FROM [dbo].[DepartmentResponsibles] WHERE [Id] = 1)
BEGIN
	INSERT [dbo].[DepartmentResponsibles] ([Id], [DepartmentId], [EmployeeId], [ResponsibleTypeId]) VALUES (1, 1, 1, 1)
END
GO
/****** Object:  Table [dbo].[tblPermissionSet]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 92)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (92, 1, N'scr.country.privileges', N'scr.perm.manage.country')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 93)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (93, 1, N'scr.position.privileges', N'scr.perm.pos.adm')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 94)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (94, 1, N'scr.admin.menu.privileges', N'scr.perm.access.adm.menu')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 95)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (95, 1, N'scr.module.admin.privileges', N'scr.perm.manage.module.sec')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 96)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (96, 1, N'scr.secgroup.admin.privileges', N'scr.perm.manage.secgroups')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (99, 1, N'scr.standard.admin.privileges', N'scr.perm.old.db.sec')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 330)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (330, 2, N'scr.module.privileges', N'scr.module.privileges')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (331, 3, N'scr.category.privileges', N'scr.category.privileges')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 332)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (332, 3, N'scr.publish.item.privileges', N'scr.publish.item.privileges')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (460, 2, N'Modul rettigheter:', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (461, 3, N'Kapittel rettigheter:', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (462, 3, N'Dokument rettigheter:', N'')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 570)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (570, 2, N'Modulrettigheter', N'Modulrettigheter')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 571)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (571, 3, N'Registerrettigheter', N'Registerrettigheter')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 610)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (610, 2, N'eDeviation object privileges', N'eDeviation object privileges')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 611)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (611, 3, N'eDeviation object privileges', N'eDeviation object privileges')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 612)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (612, 3, N'Deviation category role permission', N'Deviation category role permission')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 613)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (613, 3, N'Deviation category department permission', N'Deviation category department permission')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 700)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (700, 2, N'AnnualCycle', N'AnnualCycle')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 701)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (701, 2, N'AnnualCycleRole', N'AnnualCycleRole')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 702)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (702, 2, N'AnnualCycleDepartment', N'AnnualCycleDepartment')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 703)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (703, 2, N'AnnualCycleRole', N'AnnualCycleRole')
END
GO

IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionSet] WHERE [iPermissionSetId] = 800)
BEGIN
	INSERT [dbo].[tblPermissionSet] ([iPermissionSetId], [iPermissionSetTypeId], [strName], [strDescription]) VALUES (800, 2, N'RMRole', N'Risk management role')
END
GO

/****** Object:  Table [dbo].[tblPermissionBit]    Script Date: 02/23/2016 17:52:19 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 92)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 92, N'scr.administrate.countries', N'scr.perm.adm.countries')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 93)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 93, N'scr.administrate', N'scr.perm.adm.pos')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 94)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 94, N'scr.access', N'scr.perm.view.adm.menu')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 95)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 95, N'scr.administrate', N'scr.perm.adm.module.sec')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 96)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 96, N'scr.add.user', N'scr.add.user.secgroup')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 99, N'sec.short.read', N'scr.read')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 330)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 330, N'scr.alloww.category.internet', N'scr.allow.user.category.internet')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 331, N'scr.read', N'scr.list.cat.name')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 332)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 332, N'scr.read', N'scr.read.item.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 460, N'Godkjenn Nivå 1', N'Tillat opprettelse godkjenning av nivå 1 dokumenter.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 461, N'L', N'Leserettigheter på kapittelnavnet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 462, N'L', N'Lese dokumenter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 570)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 570, N'Administrere metadata', N'Administrere metadata')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 570)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 571, N'L', N'Les')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 610)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 610, N'Melde inn', N'Melde inn')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 1 AND [iPermissionSetId] = 611)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (1, 611, N'L', N'Les')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 96)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 96, N'scr.remove.user', N'scr.remove.user.secgroup')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 99, N'sec.short.write', N'scr.write')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 330)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 330, N'scr.administrate.subscribers', N'scr.allow.adm.subscribers')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 331, N'scr.write', N'scr.add.child.categories')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 332)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 332, N'scr.write', N'scr.add.item.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 460, N'Administrere Håndbok', N'Administrasjon av håndbok.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 461, N'S', N'Legge til underkapitler.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 462, N'S', N'Legge til dokumenter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 571)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 571, N'S', N'Skriv')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 610)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 610, N'Behandle', N'Behandle')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 2 AND [iPermissionSetId] = 611)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (2, 611, N'B', N'Behandle')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 99, N'sec.short.change', N'scr.change')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 331, N'scr.change', N'scr.edit.this.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 332)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 332, N'scr.change', N'scr.edit.item.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 460, N'Se avdelingens lesekvitteringer', N'Se lesekvitteringer til de som er ansatt i samme organisasjonsenhet')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 461, N'E', N'Redigere dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 462, N'E', N'Redigere dokumenter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 571)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 571, N'E', N'Endre')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 4 AND [iPermissionSetId] = 610)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (4, 610, N'Administrere', N'Administrere')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 99, N'sec.short.delete', N'scr.delete')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 331, N'scr.delete', N'scr.delete.this.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 332)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 332, N'scr.delete', N'scr.delete.item.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 460, N'Tilgang til admin rapporter', N'Har tilgang til alle rapporter')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 461, N'F', N'Fjerne dette kapitellet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 462, N'F', N'Fjerne dokumenter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 8 AND [iPermissionSetId] = 571)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (8, 571, N'SL', N'Slette')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 99)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 99, N'sec.short.admin', N'scr.admin')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 331, N'scr.admin', N'scr.adm.security.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 460)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 460, N'Administrate Internet Documents', N'Enable to manage internet documents')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 461, N'A', N'Administrere rettigheter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 462, N'G', N'Godkjenne dokumenter i dette kapittelet.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 16 AND [iPermissionSetId] = 571)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (16, 571, N'A', N'Admin')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 32 AND [iPermissionSetId] = 331)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (32, 331, N'scr.editor', N'scr.editor.security.category')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 32 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (32, 461, N'SF', N'Tvangsabonnering på forsiden.')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 32 AND [iPermissionSetId] = 462)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (32, 462, N'A', N'Administrere dokumenter')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[tblPermissionBit] WHERE [iBitNumber] = 64 AND [iPermissionSetId] = 461)
BEGIN
	INSERT [dbo].[tblPermissionBit] ([iBitNumber], [iPermissionSetId], [strName], [strDescription]) VALUES (64, 461, N'SM', N'Tvangsabonnering pr epost.')
END
GO

/****** Object:  Table [dbo].[m136_tblInfoType]    Script Date: 02/24/2016 11:38:16 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (1, N'Nummer', N'Felt som kan inneholde ett 32 biters heltall.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 2)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (2, N'Tekst (liten)', N'Felt som kan inneholde opp til 100 tegn.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 3)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (3, N'Tekst', N'Felt som kan inneholde opp til 6000 tegn.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 4)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (4, N'Tekst (stor)', N'Felt som kan inneholde mer enn 6000 tegn.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 5)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (5, N'Dato', N'Felt for dato, kan også inneholde null.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblInfoType] WHERE [iInfoTypeId] = 6)
BEGIN
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] ON
	INSERT [dbo].[m136_tblInfoType] ([iInfoTypeId], [strName], [strDescription]) VALUES (6, N'Rik tekst', N'Felt som kan inneholde store tekstmengder med formatering.')
	SET IDENTITY_INSERT [dbo].[m136_tblInfoType] OFF
END
GO

/****** Object:  Table [dbo].[m136_tblProcessRelationType]    Script Date: 02/24/2016 11:53:07 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblProcessRelationType] WHERE [iRelationTypeId] = 0)
BEGIN
	INSERT [dbo].[m136_tblProcessRelationType] ([iRelationTypeId], [strName]) VALUES (0, N'Uspesifisert')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblProcessRelationType] WHERE [iRelationTypeId] = 1)
BEGIN
	INSERT [dbo].[m136_tblProcessRelationType] ([iRelationTypeId], [strName]) VALUES (1, N'Input /inngangsverdier')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblProcessRelationType] WHERE [iRelationTypeId] = 2)
BEGIN
	INSERT [dbo].[m136_tblProcessRelationType] ([iRelationTypeId], [strName]) VALUES (2, N'Styring')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblProcessRelationType] WHERE [iRelationTypeId] = 3)
BEGIN
	INSERT [dbo].[m136_tblProcessRelationType] ([iRelationTypeId], [strName]) VALUES (3, N'Outpur /utgangsverdier')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblProcessRelationType] WHERE [iRelationTypeId] = 4)
BEGIN
	INSERT [dbo].[m136_tblProcessRelationType] ([iRelationTypeId], [strName]) VALUES (4, N'Ressurser')
END
GO

/****** Object:  Table [dbo].[m136_tblRelationType]    Script Date: 02/24/2016 13:14:27 ******/
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 2)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (2, N'Image')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 5)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (5, N'Attachment')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 20)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (20, N'Interne vedlegg')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 50)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (50, N'Interne bilder')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 55)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (55, N'Interne bilder i editor')
END
GO
IF NOT EXISTS(SELECT * FROM [dbo].[m136_tblRelationType] WHERE [iRelationTypeId] = 136)
BEGIN
	INSERT [dbo].[m136_tblRelationType] ([iRelationTypeId], [strName]) VALUES (136, N'Article')
END
GO


INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'001', N'Upgrade_01.00.00.001.sql', N'Initialize Risk Management module')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'002', N'Upgrade_01.00.00.002.sql', N'Create analysis')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'003', N'Upgrade_01.00.00.003.sql', N'Create analysis')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'004', N'Upgrade_01.00.00.004.sql', N'Create analysis')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'005', N'Upgrade_01.00.00.005.sql', N'Risk evaluations')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'006', N'Upgrade_01.00.00.006.sql', N'Analysis attachments')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'007', N'Upgrade_01.00.00.007.sql', N'Analysis attachments')
INSERT [Risk].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'008', N'Upgrade_01.00.00.008.sql', N'Search analysis')
GO

INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'001', N'Upgrade_01.00.00.001.sql', N'Stored: GetCategory, GetCategoryById, GetCategoryByType, CreateCategory, EditCategory, DeleteCategory,
AddCustomField, UpdateCustomFieldAndItOption, DeleteCustomField,
AddCustomFieldOption, DeleteCustomFieldOptions,
CreateDeviation.
Table type: CustomFieldOptionTable, IdsTable')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'002', N'Upgrade_01.00.00.002.sql', N'Add SP to support deviation start page.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'003', N'Upgrade_01.00.00.003.sql', N'Add SP to support deviation registration.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'004', N'Upgrade_01.00.00.004.sql', N'add priority to deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'005', N'Upgrade_01.00.00.005.sql', N'Add SP to support deviation report Category number.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'006', N'Upgrade_01.00.00.006.sql', N'update deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'007', N'Upgrade_01.00.00.007.sql', N'handle unaccepted deviation after acceptance period')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'008', N'Upgrade_01.00.00.008.sql', N'update deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'009', N'Upgrade_01.00.00.009.sql', N'update deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'010', N'Upgrade_01.00.00.010.sql', N'Add DeviationDocument')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'011', N'Upgrade_01.00.00.011.sql', N'Edit GetDeviationByFilter stored')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'012', N'Upgrade_01.00.00.012.sql', N'Edit HandleExpiredUnAcceptedDeviation stored')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'013', N'Upgrade_01.00.00.013.sql', N'Update deviation tasks')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'014', N'Upgrade_01.00.00.014.sql', N'create GetRolesWithXPremissionOfYModule sp')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'015', N'Upgrade_01.00.00.015.sql', N'edit getNotification sp')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'016', N'Upgrade_01.00.00.016.sql', N'Update deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'017', N'Upgrade_01.00.00.017.sql', N'Implement reopening deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'018', N'Upgrade_01.00.00.018.sql', N'Create SP for Report.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'019', N'Upgrade_01.00.00.019.sql', N'Implement delete/restore deviation')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'020', N'Upgrade_01.00.00.020.sql', N'Update GetDeviationByFilter')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'021', N'Upgrade_01.00.00.021.sql', N'Update GetDeviationByFilter')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'022', N'Upgrade_01.00.00.022.sql', N'Update [Deviation].[CategoryWiseLoadActions] and [Deviation].[CategoryWiseLoadAll]')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'023', N'Upgrade_01.00.00.023.sql', N'Implement ServiceAreas')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'024', N'Upgrade_01.00.00.024.sql', N'Update GetDeviationByFilter')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'025', N'Upgrade_01.00.00.025.sql', N'Add AddCategoryImage')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'026', N'Upgrade_01.00.00.026.sql', N'Fix report CategoryWiseLoadAll')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'027', N'Upgrade_01.00.00.027.sql', N'Implement Category - Severity tooltip')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'028', N'Upgrade_01.00.00.028.sql', N'Update SP for reports')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'029', N'Upgrade_01.00.00.029.sql', N'Update SPs for home page')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'030', N'Upgrade_01.00.00.030.sql', N'Fixed HandledByDepartment')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'031', N'Upgrade_01.00.00.031.sql', N'Get OwnerId')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'032', N'Upgrade_01.00.00.032.sql', N'Support new statuses for deviation in-progress.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'033', N'Upgrade_01.00.00.033.sql', N'Support new statuses for deviation in-progress.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'034', N'Upgrade_01.00.00.034.sql', N'Support new statuses for deviation in-progress.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'035', N'Upgrade_01.00.00.035.sql', N'Get OwnerEmail.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'037', N'Upgrade_01.00.00.037.sql', N'Get in-progress status.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'036', N'Upgrade_01.00.00.036.sql', N'Get deviation title, category nmae, category type.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'038', N'Upgrade_01.00.00.038.sql', N'Fix searching deviations and search base actions.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'039', N'Upgrade_01.00.00.039.sql', N'Add column UpdatedDate to BaseAction table.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'040', N'Upgrade_01.00.00.040.sql', N'Add column sequenceId for my deviation tasks.')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'041', N'Upgrade_01.00.00.041.sql', N'Add SP for add manually deviation log')
INSERT [Deviation].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'042', N'Upgrade_01.00.00.042.sql', N'Fixed get deviation attachments.')
GO

/****** Object:  Table [dbo].[SchemaChanges]    Script Date: 11/03/2016 17:59:28 ******/
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'000', N'Upgrade_01.00.00.000.sql', N'Create table SchemaChanges')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'001', N'Upgrade_01.00.00.001.sql', N'Create stored procedure to get chapter items,
 read access,
 document information,
 list of document approved within x days, 
 approved subscription,
 most view document,
 my favourite, 
 recent documents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'002', N'Upgrade_01.00.00.002.sql', N'Create stored procedure to get chapter items,
 read access,
 document information,
 list of document approved within x days, 
 approved subscription,
 most view document,
 my favourite,
 recent documents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'003', N'Upgrade_01.00.00.003.sql', N'Change iLevelType as Level --> iLevel as Level')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'004', N'Upgrade_01.00.00.004.sql', N'Removed comparison procedure. ')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'005', N'Upgrade_01.00.00.005.sql', N'Adding level type to the GetChapterItems')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'006', N'Upgrade_01.00.00.006.sql', N'update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'007', N'Upgrade_01.00.00.007.sql', N'Adding field [responsible]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'008', N'Upgrade_01.00.00.008.sql', N'Adding field IsNew')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'009', N'Upgrade_01.00.00.009.sql', N'Checking last login for getting what new count')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'010', N'Upgrade_01.00.00.010.sql', N'update store procedure [dbo].[m136_GetDocumentInformation] and create new store procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'011', N'Upgrade_01.00.00.011.sql', N'create new stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
edit stored procedure
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'012', N'Upgrade_01.00.00.012.sql', N'Update m136_GetChapterReadAccess to not contain HandbookTest')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'013', N'Upgrade_01.00.00.013.sql', N'update store procedure for review code')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'014', N'Upgrade_01.00.00.014.sql', N'edit stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'015', N'Upgrade_01.00.00.015.sql', N'edit stored procedure [dbo].[m136_GetFileContents] and [dbo].[m136_GetDocumentConfirmationDate]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'016', N'Upgrade_01.00.00.016.sql', N'edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'017', N'Upgrade_01.00.00.017.sql', N'edit stored procedure 
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_AddDocumentToFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
[dbo].[m136_GetChapterItems],
[dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'018', N'Upgrade_01.00.00.018.sql', N'Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'019', N'Upgrade_01.00.00.019.sql', N'edit stored procedure 
[dbo].[m136_RemoveHandbookOffFavorites],
[dbo].[m136_RemoveDocumentOffFavorites],
format the stored
[dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'020', N'Upgrade_01.00.00.020.sql', N'Add stored m136_GetApprovedDocumentsByHandbookIdRecursive for getting all documents - includes sub folders.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'021', N'Upgrade_01.00.00.021.sql', N'edit stored procedure
[dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'022', N'Upgrade_01.00.00.022.sql', N'Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetLatestApprovedSubscriptions], [dbo].[m136_GetDocumentsApprovedWithinXDays] for getting HasAttachment.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'023', N'Upgrade_01.00.00.023.sql', N'Updated m136_GetApprovedDocumentsByHandbookIdRecursive')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'024', N'Upgrade_01.00.00.024.sql', N'Modify stored procedure to remove the join to the documenttype table.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'025', N'Upgrade_01.00.00.025.sql', N'Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'026', N'Upgrade_01.00.00.026.sql', N'Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetLatestApprovedSubscriptions], [dbo].[m136_GetDocumentsApprovedWithinXDays] for getting HasAttachment.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'027', N'Upgrade_01.00.00.027.sql', N'Modify function [dbo].[fnHasDocumentAttachment]: only check iRelationTypeId = 20.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'028', N'Upgrade_01.00.00.028.sql', N'Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'029', N'Upgrade_01.00.00.029.sql', N'create stored
[dbo].[m136_NormalSearch]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'030', N'Upgrade_01.00.00.030.sql', N'Updated [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'031', N'Upgrade_01.00.00.031.sql', N'repalce stored
[dbo].[m136_NormalSearch]
with stored
[dbo].[m136_SearchDocuments ]
add fulltext index search for tblDocument and tblTextIndex
add stored procedure m136_SearchDocumentsById
add stored
[dbo].[m136_SearchDocumentsById]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'032', N'Upgrade_01.00.00.032.sql', N'Modify stored procedure [dbo].[m136_GetChapterItems], [dbo].[m136_GetApprovedDocumentsByHandbookIdRecursive] for getting all documents of sub folders.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'033', N'Upgrade_01.00.00.033.sql', N'Modify stored procedure [dbo].[m136_GetChapterItems] for setting tree content level.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'034', N'Upgrade_01.00.00.034.sql', N'Modify stored procedure [dbo].[m136_GetChapterItems] revert back to script 32.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'035', N'Upgrade_01.00.00.035.sql', N'Stored procedure [m136_GetDocumentLatestApproved] added')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'036', N'Upgrade_01.00.00.036.sql', N'add stored
[dbo].[m136_AddHandbookToEmailSubscription],
[dbo].[m136_RemoveHandbookFromEmailSubscription],
[dbo].[m136_GetUserEmailSubsciptions]
update stored
[dbo].[m136_AddHandbookToFavorites],
[dbo].[m136_RemoveHandbookOffFavorites]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'037', N'Upgrade_01.00.00.037.sql', N'add stored procedure [dbo].[m136_AuthenticateDomainUser]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'038', N'Upgrade_01.00.00.038.sql', N'update stored
[dbo][m136_GetMyFavorites],
[dbo][m136_GetLatestApprovedSubscriptions]
Create function
[dbo].[m136_fnGetFavoriteFolders],
[dbo].[m136_IsForcedHandbook]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'039', N'Upgrade_01.00.00.039.sql', N'Init upgrade script for GastroHandbook App')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'040', N'Upgrade_01.00.00.040.sql', N'Rename procedure [dbo].[m136_SearchDocuments]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'041', N'Upgrade_01.00.00.041.sql', N'Changed stored procedures to not use the UTC')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'042', N'Upgrade_01.00.00.042.sql', N'Add reversed columns for title and description to m136_tblDocument. Add trigger to autofill these new columns. Add to full-text')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'043', N'Upgrade_01.00.00.043.sql', NULL)
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'044', N'Upgrade_01.00.00.044.sql', N'New way of getting latest documents (whats new); previous login removed; login is updated and returned in authenticate procedures')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'045', N'Upgrade_01.00.00.045.sql', N'Edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'046', N'Upgrade_01.00.00.046.sql', N'update stored m136_SearchDocuments, m136_SearchDocumentsById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'047', N'Upgrade_01.00.00.047.sql', N'Some fixes to the updated favorites')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'048', N'Upgrade_01.00.00.048.sql', N'Edit stored procedure [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'049', N'Upgrade_01.00.00.049.sql', N'Edit type of dtmAccessed column and edit store procedure [dbo].[m136_InsertOrUpdateDocAccessLog], [dbo].[m136_LogDocumentRead]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'050', N'Upgrade_01.00.00.050.sql', N'Updated GetDocumentInformation')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'051', N'Upgrade_01.00.00.051.sql', N'Loading file document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'052', N'Upgrade_01.00.00.052.sql', N'update stored m136_SearchDocuments, m136_SearchDocumentsById fix Total to TotalCount')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'053', N'Upgrade_01.00.00.053.sql', N'Updated m136_GetDocumentFieldsAndRelates')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'054', N'Upgrade_01.00.00.054.sql', N'm136_GetFileOrImageContents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'063', N'Upgrade_01.00.00.063.sql', N'Modify stored procedure m136_GetMetadataGroupsRecursive and m136_GetDocumentMetatags for extracting a function that get handbook recursive.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'064', N'Upgrade_01.00.00.064.sql', N'update stored [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'065', N'Upgrade_01.00.00.065.sql', N'Modify stored procedure m136_GetApprovedDocumentsByHandbookIdRecursive for reusing function [dbo].[m136_GetHandbookRecursive].')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'066', N'Upgrade_01.00.00.066.sql', N'update m136_SearchDocument and m136_SearchDocumentById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'067', N'Upgrade_01.00.00.067.sql', N'Modified stored procedure m136_GetDocumentMetatags for reorder metatag value, unclassified group shoud be bottom.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'068', N'Upgrade_01.00.00.068.sql', N'Update stored m136_UpdateFavoriteSortOrder to m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'069', N'Upgrade_01.00.00.069.sql', N'update m136_SearchDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'070', N'Upgrade_01.00.00.070.sql', N'Update stored m136_UpdateFavoriteSortOrders, m136_GetUserEmailSubsciptionsFolders')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'073', N'Upgrade_01.00.00.073.sql', N'Create procedure [dbo].[m136_ProcessLatestApprovedDocuments] and [dbo].[m136_SetVersionFlags] for updating LatestApproved when dtmPublishDate in the future.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'055', N'Upgrade_01.00.00.055.sql', N'Search update')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'056', N'Upgrade_01.00.00.056.sql', N'Updated Clustered Indexes')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'057', N'Upgrade_01.00.00.057.sql', N'Create stored procedure m136_GetMetadataGroups for getting metadata group.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'058', N'Upgrade_01.00.00.058.sql', N'create stored [dbo].[m136_GetUserEmailSubsciptionsFolder],
[m136_UpdateFavoritesSortOrder]
table value type UpdatedFavoriteItemsTable, 
update stored [dbo][m136_GetMyFavorites] to get iSort values')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'059', N'Upgrade_01.00.00.059.sql', N'Update GetParentPathEx')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'060', N'Upgrade_01.00.00.060.sql', N'update stored [dbo].[m136_SearchDocumentsById]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'061', N'Upgrade_01.00.00.061.sql', N'Update procedure [dbo].[m136_GetDocumentData]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'062', N'Upgrade_01.00.00.062.sql', N'Modify stored procedure m136_GetMetadataGroupsRecursive and m136_GetDocumentMetatags for extracting a function that get handbook recursive.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'071', N'Upgrade_01.00.00.071.sql', N'Implement exportjob as background.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'072', N'Upgrade_01.00.00.072.sql', N'Create procedure [dbo].[m136_DeleteExportJobs]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'074', N'Upgrade_01.00.00.074.sql', N'Update stored m136_SearchDocumentsById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'075', N'Upgrade_01.00.00.075.sql', N'Update seed to insert new data for feedback and readConfirm table')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'076', N'Upgrade_01.00.00.076.sql', N'Create stored procedure [dbo].[m136_GetMenuGroups] for getting menu group in start page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'077', N'Upgrade_01.00.00.077.sql', N'update m136_SearchDocument, m136_SearchDocumentById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'078', N'Upgrade_01.00.00.078.sql', N'Update m136_GetChapterItems, m136_GetApprovedDocumentsByHandbookIdRecursive for adding folder icon into grid.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'079', N'Upgrade_01.00.00.079.sql', N'Updated m136_GetMenuGroups.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'080', N'Upgrade_01.00.00.080.sql', N'Updated m136_GetMenuGroups for dtmRemove, dtmDisplay, bNewWindow.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'081', N'Upgrade_01.00.00.081.sql', N'Created m136_be_GetMyWorkingDocuments for getting my under revision documents.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'082', N'Upgrade_01.00.00.082.sql', N'Create m136_be_GetParentsIncludeSelf')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'083', N'Upgrade_01.00.00.083.sql', N'Create stored procedures create folder page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'084', N'Upgrade_01.00.00.084.sql', N'Create stored procedures edit folder page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'085', N'Upgrade_01.00.00.085.sql', N'Create stored procedures edit information page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'086', N'Upgrade_01.00.00.086.sql', N'Create m136_be_GetPreviousVersions, 
m136_be_GetUserWithApprovePermission,
m136_be_GetUserWithCreatePermission')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'087', N'Upgrade_01.00.00.087.sql', N'Create functions [dbo].[fn136_GetParentPathExNew] for simple searching.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'088', N'Upgrade_01.00.00.088.sql', N'Modified stored procedures for folder permission.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'089', N'Upgrade_01.00.00.089.sql', N'Created stored procedures for update folder documents.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'090', N'Upgrade_01.00.00.090.sql', N'Create [dbo].[m136_be_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'091', N'Upgrade_01.00.00.091.sql', N'Create stored procedures for document types management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'092', N'Upgrade_01.00.00.092.sql', N'Create stored procedures for searching departments.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'093', N'Upgrade_01.00.00.093.sql', N'Create stored procedures for document template management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'095', N'Upgrade_01.00.00.095.sql', N'Create stored procedures roles management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'096', N'Upgrade_01.00.00.096.sql', N'Create stored procedures handbook permissions management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'097', N'Upgrade_01.00.00.097.sql', N'Alter procefures for getting document templates and theirs fields.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'098', N'Upgrade_01.00.00.098.sql', N'Create stored procedure for update security group.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'101', N'Upgrade_01.00.00.101.sql', N'Create stored procedure for security.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'102', N'Upgrade_01.00.00.102.sql', N'Create stored procedure for security.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'103', N'Upgrade_01.00.00.103.sql', N'Create stored procedure for staff management.')
GO
print 'Processed 100 total records'
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'104', N'Upgrade_01.00.00.104.sql', N'Modify stored procedure folders/documents management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'105', N'Upgrade_01.00.00.105.sql', N'Modify stored procedure for admin role permissions management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'106', N'Upgrade_01.00.00.106.sql', N'Create stored procedures for document management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'107', N'Upgrade_01.00.00.107.sql', N'Update store [dbo].[m136_be_GetDocumentEventLog] and [dbo].[m136_be_GetPreviousVersions] and create store [dbo].[m136_be_GetDocumentInformationByEntityId] ')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'108', N'Upgrade_01.00.00.108.sql', N'Create stored procedures for document management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'109', N'Upgrade_01.00.00.109.sql', N'Create stored procedures for department management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'110', N'Upgrade_01.00.00.110.sql', N'Create stored procedures for related attachments management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'094', N'Upgrade_01.00.00.094.sql', N'Create stored procedures for document fields management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'099', N'Upgrade_01.00.00.099.sql', N'Create [dbo].[m136_be_GetTemplateMetaInfo]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'111', N'Upgrade_01.00.00.111.sql', N'Create stored procedures for Get reading confrim of ducument.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'112', N'Upgrade_01.00.00.112.sql', N'Alter stored procedures m136_be_UpdateFolderDocuments.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'113', N'Upgrade_01.00.00.113.sql', N'Create stored procedures for related management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'114', N'Upgrade_01.00.00.114.sql', N'Create stored procedures for News backend.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'115', N'Upgrade_01.00.00.115.sql', N'Create stored procedures for sorting document types.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'116', N'Upgrade_01.00.00.116.sql', N'Create stored procedures getting documents recursive.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'117', N'Upgrade_01.00.00.117.sql', N'Create store verify delete Folder.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'118', N'Upgrade_01.00.00.118.sql', N'Get Permission by UserId.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'119', N'Upgrade_01.00.00.119.sql', N'Alter [dbo].[m136_GetDocumentInformation] store')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'120', N'Upgrade_01.00.00.120.sql', N'Create stored procedure for making reporting: my reading receipts.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'121', N'Upgrade_01.00.00.121.sql', N'Create stored procedure get virtual of a document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'122', N'Upgrade_01.00.00.122.sql', N'Create stored procedure for update document information')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'124', N'Upgrade_01.00.00.124.sql', N'Create some stored procedures to support feature Approve document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'125', N'Upgrade_01.00.00.125.sql', N'Modify procedure m136_be_GetUserWithApprovePermissionOnDocument, create procedure m136_be_GetUserApprovedOnLatestDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'126', N'Upgrade_01.00.00.126.sql', N'Create and modify some stored procedure to support feature Send Document To Approval and Approve Document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'127', N'Upgrade_01.00.00.127.sql', N'Modified m136_be_InsertFolder to make sure folder permissions be created')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'128', N'Upgrade_01.00.00.128.sql', N'Add one more document permission for managing documents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'129', N'Upgrade_01.00.00.129.sql', N'Create procedure  [dbo].[m136_be_GetDocumentsByDocumentIds]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'130', N'Upgrade_01.00.00.130.sql', N'Alter stored procedures admin roles.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'131', N'Upgrade_01.00.00.131----.sql', N'Alter stored procedures advance search.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'131', N'Upgrade_01.00.00.131.sql', N'Create procedure  [dbo].[m136_be_ReopenDocument] ')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'135', N'Upgrade_01.00.00.135.sql', N'Create stored procedure m136_be_RestoreDocuments')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'136', N'Upgrade_01.00.00.136.sql', N'Modify stored procedures related to refactoring feature delete documents.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'137', N'Upgrade_01.00.00.137.sql', N'Modify stored procedures related to refactor notify message.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'138', N'Upgrade_01.00.00.138.sql', N'CREATE stored procedures [dbo].[m136_be_GetUsersHavePermissionsForSpecifiedDocuments]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'139', N'Upgrade_01.00.00.139.sql', N'Modified stored procedures for getting iDeleted')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'140', N'Upgrade_01.00.00.140.sql', N'Modify procedure m136_be_SendDocumentToApproval')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'141', N'Upgrade_01.00.00.141.sql', N'Modified stored procedures for getting iDeleted')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'142', N'Upgrade_01.00.00.142.sql', N'Modify procedure [dbo].[m136_be_CreateNewDocumentVersion]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'143', N'Upgrade_01.00.00.143.sql', N'Modified stored procedure for updating document.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'144', N'Upgrade_01.00.00.144.sql', N'Modified stored procedure for administrator.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'162', N'Upgrade_01.00.00.162.sql', N'Modified stored procedure [dbo].[m136_be_ArchiveDocument]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'163', N'Upgrade_01.00.00.163.sql', N'Drop procedure m136_be_GetAuthorEmailOfDocument, modify procedures m136_be_GetDocumentInformation, fnDocumentCanBeApproved, m136_be_UserCanApproveDocument, m136_be_ApproveDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'164', N'Upgrade_01.00.00.164.sql', N'Modified stored procedures for getting iCreatedbyId')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'165', N'Upgrade_01.00.00.165.sql', N'Modify procedure m136_be_ChangeInternetDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'166', N'Upgrade_01.00.00.166.sql', N'Created stored procedures for home page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'167', N'Upgrade_01.00.00.167.sql', N'Modify stored procedures [dbo].[m136_GetDocumentFieldsAndRelates].')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'168', N'Upgrade_01.00.00.168.sql', N'Created stored procedures for home page.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'170', N'Upgrade_01.00.00.170.sql', N'Modify procedure and raiser error')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'171', N'Upgrade_01.00.00.171.sql', N'Modify stored procedure for edit document template fields')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'172', N'Upgrade_01.00.00.172.sql', N'Created tables for department management')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'173', N'Upgrade_01.00.00.173.sql', N'Modified stored procedure for get document information by entityId')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'174', N'Upgrade_01.00.00.174.sql', N'Created SP for rollback document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'177', N'Upgrade_01.00.00.177.sql', N'CREATE SP [m136_be_GetApplicationPermissionsByUserId]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'100', N'Upgrade_01.00.00.100.sql', N'Create stored procedure for update security group.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'145', N'Upgrade_01.00.00.145.sql', N'Modified stored procedure for creating document.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'169', N'Upgrade_01.00.00.169.sql', N'Modify procedure m136_be_RestoreDocuments')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'175', N'Upgrade_01.00.00.175.sql', N'Created SP for getting module permissions')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'176', N'Upgrade_01.00.00.176.sql', N'ALTER SP GetdocumentInformation')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'178', N'Upgrade_01.00.00.178.sql', N'Created SP for getting deviation department permissions')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'179', N'Upgrade_01.00.00.179.sql', N'Add new columns and procedures to support feature News Category Management')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'180', N'Upgrade_01.00.00.180.sql', N'Created SP for metadata permissions management')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'185', N'Upgrade_01.00.00.185.sql', N'Create types, procedures to support for feature Tag metadata to Chapter, Document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'186', N'Upgrade_01.00.00.186.sql', N'Created script for update folder information')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'187', N'Upgrade_01.00.00.187.sql', N'Update script for metadata')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'188', N'Upgrade_01.00.00.188.sql', N'Created script getting folders recursive')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'189', N'Upgrade_01.00.00.189.sql', N'Created script for updating role folder permissions')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'190', N'Upgrade_01.00.00.190.sql', N'Create procedure m136_be_GetEmployeeDocumentConfirms')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'191', N'Upgrade_01.00.00.191.sql', N'Modify procedures m136_be_GetNewsForStartpage, m136_be_GetNewsById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'192', N'Upgrade_01.00.00.192.sql', N'Created script for updating department information')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'193', N'Upgrade_01.00.00.193.sql', N'create SP for reading reciept folder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'194', N'Upgrade_01.00.00.194.sql', N'Created script for my reading reciept folder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'195', N'Upgrade_01.00.00.195.sql', N'Created script for getting document information.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'196', N'Upgrade_01.00.00.196.sql', N'Create some procedures to support feature Menu Management.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'197', N'Upgrade_01.00.00.197.sql', N'Update Store Insert folder.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'198', N'Upgrade_01.00.00.198.sql', N'Modify stored procedures m136_GetMenuGroups')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'199', N'Upgrade_01.00.00.199.sql', N'Updated script for getting documents recursive.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'200', N'Upgrade_01.00.00.200.sql', N'Updated script for getting menus.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'201', N'Upgrade_01.00.00.201.sql', N'Add table CacheUpdate, add some procedures and modify some existing procedures to support update frontend''s cache from changes in backend')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'202', N'Upgrade_01.00.00.202.sql', N'Implmenet feature show news by sites, update fields dtmCreated and dtmChanged when news is created, changed, seperate procedure GetNewsById into 2 procedures GetActivenewsById and GetNewsById')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'203', N'Upgrade_01.00.00.203.sql', N'Implmenet get Report folder Statistics')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'206', N'Upgrade_01.00.00.206.sql', N'Create table EditorTemplate and some related sql script to load, create, update, delete editor templates.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'207', N'Upgrade_01.00.00.207.sql', N'Modify procedure m147_be_LinkDocumentToRegisterItemValues')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'208', N'Upgrade_01.00.00.208.sql', N'Create procedure m136_GetAttachmentsInFolder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'209', N'Upgrade_01.00.00.209.sql', N'Add procedures to support feature multi secondary departments for employee.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'210', N'Upgrade_01.00.00.210.sql', N'Get active metadata registers')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'212', N'Upgrade_01.00.00.212.sql', N'Modify procedure m136_GetAttachmentsInFolder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'213', N'Upgrade_01.00.00.213.sql', N'Add SP for retrieve from send to approval')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'214', N'Upgrade_01.00.00.214.sql', N'Create tables and procedures support feature manage reading lists')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'215', N'Upgrade_01.00.00.215.sql', N'Add sp for fixing report issues')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'216', N'Upgrade_01.00.00.216.sql', N'Modify some existing procedures and create some new procedures support for feature show reading document list in Frontend.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'217', N'Upgrade_01.00.00.217.sql', N'Loading file document by DocumentId')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'218', N'Upgrade_01.00.00.218.sql', N'Update SP [dbo].[m136_be_ReportDocumentsPerFolder]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'219', N'Upgrade_01.00.00.219.sql', N'Create SP for function Change document draft template')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'220', N'Upgrade_01.00.00.220.sql', N'Update SP for report Update Folder statistics ')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'221', N'Upgrade_01.00.00.221.sql', N'Create procedures, modify existing procedures to support feature allow only one user can edit document at the same time')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'222', N'Upgrade_01.00.00.222.sql', N'Update get treelist sp m136_be_GetChapterItems and m136_GetChapterItems')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'225', N'Upgrade_01.00.00.225.sql', N'Modify procedure m136_be_CreateNewsCategory')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'226', N'Upgrade_01.00.00.226.sql', N'Add procedure [dbo].[m136_be_EmployeesWithPermissions]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'227', N'Upgrade_01.00.00.227.sql', N'Change structure of table ReadingListDocuments and modify some existing procedures related to reading list feature')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'123', N'Upgrade_01.00.00.123.sql', N'Create stored procedure reject of a document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'211', N'Upgrade_01.00.00.211.sql', N'Set default permissions for root folder')
GO
print 'Processed 200 total records'
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'223', N'Upgrade_01.00.00.223.sql', N'Update SP [dbo].[m136_be_ReportHandbookUpdatedOverview]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'224', N'Upgrade_01.00.00.224.sql', N'Create procedure m136_be_EmployeePermissionsToFolder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'228', N'Upgrade_01.00.00.228.sql', N'Update SPs with checking NULL identifier')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'229', N'Upgrade_01.00.00.229.sql', N'Update m136_be_GetRoleMembers, m136_be_GetDepartmentReponsibles')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'230', N'Upgrade_01.00.00.230.sql', N'Update SPs with checking NULL identifier')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'231', N'Upgrade_01.00.00.231.sql', N'Modify existing procedures m136_be_GetDocumentInformation, m136_LockDocument. Create new procedures m136_HasLockDocumentWithId, m136_UnlockDocumentByAdmin')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'232', N'Upgrade_01.00.00.232.sql', N'Modify SP for print')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'233', N'Upgrade_01.00.00.233.sql', N'Create type MenuPermission, modify existing procedures be_GetChildMenusOf, be_GetMenuById, be_CreateMenu, be_UpdateMenu')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'235', N'Upgrade_01.00.00.235.sql', N'Support Flowchartimage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'236', N'Upgrade_01.00.00.236.sql', N'Update be_GetSecondaryDepartmentsOfUser')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'246', N'Upgrade_01.00.00.246.sql', N'Add default image for CKEditor''s Content Template')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'247', N'Upgrade_01.00.00.247.sql', N'Modify procedure be_UpdateReadingList')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'248', N'Upgrade_01.00.00.248.sql', N'Update Catch section for procedures be_CreateMenu, be_UpdateMenu, be_DeleteMenus')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'249', N'Upgrade_01.00.00.249.sql', N'update SP [dbo].[m136_be_GetEmployeeDocumentConfirms]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'250', N'Upgrade_01.00.00.250.sql', N'update SP [dbo].[m136_spReportFolderDocumentStatistics]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'251', N'Upgrade_01.00.00.251.sql', N'Update SPs supporting readCount')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'252', N'Upgrade_01.00.00.252.sql', N'Add procedures to support feature move doc/folder in tree view')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'253', N'Upgrade_01.00.00.253.sql', N'Add table and SP for document hearing action')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'254', N'Upgrade_01.00.00.254.sql', N'Fix flow chart load existed image.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'255', N'Upgrade_01.00.00.255.sql', N'Update SP for News')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'256', N'Upgrade_01.00.00.256.sql', N'Create SP for Document action hearing - active')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'257', N'Upgrade_01.00.00.257.sql', N'Create SP for Document action hearing - Edit')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'258', N'Upgrade_01.00.00.258.sql', N'Create procedure m136_be_GetDocumentInformationHaveVersion')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'259', N'Upgrade_01.00.00.259.sql', N'Implement verifying document links')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'260', N'Upgrade_01.00.00.260.sql', N'Fix readcount for recursive querying')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'262', N'Upgrade_01.00.00.262.sql', N'Modified fn136_GetParentPathEx. Add one more check for folder which is belong to root folder.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'265', N'Upgrade_01.00.00.265 - Copy.sql', N'Create scripts support uploading videos')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'265', N'Upgrade_01.00.00.265.sql', N'Update SP for change document icon')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'266', N'Upgrade_01.00.00.266.sql', N'Set 0 as default image id for CKEditor''s Content Template')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'267', N'Upgrade_01.00.00.267.sql', N'Create SP for PBI hearing startpage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'268', N'Upgrade_01.00.00.268.sql', N'Create SP for PBI hearing startpage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'269', N'Upgrade_01.00.00.269.sql', N'Update SP [dbo].[m136_be_ReportDocumentsPerFolder]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'270', N'Upgrade_01.00.00.270.sql', N'Create SP for hearing feedback')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'274', N'Upgrade_01.00.00.274.sql', N'Fix get parent handbookIds. Check null for iParentId')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'275', N'Upgrade_01.00.00.275.sql', N'Modify existing procedures to allow administrator set printing orientation of document.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'276', N'Upgrade_01.00.00.276.sql', N'Create procedure m136_be_IsDocumentTemplateExpired')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'277', N'Upgrade_01.00.00.277.sql', N'Modify procedure m136_be_GetDocumentFieldsAndRelates')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'280', N'Upgrade_01.00.00.280.sql', N'Created script for most read report.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'281', N'Upgrade_01.00.00.281.sql', N'Add column iRecepitsCopied to table m136_tblDocument, modify procedures m136_be_ApproveDocument, m136_GetRecentlyApprovedDocuments, m136_GetLatestApprovedSubscriptions')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'282', N'Upgrade_01.00.00.282.sql', N'Modify procedure m136_be_GetDocumentInformation')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'283', N'Upgrade_01.00.00.283.sql', N'Modify SP for Get document for metatag')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'284', N'Upgrade_01.00.00.284.sql', N'Modify procedure m136_be_IsDocumentTemplateExpired')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'285', N'Upgrade_01.00.00.285.sql', N'Modify procedure m136_ProcessFeedback')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'286', N'Upgrade_01.00.00.286.sql', N'Modify procedure m136_ProcessFeedback')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'287', N'Upgrade_01.00.00.287.sql', N'Modify procedure [dbo].[m136_be_GetDocumentFieldsAndRelates] AND [dbo].[m136_GetDocumentFieldsAndRelates]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'289', N'Upgrade_01.00.00.289.sql', N'Create new script for module Activity, Activity Task')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'132', N'Upgrade_01.00.00.132.sql', N'Alter stored procedures reopen document.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'133', N'Upgrade_01.00.00.133.sql', N'Create some stored procedure to support feature delete single & multiple documents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'134', N'Upgrade_01.00.00.134.sql', N'Alter stored procedures reopen document.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'155', N'Upgrade_01.00.00.155.sql', N'Modify m136_be_GetUserWithApprovePermissionOnDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'156', N'Upgrade_01.00.00.156.sql', N'Modify m136_be_ChangeDocumentType')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'157', N'Upgrade_01.00.00.157.sql', N'Modify procedure m136_be_GetMyWorkingDocuments, m136_be_GetOtherWorkingDocuments, m136_be_GetSoonToExpiredDocuments')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'158', N'Upgrade_01.00.00.158.sql', N'Modify m136_SetVersionFlags')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'204', N'Upgrade_01.00.00.204.sql', N'Implmenet get Report update Document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'205', N'Upgrade_01.00.00.205.sql', N'Implement change title document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'234', N'Upgrade_01.00.00.234.sql', N'Support Flowchartimage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'245', N'Upgrade_01.00.00.245.sql', N'Fix department path.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'261', N'Upgrade_01.00.00.261.sql', N'Create SP for end hearing by plugin')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'264', N'Upgrade_01.00.00.264.sql', N'Fixed startpage SPs, support location/path')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'271', N'Upgrade_01.00.00.271.sql', N'Fix updated favorite and what"s new')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'288', N'Upgrade_01.00.00.288.sql', N'Support edit message template.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'290', N'Upgrade_01.00.00.290.sql', N'Modify procedure be_GetActiveActivities, create procedures GetActiveActivities, GetUpcomingActivities')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'291', N'Upgrade_01.00.00.291.sql', N'Modify procedure [dbo].[m136_be_ReportMostReadDocuments]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'292', N'Upgrade_01.00.00.292.sql', N'Create procedure m136_be_ChangePrintOrientation')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'293', N'Upgrade_01.00.00.293.sql', N'Create procedure [dbo].[m136_be_GetDocumentHearingInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'294', N'Upgrade_01.00.00.294.sql', N'Refactor procedures in script 272.sql')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'295', N'Upgrade_01.00.00.295.sql', N'modify SP Getdocumentmetatags')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'296', N'Upgrade_01.00.00.296.sql', N'Fixed querying folder recursively.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'297', N'Upgrade_01.00.00.297 - Copy.sql', N'Support Risk management module')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'297', N'Upgrade_01.00.00.297.sql', N'Modify procedurs IsUserLeader, CreateActivityForAdminLeader CreateActivityForNormalUser, UpdateActivity, DeleteActivities, CreateActivityTask, UpdateActivityTask')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'298', N'Upgrade_01.00.00.298.sql', N'Create procedures GetActivitiesInYear, GetActivitiesInMonthOfYear')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'299', N'Upgrade_01.00.00.299.sql', N'Support Risk management module')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'300', N'Upgrade_01.00.00.300.sql', N'Modify SP [dbo].[m136_GetDocumentInformation]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'301', N'Upgrade_01.00.00.301.sql', N'Add column CompletedDate to table ActivityTasks, modify procedures GetActivityDetailsById, CreateActivityTask, UpdateActivityTask, GetActiveActivitiesForNotification, GetUserActivitiesInYear, GetUserActivitiesInMonthOfYear')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'302', N'Upgrade_01.00.00.302.sql', N'Apply permission controll to some existing procedures')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'303', N'Upgrade_01.00.00.303.sql', N'Fixed new list. Replace createdDate by publishedDate. Fixed metadata with virtual docs')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'304', N'Upgrade_01.00.00.304.sql', N'Modify procedures m147_LinkHandbookToRegisterItem, m147_DeleteHandbookRegisterItem, m147_be_LinkDocumentToRegisterItemValues, m147_be_UntagDocumentRegisterItemValues')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'305', N'Upgrade_01.00.00.305.sql', N'create vaule default when dbo.m147_tblEtype table have not row')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'306', N'Upgrade_01.00.00.306.sql', N'Modify procedures m136_be_RejectDocument, m136_be_SendDocumentToApproval, m136_be_RollbackChangesDocument, m136_be_InsertFolder')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'307', N'Upgrade_01.00.00.307.sql', N'Create table m136_FormulaImages, procedures m136_be_AddFormulaImage, m136_GetFormulaImage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'308', N'Upgrade_01.00.00.308.sql', N'Modify procedure GetUpcomingActivities')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'309', N'Upgrade_01.00.00.309.sql', N'Add procedure m136_be_UpdateReadForHearingMember')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'310', N'Upgrade_01.00.00.310.sql', N'Modify procedure GetUserActivitiesInMonthOfYear')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'311', N'Upgrade_01.00.00.311.sql', N'Modify procedure Calendar.SearchActivities')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'312', N'Upgrade_01.00.00.312.sql', N'Modify procedures be_GetMenuById, be_CreateMenu, be_UpdateMenu')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'146', N'Upgrade_01.00.00.146.sql', N'Modify procedure m136_be_GetChapterItems, Create procedure m136_be_ChangeInternetDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'147', N'Upgrade_01.00.00.147.sql', N'Modify procedure m136_be_UserCanApproveDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'148', N'Upgrade_01.00.00.148.sql', N'Modified stored procedure for document templates and document fields.')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'149', N'Upgrade_01.00.00.149.sql', N'Modified stored procedure [dbo].[m136_be_ArchiveDocument]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'150', N'Upgrade_01.00.00.150.sql', N'Modify procedures m136_be_UserCanApproveDocument, m136_be_ChangeInternetDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'151', N'Upgrade_01.00.00.151.sql', N'Modify procedure [dbo].[m136_be_ChangeDocumentType]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'152', N'Upgrade_01.00.00.152.sql', N'Modify procedure [dbo].[m136_be_ChangeInternetDocument]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'153', N'Upgrade_01.00.00.153.sql', N'Revert function [dbo].[fnSecurityGetPermission], remove procedure m136_be_UserCanPublishInternetDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'154', N'Upgrade_01.00.00.154.sql', N'Modify procedure for updatign related documents')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'159', N'Upgrade_01.00.00.159.sql', N'Add new [dbo].[m136_be_VerifyUsersHavePermissionsForSpecifiedDocuments]')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'160', N'Upgrade_01.00.00.160.sql', N'Modify m136_be_GetUserWithApprovePermissionOnDocument')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'161', N'Upgrade_01.00.00.161.sql', N'Modify procedure m136_be_SendDocumentToApproval')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'272', N'Upgrade_01.00.00.272.sql', N'Create store procedures for reports related to reading lists')
GO
print 'Processed 300 total records'
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'273', N'Upgrade_01.00.00.273.sql', N'Create scripts support uploading videos')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'181', N'Upgrade_01.00.00.181.sql', N'Add sql scripts to support features news/news category')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'182', N'Upgrade_01.00.00.182.sql', N'Modify procedures m136_be_GetNewsById, m136_be_GetNewsForStartpage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'183', N'Upgrade_01.00.00.183.sql', N'Add some scripts to support store flow charts as json and also load existing flow charts')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'184', N'Upgrade_01.00.00.184.sql', N'Created some scripts to support feature sort manually sub-chapters'' order')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'240', N'Upgrade_01.00.00.240.sql', N'Create m136_be_GetEmployeesByFilter')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'241', N'Upgrade_01.00.00.241.sql', N'Modify procedures m136_be_GetNewsForStartpage, m136_GetNewsForStartpage')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'242', N'Upgrade_01.00.00.242.sql', N'Create table m136_FlowChart and some procedures to support load images from db4')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'263', N'Upgrade_01.00.00.263.sql', N'Create SP for Copy Document')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'237', N'Upgrade_01.00.00.237.sql', N'Support MessageTemplate')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'238', N'Upgrade_01.00.00.238.sql', N'Create procedure m136_be_UpdateTimeStampForEventLog, modify procedure m136_be_AddEventLog')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'239', N'Upgrade_01.00.00.239.sql', N'Get user by permission. Fixed get file document issue, shoud remove iLatestVersion = 1')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'244', N'Upgrade_01.00.00.244.sql', N'Fix template fields ordering')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'243', N'Upgrade_01.00.00.243.sql', N'Create procedure m123_GetDeviationNewsForStartpage to get news for deviation')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'278', N'Upgrade_01.00.00.278.sql', N'Add and modify some procedure to allow administrator to change menus'' sort order')
INSERT [dbo].[SchemaChanges] ([MajorReleaseNumber], [MinorReleaseNumber], [BuildReleaseNumber], [RevisionReleaseNumber], [ScriptName], [Description]) VALUES (N'01', N'00', N'00', N'279', N'Upgrade_01.00.00.279.sql', N'Created script for upload video.')
GO



MERGE dbo.tblCountry AS t
USING (VALUES
(0, N'Root country', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(1, N'NORGE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(2, N'AFGHANISTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(3, N'ANGOLA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(4, N'ANGUILLA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(5, N'AALAND ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(6, N'ALBANIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(7, N'ANDORRA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(8, N'NETHERLANDS ANTILLES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(9, N'UNITED ARAB EMIRATES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(10, N'ARGENTINA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(11, N'ARMENIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(12, N'AMERICAN SAMOA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(13, N'ANTARCTICA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(14, N'FRENCH SOUTHERN TERRITORIES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(15, N'ANTIGUA AND BARBUDA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(16, N'AUSTRALIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(17, N'AUSTRIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(18, N'AZERBAIJAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(19, N'BURUNDI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(20, N'BELGIUM', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(21, N'BENIN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(22, N'BURKINA FASO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(23, N'BANGLADESH', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(24, N'BULGARIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(25, N'BAHRAIN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(26, N'BAHAMAS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(27, N'BOSNIA AND HERZEGOWINA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(28, N'BELARUS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(29, N'BELIZE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(30, N'BERMUDA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(31, N'BOLIVIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(32, N'BRAZIL', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(33, N'BARBADOS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(34, N'BRUNEI DARUSSALAM', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(35, N'BHUTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(36, N'BOUVET ISLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(37, N'BOTSWANA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(38, N'CENTRAL AFRICAN REPUBLIC', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(39, N'CANADA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(40, N'COCOS (KEELING) ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(41, N'SWITZERLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(42, N'CHILE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(43, N'CHINA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(44, N'COTE D''IVOIRE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(45, N'CAMEROON', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(46, N'CONGO, Democratic Republic of (was Zaire)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(47, N'CONGO, Republic of', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(48, N'COOK ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(49, N'COLOMBIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(50, N'COMOROS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(51, N'CAPE VERDE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(52, N'COSTA RICA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(53, N'CUBA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(54, N'CHRISTMAS ISLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(55, N'CAYMAN ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(56, N'CYPRUS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(57, N'CZECH REPUBLIC', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(58, N'GERMANY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(59, N'DJIBOUTI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(60, N'DOMINICA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(61, N'DENMARK', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(62, N'DOMINICAN REPUBLIC', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(63, N'ALGERIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(64, N'ECUADOR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(65, N'EGYPT', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(66, N'ERITREA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(67, N'WESTERN SAHARA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(68, N'SPAIN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(69, N'ESTONIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(70, N'ETHIOPIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(71, N'FINLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(72, N'FIJI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(73, N'FALKLAND ISLANDS (MALVINAS)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(74, N'FRANCE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(75, N'FAROE ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(76, N'MICRONESIA, FEDERATED STATES OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(77, N'GABON', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(78, N'UNITED KINGDOM', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(79, N'GEORGIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(80, N'GHANA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(81, N'GIBRALTAR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(82, N'GUINEA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(83, N'GUADELOUPE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(84, N'GAMBIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(85, N'GUINEA-BISSAU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(86, N'EQUATORIAL GUINEA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(87, N'GREECE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(88, N'GRENADA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(89, N'GREENLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(90, N'GUATEMALA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(91, N'FRENCH GUIANA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(92, N'GUAM', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(93, N'GUYANA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(94, N'HONG KONG', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(95, N'HEARD AND MC DONALD ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(96, N'HONDURAS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(97, N'CROATIA (local name: Hrvatska)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(98, N'HAITI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(99, N'HUNGARY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(100, N'INDONESIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(101, N'INDIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(102, N'BRITISH INDIAN OCEAN TERRITORY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(103, N'IRELAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(104, N'IRAN (ISLAMIC REPUBLIC OF)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(105, N'IRAQ', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(106, N'ICELAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(107, N'ISRAEL', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(108, N'ITALY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(109, N'JAMAICA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(110, N'JORDAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(111, N'JAPAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(112, N'KAZAKHSTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(113, N'KENYA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(114, N'KYRGYZSTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(115, N'CAMBODIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(116, N'KIRIBATI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(117, N'SAINT KITTS AND NEVIS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(118, N'KOREA, REPUBLIC OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(119, N'KUWAIT', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(120, N'LAO PEOPLE''S DEMOCRATIC REPUBLIC', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(121, N'LEBANON', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(122, N'LIBERIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(123, N'LIBYAN ARAB JAMAHIRIYA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(124, N'SAINT LUCIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(125, N'LIECHTENSTEIN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(126, N'SRI LANKA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(127, N'LESOTHO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(128, N'LITHUANIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(129, N'LUXEMBOURG', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(130, N'LATVIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(131, N'MACAU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(132, N'MOROCCO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(133, N'MONACO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(134, N'MOLDOVA, REPUBLIC OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(135, N'MADAGASCAR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(136, N'MALDIVES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(137, N'MEXICO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(138, N'MARSHALL ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(139, N'MACEDONIA, THE FORMER YUGOSLAV REPUBLIC OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(140, N'MALI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(141, N'MALTA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(142, N'MYANMAR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(143, N'MONGOLIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(144, N'NORTHERN MARIANA ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(145, N'MOZAMBIQUE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(146, N'MAURITANIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(147, N'MONTSERRAT', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(148, N'MARTINIQUE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(149, N'MAURITIUS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(150, N'MALAWI', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(151, N'MALAYSIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(152, N'MAYOTTE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(153, N'NAMIBIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(154, N'NEW CALEDONIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(155, N'NIGER', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(156, N'NORFOLK ISLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(157, N'NIGERIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(158, N'NICARAGUA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(159, N'NIUE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(160, N'NETHERLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(161, N'NORWAY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(162, N'NEPAL', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(163, N'NAURU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(164, N'NEW ZEALAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(165, N'OMAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(166, N'PAKISTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(167, N'PANAMA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(168, N'PITCAIRN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(169, N'PERU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(170, N'PHILIPPINES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(171, N'PALAU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(172, N'PAPUA NEW GUINEA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(173, N'POLAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(174, N'PUERTO RICO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(175, N'KOREA, DEMOCRATIC PEOPLE''S REPUBLIC OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(176, N'PORTUGAL', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(177, N'PARAGUAY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(178, N'PALESTINIAN TERRITORY, Occupied', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(179, N'FRENCH POLYNESIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(180, N'QATAR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(181, N'REUNION', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(182, N'ROMANIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(183, N'RUSSIAN FEDERATION', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(184, N'RWANDA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(185, N'SAUDI ARABIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(186, N'SERBIA AND MONTENEGRO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(187, N'SUDAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(188, N'SENEGAL', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(189, N'SINGAPORE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(190, N'SOUTH GEORGIA AND THE SOUTH SANDWICH ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(191, N'SAINT HELENA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(192, N'SVALBARD AND JAN MAYEN ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(193, N'SOLOMON ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(194, N'SIERRA LEONE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(195, N'EL SALVADOR', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(196, N'SAN MARINO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(197, N'SOMALIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(198, N'SAINT PIERRE AND MIQUELON', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(199, N'SAO TOME AND PRINCIPE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(200, N'SURINAME', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(201, N'SLOVAKIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(202, N'SLOVENIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(203, N'SWEDEN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(204, N'SWAZILAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(205, N'SEYCHELLES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(206, N'SYRIAN ARAB REPUBLIC', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(207, N'TURKS AND CAICOS ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(208, N'CHAD', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(209, N'TOGO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(210, N'THAILAND', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(211, N'TAJIKISTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(212, N'TOKELAU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(213, N'TURKMENISTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(214, N'TIMOR-LESTE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(215, N'TONGA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(216, N'TRINIDAD AND TOBAGO', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(217, N'TUNISIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(218, N'TURKEY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(219, N'TUVALU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(220, N'TAIWAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(221, N'TANZANIA, UNITED REPUBLIC OF', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(222, N'UGANDA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(223, N'UKRAINE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(224, N'UNITED STATES MINOR OUTLYING ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(225, N'URUGUAY', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(226, N'UNITED STATES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(227, N'UZBEKISTAN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(228, N'VATICAN CITY STATE (HOLY SEE)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(229, N'SAINT VINCENT AND THE GRENADINES', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(230, N'VENEZUELA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(231, N'VIRGIN ISLANDS (BRITISH)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(232, N'VIRGIN ISLANDS (U.S.)', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(233, N'VIET NAM', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(234, N'VANUATU', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(235, N'WALLIS AND FUTUNA ISLANDS', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(236, N'SAMOA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(237, N'YEMEN', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(238, N'SOUTH AFRICA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(239, N'ZAMBIA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(240, N'ZIMBABWE', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
,(241, N'ARUBA', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'', N'')
) 
AS src([iCountryId], [strName], [strEmergency1Text], [strEmergency1Nr], 
[strEmergency2Text], [strEmergency2Nr], [strEmergency3Text], 
[strEmergency3Nr], [strEmergency4Text], [strEmergency4Nr], 
[strEmergency5Text], [strEmergency5Nr], [strMessage])
ON t.iCountryId = src.iCountryId

WHEN NOT MATCHED BY TARGET THEN
  INSERT ([iCountryId], [strName], [strEmergency1Text], [strEmergency1Nr], 
[strEmergency2Text], [strEmergency2Nr], [strEmergency3Text], 
[strEmergency3Nr], [strEmergency4Text], [strEmergency4Nr], 
[strEmergency5Text], [strEmergency5Nr], [strMessage])
  VALUES(src.iCountryId, src.[strName], src.[strEmergency1Text], src.[strEmergency1Nr], 
src.[strEmergency2Text], src.[strEmergency2Nr], src.[strEmergency3Text], 
src.[strEmergency3Nr], src.[strEmergency4Text], src.[strEmergency4Nr], 
src.[strEmergency5Text], src.[strEmergency5Nr], src.[strMessage])

WHEN MATCHED THEN
  UPDATE
	SET [strName] = src.[strName],
	[strEmergency1Text] = src.[strEmergency1Text],
	[strEmergency1Nr] = src.[strEmergency1Nr],
	[strEmergency2Text] = src.[strEmergency2Text],
	[strEmergency2Nr] = src.[strEmergency2Nr],
	[strEmergency3Text] = src.[strEmergency3Text],
	[strEmergency3Nr] = src.[strEmergency3Nr],
	[strEmergency4Text] = src.[strEmergency4Text],
	[strEmergency4Nr] = src.[strEmergency4Nr],
	[strEmergency5Text] = src.[strEmergency5Text],
	[strEmergency5Nr] = src.[strEmergency5Nr],
	[strMessage] = src.[strMessage];
GO


MERGE dbo.MessageTemplate AS t
USING (VALUES
(1, N'Email: Deviation - Register', 151)
,(2, N'Email: Deviation - Accept', 151)
,(3, N'Email: Deviation - Forward', 151)
,(4, N'Email: Deviation - Close', 151)
,(5, N'Email: Task/Action - Assign', 151)
,(6, N'Email: Task/Action - Close', 151)
,(7, N'Email: Deviation - Reopen', 151)
,(8, N'Email: Deviation - Delete', 151)
,(9, N'Email: Deviation - Restore', 151)
,(10, N'Email: Deviation - Expired', 151)
,(11, N'Email: Deviation - CategoryChanged', 151)
,(12, N'Email: Deviation Tasks/Actions - Expiring', 151)
,(13, N'Email: Deviation - Expiring', 151)
,(14, N'Email: Deviation Tasks/Actions - Expiring', 151)
,(15, N'Reminder - Expired Deviation/Task/Action', 151)) 
AS src([TemplateId], [Name], [ModuleId])
ON t.[TemplateId] = src.[TemplateId]

WHEN NOT MATCHED BY TARGET THEN
  INSERT ([TemplateId], [Name], [ModuleId])
  VALUES(src.[TemplateId], src.[Name], src.[ModuleId])

WHEN MATCHED THEN
  UPDATE
	SET Name = src.Name;
GO



MERGE dbo.MessageTemplateLanguage AS t
USING (VALUES
(1, 1, N'Avvik er registrert', N'<p>Et avvik ''{Title}'' er registrert av bruker ''{Creator}''.<br />
		Rapport type: {ReportType}<br />
		Kategori: {CategoryName}<br />
		Beskrivelse: {Description}<br />
		<br />
		Intranett/Innenfor organisasjon<br />
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br />
		<br />
		Internett/Utenfor organisasjon<br />
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></p>
		')
,(2, 1, N'Deviation is registered', N'A deviation ''{Title}'' is registered by user ''{Creator}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		<br />
		Intranet / Within the organization<br />
		<a href="{Url}" target="_blank">(Link to deviation)</a><br />
		<br />
		Internet / Outside Organization<br />
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a></p>
		')
,(1, 2, N'Avvik er akseptert', N'Et avvik ''{Title}'' er akseptert av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 2, N'Deviation is accepted', N'A deviation ''{Title}'' is accepted by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 3, N'Avvik er videresendt', N'Et avvik ''{Title}'' er videresendt av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 3, N'Deviation is forwarded', N'A deviation ''{Title}'' is forwarded by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 4, N'Avvik er lukket', N'Et avvik ''{Title}'' er lukket av bruker ''{Owner}''.<br/>
			Rapport type: {ReportType}<br/>
			Kategori: {CategoryName}<br/>
			Beskrivelse: {Description}<br/><br/>
			Intranett/Innenfor organisasjon<br/>
			<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
			Internett/Utenfor organisasjon<br/>
			<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 4, N'Deviation is closed', N'A deviation ''{Title}'' is closed by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 5, N'Oppgaver/Tiltak er tilordnet', N'Et oppgaver/tiltak ''{TaskActionTitle}'' er tilordnet av bruker ''{Creator}''.<br />
Avvik: {Title}<br />
Beskrivelse: {Description}<br />
<br />
Intranett/Innenfor organisasjon<br />
<a href="{Url}" target="_blank">(Lenke til avvik)</a><br />
<br />
Internett/Utenfor organisasjon<br />
<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 5, N'Task/Action is assigned', N'A task/action ''{TaskActionTitle}'' is assigned by user ''{Creator}''.<br/>
		Deviation: {Title}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to task/action)</a>')
,(1, 6, N'Oppgaver/Tiltak er lukket', N'Et oppgaver/tiltak ''{TaskActionTitle}'' er lukket av bruker ''{Creator}''.<br/>
		Avvik: {Title}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a>')
,(2, 6, N'Task/Action is closed', N'A task/action ''{TaskActionTitle}'' is closed by user ''{Creator}''.<br/>
		Deviation: {Title}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to task/action)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to task/action)</a>')
,(1, 7, N'Avvik er gjenåpning', N'Et avvik ''{Title}'' er gjenåpnet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 7, N'Deviation is reopened', N'A deviation ''{Title}'' is reopened by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 8, N'Avvik er slettet', N'Et avvik ''{Title}'' er slettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 8, N'Deviation is deleted', N'A deviation ''{Title}'' is reopened by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 9, N'Avvik er gjenopprettet', N'Et avvik ''{Title}'' er gjenopprettet av bruker ''{Owner}''.<br/>
		Rapport type: {ReportType}<br/>
		Kategori: {CategoryName}<br/>
		Beskrivelse: {Description}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 9, N'Deviation is restored', N'A deviation ''{Title}'' is restored by user ''{Owner}''.<br/>
		Report type: {ReportType}<br/>
		Category: {CategoryName}<br/>
		Description: {Description}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 10, N'Avvik er utløpt', N'Følgende avvik er utløpt:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til avvik)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></td></tr></tbody>
		</table></div>')
,(2, 10, N'Deviations expired', N'The following deviations are expired:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to deviation)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to deviation)</a></td></tr></tbody>
		</table></div>')
,(1, 11, N'Avvik ''{Title}'' er endret kategori', N'Et avvik ''{Title}'' er endret kategori av bruker ''{User}''.<br/>
		Rapport type: {ReportType}<br/>
		Beskrivelse: {Description}<br/>
		Gamle kategorien: {OldCategoryName}<br/>
		Ny kategori: {NewCategoryName}<br/><br/>
		Intranett/Innenfor organisasjon<br/>
		<a href="{Url}" target="_blank">(Lenke til avvik)</a><br/><br/>
		Internett/Utenfor organisasjon<br/>
		<a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a>')
,(2, 11, N'Deviation ''{Title}'' is changed category', N'A deviation ''{Title}'' is changed category by ''{User}''.<br/>
		Report type: {ReportType}<br/>
		Description: {Description}<br/>
		Old category: {OldCategoryName}<br/>
		New category: {NewCategoryName}<br/><br/>
		Intranet / Within the organization<br/>
		<a href="{Url}" target="_blank">(Link to deviation)</a><br/><br/>
		Internet / Outside Organization<br/>
		<a href="{PublicUrl}" target="_blank">(Link to deviation)</a>')
,(1, 12, N'Avvik Oppgaver / Handlinger Utløpt', N'Følgende oppgaver / handlinger er utløpt:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a></td></tr></tbody>
		</table></div>')
,(2, 12, N'Deviation Tasks/Actions Expired', N'The following Tasks/Actions are expired:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to task/action)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to task/action)</a></td></tr></tbody>
		</table></div>')
,(1, 13, N'Avvik er utløper', N'Følgende avvik utløper i dag:
		<div><table border="1">
		<thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>Internett/Utenfor organisasjon</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til avvik)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til avvik)</a></td></tr></tbody>
		</table></div>')
,(2, 13, N'Deviations Expiring', N'The following deviations are expiring today:
		<div><table border="1">
		<thead><tr><th>Title</th><th>Owner</th><th>Report type</th><th>Category</th><th>Description</th><th>Intranet / Within the organization</th><th>Internet / Outside Organization</th></tr></thead>
		<tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to deviation)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to deviation)</a></td></tr></tbody>
		</table></div>')
,(1, 14, N'Avvik Oppgaver / Handlinger Utløper', N'Følgende oppgaver / handlinger er utløper i dag: <div><table border="1"><thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>
	Internett/Utenfor organisasjon</th></tr></thead><tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Lenke til oppgaver/tiltak)</a></td><td><a href="{PublicUrl}" target="_blank">(Lenke til oppgaver/tiltak)</a></td></tr></tbody></table></div>')
,(2, 14, N'Deviation Tasks/Actions Expiring', N'The following Tasks/Actions are expiring today: <div><table border="1"><thead><tr><th>Tittel</th><th>Eier</th><th>Rapporttype</th><th>Kategori</th><th>Beskrivelse</th><th>Intranett/Innenfor organisasjon</th><th>
	Internett/Utenfor organisasjon</th></tr></thead><tbody><tr><td>{Title}</td><td>{Owner}</td><td>{ReportType}</td><td>{CategoryName}</td><td>{Description}</td><td><a href="{Url}" target="_blank">(Link to task/action)</a></td><td><a href="{PublicUrl}" target="_blank">(Link to task/action)</a></td></tr></tbody></table></div>')
,(1, 15, N'Påminnelse - Utløpt {0}', N'Vennligst følg opp, "{0}", som er utløpt.<br/><br/> Med vennlig hilsen <br/>{1}')
,(2, 15, N'Reminder - Expired {0}', N'Please follow up, "{0}", which is expired.<br/><br/> Best regards <br/>{1}')) 
AS src([Language], [TemplateId], [Subject], [Body])
ON t.[TemplateId] = src.[TemplateId] AND t.[Language] = src.[Language]

WHEN NOT MATCHED BY TARGET THEN
  INSERT ([Language], [TemplateId], [Subject], [Body])
  VALUES(src.[Language], src.[TemplateId], src.[Subject], src.[Body])

WHEN MATCHED THEN
  UPDATE
	SET [Subject] = src.[Subject],
		[Body] = src.[Body];
GO


/*Initialize data for Risk.luConsequences*/
MERGE INTO Risk.luConsequences AS t
USING (VALUES 
    (0, 'Ikke vurdert'),
    (1, 'Lav'),
    (2, 'Lav til middels'),
    (3, 'Middels'),
    (4, 'Middels til høy'),
    (5, 'Høy')
 ) AS s(Id, Name)
ON t.Id = s.Id
WHEN NOT MATCHED BY TARGET THEN 
INSERT (Id, Name) VALUES(s.Id, s.Name);
GO

/*Initialize data for Risk.luConsequenceTypes*/
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[Risk].[luConsequenceTypes]') AND type in (N'U'))
BEGIN
	CREATE TABLE [Risk].[luConsequenceTypes](
		[Id] [tinyint] NOT NULL,
		[Name] [nvarchar](100) NOT NULL
	 CONSTRAINT [PK_Risk_luConsequenceTypes] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypes lct WHERE lct.Id = 1)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypes]
           ([Id]
           ,[Name])
     VALUES
           (1
           ,N'Person')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypes lct WHERE lct.Id = 2)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypes]
           ([Id]
           ,[Name])
     VALUES
           (2
           ,N'Miljø')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypes lct WHERE lct.Id = 3)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypes]
           ([Id]
           ,[Name])
     VALUES
           (3
           ,N'Økonomisk')
END
GO

/*Initialize data for Risk.luConsequencesLanguage*/
IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 1 AND lctl.Language = 1)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (1
           ,1
           ,1
           ,N'Person')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 1 AND lctl.Language = 2)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (2
           ,1
           ,2
           ,N'Person')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 2 AND lctl.Language = 1)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (3
           ,2
           ,1
           ,N'Miljø')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 2 AND lctl.Language = 2)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (4
           ,2
           ,2
           ,N'Environment')
END
GO


IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 3 AND lctl.Language = 1)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (5
           ,3
           ,1
           ,N'Økonomisk')
END
GO

IF NOT EXISTS(SELECT * FROM Risk.luConsequenceTypesLanguage lctl WHERE lctl.ConsequenceTypeId = 3 AND lctl.Language = 2)
BEGIN
	INSERT INTO [Risk].[luConsequenceTypesLanguage]
           ([Id]
           ,[ConsequenceTypeId]
           ,[Language]
           ,[Name])
     VALUES
           (6
           ,3
           ,2
           ,N'Economy')
END
GO

/*Initialize data for Risk.luConsequencesLanguage*/
MERGE INTO Risk.luConsequencesLanguage AS t
USING (VALUES 
	(11, 0, 1, 'Ikke vurdert'),
	(12, 0, 2, 'Not rated')
	) AS s(Id, ConsequencesId, [Language], Name)
ON (t.ConsequencesId = s.ConsequencesId AND t.[Language] = s.[Language])
WHEN NOT MATCHED BY TARGET THEN 
INSERT (Id, ConsequencesId, [Language], Name) VALUES(s.Id, s.ConsequencesId, s.[Language], s.Name);
GO



/* Initialize data for table Risk.luProbability
   t: target, s: source*/  
MERGE INTO Risk.luProbability AS t
USING (VALUES 
 (0, 'Ikke vurdert'),
 (1, 'Lite sannsynlig'), 
 (2, 'Mindre sannsynlig'), 
 (3, 'Sannsynlig'), 
 (4, 'Meget sannsynlig'), 
 (5, 'Svært sannsynlig')
 ) AS s(Id, Name)
ON t.Id = s.Id
WHEN NOT MATCHED BY TARGET THEN 
INSERT (Id, Name) VALUES(s.Id, s.Name);
GO

/*Initialize data for dbo.tblACL*/
MERGE dbo.tblACL AS t
USING (VALUES 
	(0, 136, 1, 460, 0, 63),
	(0, 136, 1, 461, 0, 31),
	(0, 136, 1, 462, 0, 47)
	) AS src(iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit)
ON (t.iEntityId = src.iEntityId AND t.iApplicationId = src.iApplicationId 
AND t.iSecurityId = src.iSecurityId AND t.iPermissionSetId = src.iPermissionSetId)

WHEN NOT MATCHED BY TARGET THEN 
	INSERT (iEntityId, iApplicationId, iSecurityId, iPermissionSetId, iGroupingId, iBit) 
	VALUES(src.iEntityId, src.iApplicationId, src.iSecurityId, src.iPermissionSetId, src.iGroupingId, src.iBit)
WHEN MATCHED THEN
	UPDATE
	SET iBit = src.iBit;
GO


/*Initialize data for dbo.m136_tblHandbook*/
IF NOT EXISTS(SELECT * FROM dbo.m136_tblHandbook WHERE iHandbookId = 0)
	BEGIN
		SET IDENTITY_INSERT dbo.m136_tblHandbook ON;
		INSERT INTO dbo.m136_tblHandbook(
			iHandbookId,
			iParentHandbookId, 
			strName, 
			strDescription, 
			iDepartmentId, 
			iLevelType, 
			iViewTypeId, 
			dtmCreated, 
			iCreatedById, 
			iDeleted,
			iMin,
			iMax,
			iLevel) 
		VALUES(
			0,
			NULL, 
			'Root', 
			'This is root folder', 
			NULL, 
			1, 
			-1, 
			GETDATE(), 
			1, 
			0,
			0,
			0,
			0);
	        
		SET IDENTITY_INSERT dbo.m136_tblHandbook OFF;
	END
GO


/*Initialize data for dbo.tblInformationType*/
MERGE [dbo].[tblInformationType] AS t
USING (VALUES 
	(0, 'scr.dummy.info.type', 'scr.reserved.not.usable', 'dummy.asp', ''),
	(2, 'scr.file', 'scr.file', 'file_listgroup.asp', '&strAction=doView'),
	(5, 'scr.image', 'scr.image', 'image_listgroup.asp', '&strAction=doView'),
	(7, 'scr.direct.link', 'scr.for.non.inf.module.group.links', '', ''),
	(8, 'scr.menu.group', 'scr.no.link.other.page', '', '')
	) AS src([iInformationTypeId]
      ,[strName]
      ,[strDescription]
      ,[strURL]
      ,[strParameters])
ON (t.[iInformationTypeId] = src.[iInformationTypeId])

WHEN NOT MATCHED BY TARGET THEN 
	INSERT ([iInformationTypeId]
      ,[strName]
      ,[strDescription]
      ,[strURL]
      ,[strParameters]) 
	VALUES(src.[iInformationTypeId], src.[strName], src.[strDescription], src.[strURL], src.[strParameters])
WHEN MATCHED THEN
	UPDATE
	SET [strName] = src.[strName],
	[strDescription] = src.[strDescription],
	[strURL] = src.[strURL],
	[strParameters] = src.[strParameters];
GO

IF (NOT EXISTS (SELECT 1 FROM luReaderTypes))
BEGIN
    INSERT INTO
        luReaderTypes
            (Id, Name)
        VALUES
            (1, 'Person'),
            (2, 'Department'),
            (3, 'Role')
END
GO