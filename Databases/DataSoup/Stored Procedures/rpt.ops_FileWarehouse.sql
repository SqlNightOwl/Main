use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[ops_FileWarehouse]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[ops_FileWarehouse]
GO
setuser N'rpt'
GO
CREATE procedure rpt.ops_FileWarehouse
	@PostDate	datetime	= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/19/2005
Purpose  :	Returns information about the OSI File Warehouse table since the date
			provided.
History  :
   Date		Developer		Modification
——————————	——————————————	————————————————————————————————————————————————————
11/29/2007	Vivian Liu		Return 5 days record including the PostDate 
06/09/2008	Neelima G.		Converted to SQL 2005 and move to DataSoup.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(1000)
,	@postOn	varchar(40)
,	@endOn	varchar(40);

exec ops.SSRSReportUsage_ins @@procid;

set	@postOn	= 'to_date(''''' + convert(char(10), isnull(@PostDate, dateadd(day, -1, getdate())), 101)
			+ ''''', ''''mm/dd/yyyy'''')'
set	@endOn	= 'to_date(''''' + convert(char(10), dateadd(day, 5, isnull(@PostDate, dateadd(day, -1, getdate()))), 101)
			+ ''''', ''''mm/dd/yyyy'''')';

set	@cmd = '
select	convert(char(10), post_date, 101) as post_date
	,	file_number
	,	record_status
	,	txn_type
	,	items	= cast(items as int)
	,	amount	= cast(amount as money)
from	openquery(OSI, ''
		select	post_date
			,	file_number
			,	record_status
			,	txn_type
			,	items
			,	amount
		from	texans.ops_FileWarehouse_vw
		where	post_date >= ' + @postOn +
		' and	post_date < ' + @endOn + ''')';

exec sp_executesql @cmd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO