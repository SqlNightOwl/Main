use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getFormValues]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getFormValues]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_getFormValues
	@EventId	int
,	@Preview	varchar(4)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/28/2006
Purpose  :	Retrieves event and field information for the requested event as long
			as the event is available
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
05/25/2006	Paul Hunter		Added the preview parameter to allow previewing of 
							future or past events.
06/16/2008	Fijula Kuniyil	Added the Coordinator details for BCC email.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@today	datetime

--	collect the current date for event comparison purposes
set	@today = convert(varchar(10), getdate(), 101)

if @Preview != 'true'
	set @Preview = 'false'

--	reset the Event Id if the Event is no longer available!
if exists (	select	top 1 * from mkt.Event
			where	EventId		= @EventId
			and	(	@today		between RegistrationStartsOn and isnull(RegistrationEndsOn, @today)
				or	@Preview	= 'true'	)	)
begin
	--	return the Event information
	select	EventId
		,	Event
		,	EventOn
		,	Description
		,	EventType
		,	IsInternal
		,	TicketsOpen		= TicketsAvailable - TicketsRequested
		,	TicketsAllowed
		,	Coordinator
		,	CoordinatorEmail
		,	BCCToCoordinator
	from	mkt.Event
	where	EventId	= @EventId

	--	return the list of fields 
	select	f.FieldNumber
		,	f.Field
		,	f.FieldCaption
		,	f.FieldType
		,	f.IsRequired
		,	f.ListOfValues
		,	DefaultControlType	= d.ControlType
		,	d.MaxLength
		,	d.OrdinalPosition
	from	mkt.EventField			f
	join	mkt.EventFieldDetail	d
			on	f.Field = d.Field
	where	f.EventId = @EventId
	order by
			f.FieldNumber
		,	f.Field
end

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getFormValues]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [mkt].[Event_getFormValues]  TO [wa_Marketing]
GO