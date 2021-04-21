use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessFrequency]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessFrequency]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessFrequency
with schemabinding
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/13/2008
Purpose  :	List of Process Scheduling Frequencies.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	top 100
		FrequencyId
	,	Frequency =	case FrequencyId
					when 1 then 'Continuous'
					else Frequency end
	,	Sequence
	,	Description
	,	CombinationRule
from	tcu.Frequency
order by FrequencyId
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO