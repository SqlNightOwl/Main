use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'mkt'
GO
CREATE trigger mkt.EventResponse_tiu
on	mkt.EventResponse
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	mkt.EventResponse	o
	join	deleted				d
			on	o.EventId		= d.EventId
			and	o.MessageType	= d.MessageType
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	mkt.EventResponse	o
	join	inserted			i
			on	o.EventId		= i.EventId
			and	o.MessageType	= i.MessageType
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO