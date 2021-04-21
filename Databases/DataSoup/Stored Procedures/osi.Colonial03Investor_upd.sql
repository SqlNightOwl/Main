use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial03Investor_upd]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[Colonial03Investor_upd]
GO
setuser N'osi'
GO
CREATE procedure osi.Colonial03Investor_upd
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/27/2007
Purpose  :	Matches Colonial loans to OSI Member records based on the Tax Id for
			the Mortgagor and Co-Mortgager.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

create table #osiMember
	(	MemberNumber	bigint	not null
	,	TaxId			char(9)	not null
	);

--	collect Member Number and Tax Id from OSI...
insert	#osiMember
	(	MemberNumber
	,	TaxId
	)
select	cast(MemberNbr as bigint)
	,	left(TaxId, 9)
from	openquery(OSI, '
		select	nvl(cast(ma.MemberAgreeNbr as number(22)), 0) as MemberNbr
			,	nvl(osiBank.pack_TaxId.func_GetTaxId(p.PersNbr, ''P'', ''N'', null), ''0'') as TaxId
		from	texans.CustomerMemberAgreement_vw	ma
		join	osiBank.Pers	p
				on	ma.PrimaryPersNbr = p.PersNbr
		where	p.PurgeYN	= ''N''
		and		p.TaxId		is not null');

truncate table osi.ColonialMember;

insert	osi.ColonialMember
select	ColonialLoanNum
	,	MemberNumber	= 0
	,	TaxId1			= ltrim(rtrim(nullif(replace(MortgagorTaxId	 , '-', ''), '000000000')))
	,	TaxId2			= ltrim(rtrim(nullif(replace(CoMortgagorTaxId, '-', ''), '000000000')))
	,	Match			= 0
from	osi.Colonial03Investor;

--	update the Colonial loans with the OSI Member Number based on TaxId
update	cm
set		MemberNumber	= m.MemberNumber
	,	Match			= 1
from	osi.ColonialMember	cm
join(	select	TaxId, MemberNumber = min(MemberNumber)
		from	#osiMember	group by TaxId
	)	m	on	cm.TaxId1 = m.TaxId
where	cm.MemberNumber	= 0;

--	update any unmatched records for TaxId 2
update	cm
set		MemberNumber	= m.MemberNumber
	,	Match			= 2
from	osi.ColonialMember	cm
join(	select	TaxId, MemberNumber = min(MemberNumber)
		from	#osiMember	group by TaxId
	)	m	on	cm.TaxId2 = m.TaxId
where	cm.MemberNumber	= 0;

drop table #osiMember;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO