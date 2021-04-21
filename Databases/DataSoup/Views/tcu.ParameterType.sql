use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ParameterType]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ParameterType]
GO
setuser N'tcu'
GO
create view tcu.ParameterType
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/06/2009
Purpose  :	Returns a list of standard Parameter Types from the Reference tables
			for the tcu.ProcessParameter table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	v.ReferenceValue	as Parameter
	,	v.ExtendedData1		as ValueType
	,	v.Description
from	tcu.Reference		r
join	tcu.ReferenceValue	v
		on	r.ReferenceId = v.ReferenceId
where	r.ReferenceObject	= 'ProcessParameter.Parameter'
and		v.IsEnabled			= 1;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO