use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[fincenBusinessMaster_vLoad]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [audit].[fincenBusinessMaster_vLoad]
GO
setuser N'audit'
GO
create view audit.fincenBusinessMaster_vLoad
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/04/2008
Purpose  :	Wraps the audit.fincenBusinessMaster table exposing the only columns
			for the file so that BCP bulk loading can be performed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	TrackingNumber
	,	BusinessName
	,	DbaName
	,	Number
	,	NumberType
	,	Incorporated
	,	Street
	,	City
	,	State
	,	Zip
	,	Country
	,	Phone
from	audit.fincenBusinessMaster
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO