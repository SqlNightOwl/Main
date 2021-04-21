use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[legacy_PremierClosedAcctXRef]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[legacy_PremierClosedAcctXRef]
GO
setuser N'rpt'
GO
CREATE procedure rpt.legacy_PremierClosedAcctXRef
	@SSN	bigint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Biju Basheer
Created  :	10/16/2007
Purpose  :	Retrieves record(s) from the PremierClosedAcctXRef table based on the SSN.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/16/2008	Paul Hunter		Moved to SQL 2005
05/26/2009	Paul Hunter		Moved source tables to DataSoup
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select 	SSN = tcu.fn_ZeroPad(SSN, 9)
	,	Name
	,	ClosedDate
	,	Type
	,	MemberNumber
	,	Note
	,	Balance
	,	Message
	,	Txn
	,	TxnDate
from 	legacy.PremierClosedAcctXRef
where 	SSN = @SSN
order by ClosedDate desc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO