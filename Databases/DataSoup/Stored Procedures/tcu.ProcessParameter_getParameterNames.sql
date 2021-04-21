use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessParameter_getParameterNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessParameter_getParameterNames]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessParameter_getParameterNames
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns a list of standard Process Parameters.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	Parameter		= left(rv.ReferenceValue, 20)
	,	ValueType		= left(rv.ExtendedData1, 10)
	,	rv.Description
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId	= rv.ReferenceId
where	r.ReferenceObject	= 'ProcessParameter.Parameter'
and		rv.IsEnabled		= 1
order by
		rv.Sequence
	,	rv.ReferenceValue
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[ProcessParameter_getParameterNames]  TO [wa_Process]
GO