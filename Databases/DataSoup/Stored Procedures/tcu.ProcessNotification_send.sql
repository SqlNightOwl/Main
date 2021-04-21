use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessNotification_send]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessNotification_send]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessNotification_send
	@ProcessId	smallint
,	@Result		tinyint					--	results from the process handler
,	@Details	varchar(4000)	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/03/2007
Purpose  :	Generates the email message for the provided Process and result.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@message	varchar(4000)	--	body of the message
,	@recipients	varchar(500)	--	recipient(s) of the message
,	@status		char(2)
,	@subject	varchar(500)	--	subject of the message
,	@today		char(10)

if exists ( select	top 1 Recipient from tcu.ProcessNotification
			where	ProcessId		= @ProcessId
			and	power(2, @Result)	= (MessageTypes & power(2, @Result)) )
begin

	set	@today = convert(char(10), getdate(), 101)

	--	translate the results into the message type
	set	@status =	case @Result
					when 0 then '-S'	--	Success
					when 1 then '-F'	--	Failure
					when 2 then '-I'	--	Information
					when 3 then '-W'	--	Warning
					else '-U' end	--	Unknown

	--	set the details by replacing any CRLF with html breaks or returning a zero length string
	set	@Details = isnull('<p>' + replace(nullif(rtrim(@Details), ''), char(13) + char(10), '<br/>') + '</p>', '')

	--	collect the recipients
	set	@recipients = tcu.fn_ProcessNotificationList(@ProcessId, @Result)

	--	create the subject and message based on process type an results
	select	@subject =	'TOM:' + cast(ProcessId as varchar) + @status + ' - ' + Process
		,	@message =	'<html><style type="text/css">body{font: 11pt tahoma;} p{font: 11pt tahoma;} td{font: 11pt tahoma;}</style></style><body><p>'
					 +	case ProcessType
						when 'OSI' then
							case @Result
							when 0 then 'Successfully retrieved the OSI file(s) for ' + Process + ' on ' + @today + '.'
							when 1 then 'Unable to find/retrieve the OSI file(s) for ' + Process + ' on ' + @today + '.'
							when 2 then 'Additional information was returned by the ' + Process + ' process when finding/retrieving the OSI file(s) on ' + @today + '.'
							when 3 then 'A warning was returned by the ' + Process + ' process when finding/retrieving the OSI file(s) on ' + @today + '.'
							else 'An unknown result was returned by the OSI ' + Process + '.'
							end
						when 'SWM' then
							case @Result
							when 0 then 'Successfully generated the ' + Process + ' SWIM file for ' + @today + '.'
							when 1 then 'Unable to generate the ' + Process + ' SWIM file using the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							when 2 then 'Additional information was returned for the ' + Process + ' SWIM process using the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							when 3 then 'A warning was returned for the ' + Process + ' SWIM process using the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							else 'An unknown result was returned by the ' + Process + ' SWIM process using the handler ' + quotename(ProcessHandler) + '.'
							end
						else	--	PRC & DTS for now
							case @Result
							when 0 then 'Successfully executed the ' + Process + ' process for ' + @today + '.'
							when 1 then 'Unable to execute the ' + Process + ' process using the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							when 2 then 'Additional information was returned for the ' + Process + ' process by the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							when 3 then 'A warning was returned for the ' + Process + ' process using the handler ' + quotename(ProcessHandler) + ' for ' + @today + '.'
							else 'An unknown result was returned by the ' + Process + ' process using the handler ' + quotename(ProcessHandler) + '.'
							end
						end
					 +	'</p>' + @Details + '</body></html>'
	from	tcu.Process with (nolock)
	where	ProcessId	= @ProcessId

	--	send the message...
	exec tcu.Email_send	@subject		= @subject
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