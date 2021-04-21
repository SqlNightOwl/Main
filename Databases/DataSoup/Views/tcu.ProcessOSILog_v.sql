use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessOSILog_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[ProcessOSILog_v]
GO
setuser N'tcu'
GO
CREATE view tcu.ProcessOSILog_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/18/2008
Purpose  :	Returns contents of the ProcessOSILog table including the full UNC
			path to the source file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/01/2008	Paul Hunter		Added the daily offset column to the path to replace
							the effective date.
02/01/2010	Paul Hunter		Added QueDesc to results.
————————————————————————————————————————————————————————————————————————————————
*/

select	l.ProcessOSILogId
	,	l.RunId
	,	l.ProcessId
	,	l.EffectiveOn
	,	l.ApplName
	,	l.QueNbr
	,	l.QueDesc
	,	l.FileName
	,	o.OSIFolder + l.DailyOffset + '\'
					+ cast(l.QueNbr as varchar(10)) + '\'
					+ l.FileName	as FileSpec
	,	l.CompletedOn
	,	l.FileDate
	,	l.FileSize
	,	l.FileCount
	,	l.CreatedBy
	,	l.CreatedOn
from	tcu.ProcessOSILog	l
cross join
	(	select tcu.fn_OSIFolder() as OSIFolder ) o;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO