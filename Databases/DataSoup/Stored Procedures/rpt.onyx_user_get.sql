use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[onyx_user_get]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[onyx_user_get]
GO
setuser N'rpt'
GO
CREATE procedure rpt.onyx_user_get
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/17/2009
Purpose  :	Retruns the Onyx active user list.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	'all'			as [user_id]
	,	'[All Users]'	as [user_name]

union all

select	[user_id]
	,	[user_name]
from	Onyx6_0.cs.user_employee_v
where	record_status = 1
order by [user_name];
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO