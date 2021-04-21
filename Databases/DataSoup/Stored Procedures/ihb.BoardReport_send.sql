use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BoardReport_send]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[BoardReport_send]
GO
setuser N'ihb'
GO
CREATE procedure ihb.BoardReport_send
	@ProcessId	smallint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/04/2007
Purpose  :	Sends emails for Corillian Usage Statistics and IHB Board Statistics.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/14/2008	Paul Hunter		Changed procedure to use the Process tables.
10/14/2008	Paul Hunter		Added Business user counts to the messages.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@activeUsers				int
,	@activeUsersLast90Days		int
,	@billPayUsers				int
,	@businessUsers				int
,	@businessUsersLast90Days	int
,	@eom						datetime
,	@message					varchar(4000)
,	@period						int
,	@periodStr					varchar(50)
,	@recipients					varchar(255)

--	determine the EOM data and associated period...
set	@eom	= tcu.fn_LastDayOfMonth(dateadd(month, -1, getdate()))
set	@period	= cast(convert(char(6), @eom, 112) as int)

if exists (	select	* from ihb.BoardReport
			where	Period = @period	)
begin
	--	load the report stats variables
	select	@activeUsers					= ActiveUsers
		,	@activeUsersLast90Days		= ActiveUsersLast90Days
		,	@billPayUsers				= BillPayUsers
		,	@businessUsers				= BusinessUsers
		,	@businessUsersLast90Days	= BusinessUsersLast90Days
		,	@periodStr					= datename(month, @eom) + ' ' + cast(year(@eom) as varchar)
	from	ihb.BoardReport
	where	Period = @period

	/*	ACTIVE USER STATISTICS:
	**	retrieve the recipients and message and then update the message values
	*/
	set	@recipients	= tcu.fn_ProcessParameter(@ProcessId, 'Active User List')
	set	@message	= tcu.fn_ProcessParameter(@ProcessId, 'Active User Message')
	set	@message	= replace(@message, '#PERIOD#'			, @periodStr)
	set	@message	= replace(@message, '#CONSUMER_USERS#'	, @activeUsers)
	set	@message	= replace(@message, '#CONSUMER_90_DAYS#', @activeUsersLast90Days)
	set	@message	= replace(@message, '#BUSINESS_USERS#'	, @businessUsers)
	set	@message	= replace(@message, '#BUSINESS_90_DAYS#', @businessUsersLast90Days)

	--	send the message...
	exec tcu.Email_send	@subject		= 'Corillian Usage Statistics'
					,	@message		= @message
					,	@sendTo			= @recipients
					,	@sendCC			= null
					,	@asHtml			= 1
					,	@attachedFiles	= null

	/*	BOARD REPORT STATISTICS:
	**	retrieve the recipients and message and then update the message values
	*/
	set	@recipients	= tcu.fn_ProcessParameter(@ProcessId, 'Board Report List')
	set	@message	= tcu.fn_ProcessParameter(@ProcessId, 'Board Report Message')
	set	@message	= replace(@message, '#PERIOD#'			, @periodStr)
	set	@message	= replace(@message, '#CONSUMER_USERS#'	, @activeUsers)
	set	@message	= replace(@message, '#CONSUMER_90_DAYS#', @activeUsersLast90Days)
	set	@message	= replace(@message, '#BUSINESS_USERS#'	, @businessUsers)
	set	@message	= replace(@message, '#BUSINESS_90_DAYS#', @businessUsersLast90Days)
	set	@message	= replace(@message, '#BILL_PAY_USERS#'	, @billPayUsers)

	--	send the message...
	exec tcu.Email_send	@subject		= 'IHB Board Report Statistics'
					,	@message		= @message
					,	@sendTo			= @recipients
					,	@sendCC			= null
					,	@asHtml			= 1
					,	@attachedFiles	= null

end

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO