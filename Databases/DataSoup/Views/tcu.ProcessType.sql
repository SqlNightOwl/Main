use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessType]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessType]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessType
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/19/2008
Purpose  :	Returns a list of available Process Types from the Reference tables.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	top 100
		ProcessType			= cast(left(rv.ReferenceCode, 3) as char(3))
	,	rv.Description
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId	= rv.ReferenceId
where	r.ReferenceObject	= 'Process.ProcessType'
and		rv.IsEnabled		= 1
order by
		rv.Sequence
	,	rv.ReferenceCode
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO