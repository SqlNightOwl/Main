use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_sav]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_sav
	@EventId				int				= null	output
,	@Event					varchar(100)
,	@EventOn				datetime
,	@RegistrationStartsOn	datetime
,	@RegistrationEndsOn		datetime		= null
,	@IsRecurring			bit				= 0
,	@HasUniqueRegistrations	bit				= 0
,	@HasAutoResponse		bit				= 0
,	@IsInternal				bit				= 0
,	@IsEnabled				bit				= 0
,	@TicketsAvailable		smallint		= null
,	@TicketsRequested		smallint		= null
,	@TicketsAllowed			tinyint			= null
,	@EventType				varchar(50)
,	@Organizer				varchar(50)		= null
,	@Description			varchar(3000)	= null
,	@Coordinator			varchar(50)		= null
,	@CoordinatorEmail		varchar(75)		= null
,	@BCCToCoordinator		bit				= 0
,	@errmsg					varchar(255)	= null	output	-- in case of error
,	@debug					tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/27/2006
Purpose  :	Inserts/Updates a record in the mktEvent table based upon the primary
			key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/20/2008	Fijula Kuniyil	Added new fields to reflect the new columns: IsInternal, 
							TicketsAvailable, TicketsRequested and TicketsAllowed.
05/23/2008	Paul Hunter		Added HasAutoResponse column & parameter.
05/16/2008	Fijula Kuniyil	Added fields for Coordinator columns.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@method	varchar(6)
,	@proc	varchar(255)
,	@rows	int

set	@method = 'update'
set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	if the id wasn't provided but the name was then overwrite
if isnull(@EventId, 0) = 0
	select	@EventId = EventId
	from	mkt.Event
	where	@Event	 = Event

--	try the update first
update	mkt.Event
set		Event					=	isnull(@Event, Event)
	,	EventOn					=	isnull(@EventOn, EventOn)
	,	RegistrationStartsOn	=	isnull(@RegistrationStartsOn, RegistrationStartsOn)
	,	RegistrationEndsOn		=	case isnull(@IsRecurring, IsRecurring)
									when 0 then isnull(@RegistrationEndsOn, RegistrationEndsOn)
									else null end
	,	IsRecurring				=	isnull(@IsRecurring, IsRecurring)
	,	HasUniqueRegistrations	=	isnull(@HasUniqueRegistrations, HasUniqueRegistrations)
	,	HasAutoResponse			=	isnull(@HasAutoResponse, HasAutoResponse)
	,	IsInternal				=	isnull(@IsInternal, IsInternal)
	,	IsEnabled				=	isnull(@IsEnabled, IsEnabled)
	,	TicketsAvailable		=	isnull(@TicketsAvailable, TicketsAvailable)
	,	TicketsRequested		=	isnull(@TicketsRequested, TicketsRequested)
	,	TicketsAllowed			=	isnull(@TicketsAllowed, TicketsAllowed)
	,	EventType				=	isnull(nullif(rtrim(@EventType), ''), EventType)
	,	Organizer				=	nullif(rtrim(@Organizer), '')
	,	Description				=	nullif(rtrim(@Description), '')
	,	Coordinator				=	nullif(rtrim(@Coordinator), '')
	,	CoordinatorEmail		=	nullif(rtrim(@CoordinatorEmail), '')
	,	BCCToCoordinator		=	isnull(@BCCToCoordinator, BCCToCoordinator)
	,	UpdatedOn				=	getdate()
	,	UpdatedBy				=	tcu.fn_UserAudit()
where	EventId = @EventId

select	@error	= @@error
	,	@rows	= @@rowcount

if @rows = 0 and @error = 0
begin
	set	@method = 'insert'

	insert	mkt.Event
		(	Event
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
		,	EventType
		,	Organizer
		,	Description
		,	Coordinator
		,	CoordinatorEmail
		,	BCCToCoordinator
		,	CreatedOn
		,	CreatedBy	)
	values
		(	@Event
		,	@EventOn
		,	@RegistrationStartsOn
		,	case isnull(@IsRecurring, 0)
			when 0 then @RegistrationEndsOn
			else null end
		,	isnull(@IsRecurring, 0)
		,	isnull(@HasUniqueRegistrations, 0)
		,	isnull(@HasAutoResponse, 0)
		,	isnull(@IsInternal, 0)
		,	isnull(@IsEnabled, 1)
		,	isnull(@TicketsAvailable, 0)
		,	isnull(@TicketsRequested, 0)
		,	isnull(@TicketsAllowed, 0)
		,	@EventType
		,	nullif(rtrim(@Organizer), '')
		,	nullif(rtrim(@Description), '')
		,	nullif(rtrim(@Coordinator), '')
		,	nullif(rtrim(@CoordinatorEmail), '')
		,	isnull(@BCCToCoordinator, 0)
		,	getdate()
		,	tcu.fn_UserAudit()	)

	select	@EventId	= scope_identity()
		,	@error		= @@error

end -- insert

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc + @method

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_sav]  TO [wa_Marketing]
GO