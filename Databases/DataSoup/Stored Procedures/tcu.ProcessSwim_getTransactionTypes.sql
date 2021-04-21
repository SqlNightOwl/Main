use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwim_getTransactionTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSwim_getTransactionTypes]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSwim_getTransactionTypes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/22/2007
Purpose  :	Returns a list of available Transaction Types for SWIM Processing.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	RtxnTypCd
	,	RtxnTypDesc
	,	RtxnTypCatDesc
from	openquery(OSI, '
		select	t.RtxnTypCd
			,	t.RtxnTypDesc
			,	c.RtxnTypCatDesc
		from	osiBank.RtxnTyp		t
		join	osiBank.RtxnTypCat	c
				on	t.RtxnTypCatCd	= c.RtxnTypCatCd
		where	t.AllowSwimYN = ''Y''')
order by
		RtxnTypCatDesc
	,	RtxnTypDesc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO