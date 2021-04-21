use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_AccountStatus_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_AccountStatus_ins]
GO
setuser N'wh'
GO
create procedure wh.dim_AccountStatus_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new values to the Warehouse Account Status dimension.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	wh.dim_AccountStatus
	(	AccountStatusCd
	,	AccountStatus
	)
select	o.AcctStatCd
	,	o.AcctStatDesc
from	wh.dim_AccountStatus	s
right join	openquery(OSI, '
		select	AcctStatCd
			,	AcctStatDesc
		from	osiBank.AcctStat'
	)	o	on	s.AccountStatusCd = o.AcctStatCd
where	s.AccountStatusCd is  null
order by o.AcctStatCd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO