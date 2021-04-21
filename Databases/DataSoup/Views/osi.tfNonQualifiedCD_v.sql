use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfNonQualifiedCD_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[tfNonQualifiedCD_v]
GO
setuser N'osi'
GO
CREATE view osi.tfNonQualifiedCD_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/18/2008
Purpose  :	Provides Texans Financial with summary tranaciton information relating
			to Time Deposits for the preceeding month.  This view is built so that
			a simple CSV file can be generated that included column headers.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/05/2009	Paul Hunter		Changed to use the RPT2 instance.
01/12/2010	Paul Hunter		Changed to us the new osi.tfTimeDeposit data that
							is loaded & extracted from the OSI DP_NEW applicaiton.
————————————————————————————————————————————————————————————————————————————————
*/

-- bulid the column header...
select	'"Minor Type"'	as MinorType
	,	'"Branch"'		as Branch
	,	'"Fund Source"'	as FundSource
	,	'"Employee"'	as Employee
	,	'Balance'		as Balance
	,	'"Account"'		as Account

union all

select	'"' + MinorDesc		+ '"'
	,	'"' + Branch		+ '"'
	,	'"' + FundSource	+ '"'
	,	'"' + OrigEmpl		+ '"'
	,	cast(Amount as varchar(25))
	,	'"****' + right(cast(Account as varchar(20)), 6) + '"'
from	osi.tfTimeDeposit
where	Account			> 0
and		IsRetirement	= 'N';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO