use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventRegistration_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[EventRegistration_sav]
GO
setuser N'mkt'
GO
CREATE procedure mkt.EventRegistration_sav
	@EventRegistrationId	int				= null	output
,	@EventId				int
,	@EMail					varchar(100)	= null
,	@First_Name				varchar(50)		= null
,	@Last_Name				varchar(50)		= null
,	@Company				varchar(100)	= null
,	@Address				varchar(100)	= null
,	@City					varchar(100)	= null
,	@State					char(2)			= null
,	@Zip_Code				varchar(10)		= null
,	@Home_Phone				varchar(25)		= null
,	@Cell_Phone				varchar(25)		= null
,	@Work_Phone				varchar(25)		= null
,	@Is_A_Member			tinyint			= null
,	@Number_Of_People		tinyint			= null
,	@Comments				varchar(1000)	= null
,	@Has_Opted_In			tinyint			= null
,	@User1					varchar(255)	= null
,	@User2					varchar(255)	= null
,	@User3					varchar(255)	= null
,	@User4					varchar(255)	= null
,	@User5					varchar(255)	= null
,	@errmsg					varchar(255)	= null	output	-- in case of error
,	@debug					tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/06/2006
Purpose  :	Inserts/Updates a record in the mktEventRegistration table based upon
			the primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/23/2008	Paul Hunter		Added logic to support the ticketing and notifications
							for Events.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@error			int
,	@autoResponse	bit
,	@IsUnique		bit
,	@messageType	tinyint
,	@method			varchar(6)
,	@proc			varchar(255)
,	@rows			int
,	@tickets		tinyint
,	@ticketsPrior	tinyint
,	@tktsAvailable	smallint
,	@tktsRequested	smallint;

--	initialize some processing variables
set @EventRegistrationId	= isnull(@EventRegistrationId, 0);
set @method					= 'update';
set	@error					= 0;
set	@ticketsPrior			= 0;
set	@proc					= db_name() + '.' + object_name(@@procid) + '.';

--	retrieve the RegistrationId for doing the update
select	@EventRegistrationId	= EventRegistrationId
	,	@ticketsPrior			= isnull(Number_Of_People, 0)
from	mkt.EventRegistration
where	EventId	= @EventId
and		Email	= rtrim(@Email)
and		1		= @IsUnique;

--	collect information about the event
select	@IsUnique		=	HasUniqueRegistrations
	,	@autoResponse	=	HasAutoResponse
	,	@tktsAvailable	=	TicketsAvailable
	,	@tktsRequested	=	TicketsRequested
	,	@tickets		=	case	--	TICKET HANDLING LOGIC
								--	tickets aren't tracked so use the variable
							when TicketsAvailable = 0 then @Number_Of_People
								--	tickets requestd + number of people is less than number of tickets available
								--	so, allow the update.
							when TicketsRequested + isnull(@Number_Of_People, 0) < TicketsAvailable then @Number_Of_People
							--	the number of tickets allocated is zero
							else 0 end
from	mkt.Event
where	@EventId = EventId;

--	set the message type based on the success of updating the tickets
set	@messageType =	case
					when @tickets		= isnull(@Number_Of_People, 0)
					  or @tktsAvailable	= 0  then 0	--	success because tickets aren't tracked or are modified
					else 1							--	failure becasue the number of tickets was modified
					end;

--	attempt to update the registration
update	mkt.EventRegistration
set		First_Name			=	nullif(rtrim(isnull(@First_Name, First_Name)), '')
	,	Last_Name			=	nullif(rtrim(isnull(@Last_Name, Last_Name)), '')
	,	Company				=	nullif(rtrim(isnull(@Company, Company)), '')
	,	Address				=	nullif(rtrim(isnull(@Address, Address)), '')
	,	City				=	nullif(rtrim(isnull(@City, City)), '')
	,	State				=	nullif(rtrim(isnull(@State, State)), '')
	,	Zip_Code			=	nullif(rtrim(isnull(@Zip_Code, Zip_Code)), '')
	,	Home_Phone			=	nullif(rtrim(isnull(@Home_Phone, Home_Phone)), '')
	,	Cell_Phone			=	nullif(rtrim(isnull(@Cell_Phone, Cell_Phone)), '')
	,	Work_Phone			=	nullif(rtrim(isnull(@Work_Phone, Work_Phone)), '')
	,	Is_A_Member			=	isnull(@Is_A_Member, Is_A_Member)
	,	Number_Of_People	=	isnull(@tickets, Number_Of_People)	--	see ticket logic above!
	,	Comments			=	nullif(rtrim(isnull(@Comments, Comments)), '')
	,	Has_Opted_In		=	isnull(@Has_Opted_In, Has_Opted_In)
	,	User1				=	nullif(rtrim(isnull(@User1, User1)), '')
	,	User2				=	nullif(rtrim(isnull(@User2, User2)), '')
	,	User3				=	nullif(rtrim(isnull(@User3, User3)), '')
	,	User4				=	nullif(rtrim(isnull(@User4, User4)), '')
	,	User5				=	nullif(rtrim(isnull(@User5, User5)), '')
	,	UpdatedOn			=	getdate()
	,	UpdatedBy			=	tcu.fn_UserAudit()
where	EventRegistrationId	=	@EventRegistrationId;

select	@error	= @@error
	,	@rows	= @@rowcount;

if @rows = 0 and @error = 0
begin
	set @method = 'insert';

	insert	mkt.EventRegistration
		(	EventId
		,	EMail
		,	First_Name
		,	Last_Name
		,	Company
		,	Address
		,	City
		,	State
		,	Zip_Code
		,	Home_Phone
		,	Cell_Phone
		,	Work_Phone
		,	Is_A_Member
		,	Number_Of_People
		,	Comments
		,	CancelledOn
		,	Has_Opted_In
		,	User1
		,	User2
		,	User3
		,	User4
		,	User5
		,	CreatedOn
		,	CreatedBy
		)
	values
		(	@EventId
		,	nullif(rtrim(@EMail), '')
		,	nullif(rtrim(@First_Name), '')
		,	nullif(rtrim(@Last_Name), '')
		,	nullif(rtrim(@Company), '')
		,	nullif(rtrim(@Address), '')
		,	nullif(rtrim(@City), '')
		,	nullif(rtrim(@State), '')
		,	nullif(rtrim(@Zip_Code), '')
		,	nullif(rtrim(@Home_Phone), '')
		,	nullif(rtrim(@Cell_Phone), '')
		,	nullif(rtrim(@Work_Phone), '')
		,	isnull(@Is_A_Member, 0)
		,	isnull(@tickets, 0)		--	see ticket logic above
		,	nullif(rtrim(@Comments), '')
		,	null
		,	isnull(@Has_Opted_In, 0)
		,	nullif(rtrim(@User1), '')
		,	nullif(rtrim(@User2), '')
		,	nullif(rtrim(@User3), '')
		,	nullif(rtrim(@User4), '')
		,	nullif(rtrim(@User5), '')
		,	getdate()
		,	tcu.fn_UserAudit()
		)

	select	@EventRegistrationId	= scope_identity()
		,	@error					= @@error;

end; -- insert

--	handle sending the any notifications.
if @autoResponse = 1
begin
	--	udate the ticket tracking
	update	mkt.Event
	set		TicketsRequested	= (TicketsRequested - @ticketsPrior) + isnull(@tickets, 0)
		,	UpdatedOn			= getdate()
		,	UpdatedBy			= tcu.fn_UserAudit()
	where	EventId				= @EventId
	and		TicketsAvailable	> 0;

	--	send the Response...
	exec mkt.EventResponse_send	@RegistrationId	= @EventRegistrationId
							,	@MessageType	= @messageType;
end;

PROC_EXIT:
if @error != 0
begin
	set	@errmsg = @proc + @method;
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @proc);
end;

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[EventRegistration_sav]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [mkt].[EventRegistration_sav]  TO [wa_Marketing]
GO