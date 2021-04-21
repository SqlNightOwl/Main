use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Email_send]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Email_send]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Email_send
	@subject		nvarchar(255)				--	subject of the message
,	@message		nvarchar(max)				--	body of the message
,	@sendTo			varchar(max)	= 'DBA'		--	[OPTIONAL] recipient(s) of the message (DBA's if none provided)
,	@sendCC			varchar(max)	= null		--	[OPTIONAL] CC recipients of the message
,	@asHtml			tinyint			= 1			--	[OPTIONAL] indicate if this is HTML or plain Text
,	@attachedFiles	nvarchar(max)	= null		--	[OPTIONAL] semi-colon delimited list of attachments
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/23/2006
Purpose  :	Sends an SMTP email message using CDO instead of xp_sendmail.  If the
			sendTo recipient isn't provided or the is set to DBA then the message
			will be sent to the DBA's
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/10/2008	Paul Hunter		Changed to use Database Mail
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on

declare
	@bodyFormat	varchar(20)

--	exit if the message = "none"
if isnull(rtrim(@message), 'none') = 'none'
	return @@error

set	@bodyFormat = case @asHtml when 1 then 'HTML' else 'TEXT' end

--	send it to the DBA's if nobody else is provided
if isnull(nullif(rtrim(@sendTo), ''), 'DBA') = 'DBA'
	set	@sendTo	= tcu.fn_Dictionary('All Applications', 'DBA Email Address')

--	send the message
exec msdb.dbo.sp_send_dbmail	@profile_name			= 'Notification Service'
							,	@recipients				= @sendTo
							,	@copy_recipients		= @sendCC
							,	@blind_copy_recipients	= null
							,	@subject				= @subject
							,	@body					= @message
							,	@body_format			= @bodyFormat
							,	@importance				= 'normal'
							,	@sensitivity			= 'normal'
							,	@file_attachments		= @attachedFiles

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO