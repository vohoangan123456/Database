INSERT INTO #Description VALUES('Rename procedure [dbo].[m136_SearchDocuments]')
GO

EXEC [dbo].[MakeSureObjectExists] '[dbo].[m136_SearchDocuments_Gastro]'
GO

ALTER PROCEDURE [dbo].[m136_SearchDocuments_Gastro]
	@PageIndex INT,
	@PageSize INT,
	@SearchString varchar(1024) = '',
	@LikeSearchWords varchar(900) = '',
	@SearchInContent BIT,
	@SecurityId INT,
	@RegisterId INT,
	@RegisterItemId INT = 0
AS
BEGIN

	DECLARE @Documents TABLE
	(
		[Rank] INT NOT NULL,
		DocumentId INT NOT NULL,
		HandbookId INT NOT NULL,
		Name VARCHAR(200) NOT NULL,
		DocumentTypeId INT NOT NULL,
		[Version] INT NOT NULL,
		LevelType INT NOT NULL,
		ApprovedDate DATETIME NULL,
		ApprovedBy VARCHAR(200) NOT NULL,
		Responsible VARCHAR(102) NOT NULL,
		DepartmentId INT NULL,
		Virtual INT NOT NULL,
		Sort INT NOT NULL,
		[Path] NVARCHAR(4000),
		ParentFolderName VARCHAR(100) NOT NULL,
		HasAttachment BIT NOT NULL
	)

	INSERT INTO @Documents
	EXEC [dbo].[m136_SearchMetataggedDocuments] @SearchString, @LikeSearchWords, @SearchInContent, @SecurityId, @RegisterId, @RegisterItemId
		
	SELECT [Rank],
		DocumentId,
		HandbookId,
		Name,
		DocumentTypeId,
		[Version],
		LevelType,
		ApprovedDate,
		ApprovedBy,
		Responsible,
		DepartmentId,
		Virtual,
		Sort,
		[Path],
		ParentFolderName,
		HasAttachment
	FROM (
		SELECT *,
			RowNumber = ROW_NUMBER() OVER (ORDER BY Sort, Name)
		FROM @Documents
	) AS [PagedList]
	
	WHERE (@PageSize=0 OR RowNumber BETWEEN @PageSize*@PageIndex+1 AND @PageSize*(@PageIndex+1)) 
	
	SELECT COUNT(*) FROM @Documents
	
END
GO