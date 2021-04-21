use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'risk'
GO
create trigger risk.CompromiseCardHolder_tiu
on	risk.CompromiseCardHolder
for	insert, update
as

set nocount on;

--	maintain the Created By/On values
if update(CreatedBy)
or update(CreatedOn)
begin
	update	o
	set		CreatedBy	= d.CreatedBy
		,	CreatedOn	= d.CreatedOn
	from	risk.CompromiseCardHolder	o
	join	deleted						d
			on	o.CardId	= d.CardId
			and	o.HolderId	= d.HolderId;
end;

--	maintain the Updated By/On values
if not update(UpdatedBy)
or not update(UpdatedOn)
begin
	update	o
	set		UpdatedBy	= tcu.fn_UserAudit()
		,	UpdatedOn	= getdate()
	from	risk.CompromiseCardHolder	o
	join	inserted					i
			on	o.CardId	= i.CardId
			and	o.HolderId	= i.HolderId;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO