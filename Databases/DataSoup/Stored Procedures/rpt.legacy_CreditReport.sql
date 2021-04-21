use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[legacy_CreditReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[legacy_CreditReport]
GO
setuser N'rpt'
GO
CREATE procedure rpt.legacy_CreditReport
	@SSN	varchar(9)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	10/09/2007
Purpose  :	Retrieves record(s) from the CreditReport table based upon the SSN.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/17/2008	Paul Hunter		Moved to SQL 2005.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select	FirstName
	,	LastName
	,	ReportDate
	,	ReportText
from	Legacy.ep.CreditReport
where	SSN	= @SSN
order by ReportDate desc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO