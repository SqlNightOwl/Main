use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventResponse_send]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[EventResponse_send]
GO
setuser N'mkt'
GO
CREATE procedure mkt.EventResponse_send
	@RegistrationId	int
,	@MessageType	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/23/2008
Purpose  :	Handles sending Event Responses.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/03/2008	Fijula Kuniyil	Added code to handle the dynamic text in the message.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@bccRecipient	varchar(100)
,	@body			varchar(max)
,	@recipient		varchar(100)
,	@error			int
,	@proc			varchar(255)
,	@subject		varchar(125)

set	@error	= 0
set	@proc	= db_name() + '.' + object_name(@@procid) + '.'

--	setup the subject, body, recipients, etc. 
select	@recipient		= reg.Email
	,	@bccRecipient	= case e.BccToCoordinator when 1 then e.CoordinatorEmail else null end
	,	@subject		= msg.Subject
	,	@body			= replace(replace(replace(replace(msg.Body
							, '#FIRST_NAME#', isnull(reg.First_Name		, ''))
							, '#LAST_NAME#'	, isnull(reg.Last_Name		, ''))
							, '#TICKETS#'	, isnull(reg.Number_Of_People, ''))
							, '#ADDRESS#'	, isnull(reg.Address			, '')
											+ isnull(', ' + reg.City		, '')
											+ isnull(', ' + reg.State		, '')
											+ isnull('  ' + reg.Zip_Code	, ''))
from	mkt.EventRegistration	reg
join	mkt.Event				e
		on	reg.EventId = e.EventId
join	mkt.EventResponse		msg
		on	e.EventId = msg.EventId
where	reg.EventRegistrationId	= @RegistrationId
and		msg.MessageType			= @MessageType

--	send the message if there's a message and email address.
if	len(@subject)			> 0
and	len(isnull(@recipient, ''))	> 0
begin
	exec msdb.dbo.sp_send_dbmail	@profile_name			= 'Marketing Events'
								,	@recipients				= @recipient
								,	@copy_recipients		= null
								,	@blind_copy_recipients	= @bccRecipient
								,	@subject				= @subject
								,	@body					= @body
								,	@body_format			= 'html'
								,	@importance				= 'normal'
								,	@sensitivity			= 'normal'
end

set @error = @@error

PROC_EXIT:
if @error != 0
begin
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @proc)
end

return @error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[EventResponse_send]  TO [wa_Marketing]
GO