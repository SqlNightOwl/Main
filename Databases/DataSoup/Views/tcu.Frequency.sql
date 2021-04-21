use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Frequency]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Frequency]
GO
setuser N'tcu'
GO
create view tcu.Frequency
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/30/2008
Purpose  :	Frequencies which are used by various applications.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	top 1000
		FrequencyId	= cast(ReferenceCode as int)
	,	Frequency	= ReferenceValue
	,	Sequence
	,	Description
	,	CombinationRule	= cast(ExtendedData1 as char(1))
from	tcu.ReferenceValue
where	ReferenceId = 4
order by
		Sequence
	,	cast(ReferenceCode as int)
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO