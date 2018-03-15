INSERT INTO #Description VALUES ('Add new column nTextBody for table m123_tblInfo to store the special character')
GO
/*change type of column strBody*/
--Add new temporal column nTextBody
ALTER TABLE m123_tblInfo
ADD nTextBody NVARCHAR(MAX);
GO
--Transfer all data from strBody to nTextBody
UPDATE m123_tblInfo
SET nTextBody = strBody
GO
--Delete column strBody
ALTER TABLE m123_tblInfo
DROP COLUMN strBody;
GO
--Re-add column strBody as nText type
ALTER TABLE m123_tblInfo
ADD strBody NVARCHAR(MAX);
GO
--transfer back data from nTextBody to strBody
UPDATE m123_tblInfo
SET strBody = nTextBody
GO

/*change type of column strIngress*/
--reset column nTextBody
UPDATE m123_tblInfo
SET nTextBody = strIngress
--Delete column strIngress and re-add
ALTER TABLE m123_tblInfo
DROP COLUMN strIngress;
GO
ALTER TABLE m123_tblInfo
ADD strIngress NVARCHAR(MAX);
GO
--Transfer back the data from nTextBody to strIngress
UPDATE m123_tblInfo
SET strIngress = nTextBody
--Delete column nTextBody
ALTER TABLE m123_tblInfo
DROP COLUMN nTextBody;
GO

IF OBJECT_ID('[dbo].[m123_be_UpdateNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_UpdateNews] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_UpdateNews]  
    @InfoId INT,  
    @Title VARCHAR(300),  
    @Ingress NVARCHAR(MAX),  
    @Body NVARCHAR(MAX),  
    @Publish DATETIME,  
    @Expire DATETIME,  
    @AlterId INT,  
    @Draft INT,
	@BIngress BIT    
AS  
BEGIN  
    UPDATE  
        m123_tblInfo  
    SET  
        strTitle = @Title,  
        strIngress = @Ingress,  
        strBody = @Body,  
        dtmChanged = GETDATE(),  
        dtmPublish = @Publish,  
        dtmExpire = @Expire,  
        iAlterId = @AlterId,  
        iDraft = @Draft,
        bIngress = @BIngress
    WHERE  
        iInfoId = @InfoId  
END
GO

IF OBJECT_ID('[dbo].[m123_be_CreateNews]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m123_be_CreateNews] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m123_be_CreateNews]  
    @CategoryId INT,  
    @Title VARCHAR(300),  
    @Ingress NVARCHAR(MAX),  
    @Body NVARCHAR(MAX),  
    @Publish DATETIME,  
    @Expire DATETIME,  
    @AuthorId INT,  
    @Draft INT,
	@BIngress BIT  
AS  
BEGIN  
    DECLARE @InfoId INT;  
    DECLARE @Now DATETIME = GETDATE();  
    INSERT INTO  
        m123_tblInfo  
            (strTitle, strIngress, strBody, dtmCreated, dtmChanged, dtmPublish, dtmExpire, iAuthorId, iDraft, bIngress)  
        VALUES  
            (@Title, @Ingress, @Body, @Now, @Now, @Publish, @Expire, @AuthorId, @Draft, @BIngress)  
    SET @InfoId = SCOPE_IDENTITY();  
    INSERT INTO  
        m123_relInfoCategory  
            (iInfoId, iCategoryId)  
        VALUES  
            (@InfoId, @CategoryId);  
    SELECT @InfoId  
END
GO