use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[State]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[State]
GO
setuser N'tcu'
GO
CREATE view tcu.State
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/20/2006
Purpose  :	List of US States.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	top 100
		State		= cast(v.ReferenceCode as char(2))
	,	StateName	= v.ReferenceValue
	,	CountryCode	= cast(v.ExtendedData1 as char(2))
from	tcu.Reference		r
join	tcu.ReferenceValue	v
		on	r.ReferenceId = v.ReferenceId
where	r.ReferenceObject	= 'State'
and		v.ExtendedData1		= 'US'
order by v.ReferenceValue
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO