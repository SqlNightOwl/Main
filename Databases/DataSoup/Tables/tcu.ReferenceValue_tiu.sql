use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.ReferenceValue_tiu
on	tcu.ReferenceValue
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.ReferenceValue	o
	join	deleted				d
			on	o.ReferenceId	 = d.ReferenceId
			and	o.ReferenceValue = d.ReferenceValue
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.ReferenceValue	o
	join	inserted			i
			on	o.ReferenceId	 = i.ReferenceId
			and	o.ReferenceValue = i.ReferenceValue
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO