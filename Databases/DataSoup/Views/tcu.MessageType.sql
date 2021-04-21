use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[MessageType]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[MessageType]
GO
setuser N'tcu'
GO
CREATE view tcu.MessageType
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns a list of available Message Types from the Reference tables.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/01/2008	Paul Hunter		Added the BitValue column.
————————————————————————————————————————————————————————————————————————————————
*/

select	top 100
		MessageType		= cast(rv.ReferenceCode as tinyint)
	,	MessageTypeName	= rv.ReferenceValue
	,	BitValue		= power(2, cast(rv.ReferenceCode as tinyint))
	,	rv.Description
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId	= rv.ReferenceId
where	r.ReferenceObject	= 'ProcessNotification.MessageType'
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