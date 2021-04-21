use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_savXML]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_savXML]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_savXML
	@eventId	int				= null	output
,	@xmlDoc		nvarchar(max)
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/19/2006
Purpose  :	Inserts/Updates records in the the Event, Event Response and 
			EventField table based upon user input from the admin tool.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/20/2008	Fijula Kuniyil	Added new columns for IsInternal, TicketsAvailable,
							TicketsRequested and TicketsAllowed.
05/21/2008	Paul Hunter		Revised and simplified the routine to accomodate the
							longer data types permitted in SQL 2005.
05/23/2008	Paul Hunter		Added HasAutoResponse column to the routine.
05/27/2008	Fijula Kuniyil	Added code to save the event response from xml.
06/16/2008	Fijula Kuniyil	Added new columns for Coordinator details.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@hWnd	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= @@servername + '.' + db_name() + '.' + object_name(@@procid)

--	variables for the Event table
declare
	@autoResponse		bit
,	@description		varchar(3000)
,	@event				varchar(100)
,	@eventOn			datetime
,	@eventType			varchar(50)
,	@isEnabled			bit
,	@isInternal			bit
,	@isRecurring		bit
,	@organizer			varchar(50)
,	@coordinator		varchar(50)
,	@coordinatorEmail	varchar(75)
,	@bCCToCoordinator	bit
,	@regEndsOn			datetime
,	@regStartsOn		datetime
,	@tktsAllowed		tinyint
,	@tktsAvailable		smallint
,	@tktsRequested		smallint
,	@uniqueReg			bit
,	@MessageType		tinyint
,	@Subject			varchar(125)
,	@Body				varchar(max)
,	@row				tinyint

--	open and create a handle to the XML document...
exec sp_xml_preparedocument @hWnd output, @xmlDoc

--	collect the values with a SELECT statement using the OPENXML rowset provider.
select	@eventId			= coalesce(nullif(@eventId, 0), EventId, 0)
	,	@event				= substring(event					, 1, 100)
	,	@eventOn			= nullif(eventOn					, '')
	,	@regStartsOn		= nullif(startsOn					, '')
	,	@regEndsOn			= nullif(endsOn						, '')
	,	@isRecurring		= case isRecurring					when '1' then 1 else 0 end
	,	@uniqueReg			= case hasUniqueRegistrations		when '1' then 1 else 0 end
	,	@autoResponse		= case hasAutoResponse				when '1' then 1 else 0 end
	,	@isInternal			= case isInternal					when '1' then 1 else 0 end
	,	@isEnabled			= case isEnabled					when '1' then 1 else 0 end
	,	@tktsAvailable		= coalesce(ticketsAvailable			, 0)
	,	@tktsRequested		= coalesce(ticketsRequested			, 0)
	,	@tktsAllowed		= coalesce(ticketsAllowed			, 0)
	,	@eventType			= nullif(ltrim(rtrim(eventType))	, '')
	,	@organizer			= nullif(ltrim(rtrim(organizer))	, '')
	,	@description		= nullif(ltrim(rtrim(description))	, '')
	,	@coordinator		= nullif(ltrim(rtrim(coordinator))	, '')
	,	@coordinatorEmail	= nullif(ltrim(rtrim(coordinatoremail))	, '')
	,	@bCCToCoordinator	= case bcctocoordinator				when '1' then 1 else 0 end
from	openxml (@hWnd, '/Event', 1)
with(	eventId 				int
	,	event					ntext	'text()'
	,	eventOn					datetime
	,	startsOn				datetime
	,	endsOn					datetime
	,	isRecurring				varchar(1)
	,	hasUniqueRegistrations	varchar(1)
	,	hasAutoResponse			varchar(1)
	,	isInternal				varchar(1)
	,	isEnabled				varchar(1)
	,	ticketsAvailable		smallint
	,	ticketsRequested		smallint
	,	ticketsAllowed			tinyint
	,	eventType				varchar(50)
	,	organizer				varchar(50)
	,	description				varchar(3000)
	,	coordinator				varchar(50)
	,	coordinatorEmail		varchar(75)
	,	bccToCoordinator		varchar(1)
	)

if @debug = 1
begin
	select	*
	from	openxml(@hWnd, '/Event', 1)
	with(	eventId 				int
		,	event					ntext	'text()'
		,	eventOn					datetime
		,	startsOn				datetime
		,	endsOn					datetime
		,	isRecurring				varchar(1)
		,	hasUniqueRegistrations	varchar(1)
		,	hasAutoResponse			varchar(1)
		,	isInternal				varchar(1)
		,	isEnabled				varchar(1)
		,	ticketsAvailable		smallint
		,	ticketsRequested		smallint
		,	ticketsAllowed			tinyint
		,	eventType				varchar(50)
		,	organizer				varchar(50)
		,	description				varchar(3000)
		,	coordinator				varchar(50)
		,	coordinatorEmail		varchar(75)
		,	bccToCoordinator		varchar(1)
		)
end	--	@debug

--	save the Event
exec mkt.Event_sav	@EventId				= @EventId	output
				,	@Event					= @event
				,	@EventOn				= @eventOn
				,	@RegistrationStartsOn	= @regStartsOn
				,	@RegistrationEndsOn		= @regEndsOn
				,	@IsRecurring			= @isRecurring
				,	@HasUniqueRegistrations	= @uniqueReg
				,	@HasAutoResponse		= @autoResponse
				,	@IsInternal				= @isInternal
				,	@IsEnabled				= @isEnabled
				,	@TicketsAvailable		= @tktsAvailable
				,	@TicketsRequested		= @tktsRequested
				,	@TicketsAllowed			= @tktsAllowed
				,	@EventType				= @eventType
				,	@Organizer				= @organizer
				,	@Description			= @description
				,	@Coordinator			= @coordinator
				,	@CoordinatorEmail		= @coordinatorEmail
				,	@BCCToCoordinator		= @bCCToCoordinator


--save Event Response part
if exists (	select	top 1 * from openxml (@hWnd, '/Event/Messages/Message', 1)
			with(	MessageType	tinyint
				,	Subject		varchar(125)
				,	body		varchar(max) 'text()'
				)
			)
begin
	--	display the old/new responses combined
	if @debug = 1
	begin
		select	Type = 'Old'
			,	MessageType
			,	Subject
			,	Body
		from	mkt.EventResponse
		where	EventId	= @EventId
		union
		select	Type = 'New', *
		from	openxml(@hWnd, '/Event/Messages/Message', 1)
		with(	MessageType	tinyint
			,	Subject		varchar(125)
			,	Body		varchar(max) 'text()'
			)	
		order by 2, 1 desc
	end

	--	delete the existing responses
	delete	mkt.EventResponse
	where	EventId	= @EventId

	--	save the new/updated non-blank responses
	insert	mkt.EventResponse
		(	EventId
		,	MessageType
		,	Subject
		,	Body
		,	CreatedOn
		,	CreatedBy
		)
	select	@EventId
		,	MessageType
		,	Subject
		,	Body
		,	getdate()			--	CreatedOn
		,	tcu.fn_UserAudit()	--	CreatedBy
	from	openxml(@hWnd, '/Event/Messages/Message', 1)
	with(	MessageType	tinyint
		,	Subject		varchar(125)
		,	Body		varchar(max) 'text()'
		)
	where	len(rtrim(isnull(Subject, '')))	> 0
	and		len(rtrim(isnull(Body, '')))	> 0
end

--Handle the event fields part
if exists (	select	top 1 * from openxml (@hWnd, '/Event/Fields/Field', 1)
			with(	id			 	int
				,	name			varchar(255)
				,	caption			varchar(125)	'text()'
				,	fieldType		varchar(20)
				,	isRequired		varchar(2)
				,	listOfValues	varchar(2000)
				)
			)
begin
	--	display the old/new fields combined
	if @debug = 1
	begin
		select	Type = 'Old'
			,	fieldNumber
			,	Field
			,	FieldCaption
			,	FieldType
			,	IsRequired
			,	listOfValues
		from	mkt.EventField
		where	EventId	= @EventId
		union
		select	Type = 'New', *
		from	openxml (@hWnd, '/Event/Fields/Field', 1)
		with(	id			 	int
			,	name			varchar(255)
			,	caption			varchar(125)	'text()'
			,	fieldType		varchar(20)
			,	isRequired		varchar(2)
			,	listOfValues	varchar(2000)	)
		order by 3, 1 desc
	end

	--	make the fieldNumber an identity column so it's sequential and unique
	--	becasue people are not always precise.
	declare	@fields	table	
		(	fieldNumber		tinyint identity primary key
		,	field			varchar(255)
		,	isRequired		bit
		,	fieldCaption	varchar(125)
		,	fieldType		varchar(20)
		,	listOfValues	varchar(2000)
		)

	insert	@fields
		(	field
		,	isRequired
		,	fieldCaption
		,	fieldType
		,	listOfValues
		)
	select	name
		,	case isRequired when '1' then 1 else 0 end 
		,	caption
		,	fieldType
		,	listOfValues
	from	openxml (@hWnd, '/Event/Fields/Field', 1)
	with(	name			varchar(255)
		,	id			 	int
		,	isRequired		varchar(2)
		,	caption			varchar(125)	'text()'
		,	fieldType		varchar(20)
		,	listOfValues	varchar(2000)
		)
	order by id

	--	remove any existing fields
	delete	mkt.EventField
	where	EventId	= @EventId

	--	add the new fields to the table using Seq for field number
 	insert	mkt.EventField
		(	EventId
		,	Field
		,	FieldNumber
		,	IsRequired
		,	FieldCaption
		,	FieldType
		,	ListOfValues
		,	CreatedOn
		,	CreatedBy	)
	select	@EventId
		,	field
		,	fieldNumber
		,	isRequired
		,	fieldCaption
		,	fieldType
		,	nullif(rtrim(listOfValues), '')
		,	getdate()			--	CreatedOn
		,	tcu.fn_UserAudit()	--	CreatedBy
	from	@fields
	order by fieldNumber

end

--	close the handle to the XML document
exec sp_xml_removedocument @hWnd

set	@error = @@error

PROC_EXIT:
if @error != 0
	set	@errmsg = @proc

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[Event_savXML]  TO [wa_Marketing]
GO