use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[Event_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[Event_get]
GO
setuser N'mkt'
GO
CREATE procedure mkt.Event_get
	@EventId	int				= null
,	@errmsg		varchar(255)	= null	output	-- in case of error
,	@debug		tinyint			= 0				-- this should always be last
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/15/2006
Purpose  :	Retrieves record(s) from the mktEvent table based upon the primary key.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/23/2008	Fijula Kuniyil	Added new column "hasAutoResponse"
06/16/2008	Fijula Kuniyil	Added Coordinator details
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@error	int
,	@proc	varchar(255)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

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
	,	EventType
	,	Organizer
	,	Description
	,	Coordinator
	,	CoordinatorEmail
	,	BCCToCoordinator
from	mkt.Event
where	EventId	= @EventId or @EventId is null

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
GRANT  EXECUTE  ON [mkt].[Event_get]  TO [wa_Marketing]
GO