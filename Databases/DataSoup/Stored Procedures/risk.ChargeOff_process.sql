use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOff_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ChargeOff_process]
GO
setuser N'risk'
GO
CREATE procedure risk.ChargeOff_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/21/2009
Purpose  :	Loads the board approved Charge Off list of accounts, produces and
			OSI update script, archives the source file & update script.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/05/2010	Paul Hunter		Added SPSA Minor Type as one of the "membership share"
							account types.
02/23/2010	Paul Hunter		Added dynamic query for the charge off and joint
							owner lookups.  Moved the D/L update to the update
							from the account table.  Added additional reasons and
							instructions to the error/exception message.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@cmd		nvarchar(max)
,	@detail		varchar(4000)
,	@exportFile	varchar(255)
,	@lastDate	varchar(10)
,	@list		varchar(max)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the working variables...
select	@actionCmd	= db_name() + '.risk.ChargeOff'
	,	@sqlFolder	= p.SQLFolder
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@switches	= '-f"' + p.SQLFolder + p.FormatFile + '" -T'
	,	@exportFile	= p.SQLFolder + f.TargetFile
	,	@detail		= ''
	,	@list		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

begin try
	--	if the file exists then load it...
	if tcu.fn_FileExists(@actionFile) = 1
	begin
		--	initialize the last date loans were charged off...
		select	@lastDate = convert(varchar(10), isnull(max(ChargeOffOn), 0), 121)
		from	risk.ChargeOff;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail out;

		--	no errors so proceed...
		if @result = 0 and len(@detail) = 0
		begin
			--	continue if there are loans that haven't been charged off...
			if exists (	select	top 1 AccountNumber from risk.ChargeOff
						where	ChargeOffOn	> cast(@lastDate as datetime)	)
			begin
				--	get the "new" ChargeOff date...
				select	@lastDate = convert(varchar(10), max(ChargeOffOn), 121)
				from	risk.ChargeOff;

				--	archive the file...
				exec tcu.File_archive	@action			= 'move'
									,	@sourceFile		= @actionFile
									,	@archiveDate	= @lastDate
									,	@detail			= @detail out
									,	@addDate		= 1
									,	@overWrite		= 1;

				--	remove any commercial loans...
				delete	risk.ChargeOff
				where	MajorCd		= 'CML'
				and		ChargeOffOn	= cast(@lastDate as datetime);

				--	make sure there's something in the ARFS column
				update	risk.ChargeOff
				set		ARFS		= ''
				where	ARFS		is null
				and		ChargeOffOn	= cast(@lastDate as datetime);

				--	build the list of the account that are being charged off...
				select	@list	= isnull(@list, cast(AccountNumber as varchar(22)))
								+ ',' + cast(AccountNumber as varchar(22))
				from	risk.ChargeOff
				where	ChargeOffOn	= cast(@lastDate as datetime);

				--	create the account temp table...
				select	top 0
						AccountNumber
					,	MajorCd
					,	MinorCd
					,	ShareAccount
					,	OwnerNumber
					,	OwnerCd
				into	#accounts
				from	risk.ChargeOff;

				--	load the temp table of accounts, share accounts and owner information...
				set	@cmd = '
				insert	#accounts
				select	*
				from	openquery(OSI, ''
						select	/*+CHOOSE*/
								c.AcctNbr
							,	c.MjAcctTypCd
							,	c.CurrMiAcctTypCd
							,	s.AcctNbr				as ShareAcctNbr
							,	nvl(s.TaxRptForPersNbr,
									s.TaxRptForOrgNbr)	as OwnerNbr
							,	case nvl(s.TaxRptForPersNbr, 0)
								when s.TaxRptForPersNbr then ''''P''''
								else ''''O'''' end		as OwnerCd
						from	osiBank.Acct c
						join	osiBank.Acct s
								on	nvl(c.TaxRptForPersNbr, 0) = nvl(s.TaxRptForPersNbr, 0)
								and	nvl(c.TaxRptForOrgNbr , 0) = nvl(s.TaxRptForOrgNbr , 0)
						where	c.AcctNbr in (' + @list + ')
						and		s.MjAcctTypCd		= ''''SAV''''
						and		s.CurrAcctStatCd	!= ''''CLS''''
						and		s.CurrMiAcctTypCd	in (''''BSHS'''',''''CSHS'''', ''''SPSA'''')'');'

				--	execute the command...
				exec sp_executesql @cmd;

				--	match accounts to the membership share account...
				update	c
				set		ShareAccount	= isnull(a.ShareAccount	, 0)
					,	MajorCd			= isnull(a.MajorCd		, '?')
					,	MinorCd			= isnull(a.MinorCd		, c.MinorCd)
					,	OwnerNumber		= isnull(a.OwnerNumber	, 0)
					,	OwnerCd			= isnull(a.OwnerCd		, 'X')
										--	the default account type is L (loan) so change CK & SAV to D (deposit)
					,	AccountType		= case when a.MajorCd in ('CK','SAV') then 'D' else 'L' end
				from	risk.ChargeOff	c
				left join
						#accounts		a
						on	c.AccountNumber = a.AccountNumber
				where	c.ChargeOffOn = cast(@lastDate as datetime);

				--	drop the temp table...
				drop table #accounts;

				--	rebuild the joint owners table...
				truncate table risk.ChargeOffJointOwner;
				alter index all on risk.ChargeOffJointOwner rebuild;

				--	add the share accounts to the existing list of accounts...
				select	@list = @list + ',' + cast(ShareAccount as varchar(22))
				from	risk.ChargeOff
				where	ChargeOffOn		= cast(@lastDate as datetime)
				and		ShareAccount	> 0;

				--	load the joint owner for any of the listed accounts...
				set @cmd = '
				insert	risk.ChargeOffJointOwner
				select	distinct AcctNbr, PersNbr
				from	openquery(OSI, ''
						select	/*+CHOOSE*/
								AcctNbr, PersNbr
						from	AcctAcctRolePers
						where	AcctNbr			in (' + @list + ')
						and		AcctRoleCd		in (''''OWN'''',''''SIGN'''')
						and (	InactiveDate	is null
							or	InactiveDate	< trunc(sysdate) )
						group by AcctNbr, PersNbr'');'

				exec sp_executesql @cmd;

				if exists (	select	top 1 AccountNumber from risk.ChargeOff
							where	ChargeOffOn = cast(@lastDate as datetime)	)
				begin
					--	set the variables to produce the OSI update scripts...
					select	@actionCmd	= 'select Script from ' + db_name() + '.risk.ChargeOff_vScript '
										+ 'where ChargeOffOn = (select max(ChargeOffOn) from '
										+ db_name() + '.risk.ChargeOff) ' 
										+ 'order by ShareAccount, AccountNumber, StatementLine'
						,	@actionFile	= @exportFile
						,	@switches	= '-c -T';

					--	export the OSI update script...
					exec @result = tcu.File_bcp	@action		= 'queryout'
											,	@actionCmd	= @actionCmd
											,	@actionFile	= @actionFile
											,	@switches	= @switches
											,	@output		= @detail out;	

					--	archive the OSI update script...
					exec tcu.File_archive	@action			= 'copy'
										,	@sourceFile		= @actionFile
										,	@archiveDate	= @lastDate
										,	@detail			= @detail out
										,	@addDate		= 1
										,	@overWrite		= 1;

					--	build the message if no errors...
					if @result = 0 and len(@detail) = 0
					begin
						--	report if there are any accounts that couldn't be matched...
						select	@detail = @detail + '<li>' + cast(AccountNumber as varchar(22)) + ' - '
										+ case MajorCd when '?' then 'charge off' else 'share' end + ' acct not found'
						from	risk.ChargeOff
						where(	ShareAccount	= 0
							or	MajorCd			= '?' )
						and		ChargeOffOn		= cast(@lastDate as datetime);

						--	set the result and build the return message....
						select	@result	=	case len(@detail) when 0 then 0 else 2 end	--	success or information
							,	@detail	=	'<p>The subject process has completed and an OSI update script is available'
										+	' in the <a href="' + @sqlFolder +'">working folder</a>.</p>'
										+	case len(@detail)
											when 0 then ''
											else '<p>Either a Share Account could not be found <b>- OR -</b> the '
												+ 'Chage Off Account could not be found for the accounts listed below:<ul>'
												+ @detail + '</ul>Do not run the update script until these errors have been rectified.</p>'
											end;
					end;
				end;
			end;
		end;	--	records loaded
		else
		begin
			set @result = 1;	--	failure
		end;	--	
	end;		--	file exists
end try
begin catch
	--	catch any unhandled exceptions...
	exec tcu.ErrorDetail_get @detail out;
	set	@result = 1;	--	failure
end catch;

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