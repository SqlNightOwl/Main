use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementIndex_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[StatementIndex_process]
GO
setuser N'osi'
GO
CREATE procedure osi.StatementIndex_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/03/2009
Purpose  :	Indexes the Statement table by Account for subsequent review.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@account	bigint
,	@cmd		varchar(255)
,	@detail		varchar(4000)
,	@member		bigint
,	@result		int
,	@start		int
,	@stop		int
,	@tableId	int

--	create temp table to hold beginning/ending record id for each account...
declare @accounts	table
	(	Account		bigint	not null
	,	Member		bigint	not null
	,	StartId		int		not null primary key
	,	StopId		int		not null
	);

--	exit if there are no records to index...
if not exists (	select	top 1 RecordId from osi.Statement
				where	Account = 0	)
	return 0;

begin try
	--	initialize the tracking variables...
	select	@detail		= ''
		,	@result		= 0
		,	@start		= 0
		,	@tableId	= object_id(N'osi.Statement');

	set	@cmd = '1)	drop the account and member indexes';
	if exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Account')
		drop index IX_Account on osi.Statement;
	if exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Member')
		drop index IX_Member on osi.Statement;

	set	@cmd = '2)	update the account and member number columns for page 1 of each statement';
	update	s
	set		Account	= a.Account
		,	Member	= m.Member
	from	osi.Statement	s
	join(	--	extract the account number for each Statement
			select	RecordId - 3	as RecordId
				,	cast(substring(Record, charindex(':', Record) + 2, 30) as bigint) as Account
			from	osi.Statement
			where	Record like '%Account%Number%:%'
		)	a	on	s.RecordId = a.RecordId
	join(	--	extract the member number for each Statement
		select	RecordId - 8	as RecordId
				,	cast(Record as bigint) as Member
			from	osi.Statement
			where	isnumeric(Record)	= 1
			and		len(Record)			> 50
		)	m	on	s.RecordId = m.RecordId
	join(	--	extract the first page of all statements...
			select	RecordId - 2 as RecordId
			from	osi.Statement
			where	Record like '%Page:%'
			and		cast(substring(Record, charindex(':', Record) + 2, 2) as tinyint) = 1
		)	p	on	s.RecordId = p.RecordId;

	set	@cmd = '3)	collect the starting record for each account';
	insert	@accounts
	select	Account
		,	Member
		,	RecordId	as StartId
		,	0			as StopId
	from	osi.Statement
	where	Account > 0
	order by RecordId;

	set	@cmd = '4)	loop and set the ending record id for each account';
	while exists (	select	top 1 StartId from @accounts
					where	StartId > @start
					and		StopId	= 0 )
	begin
		select	top 1 @start = StartId
		from	@accounts
		where	StartId > @start
		and		StopId	= 0
		order by StartId;

		update	@accounts
		set		StopId	= @start - 1
		where	StartId < @start
		and		StopId	= 0;
	end;

	set	@cmd = '5)	update last statement with the last reccord id';
	update	@accounts
	set		StopId = (select max(RecordId) from osi.Statement)
	where	StopId	= 0;

	set	@cmd = '6)	update all of the records with their associated account and member number';
	update	s
	set		Account	= a.Account
		,	Member	= a.Member
	from	osi.Statement	s
	join	@accounts		a
			on	s.RecordId	between a.StartId
								and	a.StopId
	where	s.Account = 0;

	set	@cmd = '6)	recreate the account and member indexes';
	if not exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Account')
		create nonclustered index IX_Account on osi.Statement(Account);

	if not exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Member')
		create nonclustered index IX_Member on osi.Statement(Member);

	--	set the success message...
	select	@cmd	= ''
		,	@detail	= 'The OSI Statement file for ' + datename(month, dateadd(month, -1, getdate()))
					+ ' ' + cast(year(dateadd(month, -1, getdate())) as char(4))
					+ ' has been indexed and is available for review.'
		,	@result	= 2;	--	information
end try
begin catch
	--	build the failure message...
	exec tcu.ErrorDetail_get @detail out;
	
	select	@detail	= @detail + '<br/>When executing the T-SQL command "' + @cmd + '".' 
		,	@result	= 1;	--	Failure
end catch;

--	log the results...
if len(@detail) > 0 
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @cmd
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO