use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[MemberFee_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[MemberFee_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.MemberFee_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/10/2008
Purpose  :	Loads the Member IHB Fee file and produces the SWIM file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/16/2009	Paul Hunter		Changed the process to pull directly from the IHB
							Voyager system.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@detail		varchar(4000)
,	@result		int

set	@result = 0

--	clear old data...
truncate table ihb.MemberFee;

insert	ihb.MemberFee ( MemberNumber )
select	cast(AuthRelationshipName as bigint)
from	VOYAGER.Voyager.dbo.CCUser with (nolock)
where	isnumeric(AuthRelationshipName)	= 1
and		len(AuthRelationshipName)		< 23
and		BillPayUserStatus				= 'Active'
and		BankingStatus					= 'Active';

if @@error != 0
begin
	set	@result		= 1;	--	failure
	set	@actionCmd	= 'insert ihb.MemberFee select MemberNumber from VOYAGER.Voyager.dbo.CCUser'
end;

if @result = 0
begin
	--	build the SWIM file...
	exec @result = ihb.MemberFee_savSWIM  @RunId		= @RunId
										, @ProcessId	= @ProcessId
										, @ScheduleId	= @ScheduleId;
end;

PROC_EXIT:
if @result != 0 or len(@detail) > 0
begin
	set	@result = isnull(nullif(@result, 0), 2)	--	information if not something other than zero
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO