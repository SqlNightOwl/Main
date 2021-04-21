use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ihb_SWCoprACHVerification]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ihb_SWCoprACHVerification]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ihb_SWCoprACHVerification
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	04/27/2007
Purpose  :	Retrieve records for the Corillina ACH SWCorp Verification report.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select	FileDate
	,	FileType
	,	OrginatingId	= convert(varchar(10), TransactionCode) + RTN
	,	AccountNumber
	,	TaxId
	,	CompanyName
	,	Amount
	,	LoadedOn
from	sst.SWCorpACHVerification;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO