use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dev].[DataType]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dev].[DataType]
GO
setuser N'dev'
GO
CREATE view dev.DataType
as
/*
»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»»
			© 2000-08 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huner
Created  :	04/21/2008
Purpose  :	Returns the SqlDbType enumeration for dev.Procedure_getParameters.
History  :
   Date     Developer       Description
——————————  ——————————————  ————————————————————————————————————————————————————
««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««
*/

select	top 100 percent
		dbType		= v.Sequence
	,	dataType	= v.ReferenceValue
from	tcu.Reference		r
join	tcu.ReferenceValue	v
		on	r.ReferenceId = v.ReferenceId
where	r.ReferenceObject	= 'DataType'
and		v.IsEnabled			= 1
order by v.ReferenceCode
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  SELECT  ON [dev].[DataType]  TO [public]
GO
GRANT  SELECT  ON [dev].[DataType]  TO [wa_WWW]
GO
GRANT  SELECT  ON [dev].[DataType]  TO [wa_Services]
GO