INSERT INTO #Description VALUES('Updated Clustered Indexes')
GO

IF OBJECT_ID('[dbo].[fn136_GetSqlDropConstraintKey]', 'FN') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[fn136_GetSqlDropConstraintKey]() RETURNS Int AS BEGIN RETURN 1 END;')
GO

ALTER FUNCTION [dbo].[fn136_GetSqlDropConstraintKey]
(
	@TableName varchar(100),
	@ConstraintKeyName varchar(100)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @sql NVARCHAR(MAX) = NULL
	SELECT TOP 1 @sql = N'ALTER TABLE dbo.' + @TableName + ' DROP CONSTRAINT ['+CONSTRAINT_NAME+N']'
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE CONSTRAINT_NAME like @ConstraintKeyName + '%'
	  AND TABLE_NAME = @TableName
	return @sql
END
GO

IF OBJECT_ID('[dbo].[m136_DropForeignKeyTable]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_DropForeignKeyTable] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_DropForeignKeyTable]
@TableName NVARCHAR(MAX),
@ForeignKeyName NVARCHAR(MAX)
AS
BEGIN
	DECLARE @FullForeignKey NVARCHAR(MAX)
	
	DECLARE meta_cursor CURSOR FOR
	SELECT CONSTRAINT_NAME 
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
	WHERE CONSTRAINT_NAME LIKE @ForeignKeyName + '%'
		  AND TABLE_NAME = @TableName
	
	DECLARE @sql NVARCHAR(MAX)
	
	OPEN meta_cursor;
	FETCH NEXT FROM meta_cursor 
	INTO @FullForeignKey;
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF @FullForeignKey IS NOT NULL
		BEGIN
			SET @sql = N'ALTER TABLE dbo.' + @TableName + ' DROP CONSTRAINT ['+@FullForeignKey+N']'
			EXEC(@sql)
		END
		FETCH NEXT FROM meta_cursor 
		INTO @FullForeignKey;
	END 
	CLOSE meta_cursor;
	DEALLOCATE meta_cursor;
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relApplicationPermissionSet', 'PK__relAppli') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relApplicationPermissionSet ADD CONSTRAINT PK__relApplicationPermissionSet_iApplicationId_iPermissionSetId PRIMARY KEY CLUSTERED
	(
		[iApplicationId] ASC,
		[iPermissionSetId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relDepartmentPosition', 'PK__relDepar') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relDepartmentPosition ADD CONSTRAINT PK__relDepartmentPosition_iDepartmentId_iPositionId PRIMARY KEY CLUSTERED
	(
		[iDepartmentId] ASC,
		[iPositionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relEmployeeGroup', 'PK__relEmplo') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relEmployeeGroup ADD CONSTRAINT PK__relEmployeeGroup_iEmployeeId_iGroupId PRIMARY KEY CLUSTERED
	(
		[iEmployeeId] ASC,
		[iGroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relEmployeePosition', 'PK__relEmplo') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relEmployeePosition ADD CONSTRAINT PK__relEmployeePosition_iEmployeeId_iDepartmentId_iPositionId PRIMARY KEY CLUSTERED
	(
		[iEmployeeId] ASC,
		[iDepartmentId] ASC,
		[iPositionId]
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relEmployeeSecGroup', 'PK__relEmplo') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relEmployeeSecGroup ADD CONSTRAINT PK__relEmployeeSecGroup_iEmployeeId_iSecGroupId PRIMARY KEY CLUSTERED
	(
		[iEmployeeId] ASC,
		[iSecGroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('relItem', 'PK__relItem') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.relItem ADD CONSTRAINT PK__relItem_iItemId_iItemChildId PRIMARY KEY CLUSTERED
	(
		[iItemId] ASC,
		[iItemChildId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblACL', 'PK__tblACL') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblACL ADD CONSTRAINT PK__tblACL_iEntityId_iApplicationId_iSecurityId_iPermissionSetId PRIMARY KEY CLUSTERED
	(
		[iEntityId] ASC,
		[iApplicationId] ASC,
		[iSecurityId],
		[iPermissionSetId]
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblAdminMenu', 'PK__tblAdmin') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblAdminMenu ADD CONSTRAINT PK__tblAdminMenu_iEntityId PRIMARY KEY CLUSTERED
	(
		[iEntityId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblApplication', 'PK__tblAppli') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relApplicationPermissionSet', 'FK__relApplic__iAppl'
	exec dbo.m136_DropForeignKeyTable 'tblACL', 'FK__tblACL__iApplica'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblApplication ADD CONSTRAINT PK__tblApplication_iApplicationId PRIMARY KEY CLUSTERED
	(
		[iApplicationId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	
	ALTER TABLE [dbo].[relApplicationPermissionSet] ADD CONSTRAINT FK__relApplicationPermissionSet_iApplicationId__tblApplication_iApplicationId FOREIGN KEY ([iApplicationId])
	REFERENCES [dbo].[tblApplication]([iApplicationId])
	
	ALTER TABLE [dbo].[tblACL] ADD CONSTRAINT FK__tblACL_iApplicationId__tblApplication_iApplicationId FOREIGN KEY ([iApplicationId])
	REFERENCES [dbo].[tblApplication]([iApplicationId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblBlob', 'PK__tblBlob') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblBlob ADD CONSTRAINT PK__tblBlob_iItemId_iType PRIMARY KEY CLUSTERED
	(
		[iItemId] ASC,
		[iType] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblCountry', 'PK__tblCount') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'tblDepartment', 'FK__tblDepart__iCoun'
	exec dbo.m136_DropForeignKeyTable 'tblEmployee', 'FK__tblEmploy__iCoun'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblCountry ADD CONSTRAINT PK__tblCountry_iCountryId PRIMARY KEY CLUSTERED
	(
		[iCountryId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	
	ALTER TABLE [dbo].[tblDepartment] ADD CONSTRAINT FK__tblDepartment_iCountryId__tblCountry_iCountryId FOREIGN KEY ([iCountryId])
	REFERENCES [dbo].[tblCountry] ([iCountryId])

	ALTER TABLE [dbo].[tblEmployee] ADD CONSTRAINT FK__tblEmployee_iCountryId__tblCountry_iCountryId FOREIGN KEY ([iCountryId])
	REFERENCES [dbo].[tblCountry] ([iCountryId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblDepartment', 'PK__tblDepar') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relDepartmentPosition', 'FK__relDepart__iDepa'
	exec dbo.m136_DropForeignKeyTable 'relDepartmentTarget', 'FK__relDepart__iDepa'
	exec dbo.m136_DropForeignKeyTable 'relEmployeePosition', 'FK__relEmploy__iDepa'
	exec dbo.m136_DropForeignKeyTable 'tblEmployee', 'FK__tblEmploy__iDepa'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblDepartment ADD CONSTRAINT PK__tblDepartment_iDepartmentId PRIMARY KEY CLUSTERED
	(
		[iDepartmentId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
	
	ALTER TABLE [dbo].[relDepartmentPosition] ADD CONSTRAINT FK__relDepartmentPosition_iDepartmentId__tblDepartment_iDepartmentId FOREIGN KEY ([iDepartmentId])
	REFERENCES [dbo].[tblDepartment] ([iDepartmentId])

	ALTER TABLE [dbo].[relDepartmentTarget] ADD CONSTRAINT FK__relDepartmentTarget_iDepartmentId__tblDepartment_iDepartmentId FOREIGN KEY ([iDepartmentId])
	REFERENCES [dbo].[tblDepartment] ([iDepartmentId])
	
	ALTER TABLE [dbo].[relEmployeePosition] ADD CONSTRAINT FK__relEmployeePosition_iDepartmentId__tblDepartment_iDepartmentId FOREIGN KEY ([iDepartmentId])
	REFERENCES [dbo].[tblDepartment] ([iDepartmentId])
	
	ALTER TABLE [dbo].[tblEmployee] ADD CONSTRAINT FK__tblEmployee_iDepartmentId__tblDepartment_iDepartmentId FOREIGN KEY ([iDepartmentId])
	REFERENCES [dbo].[tblDepartment] ([iDepartmentId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblEmployee', 'PK__tblEmplo') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relEmployeeGroup', 'FK__relEmploy__iEmpl'
	exec dbo.m136_DropForeignKeyTable 'relEmployeePosition', 'FK__relEmploy__iEmpl'
	exec dbo.m136_DropForeignKeyTable 'relEmployeeSecGroup', 'FK__relEmploy__iEmpl'
	exec dbo.m136_DropForeignKeyTable 'tblItem', 'FK__tblItem__iAuthor'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblEmployee ADD CONSTRAINT PK__tblEmployee_iEmployeeId PRIMARY KEY CLUSTERED
	(
		[iEmployeeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[relEmployeeGroup] ADD CONSTRAINT FK__relEmployeeGroup_iEmployeeId__tblEmployee_iEmployeeId FOREIGN KEY ([iEmployeeId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])

	ALTER TABLE [dbo].[relEmployeePosition] ADD CONSTRAINT FK__relEmployeePosition_iEmployeeId__tblEmployee_iEmployeeId FOREIGN KEY ([iEmployeeId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])
	
	ALTER TABLE [dbo].[relEmployeeSecGroup] ADD CONSTRAINT FK__relEmployeeSecGroup_iEmployeeId__tblEmployee_iEmployeeId FOREIGN KEY ([iEmployeeId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])
	
	ALTER TABLE [dbo].[tblItem] ADD CONSTRAINT FK__tblItem_iAuthorId__tblEmployee_iEmployeeId FOREIGN KEY ([iAuthorId])
	REFERENCES [dbo].[tblEmployee] ([iEmployeeId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblFile', 'PK__tblFile') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblFile ADD CONSTRAINT PK__tblFile_iAutoId PRIMARY KEY CLUSTERED
	(
		[iAutoId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblFileType', 'PK__tblFileT') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblFileType ADD CONSTRAINT PK__tblFileType_iFileTypeId PRIMARY KEY CLUSTERED
	(
		[iFileTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblGroup', 'PK__tblGroup') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relEmployeeGroup', 'FK__relEmploy__iGrou'
	exec dbo.m136_DropForeignKeyTable 'tblItem', 'FK__tblItem__iGroupI'
	exec dbo.m136_DropForeignKeyTable 'tblGroup', 'FK__tblGroup__iGroup'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblGroup ADD CONSTRAINT PK__tblGroup_iGroupId PRIMARY KEY CLUSTERED
	(
		[iGroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[relEmployeeGroup] ADD CONSTRAINT FK__relEmployeeGroup_iGroupId__tblGroup_iGroupId FOREIGN KEY ([iGroupId])
	REFERENCES [dbo].[tblGroup] ([iGroupId])

	ALTER TABLE [dbo].[tblItem] ADD CONSTRAINT FK__tblItem_iGroupId__tblGroup_iGroupId FOREIGN KEY ([iGroupId])
	REFERENCES [dbo].[tblGroup] ([iGroupId])
	
	ALTER TABLE [dbo].[tblGroup] ADD CONSTRAINT FK__tblGroup_iGroupParentId__tblGroup_iGroupId FOREIGN KEY ([iGroupParentId])
	REFERENCES [dbo].[tblGroup] ([iGroupId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblImage', 'PK__tblImage') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblImage ADD CONSTRAINT PK__tblImage_iAutoId PRIMARY KEY CLUSTERED
	(
		[iAutoId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblInformationType', 'PK__tblInfor') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'tblGroup', 'FK__tblGroup__iInfor'
	exec dbo.m136_DropForeignKeyTable 'tblItem', 'FK__tblItem__iInform'
	exec dbo.m136_DropForeignKeyTable 'tblMenu', 'FK__tblMenu__iInform'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblInformationType ADD CONSTRAINT PK__tblInformationType_iInformationTypeId PRIMARY KEY CLUSTERED
	(
		[iInformationTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[tblGroup] ADD CONSTRAINT FK__tblGroup_iInformationTypeId__tblInformationType_iInformationTypeId FOREIGN KEY ([iInformationTypeId])
	REFERENCES [dbo].[tblInformationType] ([iInformationTypeId])

	ALTER TABLE [dbo].[tblItem] ADD CONSTRAINT FK__tblItem_iInformationTypeId__tblInformationType_iInformationTypeId FOREIGN KEY ([iInformationTypeId])
	REFERENCES [dbo].[tblInformationType] ([iInformationTypeId])
	
	ALTER TABLE [dbo].[tblMenu] ADD CONSTRAINT FK__tblMenu_iInformationTypeId__tblInformationType_iInformationTypeId FOREIGN KEY ([iInformationTypeId])
	REFERENCES [dbo].[tblInformationType] ([iInformationTypeId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblItem', 'PK__tblItem') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relItem', 'FK__relItem__iItemCh'
	exec dbo.m136_DropForeignKeyTable 'relItem', 'FK__relItem__iItemId'
	exec dbo.m136_DropForeignKeyTable 'tblEmployee', 'FK__tblEmploy__iImag'
	exec dbo.m136_DropForeignKeyTable 'tblFile', 'FK__tblFile__iItemId'
	exec dbo.m136_DropForeignKeyTable 'tblImage', 'FK__tblImage__iItemI'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblItem ADD CONSTRAINT PK__tblItem_iItemId PRIMARY KEY CLUSTERED
	(
		[iItemId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[relItem] ADD CONSTRAINT FK__relItem_iItemChildId__tblItem_iItemId FOREIGN KEY ([iItemChildId])
	REFERENCES [dbo].[tblItem] ([iItemId])

	ALTER TABLE [dbo].[tblItem] ADD CONSTRAINT FK__relItem_iItemId__tblItem_iItemId FOREIGN KEY ([iItemId])
	REFERENCES [dbo].[tblItem] ([iItemId])
	
	ALTER TABLE [dbo].[tblEmployee] ADD CONSTRAINT FK__tblEmployee_iImageId__tblItem_iItemId FOREIGN KEY ([iImageId])
	REFERENCES [dbo].[tblItem] ([iItemId])
	
	ALTER TABLE [dbo].[tblFile] ADD CONSTRAINT FK__tblFile_iItemId__tblItem_iItemId FOREIGN KEY ([iItemId])
	REFERENCES [dbo].[tblItem] ([iItemId])
	
	ALTER TABLE [dbo].[tblImage] ADD CONSTRAINT FK__tblImage_iItemId__tblItem_iItemId FOREIGN KEY ([iItemId])
	REFERENCES [dbo].[tblItem] ([iItemId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblMenu', 'PK__tblMenu') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblMenu ADD CONSTRAINT PK__tblMenu_iItemId PRIMARY KEY CLUSTERED
	(
		[iItemId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblPermissionBit', 'PK__tblPermi') 
IF @sql IS NOT NULL
BEGIN
	EXEC (@sql)
	ALTER TABLE dbo.tblPermissionBit ADD CONSTRAINT PK__tblPermissionBit_iBitNumber_iPermissionSetId PRIMARY KEY CLUSTERED
	(
		[iBitNumber] ASC,
		[iPermissionSetId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblPermissionSet', 'PK__tblPermi') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'tblPermissionBit', 'FK__tblPermis__iPerm'
	exec dbo.m136_DropForeignKeyTable 'relApplicationPermissionSet', 'FK__relApplic__iPerm'
	exec dbo.m136_DropForeignKeyTable 'tblACL', 'FK__tblACL__iPermiss'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblPermissionSet ADD CONSTRAINT PK__tblPermissionSet_iPermissionSetId PRIMARY KEY CLUSTERED
	(
		[iPermissionSetId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[tblPermissionBit] ADD CONSTRAINT FK__tblPermissionBit_iPermissionSetId__tblPermissionSet_iPermissionSetId FOREIGN KEY ([iPermissionSetId])
	REFERENCES [dbo].[tblPermissionSet] ([iPermissionSetId])

	ALTER TABLE [dbo].[relApplicationPermissionSet] ADD CONSTRAINT FK__relApplicationPermissionSet_iPermissionSetId__tblPermissionSet_iPermissionSetId FOREIGN KEY ([iPermissionSetId])
	REFERENCES [dbo].[tblPermissionSet] ([iPermissionSetId])
	
	ALTER TABLE [dbo].[tblACL] ADD CONSTRAINT FK__tblACL_iPermissionSetId__tblPermissionSet_iPermissionSetId FOREIGN KEY ([iPermissionSetId])
	REFERENCES [dbo].[tblPermissionSet] ([iPermissionSetId])
	
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblPermissionSetType', 'PK__tblPermi') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'tblPermissionSet', 'FK__tblPermis__iPerm'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblPermissionSetType ADD CONSTRAINT PK__tblPermissionSetType_iPermissionSetTypeId PRIMARY KEY CLUSTERED
	(
		[iPermissionSetTypeId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[tblPermissionSet] ADD CONSTRAINT FK__tblPermissionSet_iPermissionSetTypeId__tblPermissionSetType_iPermissionSetTypeId FOREIGN KEY ([iPermissionSetTypeId])
	REFERENCES [dbo].[tblPermissionSetType] ([iPermissionSetTypeId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblPosition', 'PK__tblPosit') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relDepartmentPosition', 'FK__relDepart__iPosi'
	exec dbo.m136_DropForeignKeyTable 'relEmployeePosition', 'FK__relEmploy__iPosi'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblPosition ADD CONSTRAINT PK__tblPosition_iPositionId PRIMARY KEY CLUSTERED
	(
		[iPositionId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[relDepartmentPosition] ADD CONSTRAINT FK__relDepartmentPosition_iPositionId__tblPosition_iPositionId FOREIGN KEY ([iPositionId])
	REFERENCES [dbo].[tblPosition] ([iPositionId])
	
	ALTER TABLE [dbo].[relEmployeePosition] ADD CONSTRAINT FK__relEmployeePosition_iPositionId__tblPosition_iPositionId FOREIGN KEY ([iPositionId])
	REFERENCES [dbo].[tblPosition] ([iPositionId])
END
GO

DECLARE @sql NVARCHAR(MAX)
SET @sql = dbo.fn136_GetSqlDropConstraintKey('tblSecGroup', 'PK__tblSecGr') 
IF @sql IS NOT NULL
BEGIN
	--remove foreign key
	exec dbo.m136_DropForeignKeyTable 'relEmployeeSecGroup', 'FK__relEmploy__iSecG'
	exec dbo.m136_DropForeignKeyTable 'tblACL', 'FK__tblACL__iSecurit'
	
	EXEC (@sql)
	ALTER TABLE dbo.tblSecGroup ADD CONSTRAINT PK__tblSecGroup_iSecGroupId PRIMARY KEY CLUSTERED
	(
		[iSecGroupId] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)

	ALTER TABLE [dbo].[relEmployeeSecGroup] ADD CONSTRAINT FK__relEmployeeSecGroup_iSecGroupId__tblSecGroup_iSecGroupId FOREIGN KEY ([iSecGroupId])
	REFERENCES [dbo].[tblSecGroup] ([iSecGroupId])
	
	ALTER TABLE [dbo].[tblACL] ADD CONSTRAINT FK__tblACL_iSecurityId__tblSecGroup_iSecGroupId FOREIGN KEY ([iSecurityId])
	REFERENCES [dbo].[tblSecGroup] ([iSecGroupId])
END
GO