use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_getSetup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_getSetup]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_getSetup
	@EventId	int 	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/05/2006
Purpose  :	Retrieves the Event and a list of Fields that can be/are used in
			the Marketing RSVP Event tables.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
05/29/2008	Fijula Kuniyil	Added the Event Response Handling
06/16/2008	Fijula Kuniyil	Added extra fields for Coorinator .
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

--	return the event data
select	EventId
	,	Event
	,	EventOn
	,	RegistrationStartsOn
	,	RegistrationEndsOn
	,	IsRecurring
	,	HasUniqueRegistrations
	,	HasAutoResponse
	,	IsInternal
	,	IsEnabled
	,	TicketsAvailable
	,	TicketsRequested
	,	TicketsAllowed
	,	TicketsOpen	= TicketsAvailable - TicketsRequested
	,	EventType
	,	Organizer
	,	Description
	,	Coordinator
	,	CoordinatorEmail
	,	BCCToCoordinator
	,	CreatedBy
	,	CreatedOn
	,	UpdatedBy
	,	UpdatedOn
from	mkt.Event
where	EventId = @EventId

--	return the event fields
select	d.Field
	,	FieldCaption	=	coalesce(f.FieldCaption, replace(d.Field, '_', ' '))
	,	FieldType		=	case d.Field
							when 'State' then 'select'
							else  coalesce(f.FieldType,	d.ControlType)
							end
	,	d.IsConfigurable
	,	f.FieldNumber
	,	f.IsRequired
	,	ListOfValues	=	case d.Field
							when 'State' then 'StatesXml'
							else f.ListOfValues
							end
from	mkt.EventFieldDetail	d
left join
	(	select	Field
			,	FieldCaption
			,	FieldType
			,	FieldNumber
			,	IsRequired
			,	ListOfValues
		from	mkt.EventField
		where	EventId = @EventId
	)	f	on	d.Field	= f.Field
order by
		isnull(f.FieldNumber, 255)
	,	d.OrdinalPosition

--	return the event responses
select	EventId
	,	MessageType
	,	Subject
	,	Body
from	mkt.EventResponse
where	EventId = @EventId
order by
		MessageType
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_getSetup]  TO [wa_Marketing]
GO