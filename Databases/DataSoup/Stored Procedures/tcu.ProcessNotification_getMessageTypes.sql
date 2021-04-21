use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessNotification_getMessageTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessNotification_getMessageTypes]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessNotification_getMessageTypes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns a list of available Message Types.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/01/2008	Paul Hunter		Added the BitValue column.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

select	cast(rv.ReferenceCode as tinyint)			as MessageType
	,	rv.ReferenceValue							as MessageTypeName
	,	rv.Description
	,	power(2, cast(rv.ReferenceCode as tinyint))	as BitValue
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId	= rv.ReferenceId
where	r.ReferenceObject	= 'ProcessNotification.MessageType'
and		rv.IsEnabled		= 1
order by
		rv.Sequence
	,	rv.ReferenceCode;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO