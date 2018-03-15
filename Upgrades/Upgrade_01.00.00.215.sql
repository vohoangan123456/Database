INSERT INTO #Description VALUES('Add sp for fixing report issues')
GO


IF OBJECT_ID('[dbo].[m136_fnPersonHandbookConfirmPercentage]', 'fn') IS NULL
	EXEC ('CREATE FUNCTION [dbo].[m136_fnPersonHandbookConfirmPercentage]() RETURNS FLOAT AS BEGIN RETURN 0; END')
GO

ALTER      FUNCTION [dbo].[m136_fnPersonHandbookConfirmPercentage] (
	@iEmployeeId int,
	@iHandbookId int =0,
	@fromDate datetime = null,
	@toDate dateTime = null)  
RETURNS float AS  
BEGIN
declare @retVal float
declare @allDocs float
declare @allVirtulDocs float
declare @allRealDocs float
set @allRealDocs =  (SELECT count (distinct iDocumentId) 
		FROM
			m136_tblDocument doc
		WHERE
			doc.iHandbookId=@iHandbookId
			AND doc.iDeleted=0
			AND doc.iApproved = 1
			AND doc.iVersion=( 
				SELECT 
					MAX(iVersion) 
				FROM 
					m136_tblDocument
				WHERE 
					m136_tblDocument.iDocumentId=doc.iDocumentId 
					AND m136_tblDocument.iDeleted=0 
					AND m136_tblDocument.iDraft=0 
					AND m136_tblDocument.iApproved in(1 ,4)
			)
		)  		
set @allVirtulDocs = (SELECT count (distinct doc.iDocumentId) 
FROM
	m136_relVirtualRelation virt
	left join m136_tblDocument doc on doc.iDocumentId=virt.iDocumentId
	where virt.iHandbookId = @iHandbookId and doc.iLatestApproved = 1)

set @allDocs = sum(@allRealDocs + @allVirtulDocs)
			--AND Security TODO

declare @confirmed float
declare @confirmedReal float
declare @confirmedVirtual float

set @confirmedReal  = (SELECT COUNT(distinct doc.iDocumentId) FROM m136_tblConfirmRead cr 
	inner join m136_tblDocument doc on cr.iEntityId=doc.iEntityId
WHERE
	cr.iEmployeeId=@iEmployeeId
	AND (doc.iHandbookId=@iHandbookId OR @iHandbookId=0)
	AND (cr.dtmConfirm>@fromDate OR @fromDate is null)
	AND (cr.dtmConfirm<@toDate OR @toDate is null)
	AND doc.iDeleted=0
	AND doc.iApproved=1
	AND iVersion=( 
		SELECT 
			MAX(iVersion) 
		FROM 
			m136_tblDocument
		WHERE 
			m136_tblDocument.iDocumentId=doc.iDocumentId 
			AND m136_tblDocument.iDeleted=0 
			AND m136_tblDocument.iDraft=0 
			AND m136_tblDocument.iApproved in(1 ,4)
	)
)

set @confirmedVirtual  = (SELECT COUNT(distinct doc.iDocumentId) FROM m136_tblConfirmRead cr 
	inner join m136_tblDocument doc on cr.iEntityId=doc.iEntityId
	inner join m136_relVirtualRelation virt on doc.iDocumentId=virt.iDocumentId
WHERE
	virt.iHandbookId = @iHandbookId
	AND cr.iEmployeeId=@iEmployeeId
	AND (cr.dtmConfirm>@fromDate OR @fromDate is null)
	AND (cr.dtmConfirm<@toDate OR @toDate is null)
	AND doc.iDeleted=0
	AND doc.iApproved=1
	AND iVersion=( 
		SELECT 
			MAX(iVersion) 
		FROM 
			m136_tblDocument
		WHERE 
			m136_tblDocument.iDocumentId=doc.iDocumentId 
			AND m136_tblDocument.iDeleted=0 
			AND m136_tblDocument.iDraft=0 
			AND m136_tblDocument.iApproved in(1 ,4)
	)
)

set @confirmed = sum(@confirmedReal + @confirmedVirtual)

if @alldocs >0
	set @retVal = @confirmed/@alldocs
else
	set @retVal = 0
return @retVal*100
END
GO


IF OBJECT_ID('[dbo].[m136_spGetPersonChapterConfirmsSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spGetPersonChapterConfirmsSums] AS SELECT 1')
GO
ALTER PROCEDURE [dbo].[m136_spGetPersonChapterConfirmsSums] 
(
	@iSecurityId int = 0,
	@iHandbookId int = 0,
	@fromDate datetime = null,
	@toDate datetime = null,
	@iEmployeeId int = 0,
	@iLatestVersions bit = 1,
	@iUseRegionLeader int = 0,
	@iDepartmentLeaderPositionId int = 0,
	@recursive bit = 0
)
AS
if @toDate<>null
begin
	set @toDate = dateadd(day, 1, @toDate)
END
declare @iMin int
declare @iMax int
if @recursive != 0 and @iHandbookId > 0
begin
	select @iMin = iMin, @iMax = iMax from m136_tblHandbook where iHandbookId = @iHandbookId
end
else
begin
	select @iMin = -1, @iMax = -1
end
declare @iRegionTable table(iDepartmentId int not null)
if @iUseRegionLeader=1
begin
	insert into @iRegionTable select * FROM [dbo].[m136_getRegionleaderDepartmentIds](@iSecurityId)
end 
declare @empTable table(iEmployeeId int null)
--Seg selv
if @iEmployeeId=@iSecurityId
	insert into @empTable(iEmployeeId) SELECT @iEmployeeId
--Regionleder
if (SELECT COUNT(iEmployeeId) FROM @empTable)=0 AND @iUseRegionLeader<>0
	begin
		insert into @empTable
			SELECT iEmployeeId FROM tblEmployee where iDepartmentId in (select iDepartmentId from @iRegionTable) AND iEmployeeId=@iEmployeeId
	end
--Modul-administrator
if (SELECT COUNT(iEmployeeId) FROM @empTable)=0
 	begin
		if (dbo.fnSecurityGetPermission(136, 460, @iSecurityId,0)&2)=2
		begin
			insert into @emptable select @iEmployeeId
		end
	end
--Kan lese kvitteringer på egen org-enhet
if (SELECT COUNT(iEmployeeId) FROM @empTable)=0
 	begin
		if (dbo.fnSecurityGetPermission(136, 460, @iSecurityId,0)&4)=4
		begin
			insert into @emptable
			select iEmployeeId from tblEmployee where iDepartmentId in (select iDepartmentId from tblEmployee where iEmployeeId=@iSecurityId) AND iEmployeeId=@iEmployeeId
		end
	end
if (SELECT COUNT(iEmployeeId) FROM @empTable)>0
begin
--Mappeutdrag:
declare @bookTable table(iHandbookId int not null, strChapterName varchar(400) null, strParentPath varchar(1000) null, confirmPercent float null, iMin int )
insert into @bookTable
select
	iHandbookId,
	strName,
	REPLACE(dbo.fn136_GetParentPath(iHandbookId),',','/'),
	dbo.m136_fnPersonHandbookConfirmPercentage(@iEmployeeId, iHandbookId,@fromDate, @toDate),
	iMin
from
	m136_tblHandbook
where
	iHandbookId = @iHandbookId
	AND iDeleted=0
	AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01)>0 
if @iMin > -1 and @iMax > -1
begin
	insert into @bookTable
	select
		iHandbookId,
		strName,
		REPLACE(dbo.fn136_GetParentPath(iHandbookId),',','/'),
		dbo.m136_fnPersonHandbookConfirmPercentage(@iEmployeeId, iHandbookId,@fromDate, @toDate),
		iMin
	from
		m136_tblHandbook
	where
		iDeleted=0
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01)>0 
		and iMin > @iMin and iMax < @iMax
end
--Dokumentutdrag:
declare @docTable table(iEntityId int null, iDocumentId int null, strName varchar(200) null, iVersion int null, iHandbookId int null, iSort int null, iVirt int not null)
insert into @docTable
select	doc.iEntityId,
	doc.iDocumentId,
	doc.strName,
	doc.iVersion,
	doc.iHandbookId,
	doc.iSort,
	0
from
	@bookTable book
	right join m136_tblDocument doc on doc.iHandbookId=book.iHandbookId
WHERE
	doc.iHandbookId=book.iHandbookId
	AND iApproved=1
	AND doc.iDeleted=0
	AND iVersion=( 
		SELECT 
			MAX(iVersion) 
		FROM 
			m136_tblDocument
		WHERE 
			m136_tblDocument.iDocumentId=doc.iDocumentId 
			AND m136_tblDocument.iDeleted=0 
			AND m136_tblDocument.iDraft=0 
			AND m136_tblDocument.iApproved in (1,4)
	)
--virtual
insert into @docTable
select 	doc.iEntityId,
	virt.iDocumentId,
	doc.strName,
	doc.iVersion,
	virt.iHandbookId,
	virt.iSort,
	1
FROM
	m136_relVirtualRelation virt
	left join m136_tblDocument doc on doc.iDocumentId=virt.iDocumentId
	right join @bookTable book on book.iHandbookId=virt.iHandbookId
WHERE
	doc.iApproved=1
	AND doc.iDeleted=0
	AND iVersion=( 
		SELECT 
			MAX(iVersion) 
		FROM 
			m136_tblDocument
		WHERE 
			m136_tblDocument.iDocumentId=doc.iDocumentId 
			AND m136_tblDocument.iDeleted=0 
			AND m136_tblDocument.iDraft=0 
			AND m136_tblDocument.iApproved in (1,4)
	)
	SELECT
		doc.iDocumentId,
		doc.iEntityId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		book.strChapterName,
		book.strParentPath,
		book.confirmPercent,
		case when (isdate(cr.dtmConfirm)=1 AND cr.iEmployeeId=@iEmployeeId) then 1 else 0 end as iReadStatus,
		cr.dtmConfirm,
		doc.iVirt,
		dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, 
			details.dtmPublish, details.dtmPublishUntil, getdate(), details.iDraft, details.iApproved) as iVersionStatus,
		details.iApproved,
		details.iDraft
	FROM
		@empTable emp
		cross join @docTable doc 
		left join m136_tblDocument details on details.iEntityId = doc.iEntityId
		left outer join m136_tblConfirmRead cr on doc.iEntityId=cr.iEntityId
			AND emp.iEmployeeId=cr.iEmployeeId
			AND (dtmConfirm>@fromDate OR @fromDate is null OR dtmConfirm is null)
			AND (dtmConfirm<@toDate OR @toDate is null OR dtmConfirm is null)
		left outer join @bookTable book on doc.iHandbookId=book.iHandbookId
	ORDER BY
		book.iMin,
		doc.iSort,
		doc.iDocumentId,
		doc.iVersion desc,
		cr.dtmConfirm desc
end
GO