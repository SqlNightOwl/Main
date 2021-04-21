use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[VINtek_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[VINtek_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.VINtek_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/06/2010
Purpose  :	Process to handle updating and extracting title liens for vehicles
			to be sent to VINtek.
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
,	@fileName	sysname
,	@ftpFolder	varchar(255)
,	@result		int
,	@today		datetime

declare @persons	table
	(	PersNbr		int			primary key
	,	Person		varchar(45)	not null
	);

--	initialize a the result and today variables...
select	@result	= 0
	,	@today	= convert(char(10), getdate(), 121);

if not exists (	select	top 1 * from lnd.VINtek
				where	LoadedOn = @today )
begin
	begin try
		--	add loans from "yesterday" controlled in the OSI view...
		exec lnd.VINtek_sav;

		--	retrieve all person records updated yesterday...
		insert	@persons
		select	*
		from	openquery(OSI, '
				select	PersNbr
					,	LastName	||'', ''|| 
						FirstName	||
						case
						when MdlInit is null then null
						else '' ''|| MdlInit ||''.''
						end		as Person
				from	Pers
				where	trunc(DateLastMaint) = trunc(sysdate) - 1'
			)

		--	update if the borrower name has changed...
		update	v
		set		RecordType	= 'U'
			,	Borrower	= p.Person
			,	UpdatedOn	= @today
		from	lnd.VINtek	v
		join	@persons	p
				on	v.BorrowerNbr = p.PersNbr
		where	v.Borrower != p.Person;

		--	update if the coborrower name has changed...
		update	v
		set		RecordType	= 'U'
			,	Borrower	= p.Person
			,	UpdatedOn	= @today
		from	lnd.VINtek	v
		join	@persons	p
				on	v.CoBorrowerNbr = p.PersNbr
		where	v.CoBorrower != p.Person;

		/*
		**	Procedure to handle refinanced loans:
		**	1)	update "Existing" record with the new account number
		**	2)	remove "Add" record...
		*/
		--	1)	update "Existing" record with the new account number
		update	e
		set		RecordType	= 'U'
			,	ETLAction	= null
			,	NewAcctNbr	= a.AcctNbr
			,	UpdatedOn	= @today
		from	lnd.VINtek	e	
		join(	select	PropId from lnd.VINtek
				where	LoadedOn = @today
				group by PropId
				having count(1) > 1	)	d
				on	e.PropId		= d.PropId
				and	e.RecordType	= 'E'
		join	lnd.VINtek	a
				on	a.PropId		= d.PropId
				and	a.RecordType	= 'A'
		where	e.LoadedOn		= @today;

		--	2)	remove "Add" record...
		delete	lnd.VINtek
		where	PropId		in(	select	PropId from lnd.VINtek
								where	LoadedOn = @today
								group by PropId having count(1) > 1	)
		and		LoadedOn	= @today
		and		RecordType	= 'A';

		--	update VINtek if the primary addresses changes...
		update	v
		set		RecordType			= 'U'
			,	AddressUpdatedOn	= o.DateLastMaint
			,	Address1			= o.Address1
			,	Address2			= o.Address2
			,	City				= o.CityName
			,	StateCd				= o.StateCd
			,	ZipCd				= o.ZipCd
			,	UpdatedOn			= @today
		from	lnd.VINtek	v
		join	openquery(OSI, '
				select	a.AcctNbr
					,	ca.AddrNbr
					,	ca.Address1
					,	ca.Address2
					,	ca.CityName
					,	ca.StateCd
					,	ca.ZipCd || ZipSuf as ZipCd
					,	ca.DateLastMaint
				from	Acct				a
				join	CustomerAddress_vw	ca
						on	ca.PersNbr		= a.TaxRptForPersNbr
						and ca.AddrUseCd	= ''PRI''
				where	a.MjAcctTypCd		= ''CNS''
				and		ca.DateLastMaint	> trunc(sysdate) - 1'
				)	o	on	isnull(v.NewAcctNbr, v.AcctNbr) = o.AddrNbr
		where(	v.AddrNbr			!=	o.AddrNbr
			or	v.AddressUpdatedOn	<	o.DateLastMaint	);

		--	setup the BCP export command variables...	
		select	@actionCmd	= db_name() + '.' + f.FileName
			,	@actionFile	= p.FTPFolder + replace(f.TargetFile, '[DATE]', convert(char(8), @today, 112))
			,	@fileName	= replace(f.TargetFile, '[DATE]', convert(char(8), @today, 112))
			,	@ftpFolder	= p.FTPFolder
			,	@detail		= ''
			,	@result	= 0
		from	tcu.ProcessFile			f
		join	tcu.ProcessParameter_v	p
				on	f.ProcessId = p.ProcessId
		where	f.ProcessId	= @ProcessId;

		--	export the file...
		exec @result = tcu.File_bcp	@action		= 'out'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -T'
								,	@output		= @detail out;
		--	report any errors...
		if len(@detail) = 0 and @result = 0
		begin
			--	collect any exceptions...
			select	@detail = @detail
							+ '<tr><td>'	+ cast(AcctNbr as varchar(22))
							+ '</td><td>'	+ PropId
							+ '</td><td>'	+ rtrim(PropYear)
							+ '</td><td>'	+ Address1
							+ '</td><td>'	+ City
							+ '</td><td>'	+ StateCd
							+ '</td></tr>'
			from	lnd.VINtek
			where (	LoadedOn	= @today
				or	UpdatedOn	= @today )
			and	(	PropId		= 'MISSING'
				or	PropYear	= 'OOOO'
				or	Address1	= 'MISSING'
				or	City		= 'MISSING'
				or	StateCd		= 'XX'
				or	AddrNbr		= 0	);

			--	build the rest of the table if any records were returned...
			if @@rowcount > 0
			begin
				set	@detail	= '<p>The exceptions listed below were encountered with the data:<table width="100%" cellpadding="3">'
							+ '<tr><td>Account</td><td>Property Id</td><td>Year</td><td>Address</td><td>City</td><td>State</td></tr>'
							+ @detail + '</table></p>';
			end;

			select	@detail	= 'The subject file ' + @fileName
							+ ' has been produced and is available in the <a href="' 
							+ @ftpFolder + '">VINtek folder</a>.' + @detail
				,	@result	= 2;	--	information...
		end;
		else
		begin
			set	@result = 1;	--	failure
		end;
	end try
	begin catch
		exec tcu.ErrorDetail_get @detail output;
		set	@result = 1;	--	failure
	end catch;

end;
else
begin
	--	indicate that the process has already run...
	select	@actionCmd	= schema_name(schema_id) + '.' + object_name(object_id)
		,	@detail		= 'The subject process has already been run today.'
		,	@result		= 0	--	success...
	from	sys.procedures
	where	[object_id] = @@procId;
end;

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