use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[LoanQualityAudit_getLoadOn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[LoanQualityAudit_getLoadOn]
GO
setuser N'lnd'
GO
CREATE procedure lnd.LoanQualityAudit_getLoadOn
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	12/04/2009
Purpose  :	Gets a unique ordered list of the load dates from to be used with
			SQL Reporting to aid selection of valid dates.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	convert(char(10), LoadOn, 101) as LoadOn
from(	select	LoadOn
		from	lnd.LoanQualityAudit
		group by LoadOn
	)	d
order by cast(LoadOn as datetime) desc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO