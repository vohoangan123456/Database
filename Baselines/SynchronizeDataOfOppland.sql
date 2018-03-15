INSERT INTO #Description VALUES ('Modified [dbo].[m136_GetUserEmailSubscriptions]')
GO


IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'ExtId'
      AND Object_ID = Object_ID(N'dbo.tblDepartment'))
BEGIN
    ALTER TABLE dbo.tblDepartment ADD ExtId VARCHAR(50) NULL;
    ALTER TABLE dbo.tblDepartment ADD ExtParentId VARCHAR(50) NULL;
    ALTER TABLE dbo.tblDepartment ADD Active BIT NULL;
END
GO

IF NOT EXISTS(
    SELECT *
    FROM sys.columns 
    WHERE Name = N'ExtId'
      AND Object_ID = Object_ID(N'dbo.tblEmployee'))
BEGIN
    ALTER TABLE dbo.tblEmployee ADD ExtId INT NULL;
    ALTER TABLE dbo.tblEmployee ADD Synced DATETIME NULL;
END
GO

IF NOT EXISTS (SELECT * FROM dbo.tblDepartment WHERE iDepartmentId = -1)
BEGIN
	SET IDENTITY_INSERT dbo.tblDepartment ON;
		INSERT INTO dbo.tblDepartment
		(
		   iDepartmentId,
		   iDepartmentParentId,
		   iCompanyId,
		   iMin,
		   iMax,
		   iLevel,
		   strName,
		   strDescription,
		   strContactInfo,
		   bCompany,
		   strPhone,
		   strFax,
		   strEmail,
		   strURL,
		   iCountryId,
		   strOrgNo,
		   strVisitAddress1,
		   strVisitAddress2,
		   strVisitAddress3,
		   strAddress1,
		   strAddress2,
		   strAddress3,
		   strFileURL,
		   iChildCount,
		   ADIdentifier
	   )
	   VALUES
	   (
		   -1,-- iDepartmentId - int
		   0, -- iDepartmentParentId - int
		   -1, -- iCompanyId - int
		   0, -- iMin - int
		   0, -- iMax - int
		   1, -- iLevel - int
		   'Oppland Fylkeskommune', -- strName - varchar
		   '', -- strDescription - varchar
		   '', -- strContactInfo - varchar
		   1, -- bCompany - bit
		   '', -- strPhone - varchar
		   '', -- strFax - varchar
		   '', -- strEmail - varchar
		   '', -- strURL - varchar
		   1, -- iCountryId - int
		   '', -- strOrgNo - varchar
		   '', -- strVisitAddress1 - varchar
		   '', -- strVisitAddress2 - varchar
		   '', -- strVisitAddress3 - varchar
		   '', -- strAddress1 - varchar
		   '', -- strAddress2 - varchar
		   '', -- strAddress3 - varchar
		   '', -- strFileURL - varchar
		   0, -- iChildCount - int
		   '00000000-0000-0000-0000-000000000000' -- ADIdentifier - uniqueidentifier
	   );
	   
	   
	SET IDENTITY_INSERT dbo.tblDepartment OFF;
END
IF NOT EXISTS (SELECT * FROM dbo.tblDepartment WHERE iDepartmentId = -2)
BEGIN
	SET IDENTITY_INSERT dbo.tblDepartment ON;
		INSERT INTO dbo.tblDepartment
		(
		   iDepartmentId,
		   iDepartmentParentId,
		   iCompanyId,
		   iMin,
		   iMax,
		   iLevel,
		   strName,
		   strDescription,
		   strContactInfo,
		   bCompany,
		   strPhone,
		   strFax,
		   strEmail,
		   strURL,
		   iCountryId,
		   strOrgNo,
		   strVisitAddress1,
		   strVisitAddress2,
		   strVisitAddress3,
		   strAddress1,
		   strAddress2,
		   strAddress3,
		   strFileURL,
		   iChildCount,
		   ADIdentifier
	   )
	   VALUES
	   (
		   -2,-- iDepartmentId - int
		   -1, -- iDepartmentParentId - int
		   -1, -- iCompanyId - int
		   0, -- iMin - int
		   0, -- iMax - int
		   1, -- iLevel - int
		   'Sluttet', -- strName - varchar
		   '', -- strDescription - varchar
		   '', -- strContactInfo - varchar
		   0, -- bCompany - bit
		   '', -- strPhone - varchar
		   '', -- strFax - varchar
		   '', -- strEmail - varchar
		   '', -- strURL - varchar
		   1, -- iCountryId - int
		   '', -- strOrgNo - varchar
		   '', -- strVisitAddress1 - varchar
		   '', -- strVisitAddress2 - varchar
		   '', -- strVisitAddress3 - varchar
		   '', -- strAddress1 - varchar
		   '', -- strAddress2 - varchar
		   '', -- strAddress3 - varchar
		   '', -- strFileURL - varchar
		   0, -- iChildCount - int
		   '00000000-0000-0000-0000-000000000000' -- ADIdentifier - uniqueidentifier
	   );
	 
	SET IDENTITY_INSERT dbo.tblDepartment OFF;
END

IF TYPE_ID(N'ImportOrganization') IS NULL
	EXEC ('CREATE TYPE ImportOrganization AS TABLE(Id VARCHAR(50), Code VARCHAR(50), Name NVARCHAR(4000), ParentId VARCHAR(50), LeaderId VARCHAR(50))')
GO

IF TYPE_ID(N'ImportEmployee') IS NULL
	EXEC ('CREATE TYPE ImportEmployee AS TABLE(Id INT, UserName VARCHAR(50), FirstName NVARCHAR(500), LastName NVARCHAR(500),Email VARCHAR(200), OrganizationId VARCHAR(50))')
GO

IF OBJECT_ID('[dbo].[m136_be_SynchronizeOrganizationAndUsers]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SynchronizeOrganizationAndUsers] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SynchronizeOrganizationAndUsers] 
	@OrganizationTable	AS dbo.ImportOrganization READONLY,
	@EmployeeTable AS dbo.ImportEmployee READONLY,
	@RootDepartmentId			INT,
	@QuitDepartmentId			INT,
	@EmployeeSecGroupId			INT,
	@LoginDomain				VARCHAR(200)
AS
BEGIN
	BEGIN TRY
	BEGIN TRANSACTION 
		DECLARE @OrganizationId VARCHAR(50), @OrganizationCode VARCHAR(50),@OrganizationName NVARCHAR(4000), @OrganizationParentId VARCHAR(50), @OrganizationLeaderId VARCHAR(50)
		DECLARE @OrganizationTemp AS TABLE(DepartmentId INT, Id VARCHAR(50), Code VARCHAR(50), ParentId VARCHAR(50), LeaderId VARCHAR(50))
		DECLARE @ResultEmployee AS TABLE(iEmployeeId INT, strFirstName VARCHAR(50), strLastName VARCHAR(50), strLoginName VARCHAR(100), strEmail VARCHAR(100), EmpType BIT)
		
		DECLARE curOrganization CURSOR FOR
			SELECT Id, Code, Name, ParentId, LeaderId FROM @OrganizationTable
		OPEN curOrganization
		FETCH NEXT FROM curOrganization INTO @OrganizationId, @OrganizationCode, @OrganizationName, @OrganizationParentId, @OrganizationLeaderId
		WHILE @@fetch_status=0
		BEGIN
			DECLARE @iDepartmentId INT = NULL
			SELECT @iDepartmentId = iDepartmentId FROM dbo.tblDepartment WHERE ExtId = @OrganizationCode
			DECLARE @ParentId INT = NULL
			IF CAST(@OrganizationParentId AS INT) = 0
			BEGIN
				SET @ParentId = @RootDepartmentId
			END
			ELSE
			BEGIN
				SELECT @ParentId = iDepartmentId FROM dbo.tblDepartment WHERE ExtId = @OrganizationParentId
				IF @ParentId IS NULL OR @ParentId = 0 
					SET @ParentId = @RootDepartmentId
			END
			
			IF @iDepartmentId IS NULL OR @iDepartmentId = 0
			BEGIN
				DECLARE @iMaxDepartmentId INT;
				SELECT @iMaxDepartmentId = MAX(dpt.iDepartmentId) FROM dbo.tblDepartment dpt;
				DECLARE @NewDepartmentId INT = ISNULL(@iMaxDepartmentId,0) + 1
				SET IDENTITY_INSERT dbo.tblDepartment ON;
				INSERT INTO dbo.tblDepartment
				(
				   iDepartmentId,
				   iDepartmentParentId,
				   iCompanyId,
				   iMin,
				   iMax,
				   iLevel,
				   strName,
				   strDescription,
				   strContactInfo,
				   bCompany,
				   strPhone,
				   strFax,
				   strEmail,
				   strURL,
				   iCountryId,
				   strOrgNo,
				   strVisitAddress1,
				   strVisitAddress2,
				   strVisitAddress3,
				   strAddress1,
				   strAddress2,
				   strAddress3,
				   strFileURL,
				   iChildCount,
				   ADIdentifier,
				   ExtId,
				   ExtParentId,
				   Active
			   )
			   VALUES
			   (	
				   @NewDepartmentId,
				   @ParentId, -- iDepartmentParentId - int
				   @RootDepartmentId, -- iCompanyId - int
				   0, -- iMin - int
				   0, -- iMax - int
				   1, -- iLevel - int
				   @OrganizationName, -- strName - varchar
				   '', -- strDescription - varchar
				   '', -- strContactInfo - varchar
				   0, -- bCompany - bit
				   '', -- strPhone - varchar
				   '', -- strFax - varchar
				   '', -- strEmail - varchar
				   '', -- strURL - varchar
				   1, -- iCountryId - int
				   '', -- strOrgNo - varchar
				   '', -- strVisitAddress1 - varchar
				   '', -- strVisitAddress2 - varchar
				   '', -- strVisitAddress3 - varchar
				   '', -- strAddress1 - varchar
				   '', -- strAddress2 - varchar
				   '', -- strAddress3 - varchar
				   '', -- strFileURL - varchar
				   0, -- iChildCount - int
				   '00000000-0000-0000-0000-000000000000', -- ADIdentifier - uniqueidentifier
				   @OrganizationCode,
				   @OrganizationParentId,
				   1
			   );
				SET IDENTITY_INSERT dbo.tblDepartment OFF;
				
				INSERT INTO @OrganizationTemp 
				VALUES(@NewDepartmentId, @OrganizationId, @OrganizationCode, @OrganizationParentId,@OrganizationLeaderId)
				
			END
			ELSE
			BEGIN
				INSERT INTO @OrganizationTemp 
				VALUES(@iDepartmentId, @OrganizationId, @OrganizationCode, @OrganizationParentId,@OrganizationLeaderId)
				UPDATE dbo.tblDepartment
					SET strName = @OrganizationName,
						iDepartmentParentId = @ParentId,
						Active = 1,
						ExtParentId = @OrganizationParentId
				WHERE iDepartmentId = @iDepartmentId
			END
		FETCH NEXT FROM curOrganization INTO @OrganizationId, @OrganizationCode, @OrganizationName, @OrganizationParentId, @OrganizationLeaderId
		END
		CLOSE curOrganization
		DEALLOCATE curOrganization
		--Update department don't have in file but have active = true
		UPDATE dbo.tblDepartment
			SET Active = 0
		WHERE Active = 1
			  AND ExtId NOT IN (SELECT Code FROM @OrganizationTable)
		--Sync data for users
		DECLARE @CurrentDate DATETIME = GETDATE(), @EmpId INT, @EmpUserName VARCHAR(50), @EmpFirstName NVARCHAR(500), @EmpLastName NVARCHAR(500), @EmpEmail VARCHAR(200), @EmpOrganizationId VARCHAR(50)
		DECLARE curUsers CURSOR FOR
			SELECT Id, UserName, FirstName, LastName, Email, OrganizationId FROM @EmployeeTable
		OPEN curUsers
		FETCH NEXT FROM curUsers INTO @EmpId, @EmpUserName, @EmpFirstName, @EmpLastName, @EmpEmail, @EmpOrganizationId
		WHILE @@fetch_status=0
		BEGIN
			DECLARE @iEmployeeId INT = NULL, @EmpDepartmentId INT = NULL
			DECLARE @RelDepartmentLeader AS TABLE(DepartmentId INT)
			SELECT @iEmployeeId = iEmployeeId FROM dbo.tblEmployee WHERE ExtId = @EmpId
			
			DELETE @RelDepartmentLeader
			
			INSERT INTO @RelDepartmentLeader
			SELECT DepartmentId FROM @OrganizationTemp WHERE CAST(LeaderId AS INT) = @EmpId
			
			SELECT @EmpDepartmentId = DepartmentId FROM @OrganizationTemp WHERE Id = @EmpOrganizationId
			IF @EmpDepartmentId IS NULL OR @EmpDepartmentId = 0
				SET @EmpDepartmentId = @RootDepartmentId
				
			IF @iEmployeeId IS NULL OR @iEmployeeId = 0
			BEGIN
				DECLARE @iMaxEmployeeId INT;
				SELECT @iMaxEmployeeId = MAX(te.iEmployeeId) FROM dbo.tblEmployee te;
				DECLARE @NewEmployeeId INT = ISNULL(@iMaxEmployeeId,0) + 1;
				
				IF @EmpEmail IS NOT NULL AND @EmpEmail <> ''
				BEGIN
					IF EXISTS (SELECT e.* FROM [dbo].[tblEmployee] e WHERE e.strEmail = @EmpEmail)
					BEGIN 
						INSERT INTO @ResultEmployee
						VALUES(@NewEmployeeId, @EmpFirstName, @EmpLastName,@EmpUserName, @EmpEmail, 0)
					END
				END
				
				IF @EmpUserName IS NOT NULL AND @EmpUserName <> ''
				BEGIN
					IF EXISTS (SELECT e.* FROM [dbo].[tblEmployee] e WHERE e.strLoginName = @EmpUserName)
					BEGIN 
						INSERT INTO @ResultEmployee
						VALUES(@NewEmployeeId, @EmpFirstName, @EmpLastName,@EmpUserName, @EmpEmail, 1)
					END
				END
				
				SET IDENTITY_INSERT dbo.tblEmployee ON;
				INSERT INTO dbo.tblEmployee
				(
					iEmployeeId,
					strEmployeeNo,
					iDepartmentId,
					strExpDep,
					dtmEmployed,
					strFirstName,
					strLastName,
					strTitle,
					strAddress1,
					strAddress2,
					strAddress3,
					iCountryId,
					strPhoneHome,
					strPhoneInternal,
					strPhoneWork,
					strPhoneMobile,
					strBeeper,
					strCallNumber,
					strFax,
					strEmail,
					strLoginName,
					strLoginDomain,
					strPassword,
					iCompanyId,
					bWizard,
					strComment,
					iImageId,
					bEmailConfirmed,
					strMailPassword,
					ADIdentifier,
					LastLogin,
					PreviousLogin,
					ExtId,
					Synced
				)
				VALUES
				(
					@NewEmployeeId, -- iEmployeeId - int
					'', -- strEmployeeNo - varchar
					@EmpDepartmentId, -- iDepartmentId - int
					'', -- strExpDep - varchar
					GETDATE(), -- dtmEmployed - smalldatetime
					@EmpFirstName, -- strFirstName - varchar
					@EmpLastName, -- strLastName - varchar
					'', -- strTitle - varchar
					'', -- strAddress1 - varchar
					'', -- strAddress2 - varchar
					'', -- strAddress3 - varchar
					1, -- iCountryId - int
					'', -- strPhoneHome - varchar
					'', -- strPhoneInternal - varchar
					'', -- strPhoneWork - varchar
					'', -- strPhoneMobile - varchar
					'', -- strBeeper - varchar
					'', -- strCallNumber - varchar
					'', -- strFax - varchar
					@EmpEmail, -- strEmail - varchar
					@EmpUserName, -- strLoginName - varchar
					@LoginDomain, -- strLoginDomain - varchar
					'', -- strPassword - varchar
					@RootDepartmentId, -- iCompanyId - int
					0, -- bWizard - bit
					'', -- strComment - varchar
					0, -- iImageId - int
					0, -- bEmailConfirmed - bit
					'', -- strMailPassword - varchar
					'00000000-0000-0000-0000-000000000000', -- ADIdentifier - uniqueidentifier
					NULL, -- LastLogin - datetime
					NULL, -- PreviousLogin - datetime
					@EmpId,
					@CurrentDate
				);
				SET IDENTITY_INSERT dbo.tblEmployee OFF;
				
				INSERT INTO dbo.relEmployeeSecGroup(iEmployeeId,iSecGroupId)
				VALUES(@NewEmployeeId,@EmployeeSecGroupId)
				
				IF EXISTS (SELECT * FROM @RelDepartmentLeader)
				BEGIN
					DECLARE @RelDepartmentId INT;
					DECLARE curRelDepartmentLeader CURSOR FOR
					SELECT DepartmentId FROM @RelDepartmentLeader
					OPEN curRelDepartmentLeader
					FETCH NEXT FROM curRelDepartmentLeader INTO @RelDepartmentId
					WHILE @@fetch_status=0
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
							@RelDepartmentId,
							@NewEmployeeId,
							1 
						)
					FETCH NEXT FROM curRelDepartmentLeader INTO @RelDepartmentId
					END
					CLOSE curRelDepartmentLeader
					DEALLOCATE curRelDepartmentLeader
				END
			
			END
			ELSE
			BEGIN
				UPDATE dbo.tblEmployee 
				SET strLoginName = @EmpUserName,
					iDepartmentId = @EmpDepartmentId,
					strFirstName = @EmpFirstName,
					strLastName = @EmpLastName,
					strEmail = @EmpEmail,
					strLoginDomain = @LoginDomain,
					Synced = @CurrentDate
				WHERE iEmployeeId = @iEmployeeId
				IF NOT EXISTS( SELECT * FROM dbo.relEmployeeSecGroup WHERE iEmployeeId = @iEmployeeId AND iSecGroupId = @EmployeeSecGroupId)
				BEGIN
					INSERT INTO dbo.relEmployeeSecGroup(iEmployeeId,iSecGroupId)
					VALUES(@iEmployeeId,@EmployeeSecGroupId)
				END
				IF EXISTS (SELECT * FROM @RelDepartmentLeader)
				BEGIN
					DECLARE @RelUpdateDepartmentId INT;
					DECLARE curRelDepartmentLeaderUpdate CURSOR FOR
					SELECT DepartmentId FROM @RelDepartmentLeader
					OPEN curRelDepartmentLeaderUpdate
					FETCH NEXT FROM curRelDepartmentLeaderUpdate INTO @RelUpdateDepartmentId
					WHILE @@fetch_status=0
					BEGIN
						IF NOT EXISTS(SELECT * FROM dbo.DepartmentResponsibles WHERE DepartmentId = @RelUpdateDepartmentId AND EmployeeId = @iEmployeeId AND ResponsibleTypeId = 1)
						BEGIN
							DECLARE @MaxDepId INT;
							SELECT @MaxDepId = MAX(dr.Id) FROM dbo.DepartmentResponsibles dr;
							SET @MaxDepId = ISNULL(@MaxDepId, 0);
							INSERT INTO dbo.DepartmentResponsibles
							(
								Id,
								DepartmentId,
								EmployeeId,
								ResponsibleTypeId
							)
							VALUES
							(
								(@MaxDepId + 1),
								@RelUpdateDepartmentId,
								@iEmployeeId,
								1 
							)
						END
					FETCH NEXT FROM curRelDepartmentLeaderUpdate INTO @RelUpdateDepartmentId
					END
					CLOSE curRelDepartmentLeaderUpdate
					DEALLOCATE curRelDepartmentLeaderUpdate
				END
			END

		FETCH NEXT FROM curUsers INTO @EmpId, @EmpUserName, @EmpFirstName, @EmpLastName, @EmpEmail, @EmpOrganizationId
		END
		CLOSE curUsers
		DEALLOCATE curUsers
		--Remove user quit
		DELETE dbo.relEmployeeSecGroup
		WHERE iSecGroupId = @EmployeeSecGroupId
			  AND  iEmployeeId IN (SELECT iEmployeeId FROM dbo.tblEmployee WHERE ExtId IS NOT NULL AND Synced < @CurrentDate)
		UPDATE dbo.tblEmployee
		SET iDepartmentId = @QuitDepartmentId,
			Synced = @CurrentDate
		WHERE iEmployeeId IN (SELECT iEmployeeId FROM dbo.tblEmployee WHERE ExtId IS NOT NULL AND Synced < @CurrentDate)
		
		SELECT * FROM @ResultEmployee
		
		COMMIT
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK
		DECLARE @ErrorMessage nvarchar(MAX), @ErrorNumber int, @ErrorSeverity int, @ErrorState int, @ErrorLine int
		SELECT @ErrorMessage = N'Error %d, Line %d, Message: '+ERROR_MESSAGE(),@ErrorNumber = ERROR_NUMBER(),@ErrorSeverity = ERROR_SEVERITY(),@ErrorState = ERROR_STATE(),@ErrorLine = ERROR_LINE();
		RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState, @ErrorNumber,@ErrorLine);
	END CATCH
END
GO