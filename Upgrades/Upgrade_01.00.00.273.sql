INSERT INTO #Description VALUES('Create scripts support uploading videos')
GO

IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Uploads]') AND type in (N'U'))
	CREATE TABLE [dbo].[Uploads](
		[Id] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[iEntityId] [int] NOT NULL,
		[iFolderId] [int] NOT NULL,
		[Url] [nvarchar](4000) NOT NULL,
		[Location] [nvarchar] (4000) NOT NULL,
		[FileName] [varchar] (400) NOT NULL, 
		[ContentType] [varchar] (400),
		[iType] [int] NOT NULL DEFAULT(1),/*1: Video*/
	 CONSTRAINT [PK_Uploads] PRIMARY KEY CLUSTERED 
	(
		[Id] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


IF  NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[UploadFolders]') AND type in (N'U'))
	CREATE TABLE [dbo].[UploadFolders](
		[iFolderId] [int] IDENTITY(1,1) NOT FOR REPLICATION NOT NULL,
		[strName] [nvarchar](255) NOT NULL,
		[iParentFolderId] [int] NULL,
		[iDeleted] [int] NULL,
		[iCreatedBy] [int] NULL,
		[iModifiedBy] [int] NULL,
		[dtmCreated] [datetime] NULL,
		[dtmModified] [datetime] NULL,
		[Location] [nvarchar](4000) NOT NULL,
	 CONSTRAINT [PK_UploadFolders] PRIMARY KEY CLUSTERED 
	(
		[iFolderId] ASC
	)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
	) ON [PRIMARY]
GO


IF NOT EXISTS(SELECT * FROM [dbo].[UploadFolders] WHERE iFolderId = 1)
BEGIN
	SET IDENTITY_INSERT [dbo].[UploadFolders] ON
	INSERT [dbo].[UploadFolders] ([iFolderId], [strName], [iParentFolderId], [iDeleted], [iCreatedBy], [iModifiedBy], [dtmCreated], [dtmModified], [Location]) VALUES (1, N'Videos', NULL, 0, 1, 1, GETDATE(), GETDATE(), N'')
	SET IDENTITY_INSERT [dbo].[UploadFolders] OFF
END



IF OBJECT_ID('[dbo].[CreateUpload]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[CreateUpload] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[CreateUpload] 
	@iFolderId INT,
	@FileName varchar(400),
	@ContentType varchar(400),
	@Location nvarchar(4000),
	@iType INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Id INT = NULL;
	
    INSERT INTO dbo.Uploads
    (
		[iEntityId],
		[iFolderId],
		[Url],
		Location,
		[FileName],
		[ContentType],
		[iType]
    )
    VALUES
    (
		0,
		@iFolderId,
		'',
		@Location,
		@FileName,
		@ContentType,
		@iType
    );
    
    SELECT @Id = CAST(SCOPE_IDENTITY() AS INT);
    UPDATE dbo.Uploads
    SET
        dbo.Uploads.Url = (N'/video?id=' + ltrim(str(@Id)))
    WHERE Id = @Id;
    
    SELECT @Id;
END
GO


IF OBJECT_ID('[dbo].[LinkUpload]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[LinkUpload] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[LinkUpload] 
	@Id INT,
	@iEntityId INT
AS
BEGIN
	SET NOCOUNT ON;

    UPDATE dbo.Uploads
    SET
        iEntityId = @iEntityId
    WHERE Id = @Id;
END
GO


IF OBJECT_ID('[dbo].[GetUploadById]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUploadById] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUploadById] 
	@Id INT
AS
BEGIN
	SET NOCOUNT ON;

    SELECT u.Id, 
		u.iEntityId, 
		u.Url, 
		u.Location, 
		u.FileName, 
		u.ContentType, 
		u.iType
    FROM dbo.Uploads u
    WHERE u.Id = @Id;    
END
GO


IF OBJECT_ID('[dbo].[fnGetUploadFoldersChildCount]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[fnGetUploadFoldersChildCount]() RETURNS INT AS BEGIN RETURN 0; END')
GO

ALTER FUNCTION [dbo].[fnGetUploadFoldersChildCount] 
(
	@iFolderId INT
)
RETURNS INT
AS
BEGIN
	
	DECLARE @ReturnVal INT
	
	SET @ReturnVal = (SELECT COUNT(uf.iFolderId) 
				FROM dbo.UploadFolders uf WHERE uf.iParentFolderId = @iFolderId 
					AND iDeleted = 0);	
	RETURN @ReturnVal;
END
GO


IF OBJECT_ID('[dbo].[GetUploadFolders]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[GetUploadFolders] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[GetUploadFolders] 
	@iParentFolderId INT	
AS
BEGIN
	SET NOCOUNT ON;

	SELECT uf.iFolderId, 
		uf.strName, 
		uf.iParentFolderId, 
		uf.iDeleted, 
		uf.iCreatedBy, 
		uf.iModifiedBy, 
		uf.dtmCreated, 
		uf.dtmModified, 
		uf.Location,
		dbo.fnGetUploadFoldersChildCount(uf.iFolderId) AS iChildCount
	FROM dbo.UploadFolders uf
	WHERE uf.iParentFolderId = @iParentFolderId OR ((@iParentFolderId IS NULL OR @iParentFolderId = 0) AND (uf.iParentFolderId IS NULL OR uf.iParentFolderId = 0));
END
GO


IF OBJECT_ID('[dbo].[CreateUploadFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[CreateUploadFolder] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[CreateUploadFolder] 
	@iParentFolderId INT,
	@strName NVARCHAR(255),
	@Location NVARCHAR(4000),
	@iCreatedBy INT
AS
BEGIN
	SET NOCOUNT ON;

    INSERT INTO dbo.UploadFolders
    (
        strName,
        iParentFolderId,
        iDeleted,
        iCreatedBy,
        iModifiedBy,
        dtmCreated,
        dtmModified,
        Location
    )
    VALUES
    (
        @strName, 
        @iParentFolderId,
        0,
        @iCreatedBy,
        @iCreatedBy,
        GETDATE(),
        GETDATE(),
        @Location
    );
    
    SELECT CAST(SCOPE_IDENTITY() AS INT);
END
GO


IF OBJECT_ID('[dbo].[m136_be_GetFoldersRecursive]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_GetFoldersRecursive] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_be_GetFoldersRecursive]
	@iHandbookId INT,
	@iSecurityId INT,
	@bCheckSecurity BIT
AS
BEGIN
	SET NOCOUNT ON;
	SELECT h.iHandbookId as Id,
			h.iHandbookId,
			h.strName,
			-1 as iDocumentTypeId,
			NULL as Version,
			iLevelType as LevelType,
			NULL as dtmApproved,
			NULL as strApprovedBy,
			NULL as Responsible,
			h.iDepartmentId as DepartmentId,
			0 as Virtual,
			h.iSort,
			NULL as ParentFolderName,
			dbo.fn136_GetParentPathEx(h.iHandbookId) as [Path],
			0 as HasAttachment,
			NULL as iApproved,
			NULL as iDraft,
			ISNULL(h.iParentHandbookId,0) AS iParentHandbookId,
			[dbo].[fn136_GetChildCount] (@iSecurityId, h.iHandbookId, 1) AS iChildCount,
            0 AS IsDocument
	FROM	m136_tblHandbook h WHERE h.iHandbookId IN (SELECT  iHandbookId  FROM 
		[dbo].[m136_GetHandbookRecursive](@iHandbookId, @iSecurityId, @bCheckSecurity));
END
GO