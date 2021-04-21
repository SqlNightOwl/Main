use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfTimeDeposit_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[tfTimeDeposit_process]
GO
setuser N'osi'
GO
CREATE procedure osi.tfTimeDeposit_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/12/2008
Purpose  :	Provides Texans Financial with summary tranaciton information relating
			to Time Deposits for the preceeding month.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@period		char(7)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the process variables...
select	@actionCmd	= db_name() + '.osi.tfTimeDeposit'
	,	@actionFile	= l.FileSpec
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= ' -f"' + p.SQLFolder + p.FormatFile + '" -F27 -T'
	,	@detail		= ''
	,	@fileName	= ''
	,	@period		= convert(char(7), dateadd(month, -1, getdate()), 121)
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
join	tcu.ProcessOSILog_v		l
		on	f.ProcessId = l.ProcessId
where	f.ProcessId	= @ProcessId
and		l.RunId		= @RunId
and		f.ApplName	= N'DP_NEW';

begin try
	if tcu.fn_FileExists(@actionFile) = 1
	begin
		--	dump the old data...
		truncate table osi.tfTimeDeposit;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail out;

		if @result = 0 and len(@detail) = 0
		begin
			--	copy the source file to the arcive folder...
			exec tcu.File_archive	@action			= 'copy'
								,	@sourceFile		= @actionFile
								,	@archiveDate	= @period
								,	@detail			= null
								,	@addDate		= 1
								,	@overwrite		= 1;

			--	update the relevant columns in the imported data...
			set	@actionCmd = 'update osi.tfTimeDeposit from file loaded';
			update	osi.tfTimeDeposit
			set		MajorCd		=	rtrim(substring(Record,   3,  4))
				,	MinorCd		=	rtrim(substring(Record,   8,  4))
				,	Account		=	cast(substring(Record	,  12, 18) as bigint)
				,	Amount		=	cast(substring(Record	,  58, 15) as money)
				,	FundSource	=	substring(Record		, 115,  20)
								+	case charindex('New Funds Existing', Record)
									when 0 then '' else ' Customer' end
			where	Record	like '  TD%';

			--	update the relevant data from OSI...
			set	@actionCmd = 'update osi.tfTimeDeposit from OSI';
			update	c
			set		IsRetirement	= o.RetirementYN
				,	MinorDesc		= o.MiAcctTypDesc
				,	Branch			= o.Branch
				,	OrigEmpl		= o.OrigEmpl
				,	AcctGrpNbr		= cast(o.AcctGrpNbr as varchar(20))
			from	osi.tfTimeDeposit	c
			join	openquery(OSI, '
					select	a.AcctNbr
						,	a.RetirementYN
						,	b.OrgName						as Branch
						,	t.MiAcctTypDesc
						,	p.FirstName||'' ''||p.LastName	as OrigEmpl
						,	g.AcctGrpNbr
					from	AcctAcctRolePers	r
					join	Acct				a
							on	r.AcctNbr	 = a.AcctNbr
							and	r.AcctRoleCd = ''OEMP''
					join	Pers				p
							on	r.PersNbr = p.PersNbr
					join	MjMiAcctTyp			t
							on	t.MjAcctTypCd = a.MjAcctTypCd
							and	t.MiAcctTypCd = a.CurrMiAcctTypCd
					join	Org					b
							on	a.BranchOrgNbr = b.OrgNbr
					left join
							AcctGrpAcct			g
							on	g.AcctNbr		= a.AcctNbr
							and	g.InactiveDate	is null
					where	a.MjAcctTypCd = ''TD'''	) o
					on	c.Account = o.AcctNbr
			where	c.Account > 0;

			--	export the files...
			while exists (	select	FileName from tcu.ProcessFile
							where	ProcessId	= @ProcessId
							and		FileName	> @fileName
							and		ApplName	is null	)
			begin
				select	top 1
						@actionCmd	= db_name()	+ '.' + FileName
					,	@actionFile	= @sqlFolder + replace(TargetFile, '[DATE]', @period)
					,	@fileName	= FileName
					,	@switches	= '-c -t, -T'
				from	tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @fileName
				and		ApplName	is null
				order by FileName;

				--	export the file...
				exec @result = tcu.File_bcp	@action		= 'out'
										,	@actionCmd	= @actionCmd
										,	@actionFile	= @actionFile
										,	@switches	= @switches
										,	@output		= @detail output;

				--	copy the source file to the arcive folder if there are no errors...
				if @result = 0 and len(@detail) = 0
				begin
					--	archive the files...
					exec tcu.File_archive	@action			= 'copy'
										,	@sourceFile		= @actionFile
										,	@archiveDate	= null
										,	@detail			= null
										,	@addDate		= 0
										,	@overwrite		= 1;
				end;
				else	--	report any errors and break out of the loop...
				begin
					set	@result = 3;	--	warning
					break;
				end;
			end;

			--	report success...
			if @result = 0 and len(@detail) = 0
			begin
				--	set the success message...	
				select	@detail	= '<p>The monthly Texans Financial extracts for '
								+ datename(month, dt.LastMonth) + ' ' + cast(year(dt.LastMonth) as varchar)
								+ ' have completed and may be retrieved from the <a href="'+ @sqlFolder
								+ '">Texans Financial</a> folder.</p>'
					,	@result	= 0
				from	( select LastMonth = dateadd(month, -1, getdate()) ) dt;
			end;
		end;
		else
		begin
			--	report as a failure...
			set @result = 1;	--	failure
		end;
	end;
end try
begin catch
	exec tcu.ErrorDetail_get @detail out;
	set	@result = 1;	--	failure
end catch;

--	record the results...
if @result != 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
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