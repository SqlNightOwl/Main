use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_Referrals_eStatement]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_Referrals_eStatement]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_Referrals_eStatement
as	
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	03/20/2008
Purpose  :	Retrieve records for the e-Statement report.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/08/2008	Paul Hunter		Added to SQL 2005
12/15/2008	Paul Hunter		Changed to use ONYX 6.0 schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

select	r.Branch
	,	r.EmployeeName
	,	r.EmployeeNumber
	,	r.MemberNumber
	,	r.MemberName
	,	Payment			= cast(3.00 as money)
from	Onyx6_0.cs.eStatement_Referrals	r
join	osi.mdEStatement				e
		on	r.MemberNumber = cast(e.MemberNumber as varchar(25));
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO