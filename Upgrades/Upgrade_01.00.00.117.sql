INSERT INTO #Description VALUES('Create store verify delete Folder.')
GO

IF OBJECT_ID('[dbo].[m136_be_VerifyDeleteFolderPermissions]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: OCT 27, 2015
-- Description:	Count number Folder and document recursive
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_VerifyDeleteFolderPermissions]
	@HandbookId INT = 0,
	@SecurityId INT = 0,
	@DeleteFolderPermission INT,
	@DeleteDocumentPermission INT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @returnPermission BIT = 1;
	
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	
		INSERT INTO @AvailableChildren(iHandbookId)
		SELECT 
			iHandbookId 
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
	   
	   DECLARE @CountFolderRecursive AS INT
	   DECLARE @CountFolder AS INT
	   DECLARE @CountDocument AS INT
	   
	   SELECT @CountFolderRecursive = Count(iHandbookId)
	   FROM @AvailableChildren
	   
	   SELECT 
			@CountFolder = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 461, @SecurityId, iHandbookId) & @DeleteFolderPermission  = @DeleteFolderPermission
		
		SELECT 
			@CountDocument = Count(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		where dbo.[fnSecurityGetPermission]( 136, 462, @SecurityId, iHandbookId) & @DeleteDocumentPermission  = @DeleteDocumentPermission
		
		
		DECLARE @NumberSubFolder AS INT
		DECLARE @NumberDocument AS INT
		
		SELECT  @NumberDocument = COUNT(*)
		FROM (	
				SELECT DISTINCT 
					d.iDocumentId AS Id
				FROM 
					m136_tblDocument d
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON d.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1
			UNION       
				SELECT 
					d.iDocumentId AS Id
				FROM 
					m136_relVirtualRelation virt 
						JOIN m136_tblDocument d
							ON virt.iDocumentId = d.iDocumentId
						JOIN m136_tblHandbook h 
							ON d.iHandbookId = h.iHandbookId
						JOIN @AvailableChildren ac
							ON virt.iHandbookId = ac.iHandbookId
				WHERE
					d.iLatestVersion = 1) AS Document
					
		SELECT 
			@NumberSubFolder = COUNT(iHandbookId)
		FROM 
			[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1)
		WHERE iHandbookId != @HandbookId
		
		IF @CountFolderRecursive = 0 OR @CountFolder != @CountFolderRecursive
			SET @returnPermission = 0;
			
		IF @NumberDocument <> 0 AND (@CountFolderRecursive = 0 OR @CountDocument != @CountFolderRecursive)
			SET @returnPermission = 0;
		
		SELECT @returnPermission
		
		SELECT @NumberDocument
		
		SELECT @NumberSubFolder
		
END
GO

IF OBJECT_ID('[dbo].[m136_be_DeleteFolder]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_be_DeleteFolder] AS SELECT 1')
GO
-- =============================================
-- Author:		SI.NGUYEN.MANH
-- Create date: OCT 30, 2015
-- Description:	Delete Folder
-- =============================================
ALTER PROCEDURE [dbo].[m136_be_DeleteFolder]
	@HandbookId INT = 0,
	@SecurityId INT = 0
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @AvailableChildren TABLE(iHandbookId INT NOT NULL PRIMARY KEY);
	DECLARE @DocumentChildren TABLE(Id INT NOT NULL PRIMARY KEY);
	
	INSERT INTO @AvailableChildren(iHandbookId)
	SELECT 
		iHandbookId 
	FROM 
		[dbo].[m136_GetHandbookRecursive](@HandbookId, @SecurityId, 1);
			
	INSERT INTO @DocumentChildren(Id)		
	SELECT DISTINCT d.iDocumentId AS Id
		FROM m136_tblDocument d
			JOIN m136_tblHandbook h 
				ON d.iHandbookId = h.iHandbookId
			JOIN @AvailableChildren ac
				ON d.iHandbookId = ac.iHandbookId
	
	--Delete virtual of handbook
	DELETE FROM	dbo.m136_relVirtualRelation	
	WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
	
	--Delete virtual of document
	DELETE FROM	dbo.m136_relVirtualRelation	
	WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
	
	--Delete Subcribe handbook
	DELETE FROM	dbo.m136_tblSubscribe
	WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
	
	--Delete Subcribe of document
	DELETE FROM	dbo.m136_tblSubscriberDocument
	WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
	
	--Set iDelete = 1 for handbook table
	UPDATE dbo.m136_tblHandbook
		SET iDeleted = 1
	WHERE iHandbookId IN (SELECT iHandbookId FROM  @AvailableChildren)
	
	--Set iDelete = 1 for Document table
	UPDATE dbo.m136_tblDocument
		SET iDeleted = 1
	WHERE iDocumentId IN (SELECT Id FROM  @DocumentChildren)
END
GO