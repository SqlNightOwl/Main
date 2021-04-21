use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessParameter_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessParameter_v]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessParameter_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/30/2007
Purpose  :	Collects the Standard Process Parameters in a "wide" format.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/08/2008	Paul Hunter		Added "FormatFile" as one of the returned values.
08/26/2009	Paul Hunter		Added all values defined in the view tcu.ParameterType.
							Renamed view to tcu.ProcessParameter_v
01/08/2010	Paul Hunter		Changed the 
————————————————————————————————————————————————————————————————————————————————
*/

select	p.ProcessId
	,	FileShare			= max(	case pp.Parameter
									when 'File Share'			then pp.Value
									else null end)
	,	FolderOffset		= max(	case pp.Parameter
									when 'Folder Offset'		then pp.Value
									else null end)
	,	FormatFile			= max(	case pp.Parameter
									when 'Format File'			then pp.Value
									else null end)
	,	FTPFolder			= tcu.fn_FTPFolder(max(
									case pp.Parameter
									when 'Folder Offset'		then '\' + pp.Value + '\'
									else null end))
	,	LastRun				= isnull(cast(max(
									case pp.Parameter
									when 'Last Run'				then pp.Value
									else null end) as datetime), pl.LogLastRun)
	,	MessageBody			= max(	case pp.Parameter	
									when 'Message Body'			then pp.Value
									else null end)
	,	MessageRecipient	= max(	case pp.Parameter
									when 'Message Recipient'	then pp.Value
									else null end)
	,	RetentionPeriod		= abs(isnull(cast(max(
									case pp.Parameter
									when 'Retention Period'		then pp.Value
									else null end) as int), 30)) * -1
	,	SecondaryHandler	= max(	case pp.Parameter 
									when 'Secondary Handler'	then pp.Value
									else null end)
	,	SQLFolder			= tcu.fn_SQLFolder(max(
									case pp.Parameter
									when 'Folder Offset'		then '\' + pp.Value + '\' 
									else null end))
from	tcu.Process				p
left join
		tcu.ProcessParameter	pp
		on	p.ProcessId	= pp.ProcessId
left join
		tcu.ParameterType		pt
		on	pp.Parameter = pt.Parameter
left join
	(	select	ProcessId, LogLastRun = max(FinishedOn)
		from	tcu.ProcessLog
		where	Result = 0 group by ProcessId
	)	pl	on	p.ProcessId	= pl.ProcessId
group by
		p.ProcessId
	,	pl.LogLastRun;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO