use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[WireRequest_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[WireRequest_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.WireRequest_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/09/2009
Purpose  :	Retrieves Wire Transfer Requests from the IHB system, builds an email
			message and sends them to the recipients of the information messages.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/08/2010	Paul Hunter		Added record retention policy.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@colnSub	varchar(25)
,	@crlf		char(2)
,	@crlfSub	varchar(25)
,	@message	varchar(max)
,	@recipients	varchar(255)
,	@request	varchar(4000)
,	@requestOn	datetime
,	@result		int
,	@retention	int
,	@template	varchar(4000)
,	@wireId		int

set	@result = 0;

--	retrieve the retentior period
set	@retention	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int) * -1;

--	determine when the last wires were received/reported...
select	@requestOn	= max(RequestedOn)
from	ihb.WireRequest;

--	collect new wire requests...
insert	ihb.WireRequest
	(	WireRequestId
	,	RequestedOn
	,	MemberNumber
	,	MemberName
	,	Request
	)
select	MessageToFIId
	,	DateCreated
	,	cast(AuthRelationshipName	as varchar(22))
	,	cast(UserName				as nvarchar(50))
	,	cast(Body					as varchar(max))
from	VOYAGER.tcu_Workspace.dbo.rptWireTransfers_v
where	DateCreated > @requestOn;

--	build the message if any new wires were requested...
if	@@rowcount	> 0
and	@@error		= 0
begin

	--	update the Amount and Wire To Bank name from the Request...
	update	r
	set		Amount	= cast(substring(r.Request, d.amntStart, d.amntEnd - d.amntStart) as money)
		,	WireTo	= left(rtrim(substring(r.Request, d.bankStart, d.bankEnd - d.bankStart)), 50)
	from	ihb.WireRequest	r
	join(	select	WireRequestId
				,	charindex('Wire Amount ($):'			, Request) + 17	as amntStart
				,	charindex('From Account Number:'		, Request)		as amntEnd
				,	charindex('Wire To - Name of Bank:'		, Request) + 24	as bankStart
				,	charindex('Wire To - Street Address:'	, Request)		as bankEnd
			from	ihb.WireRequest
			where	RequestedOn > @requestOn
		)	d	on	r.WireRequestId = d.WireRequestId
	where	r.RequestedOn > @requestOn

	--	initialize variables used to build the detail message
	set	@colnSub	= ':</td><td width="50%">';
	set	@crlf		= char(13) + char(10);
	set	@crlfSub	= '</td></tr><tr><td>';
	set	@message	= '<html><head><title>Wire Transfer Report</title>'
					+ '<style type="text/css"> '
					+ 'body {font:10pt tahoma; vertical-align:top;} '
					+ 'p {font-family:tahoma;text-align:center;} '
					+ 'table {padding:1px; width:100%;} '
					+ 'th {background-color:#0066FF; color:white; font:italic bold 10pt tahoma; vertical-align:middle;} '
					+ 'tr {font-size:10pt; vertical-align:top;} '
					+ '.asof {font-style:italic;} '
					+ '.btn {text-align:center} '
					+ '.hdr {font-style:italic;font-weight:bold;font-size:12pt;} '
					+ '.row {background-color:#99ccff;}'
					+ '</style></head><body><p><div class="hdr">Wire Transfer Requests</div>'
					+ '<div class="asof">Received Since: &nbsp;' + cast(@requestOn as varchar) + '</div></p>'
					+ '<table><tr>'
					+ '<th width="10%">Message Id</th>'
					+ '<th width="15%">Member Number</th>'
					+ '<th width="25%">Member Name</th>'
					+ '<th width="10%">Amount</th>'
					+ '<th width="25%">Wire To Bank</th>'
					+ '<th width="15%">Requested</th></tr>'
	set	@template	= '<tr class="row">'
					+ '<td>%WIRE_ID</td>'
					+ '<td>%MBR_NBR</td>'
					+ '<td>%MBR_NAM</td>'
					+ '<td>%$AMOUNT</td>'
					+ '<td>%WIRE_TO</td>'
					+ '<td>%RQST_DT</td></tr>'
					+ '<tr><td class="btn">Request:</td><td colspan="5">'
					+ '<table><tr><td width="50%">%DETAIL</td></tr></table></td></tr>';
	set	@wireId		= 0;

	--	loop thru the wires and build up the message...
	while exists (	select	top 1 WireRequestId
					from	ihb.WireRequest
					where	WireRequestId	> @wireId
					and		RequestedOn		> @requestOn )
	begin
		--	get the next wire request...
		select	top 1
				@wireId		=	WireRequestId
			,	@request	=	replace(
								replace(
								replace(
								replace(
								replace(
								replace(
								replace( @template
										, '%WIRE_ID', WireRequestId)
										, '%MBR_NBR', MemberNumber	)
										, '%MBR_NAM', MemberName	)
										, '%$AMOUNT', Amount		)
										, '%WIRE_TO', WireTo		)
										, '%RQST_DT', RequestedOn	)
										, '%DETAIL', replace(
													 replace(Request
															, ': '	, @colnSub	)
															, @crlf	, @crlfSub	)
										)
		from	ihb.WireRequest
		where	WireRequestId	> @wireId
		and		RequestedOn		> @requestOn
		order by WireRequestId;

		set	@result = isnull(nullif(@result, 0), @@error);

		--	add the request to the message...
		set @message = @message + @request;

	end;

	--	close out the message...
	set	@message = @message + '</body></html>';

	--	collect the recipients of the informaiton messages...
	set @recipients = tcu.fn_ProcessNotificationList(@ProcessId, 2)

	--	send the message...
	exec @result = tcu.Email_send	@subject		= 'IHB Wire Transfer Requests'
								,	@message		= @message
								,	@sendTo			= @recipients
								,	@sendCC			= null
								,	@asHtml			= 1
								,	@attachedFiles	= null;

	set	@result = isnull(nullif(@result, 0), @@error);

	--	add the incidents to Onyx/TTS...
	exec Onyx6_0.sync.incident_sav_IHBWireRequest @requestOn

end;

set	@result = isnull(nullif(@result, 0), @@error);

--	remove old data...
delete	ihb.WireRequest
where	RequestedOn	< dateadd(day, @retention, getdate())

--	record the process run...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= 'select * from VOYAGER.tcu_Workspace.dbo.rptWireTransfers_v'
					,	@Message	= null;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO