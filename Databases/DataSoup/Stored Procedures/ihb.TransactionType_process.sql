use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[TransactionType_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[TransactionType_process]
GO
setuser N'ihb'
GO
create procedure ihb.TransactionType_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/26/2009
Purpose  :	Used to retrieve changed OSI Transaciton Category/Type information
			to provide IHB code updates.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@detail	varchar(4000)
,	@result	int

--	initialize the working variables...
select	@detail = 'no action'
	,	@result	= 0;

--	generate a message if any data was changed/added in the prior month...
if exists (	select top 1 * from	openquery(OSI, '
			select	c.RtxnTypCatCd
				,	c.RtxnTypCatDesc
				,	t.RtxnTypCd
				,	t.RtxnTypDesc
				,	greatest(t.DateLastMaint
							,c.DateLastMaint)	as DateLastMaint
			from	RtxnTyp		t
			join	RtxnTypCat	c
					on	t.RtxnTypCatCd = c. RtxnTypCatCd
			where	t.DateLastMaint > last_day(add_months(trunc(sysdate), -2)) + 1
				or	c.DateLastMaint	> last_day(add_months(trunc(sysdate), -2)) + 1')	)
begin
	--	collect the updated records...
	select	@detail	= @detail
					+ '<tr><td>'	+ RtxnTypCatCd
					+ '</td><td>'	+ RtxnTypCatDesc
					+ '</td><td>'	+ RtxnTypCd
					+ '</td><td>'	+ RtxnTypDesc
					+ '</td><td>'	+ convert(char(10), DateLastMaint, 101)
					+ '</td></tr>'
	from	openquery(OSI, '
			select	c.RtxnTypCatCd
				,	c.RtxnTypCatDesc
				,	t.RtxnTypCd
				,	t.RtxnTypDesc
				,	greatest(t.DateLastMaint
							,c.DateLastMaint)	as DateLastMaint
			from	RtxnTyp		t
			join	RtxnTypCat	c
					on	t.RtxnTypCatCd = c. RtxnTypCatCd
			where	t.DateLastMaint > last_day(add_months(trunc(sysdate), -2)) + 1
				or	c.DateLastMaint	> last_day(add_months(trunc(sysdate), -2)) + 1
			order by 1, 3');

	--	finish off the message...
	set	@detail	= '<p>The following records were updated during the prior month</p>'
				+ '<table cellpadding="2">'
				+ '<tr><th>Category<br />Code'
				+ '</th><th>Category Description'
				+ '</th><th>Transaction<br />Code'
				+ '</th><th>Transaction Description'
				+ '</th><th>Updated On'
				+ '</th></tr>' + @detail + '</table>';
end;
else
begin
	--
	select	@detail	= 'No changes have been made in the OSI Transaction Type table.'
		,	@result	= 2;	--	informational
end

exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= ''
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO