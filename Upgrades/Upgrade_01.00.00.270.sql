INSERT INTO #Description VALUES('Create SP for hearing feedback')
GO

IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'dbo.m136_HearingComments') 
         AND name = 'IsDraft'
)
 BEGIN
 /*Column does not exist */
	ALTER TABLE dbo.m136_HearingComments
	ADD [IsDraft] BIT
 END
 GO
 
 IF NOT EXISTS (
  SELECT 1 
  FROM   sys.columns 
  WHERE  object_id = OBJECT_ID(N'dbo.m136_HearingComments') 
         AND name = 'Published'
)
 BEGIN
 /*Column does not exist */
	ALTER TABLE dbo.m136_HearingComments
	ADD [Published] DATETIME
 END
 GO
 
IF OBJECT_ID('[dbo].[m136_be_GetHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHearingComment]  AS SELECT 1')
GO

ALTER PROCEDURE [dbo].[m136_be_GetHearingComment] 
	@UserId AS INT,
	@HearingsId AS INT
AS
BEGIN
	SELECT h.*, e.strFirstName, e.strLastName
	FROM dbo.m136_HearingComments h
	LEFT JOIN dbo.tblEmployee e ON e.iEmployeeId = h.CreatedBy 
	WHERE HearingsId = @HearingsId
		  AND (h.IsDraft = 0 OR (h.IsDraft = 1 AND h.CreatedBy = @UserId))
	ORDER BY h.IsDraft, h.Published, h.CreatedDate
END
GO

IF OBJECT_ID('[dbo].[m136_be_CreateHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_CreateHearingComment]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_CreateHearingComment] 
	@UserId AS INT,
	@HearingsId AS INT,
	@FieldId AS INT = NULL,
	@Comment AS NVARCHAR(MAX),
	@IsDraft AS BIT
AS
BEGIN
	DECLARE @Published AS DATETIME = NULL
	DECLARE @CurrentDate AS DATETIME = GETDATE()
	IF(@IsDraft = 0)
		BEGIN
			SET @Published = @CurrentDate
		END
	INSERT INTO dbo.m136_HearingComments(HearingsId,iMetaInfoTemplateRecordsId,CreatedDate,CreatedBy,Comment,IsDraft,Published)
	VALUES(@HearingsId, @FieldId, @CurrentDate, @UserId, @Comment, @IsDraft, @Published)
END
GO

IF OBJECT_ID('[dbo].[m136_be_GetHearingCommentByFieldId]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetHearingCommentByFieldId]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetHearingCommentByFieldId] 
	@UserId AS INT,
	@HearingsId AS INT,
	@FieldId AS INT = NULL
AS
BEGIN
	SELECT h.*, e.strFirstName, e.strLastName
	FROM dbo.m136_HearingComments h
	LEFT JOIN dbo.tblEmployee e ON e.iEmployeeId = h.CreatedBy 
	WHERE HearingsId = @HearingsId
		  AND (h.IsDraft = 0 OR (h.IsDraft = 1 AND h.CreatedBy = @UserId))
		  AND ((@FieldId IS NULL AND h.iMetaInfoTemplateRecordsId IS NULL) OR (h.iMetaInfoTemplateRecordsId = @FieldId))
	ORDER BY h.IsDraft, h.Published, h.CreatedDate
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateHearingComment]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateHearingComment]
	@Id AS INT,
	@Comment AS NVARCHAR(MAX),
	@IsDraft AS BIT
AS
BEGIN
	DECLARE @Published AS DATETIME = NULL
	DECLARE @CurrentDate AS DATETIME = GETDATE()
	
	IF(@IsDraft = 0)
		BEGIN
			SET @Published = @CurrentDate
		END
		
	UPDATE dbo.m136_HearingComments 
	SET Comment = @Comment, IsDraft = @IsDraft, Published = @Published
	WHERE Id = @Id
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteHearingComment]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteHearingComment]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_DeleteHearingComment]
	@Id AS INT
AS
BEGIN
	DELETE FROM dbo.m136_HearingComments 
	WHERE Id = @Id
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
	UPDATE dbo.m136_HearingComments 
	SET IsDraft = 0, Published = GETDATE()
	WHERE CreatedBy = @UserId
		  AND HearingsId = @HearingsId
		  AND IsDraft = 1
END
GO

IF OBJECT_ID('[dbo].[m136_be_UpdateHearingResponseForMember]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_UpdateHearingResponseForMember]  AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_UpdateHearingResponseForMember]
	@UserId AS INT,
	@HearingsId AS INT,
	@HearingResponse AS INT
AS
BEGIN
	UPDATE dbo.m136_HearingMembers
	SET HearingResponse = @HearingResponse
	WHERE EmployeeId = @UserId
		  AND HearingsId = @HearingsId
END
GO