use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[legacy_AccountXRef]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[legacy_AccountXRef]
GO
setuser N'rpt'
GO
CREATE procedure rpt.legacy_AccountXRef
	@memberNumber	bigint			= null
,	@premierNumber	varchar(25)		= null
,	@osiAcctNbr		bigint			= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/20/2007
Purpose  :	Returns OSI Account information for the information specified.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/17/2008	Paul Hunter		Moved to SQL 2005
05/27/2009	Paul Hunter		Moved source tables to DataSoup.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

exec ops.SSRSReportUsage_ins @@procid;

set @memberNumber	= nullif(@memberNumber, 0);
set @premierNumber	= nullif(@premierNumber, '');
set @osiAcctNbr		= nullif(@osiAcctNbr, 0);

select	x.MemberNumber
	,	m.MemberName
	,	m.Address1
	,	Address2		=	coalesce( m.Address2
									, m.City + ', ' + isnull(m.State, '') + '  ' + isnull(m.Zip, ''))
	,	Address3		=	case
							len(isnull(m.Address2, '')) when 0 then null
							else m.City + ', ' + isnull(m.State, '') + '  ' + isnull(m.Zip, '') end
	,	x.PremierTable
	,	x.PremierType
	,	PremierNumber	=	nullif(x.PremierNumber, '0')
	,	OSIMbrNbr		=	nullif(x.OSIMbrNbr, 0)
	,	x.OSIAcctNbr
	,	x.OSIAcctType
from	legacy.osiPremierAccountXRef	x
join	legacy.Member					m
		on	x.MemberNumber = m.MemberNumber
where	m.IsPurged		= 0
and	(	x.MemberNumber	= @MemberNumber		or @MemberNumber	is null)
and	(	x.PremierNumber	= @PremierNumber	or @PremierNumber	is null)
and	(	x.OSIAcctNbr	= @OSIAcctNbr		or @OSIAcctNbr		is null)
order by
		x.MemberNumber
	,	case x.PremierTable
		when 'Share' then 1
		when 'CD'	 then 2
		when 'Loan'  then 3 end
	,	x.PremierType
	,	x.PremierNumber;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO