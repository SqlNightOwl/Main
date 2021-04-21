use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[IrsDetail_process]
GO
setuser N'osi'
GO
CREATE procedure osi.IrsDetail_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/23/2008
Purpose  :	Loads the IRS Reports file splits the data into separate files so
			the data can be sent to MicroDynamamics and NCP.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
11/17/2008	Paul Hunter		Added updates of the Member Number, Address and Amounts.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archDate	varchar(10)
,	@detail		varchar(4000)
,	@lastRow	int
,	@result		int

--	initialize the working parameters...
select	@actionCmd	= db_name() + '.osi.IrsDetail_vLoad'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	if the file extist then load the source file and produce the split out files...
if tcu.fn_FileExists(@actionFile) = 1
begin
	truncate table osi.IrsDetail;
	exec sp_refreshview N'osi.IrsDetail_vLoad';

	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T -b10000'
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set @result = 1;	--	failure
	end;
	else if exists ( select	top 1 Detail from osi.IrsDetail_vLoad )
	begin
		--	archive the file...
		set	@archDate = cast(year(dateadd(year, -1, getdate())) as char(4));
		exec tcu.File_archive	@Action			= 'move'
							,	@SourceFile		= @actionFile
							,	@ArchiveDate	= @archDate
							,	@Detail			= @detail out
							,	@AddDate		= 1
							,	@OverWrite		= 1;

		--	set the row type...
		update	osi.IrsDetail
		set		RowType	= left(Detail, 1)
		where	Detail	not like 'B%';

		--	set the IRS Report Id...
		update	osi.IrsDetail
		set		IrsReportId	= substring(Detail, 27, 1)
		where	RowType		= 'A';

		--	collect the absolute last "C" row of th file
		select	@lastRow = max(RowId)
		from	osi.IrsDetail
		where	RowType = 'C';

		--	update the rows within the report detail and header...
		update	d
		set		IrsReportId		=	x.IrsReportId
			,	AccountNumber	=	case RowType
									when 'B' then cast(substring(d.Detail, 21, 22) as bigint)
									when 'C' then cast(substring(d.Detail, 7, 8) as bigint)
									else AccountNumber end
			,	TaxId			=	case RowType
									when 'B' then substring(d.Detail, 12, 9)
									else TaxId end
			,	Address			=	case RowType
									when 'B' then substring(d.Detail, 368, 40)
									else Address end
			,	City			=	case RowType
									when 'B' then substring(d.Detail, 448, 40)
									else City end
			,	State			=	case RowType
									when 'B' then substring(d.Detail, 488, 2)
									else State end
			,	Zip				=	case RowType
									when 'B' then substring(d.Detail, 490, 5)
									else Zip end
			,	Amount1			=	case RowType
									when 'B' then cast(substring(d.Detail, 55, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 16, 18) as bigint)
									else 0 end
			,	Amount2			=	case RowType
									when 'B' then cast(substring(d.Detail, 67, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 34, 18) as bigint)
									else 0 end
			,	Amount3			=	case RowType
									when 'B' then cast(substring(d.Detail, 79, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 52, 18) as bigint)
									else 0 end
			,	Amount4			=	case RowType
									when 'B' then cast(substring(d.Detail, 91, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 70, 18) as bigint)
									else 0 end
			,	Amount5			=	case RowType
									when 'B' then cast(substring(d.Detail, 103, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 88, 18) as bigint)
									else 0 end
			,	Amount6			=	case RowType
									when 'B' then cast(substring(d.Detail, 115, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 106, 18) as bigint)
									else 0 end
			,	Amount7			=	case RowType
									when 'B' then cast(substring(d.Detail, 127, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 124, 18) as bigint)
									else 0 end
			,	Amount8			=	case RowType
									when 'B' then cast(substring(d.Detail, 139, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 142, 18) as bigint)
									else 0 end
			,	Amount9			=	case RowType
									when 'B' then cast(substring(d.Detail, 151, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 160, 18) as bigint)
									else 0 end
			,	AmountA			=	case RowType
									when 'B' then cast(substring(d.Detail, 163, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 178, 18) as bigint)
									else 0 end
			,	AmountB			=	case RowType
									when 'B' then cast(substring(d.Detail, 175, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 196, 18) as bigint)
									else 0 end
			,	AmountC			=	case RowType
									when 'B' then cast(substring(d.Detail, 187, 12) as bigint)
									when 'C' then cast(substring(d.Detail, 214, 18) as bigint)
									else 0 end
		from	osi.IrsDetail	d
		cross join
			(	select	FirstId	= RowId	-- this retrieves the beginning/ending records of the report
					,	LastId	= isnull((	select	min(RowId) - 1 from osi.IrsDetail
											where	RowType	= 'A' and RowId	> s.RowId )
										,	@lastRow	)
					,	IrsReportId
				from	osi.IrsDetail s
				where	RowType = 'A'
			)	x
		where	d.RowId between x.FirstId and x.LastId;

		--	update the MemberNumbers from OSI...
		update	d
		set		MemberNumber	= cast(o.MemberAgreeNbr as bigint)
		from	osi.IrsDetail	d
		join	openquery(OSI,'
				select	a.AcctNbr
					,	ma.MemberAgreeNbr
				from	osiBank.Acct	a
				join	osiBank.MemberAgreement ma
					on	(a.TaxRptForPersNbr	= ma.PrimaryPersNbr	and a.TaxRptForPersNbr	is not null)
					or	(a.TaxRptForOrgNbr	= ma.PrimaryOrgNbr	and a.TaxRptForOrgNbr	is not null)'
			)	o	on	d.AccountNumber = o.AcctNbr
		where	d.RowType = 'B';

		--	this procedure produces the output files...
		set	@actionCmd	= @actionCmd + ' ~ '
						+ 'osi.IrsDetail_exportFiles'
						+ ' @RunId = '			+ cast(@RunId as varchar)
						+ ', @ProcessId = '		+ cast(@ProcessId as varchar)
						+ ', @ScheduleId = '	+ cast(@ScheduleId as varchar);

		exec @result =	osi.IrsDetail_exportFiles	@RunId		= @RunId
												,	@ProcessId	= @ProcessId
												,	@ScheduleId	= @ScheduleId;

	end;
	else
	begin
		select	@detail	= 'The IRS file "' + @actionFile + '" could contained no data or couldn''t be loaded.'
			,	@result	= 3;	--	warning...
	end;
end;
else
begin
	select	@detail	= 'The IRS file "' + @actionFile + '" was not found.'
		,	@result = 2;	--	information...
end;

--	log the execution
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @actionCmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO