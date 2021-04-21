use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[EventField_getFieldTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[EventField_getFieldTypes]
GO
setuser N'mkt'
GO
CREATE procedure mkt.EventField_getFieldTypes
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/07/2006
Purpose  :	Retrieves a list of valid FieldTypes that can be used in the
			mktEventField table when creating the Field list for Events.
Hostory  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
10/30/2008	Paul Hunter		Changed the procedure to use the ReferenceValue table.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

select	FieldType = rv.ReferenceValue
from	tcu.Reference		r
join	tcu.ReferenceValue	rv
		on	r.ReferenceId = rv.ReferenceId
where	r.ReferenceObject	= 'EventField.FieldType'
and		rv.IsEnabled		= 1
order by
		rv.ReferenceValue
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[EventField_getFieldTypes]  TO [wa_Marketing]
GO