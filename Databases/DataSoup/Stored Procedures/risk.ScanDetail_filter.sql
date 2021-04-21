use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ScanDetail_filter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ScanDetail_filter]
GO
setuser N'risk'
GO
CREATE procedure risk.ScanDetail_filter
	@ScanId		int				= null	
,	@DeviceId	int				= null
,	@ScanType	char(1)			= null
,	@Company	varchar(50)		= null
,	@ScanOn		datetime		= null
,	@DeviceType	varchar(10)		= null
,	@AssignedTo	int				= null
,	@Severity	varchar(16)		= null
,	@Status		varchar(10)		= null
,	@StartIP	varchar(15)		= null
,	@EndIP		varchar(15)		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Fijula Kuniyil	
Created  :	04/02/2009
Purpose  :	Returns the Scan details based on the filter provided 
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/
set nocount on;

declare
	@return	int

--	if only a StartIP is provided, then only match that IP, otherwise use the "range"
select	@ScanOn		= convert(char(10)	, @ScanOn, 121)
	,	@EndIP		= coalesce(@EndIP	, @StartIP, '999.999.999.999')
	,	@StartIP	= coalesce(@StartIP	, '')	--	use the start ip or begin at the beginning

select	s.ScanId
	,	s.Scan
	,	s.ScanType
	,	convert(char(10), s.ScanOn, 121)				as ScanOn
	,	s.Company
	,	s.FileName
	,	sd.ScanId
	,	sd.ScanDetailId
	,	sd.DeviceId
	,	sd.IP
	,	sd.RawProtocol
	,	sd.ScriptId
	,	sd.Severity
	,	sd.Detail
	,	sd.PortName
	,	sd.Port
	,	sd.Protocol
	,	isnull(nullif(sd.AssignedTo, 0), d.AssignedTo)	as AssignedTo
	,	sd.Status
	,	sd.Resolution
	,	sd.ApprovedBy
	,	d.Device
	,	d.ExtendedName
	,	d.DeviceType
from	risk.Scan		s
left join
		risk.ScanDetail	sd
		on	sd.ScanId = s.ScanId
left join
		risk.Device		d
		on	sd.DeviceId = d.DeviceId
where	(sd.IP			between	@StartIP and @EndIP	)
and		(s.ScanOn		= @ScanOn		or @ScanOn		is null)
and		(s.ScanId		= @ScanId		or @ScanId		is null)
and		(d.DeviceId		= @DeviceId		or @DeviceId	is null)
and	(	(sd.AssignedTo	= @AssignedTo	or @AssignedTo	is null)
	or	(d.AssignedTo	= @AssignedTo	or @AssignedTo	is null)
	)
and		(sd.Severity	= @Severity		or @Severity	is null)
and		(sd.Status		= @Status		or @Status		is null)
and		(s.ScanType		= @ScanType		or @ScanType	is null)
and		(d.DeviceType	= @DeviceType	or @DeviceType  is null)

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [risk].[ScanDetail_filter]  TO [wa_SecurityScan]
GO