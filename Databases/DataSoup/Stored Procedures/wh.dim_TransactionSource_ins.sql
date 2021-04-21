use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_TransactionSource_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_TransactionSource_ins]
GO
setuser N'wh'
GO
create procedure wh.dim_TransactionSource_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new values to the Warehouse Transaction Source dimension.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	wh.dim_TransactionSource
	(	TransactionSourceCd
	,	TransactionSource
	)
select	o.RtxnSourceCd
	,	o.RtxnSourceDesc
from	wh.dim_TransactionSource	s
right join	openquery(OSI, '
		select	RtxnSourceCd
			,	RtxnSourceDesc
		from	osiBank.RtxnSource'
	)	o	on	s.TransactionSourceCd = o.RtxnSourceCd
where	s.TransactionSourceCd is  null
order by o.RtxnSourceCd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO