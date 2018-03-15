INSERT INTO #Description VALUES ('Update move news to other news category.')
GO

IF OBJECT_ID('[dbo].[m123_be_MoveNewsCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_MoveNewsCategory] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_MoveNewsCategory]  
    @InfoId INT,    
    @FromNewsCategoryID INT,    
    @ToNewsCategoryID INT  
AS    
BEGIN  
	UPDATE m123_relInfoCategory SET iCategoryId = @ToNewsCategoryID WHERE iInfoId = @InfoId AND iCategoryId = @FromNewsCategoryID;
END

GO
IF OBJECT_ID('[dbo].[m123_be_MoveMultipleNewsCategory]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_MoveMultipleNewsCategory] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_MoveMultipleNewsCategory]  
    @InfoIds AS [dbo].[Item] READONLY,      
    @FromNewsCategoryID INT,      
    @ToNewsCategoryID INT     
AS      
BEGIN   
	UPDATE m123_relInfoCategory SET iCategoryId = @ToNewsCategoryID WHERE iInfoId IN (SELECT Id FROM @InfoIds) AND iCategoryId = @FromNewsCategoryID; 
END  