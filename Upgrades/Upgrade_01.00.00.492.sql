INSERT INTO #Description VALUES ('Update SP m136_spGetChapterEmployeeSums')
GO

IF OBJECT_ID('[dbo].[m136_spGetChapterEmployeeSums]', 'p') IS NULL
    EXEC ('CREATE PROCEDURE [dbo].[m136_spGetChapterEmployeeSums] AS SELECT 1')
GO

ALTER       PROCEDURE [dbo].[m136_spGetChapterEmployeeSums] 
(
	@iSecurityId int = 0,
	@iHandbookId int = 0,
	@iDepartmentId int = 0,
	@fromDate datetime = null,
	@toDate datetime = null,
	@iUseRegionLeader int = 0,
	@iDepartmentLeaderPositionId int = 0,
	@iRecursive int = 0
)
AS
BEGIN
	if @toDate<>null
	begin
		set @toDate = dateadd(day, 1, @toDate)
	END

	declare @iMin int
	declare @iMax int

	if @iRecursive = 1
		begin
			select @iMin=iMin FROM m136_tblHandbook where iHandbookId=@iHandbookId
			select @iMax=iMax FROM m136_tblHandbook where iHandbookId=@iHandbookId
		end
	else
		begin
			set @iMin = 0
			set @iMax = 0
		end
	--Regiontable
	declare @iRegionTable table(iDepartmentId int not null)
	if @iUseRegionLeader=1
	begin
		insert into @iRegionTable select * FROM [dbo].[m136_getRegionleaderDepartmentIds](@iSecurityId)
	end 

	--Mappeutdrag:
	declare @bookTable table(iHandbookId int not null, strChapterName varchar(400) null, strParentPath varchar(1000) null, iMin int null, iMax int null)
	insert into @bookTable
	select
		iHandbookId,
		strName,
		dbo.fn136_GetParentPath(iHandbookId),
		iMin,
		iMax
	from
		m136_tblHandbook
	where
		((iMin>@iMin
		AND iMin<@iMax)
		 OR iHandbookId = @iHandbookId)
		AND iDeleted=0
		AND (dbo.fnSecurityGetPermission(136, 462, @iSecurityId, iHandbookId) & 0x01)>0 

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



	--Ansatt-utdrag
	declare @empTable table(iEmployeeId int null, strFirstName varchar(100) null, strLastName varchar(100) null, iDepartmentId int null)

	--Security, see own org-unit's reports?
	declare @moduleAccess int
	set @moduleAccess = dbo.fnSecurityGetPermission(136, 460, @iSecurityId, 0)
	if((@moduleAccess&4)=4 OR (@moduleAccess&8)=8)
	begin
		declare @iUserDepartmentId int
		select @iUserDepartmentId=iDepartmentId FROM tblEmployee where iEmployeeId=@iSecurityId
		insert into @empTable
			select
				iEmployeeId,
				strFirstName,
				strLastName,
				iDepartmentId
			from
				tblEmployee
			where
				(iDepartmentId = @iDepartmentId 
				OR @iDepartmentId=0)
				AND iDepartmentId>0
				AND iDepartmentId=@iUserDepartmentId
	end

	--Regionleder
	if (SELECT COUNT(iEmployeeId) FROM @empTable)=0 AND @iUseRegionLeader<>0
		begin
			insert into @empTable
				SELECT iEmployeeId, strFirstName, strLastName, iDepartmentId  FROM tblEmployee where iDepartmentId in (select iDepartmentId from @iRegionTable) AND iDepartmentId=@iDepartmentId
		end
	--Modul-administrator?
	if((@moduleAccess&2)=2)
	begin
		delete from @empTable
		insert into @empTable
		select
			iEmployeeId,
			strFirstName,
			strLastName,
			iDepartmentId
		from
			tblEmployee
		where
			iDepartmentId = @iDepartmentId 
	end


			
			
	--Confirm-table utdrag
	declare @cTable table(iEntityId int not null, iEmployeeId int, dtmConfirm datetime)
	insert into @cTable
	select
		iEntityId, iEmployeeId, dtmConfirm
	from
		m136_tblConfirmRead cr
	where
		iEntityId in (select iEntityId from @docTable)
		AND iEmployeeId in (select iEmployeeId from @empTable)
		AND (dtmConfirm>@fromDate OR @fromDate is null)
		AND (dtmConfirm<@toDate OR @toDate is null)

	-- Return select
	SELECT doc.iDocumentId,
		doc.iEntityId,
		doc.strName,
		doc.iVersion,
		doc.iHandbookId,
		book.strChapterName,
		book.strParentPath,
		ISNULL(dep.strName, '') as strDepName,
		ISNULL(dep.iDepartmentId,0) as iDepartmentId,
		ISNULL(dep.iLevel,0) as iLevel,
		ISNULL(emp.strFirstName,'') +' '+ ISNULL(emp.strLastName,'') as strEmployeeName,
		ISNULL(emp.iEmployeeId,0) as iEmployeeId,
		(case when isnull(cr.iEmployeeId, 0)=0 then 0 else 1 end) as iReadStatus,
		cr.dtmConfirm,
		doc.iVirt,
		dbo.m136_fnGetVersionStatus(doc.iEntityId, doc.iDocumentId, doc.iVersion, 
			details.dtmPublish, details.dtmPublishUntil, getdate(), details.iDraft, details.iApproved) as iVersionStatus,
		details.iApproved,
		details.iDraft
	FROM

		@docTable doc
		full join @empTable emp on 1=1
		join m136_tblDocument details on details.iEntityId = doc.iEntityId
		left join @cTable cr on cr.iEmployeeId=emp.iEmployeeId AND cr.iEntityId=doc.iEntityId
		left outer join tblDepartment dep on dep.iDepartmentId=emp.iDepartmentId
		left outer join @bookTable book on doc.iHandbookId=book.iHandbookId
	WHERE
		isnull(doc.iEntityId, 0)>0
	order by
		book.iMin asc,
		doc.iSort asc,
		doc.iDocumentId asc,
		strDepName asc,
		iReadStatus desc,
		strEmployeeName asc,
		dtmConfirm desc


	--SELECT * FROM @bookTable
END

GO