use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getProcessTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getProcessTypes]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_getProcessTypes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns a list of available Process Types.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@constraint	varchar(4000)

select	@constraint	= check_clause
from	INFORMATION_SCHEMA.CHECK_CONSTRAINTS
where	constraint_name = 'CK_Process_ProcessType'

select	ProcessType			= left(rv.ReferenceCode, 3)
	,	rv.Description
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId	= rv.ReferenceId
join(	select	value from tcu.fn_split(@constraint, '''')
		where	charindex('[', value) = 0
		and		charindex(')', value) = 0
	)	cc	on	rv.ReferenceCode = cc.Value 
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