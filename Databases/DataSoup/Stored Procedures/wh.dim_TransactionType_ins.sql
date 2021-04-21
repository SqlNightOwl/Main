use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_TransactionType_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_TransactionType_ins]
GO
setuser N'wh'
GO
create procedure wh.dim_TransactionType_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new values to the Warehouse Transaction Type dimension.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	wh.dim_TransactionType
	(	TransactionTypeCd
	,	TransactionType
	,	TransactionCategoryCd
	,	TransactionCategory
	)
select	o.RtxnTypCd
	,	o.RtxnTypDesc
	,	o.RtxnTypCatCd
	,	o.RtxnTypCatDesc
from	wh.dim_TransactionType	t
right join	openquery(OSI, '
		select	t.RtxnTypCd
			,	t.RtxnTypDesc
			,	t.RtxnTypCatCd
			,	c.RtxnTypCatDesc
		from	osiBank.RtxnTyp		t
		join	osiBank.RtxnTypCat	c
				on	t.RtxnTypCatCd = c.RtxnTypCatCd'
	)	o	on	t.TransactionTypeCd = o.RtxnTypCd
where	t.TransactionTypeCd is  null
order by o.RtxnTypCd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO