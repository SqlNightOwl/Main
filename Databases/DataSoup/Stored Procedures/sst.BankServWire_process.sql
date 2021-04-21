use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServWire_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[BankServWire_process]
GO
setuser N'sst'
GO
CREATE procedure sst.BankServWire_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/23/2008
Purpose  :	Wrapper process for loading Corillian wires which are destined for
			BankServ and loading the Acknowledgement file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@resultAcks	int
,	@resultWire	int
,	@retention	int
,	@return		int

select	@retention	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int) * -1
	,	@resultAcks	= 0
	,	@resultWire	= 0;

--	remove old wires from the system
delete	sst.BankServWire
where	WireLoadedOn < dateadd(day, @retention, getdate());

--	clear the table for loading new data
truncate table sst.BankServWire_load;

--	refresh the view...
exec sp_refreshview 'sst.BankServWire_vLoad';

--	this binds the view to the process
if (select count(1) from sst.BankServWire_vLoad) > 0
	return 1;	--	failure

--	first load the wire requests...
exec @resultWire = sst.BankServWire_savWire	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;

--	then load the acknowledgements...
exec @resultAcks = sst.BankServWire_savAcks	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;

set @return	=	case
				when @resultWire > 0
				or	 @resultAcks > 0 then 1	--	failure
				else 0 end;					--	success

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO