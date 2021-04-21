use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Notice_vExport]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[Notice_vExport]
GO
setuser N'osi'
GO
CREATE view osi.Notice_vExport
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/15/2008
Purpose  :	Returns the information necessary for creating the individual notice 
			files.  The lay out is for the Notices to be preceeded by the name of 
			the file, a form feed character and then the "body" of the Notice.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Detail
	,	RowId
	,	ReportType
from(	--	place a Form Feed on all but the initial line for each report type
		select	Detail	= char(12)
			,	RowId	= min(rowId) - 2
			,	ReportType
		from	osi.Notice	n
		group by FileName, ReportType
		having	min(rowId)	> (select min(RowId) from osi.Notice where ReportType = n.ReportType)

	union all
		--	place the name of the file as the separator between notices for each report type
		select	Detail	= FileName
			,	RowId	= min(rowId) - 1
			,	ReportType
		from	osi.Notice
		group by FileName, ReportType

	union all
		--	returns the details of the report
		select	Detail
			,	RowId
			,	ReportType
		from	osi.Notice
	)	d;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO