use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_AccountType_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_AccountType_ins]
GO
setuser N'wh'
GO
create procedure wh.dim_AccountType_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new values to the Warehouse Account Type dimension.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	wh.dim_AccountType
	(	CategoryCd
	,	Category
	,	MajorTypeCd
	,	MajorType
	,	MinorTypeCd
	,	MinorType
	,	CustomDesc
	,	EffectiveOn
	)
select	o.MjAcctTypCatCd
	,	o.MjAcctTypCatDesc
	,	o.MjAcctTypCd
	,	o.MjAcctTypDesc
	,	o.MiAcctTypCd
	,	o.MiAcctTypDesc
	,	isnull(o.MiCustDesc, '')
	,	o.EffDate
from	wh.dim_AccountType	t
right join	openquery(OSI, '
		select	c.MjAcctTypCatCd
			,	c.MjAcctTypCatDesc
			,	mj.MjAcctTypCd
			,	mj.MjAcctTypDesc
			,	mi.MiAcctTypCd
			,	mi.MiAcctTypDesc
			,	mi.MiCustDesc
			,	mi.EffDate
		from	osiBank.MjAcctTypCat	c
		join	osiBank.MjAcctTyp		mj
				on	c.MjAcctTypCatCd = mj.MjAcctTypCatCd
		join	osiBank.MjMiAcctTyp		mi
				on	mj.MjAcctTypCd = mi.MjAcctTypCd'
	)	o	on	t.MajorTypeCd	= o.MjAcctTypCd
			and	t.MinorTypeCd	= o.MiAcctTypCd
where	t.MajorTypeCd is null
order by
		o.MjAcctTypCd
	,	o.MiAcctTypCd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO