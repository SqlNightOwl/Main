use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'mkt'
GO
CREATE trigger mkt.Event_tiu
on	mkt.Event
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	mkt.Event	o
	join	deleted		d
			on	o.EventId = d.EventId
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	mkt.Event	o
	join	inserted	i
			on	o.EventId = i.EventId
end

--	enforce the table constraint CK_Event_RegistrationDates
if update(IsRecurring)
or update(RegistrationEndsOn)
begin
	update	o
	set		RegistrationEndsOn	= null
		,	UpdatedOn			= getdate()
		,	UpdatedBy			= tcu.fn_UserAudit()
	from	mkt.Event	o
	join	inserted	i
			on	o.EventId = i.EventId
	where	i.RegistrationEndsOn	is not null
	and		i.IsRecurring			= 1
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO