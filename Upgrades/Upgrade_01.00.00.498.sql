INSERT INTO #Description VALUES ('Update SP [dbo].[m136_spReportFolderDocumentStatistics]')
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'AllowForwarding' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_Hearings'))
BEGIN
    ALTER TABLE dbo.m136_Hearings ADD AllowForwarding BIT
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'Conclusion' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_Hearings'))
BEGIN
    ALTER TABLE dbo.m136_Hearings ADD Conclusion nvarchar(max)
END
GO

IF NOT EXISTS(SELECT * FROM sys.columns 
        WHERE [NAME] = N'Notify' AND [OBJECT_ID] = OBJECT_ID(N'dbo.m136_Hearings'))
BEGIN
    ALTER TABLE dbo.m136_Hearings ADD Notify BIT
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
	@Employees AS [dbo].[Item] READONLY,
	@AllowForwarding BIT,
	@Notify BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	SET NOCOUNT ON;
	DECLARE @HearingId INT;
	INSERT INTO dbo.m136_Hearings(EntityId,IsPublic,CreatedDate,CreatedBy,DueDate,IsActive,AllowForwarding,Notify)
	VALUES(@EntityId, @IsPublic, GETDATE(), @CreateBy, @DueDate, 1,@AllowForwarding, @Notify)
	SET @HearingId = SCOPE_IDENTITY();
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
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

IF OBJECT_ID('[dbo].[m136_be_EditDocumentHearing]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_EditDocumentHearing] AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_EditDocumentHearing] 
	@HearingId			INT,
	@IsPublic			BIT,
	@DueDate			DATETIME,
	@EmployeesAdd AS [dbo].[Item] READONLY,
	@EmployeesDelete AS [dbo].[Item] READONLY,
	@AllowForwarding BIT,
	@Notify BIT
AS
BEGIN
BEGIN TRY
    BEGIN TRANSACTION;
	UPDATE dbo.m136_Hearings
		SET IsPublic = @IsPublic, DueDate = @DueDate,
		    AllowForwarding = @AllowForwarding,
			Notify = @Notify
	WHERE Id = @HearingId
	DELETE FROM [dbo].[m136_HearingMembers]
	WHERE HearingsId = @HearingId
		  AND EmployeeId IN (SELECT Id FROM @EmployeesDelete)
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
	FROM @EmployeesAdd
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

IF OBJECT_ID('[dbo].[m136_be_AddMembersToHearingDocument]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_AddMembersToHearingDocument] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_AddMembersToHearingDocument] 
	@HearingId			INT,
	@Employees AS [dbo].[Item] READONLY
AS
BEGIN
	INSERT INTO [dbo].[m136_HearingMembers](HearingsId, EmployeeId, HasRead)
	SELECT @HearingId, Id, 0
	FROM @Employees
	WHERE Id NOT IN( SELECT EmployeeId FROM dbo.m136_HearingMembers WHERE HearingsId = @HearingId)
	
	SELECT m.Id, m.HearingsId, m.EmployeeId, m.HasRead, m.HearingResponse,
		   e.strFirstName AS FirstName, e.strLastName AS LastName, e.strEmail AS Email, 
		   [dbo].[IsCommentsForHearingDocument](m.EmployeeId, m.HearingsId) HasComment,
		   d.iDepartmentId AS DepartmentId, d.strName AS DepartmentName,
		   lu.Name AS Response, m.Reason,
		   [dbo].[CountHearingComments](m.EmployeeId, @HearingId) CountComment
	FROM dbo.m136_HearingMembers m
	LEFT JOIN dbo.tblEmployee e ON m.EmployeeId = e.iEmployeeId
	LEFT JOIN dbo.tblDepartment d ON e.iDepartmentId = d.iDepartmentId
	LEFT JOIN dbo.m136_luHearingResponses lu ON m.HearingResponse = lu.Id
	WHERE m.HearingsId = @HearingId
END
GO

IF OBJECT_ID('[dbo].[m136_be_SendDocumentToApproval]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_SendDocumentToApproval] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_SendDocumentToApproval]
    @ApproverId INT,
	@EntityId INT,
	@TransferReadingReceipts BIT,
	@Conclusion NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
            DECLARE @DocumentId INT;
            SELECT
                @DocumentId = iDocumentId
            FROM
                m136_tblDocument
            WHERE
                iEntityId = @EntityId
            UPDATE
                m136_tblDocument
            SET
                iDraft = 0, 
                iApproved = 0
            WHERE
                iEntityId = @EntityId;
                
            INSERT INTO
                m136_relSentEmpApproval
                    (iEmployeeId, iEntityId, dtmSentToApproval)
                VALUES
                    (@ApproverId, @EntityId, GETDATE())
            DELETE FROM
                m136_tblCopyConfirms
            WHERE
                iEntityId = @EntityId;
                
            IF @TransferReadingReceipts = 1
            BEGIN
                INSERT INTO
                    m136_tblCopyConfirms
                        (iEntityId)
                    VALUES
                        (@EntityId)
            END
            EXEC m136_SetVersionFlags @DocumentId;
            
            IF @Conclusion IS NOT NULL
				Update dbo.m136_Hearings	
				SET Conclusion = @Conclusion
				WHERE EntityId = @EntityId AND  Id = (SELECT MAX(Id) FROM dbo.m136_Hearings WHERE EntityId = @EntityId)
				
        COMMIT TRANSACTION;
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

IF OBJECT_ID('[dbo].[m136_be_UpdatePublishAllComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdatePublishAllComment]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdatePublishAllComment]
	@UserId AS INT,
	@HearingsId AS INT
AS
BEGIN
    DECLARE @CommentTable TABLE(Id INT, HearingsId INT, iMetaInfoTemplateRecordsId INT NULL, Comment NVARCHAR(MAX), CreatedDate DATETIME, CreatedBy INT)
	INSERT INTO @CommentTable
	SELECT c.Id, c.HearingsId, c.iMetaInfoTemplateRecordsId, c.Comment, c.CreatedDate, c.CreatedBy
	FROM dbo.m136_HearingComments c
	JOIN dbo.m136_Hearings h ON c.HearingsId = h.Id AND h.Notify = 1
	WHERE c.CreatedBy = @UserId
	  AND c.HearingsId = @HearingsId
	  AND c.IsDraft = 1
	  AND h.Notify = 1
	
	UPDATE dbo.m136_HearingComments 
	SET IsDraft = 0, Published = GETDATE()
	WHERE CreatedBy = @UserId
		  AND HearingsId = @HearingsId
		  AND IsDraft = 1
	
	SELECT *
	FROM @CommentTable
END
GO

IF OBJECT_ID('[dbo].[CountHearingComments]', 'fn') IS NULL
    EXEC ('CREATE FUNCTION [dbo].[CountHearingComments]() RETURNS VARCHAR(50) AS BEGIN RETURN NULL END;')
GO

ALTER FUNCTION [dbo].[CountHearingComments]
(
	@EmployeeId INT,
	@HearingId INT
)
RETURNS VARCHAR(50)
AS
BEGIN
	DECLARE @result VARCHAR(50), @PublishComment INT, @DrafComment INT;
	SELECT @PublishComment=COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = @EmployeeId AND HearingsId = @HearingId AND IsDraft = 0
	SELECT @DrafComment =COUNT(Id) FROM dbo.m136_HearingComments WHERE CreatedBy = @EmployeeId AND HearingsId = @HearingId AND IsDraft = 1
	
	SET @result = CONVERT(VARCHAR,ISNULL(@PublishComment,0)) + (CASE WHEN @DrafComment IS NOT NULL AND @DrafComment <> 0 THEN '(' + CONVERT(VARCHAR,ISNULL(@DrafComment,0)) + ')' ELSE '' END )
	Return @result;
END
GO

IF OBJECT_ID('[dbo].[m136_be_PublishHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_PublishHearingComment]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_PublishHearingComment]
	@Id AS INT
AS
BEGIN
	DECLARE @Published AS DATETIME = GETDATE()
		
	UPDATE dbo.m136_HearingComments 
	SET IsDraft = 0, Published = @Published
	WHERE Id = @Id
END
GO
