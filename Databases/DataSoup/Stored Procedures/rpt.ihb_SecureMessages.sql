use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ihb_SecureMessages]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ihb_SecureMessages]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ihb_SecureMessages
	@FromDate	datetime
,	@ToDate		datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	05/17/2007
Purpose  :	Retrieve records from for the Corillian Secure Message report.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set	@FromDate	= convert(char(10), isnull(@FromDate, getdate()), 121);
set	@ToDate		= convert(char(10), isnull(@ToDate, @FromDate) + 1, 121);

select	CaseId
	,	AgentName
	,	MemberNumber
	,	MemberName
	,	OpenedOn
	,	ClosedOn
	,	Subject
	,	Status
from	ihb.SecureMessage
where	OpenedOn between @FromDate and @ToDate
	or	ClosedOn between @FromDate and @ToDate
order by
		AgentName
	,	CaseId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO