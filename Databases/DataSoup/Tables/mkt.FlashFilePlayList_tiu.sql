use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'mkt'
GO
CREATE trigger mkt.FlashFilePlayList_tiu
on	mkt.FlashFilePlayList
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	mkt.FlashFilePlayList	o
	join	deleted					d
			on	o.PlayListId	= d.PlayListId
			and	o.Sequence		= d.Sequence
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	mkt.FlashFilePlayList	o
	join	inserted				i
			on	o.PlayListId	= i.PlayListId
			and	o.Sequence		= i.Sequence
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO