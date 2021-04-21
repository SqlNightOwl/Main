use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_Merchant_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_Merchant_ins]
GO
setuser N'wh'
GO
create procedure wh.dim_Merchant_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new values to the Warehouse Merchant dimension.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	wh.dim_Merchant
	(	MerchantCd
	,	State
	,	CountryCd
	,	TransactionCount
	)
select	n.ExtRtxnDescText						as MerchantCd
	,	left(right(n.ExtRtxnDescText, 4), 2)	as State
	,	right(n.ExtRtxnDescText, 2)				as Country
	,	0										as TransactionCount
from	wh.dim_Merchant	m
right join
	(	select	o.ExtRtxnDescText
		from	wh.fact_Transaction_stage	s
		join	openquery(OSI, '
				select	ExtRtxnDescNbr
					,	ExtRtxnDescText
				from	osiBank.ExtRtxnDesc'
			)	o	on s.TxnDescNbr= o.ExtRtxnDescNbr
		where	s.CardTxnNbr > 0
		group by o.ExtRtxnDescText
	)	n	on	m.MerchantCd = n.ExtRtxnDescText
where	m.MerchantCd is null;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO