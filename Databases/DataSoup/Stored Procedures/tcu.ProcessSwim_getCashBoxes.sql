use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwim_getCashBoxes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSwim_getCashBoxes]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSwim_getCashBoxes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/22/2007
Purpose  :	Returns a list of available Cash Boxes for SWIM Processing.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	CashBoxNbr
	,	CashBoxDesc
from	openquery(OSI, '
		select	CashBoxNbr
			,	CashBoxDesc
		from	osiBank.CashBox
		where	CashBoxTypCd = ''BATC''
		order by CashBoxDesc')
order by CashBoxDesc;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO