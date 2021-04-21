use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.adGroupUser_tiu
on	tcu.adGroupUser
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.adGroupUser	o
	join	deleted			d
			on	o.samGroupName	= d.samGroupName
			and	o.samUserName	= d.samUserName
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.adGroupUser	o
	join	inserted		i
			on	o.samGroupName	= i.samGroupName
			and	o.samUserName	= i.samUserName
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO