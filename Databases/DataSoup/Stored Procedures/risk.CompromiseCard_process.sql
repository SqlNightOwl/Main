use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[CompromiseCard_process]
GO
setuser N'risk'
GO
CREATE procedure risk.CompromiseCard_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/16/2009
Purpose  :	Loads the Compromised Card file into the table and exports the status
			for matching cards.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@error		int
,	@fileId		int
,	@fileName	varchar(255)
,	@message	varchar(4000)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the process parameters
select	@actionCmd	= db_name() + '.' + f.TargetFile
	,	@sqlFolder	= p.SQLFolder
	,	@fileName	= f.FileName
	,	@switches	= '-T -f"' + p.SQLFolder + p.FormatFile + '"'
	,	@detail		= ''
	,	@error		= 0
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId
and		f.ApplName	= 'Source';

--	clear old data...
truncate table risk.CompromiseCard_load;

--	search for files...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load any files that were found...
while exists (	select	top 1 FileId, FileName
				from	tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin
	--	get the next file...
	select	top 1
			@fileId		= FileId
		,	@actionFile	= @sqlFolder + FileName
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;

	--	keep a running error number...
	set @error = isnull(nullif(@result, 0), @@error);

	if @result = 0 and len(@detail) = 0
	begin
		--	delete the source file...
		exec @result = tcu.File_action	@action		= 'eras'	--	delete the file
									,	@sourceFile	= @actionFile
									,	@targetFile	= null
									,	@overWrite	= 0
									,	@output		= @detail output;
	end;
	else
	begin
		set	@error		= 1;	--	failure
		set	@fileName	= @actionFile + '.error';
		set	@message	= @detail + '<br/>' + @fileName;
		set	@detail		= '';

		--	rename the the file to prevent secondary loading...
		exec @result = tcu.File_action	@action		= 'move'	--	rename file
									,	@sourceFile	= @actionFile
									,	@targetFile	= @fileName
									,	@overWrite	= 0
									,	@output		= @detail output;
	end;
end;	--	end file loading

--	process the loaded files...
if exists (	select top 1 * from risk.CompromiseCard_load )
and	@error = 0
begin
	--	clean up the alert description
	update	risk.CompromiseCard_load
	set		Alert = left(Alert, charindex(' ', Alert) - 1);

	--	create new compromise group if they don't exist...
	insert	risk.Compromise
		(	CompromisePrefix
		,	Compromise
		,	ReceivedOn
		)
	select	distinct
			substring(l.Alert, 1, 15)
		,	l.Alert
		,	convert(char(10), getdate(), 121)
	from	risk.CompromiseCard_load	l
	left join
			risk.Compromise				c
			on	l.Alert = c.CompromisePrefix
	where	c.CompromisePrefix is null;

	--	update the Alerts with the CompromiseId
	update	l
	set		CompromiseId = c.CompromiseId
	from	risk.CompromiseCard_load	l
	join	risk.Compromise				c
			on	l.Alert = c.Compromise;

	--	add the Alerts...
	insert	risk.CompromiseAlert
		(	Alert
		,	CompromiseId
		,	LoadedOn
		)
	select	distinct
			l.Alert
		,	l.CompromiseId
		,	convert(char(10), getdate(), 121)
	from	risk.CompromiseCard_load	l
	left join
			risk.CompromiseAlert		a
			on	l.Alert	= a.Alert
	where	a.Alert is null;

	--	collect the Alert Id's from the Alerts just added...
	update	l
	set		AlertId	= a.AlertId
	from	risk.CompromiseCard_load	l
	join	risk.CompromiseAlert		a
			on	l.Alert = a.Alert;

	--	create a table to hold card & agreement numbers
	select	cast(ExtCardNbr as char(16))	as ExtCardNbr 
		,	cast(AgreeNbr as int)			as AgreeNbr
	into	#agreements
	from	openquery(OSI, '
			select	ExtCardNbr, AgreeNbr
			from	CardAgreement
			where	AgreeTypCd	< ''VRU''')

	--	add all new Cards to the table...
	insert	risk.CompromiseCard
		(	AlertId
		,	CardNumber
		,	AgreeId
		,	IsInitialReport
		,	InitialAlertId
		)
	select	distinct
			l.AlertId
		,	l.CardNumber
		,	isnull(o.AgreeNbr, 0)
		,	1			--	assume this is the initial report...
		,	l.AlertId	--	and that this is the initial alert...
	from	risk.CompromiseCard_load	l
	left join	risk.CompromiseCard		c
			on	l.AlertId		= c.AlertId
			and	l.CardNumber	= c.CardNumber
			--	insert every card and all matching agreements
	left join	#agreements				o
			on	l.CardNumber = o.ExtCardNbr
	where	c.CardNumber is null
	order by
			l.AlertId
		,	l.CardNumber;

	drop table #agreements;

	--	update the alert with the unique number of cards loaded...
	update	a
	set		NumberOfCards	= c.Cards
		,	UpdatedBy		= a.UpdatedBy
		,	UpdatedOn		= a.UpdatedOn
	from	risk.CompromiseAlert	a
	join(	select	AlertId, count(distinct CardNumber) as Cards
			from	risk.CompromiseCard_load
			group by AlertId
		)	c	on	a.AlertId = c.AlertId;

	--	update cards in this alert that have been reported in another compromises/alerts...
	update	c
	set		IsInitialReport	= 0
		,	InitialAlertId	= ir.AlertId
		,	Comments		= 'Initially report on ' + ic.Compromise
							+ ' compromise in alert ' + ia.Alert + '.' 
		,	UpdatedBy		= c.UpdatedBy
		,	UpdatedOn		= c.UpdatedOn
	from	risk.CompromiseCard			c
	join	risk.CompromiseCard_load	l
			on	c.AlertId = l.AlertId
	join(	--	collect the initial report of each card/agreement within each compromise/alert
			select	min(a.AlertId) as AlertId	--	initial alert for this card
				,	c.CardNumber
				,	c.AgreeId
			from	risk.CompromiseAlert	a
			join	risk.CompromiseCard		c
					on	a.AlertId = c.AlertId
			where	c.AgreeId > 0
			group by c.CardNumber, c.AgreeId
		)	ir
			on	c.CardNumber =	ir.CardNumber
	join	risk.CompromiseAlert	ia	--	initial alert
			on	ir.AlertId = ia.AlertId
	join	risk.Compromise			ic	--	initial compromise
			on	ia.CompromiseId = ic.CompromiseId
	where	c.AlertId			!= ir.AlertId
	and		c.IsInitialReport	= 1;

	--	build a temp table of card owner details...
	select	distinct
			c.CardId
		,	o.OwnerType
		,	o.OwnerId
		,	o.AgreeNbr
		,	o.AgreeTypCd
		,	Owner			= isnull(o.Owner			, c.Owner)			--	pickup the default value
		,	MemberNumber	= isnull(o.MemberAgreeNbr	, c.MemberNumber)	--	pickup the default value
		,	Member			= isnull(o.Member			, c.Member)			--	pickup the default value
		,	MemberGroup		= isnull(o.MemberGroupCd	, c.MemberGroup)	--	pickup the default value
		,	o.DateLastTran
	into	#cardOwners
	from	risk.CompromiseCard			c
	join	risk.CompromiseCard_load	l
			on	c.AlertId = l.AlertId
	join	risk.CompromiseCard_vOwner	o
			on	c.CardNumber	= o.ExtCardNbr
			and	c.AgreeId		= o.AgreeNbr;

	--	extract/update the Card Agreement & Owner/Customer and Member information...
	update	c
	set		OwnerType		= o.OwnerType
		,	OwnerId			= o.OwnerId
		,	AgreeId			= o.AgreeNbr
		,	AgreeTypeCode	= o.AgreeTypCd
		,	Owner			= isnull(o.Owner		, c.Owner)			--	pickup the default value
		,	MemberNumber	= isnull(o.MemberNumber	, c.MemberNumber)	--	pickup the default value
		,	Member			= isnull(o.Member		, c.Member)			--	pickup the default value
		,	MemberGroup		= isnull(o.MemberGroup	, c.MemberGroup)	--	pickup the default value
		,	LastUsedOn		= o.DateLastTran
		,	UpdatedBy		= c.UpdatedBy
		,	UpdatedOn		= c.UpdatedOn
	from	risk.CompromiseCard	c
	join	#cardOwners			o
			on	c.CardId = o.CardId;

	--	drop the temp card owner table...
	drop table #cardOwners;

	--	collect the cardholder informaiton from OSI
	select	*
	into	#cardHolders
	from	risk.CompromiseCard_vHolder;

	--	add	the Card Holder information...
	insert	risk.CompromiseCardHolder
		(	CardId
		,	AgreeId
		,	HolderId
		,	IssueId
		,	CardHolderNbr
		,	CardHolder
		,	StatusCode
		,	IssuedOn
		,	ExpiresOn
		,	Address1
		,	Address2
		,	City
		,	State
		,	ZipCode
		,	Phone
		,	Mobile
		)
	select	distinct
			c.CardId
		,	c.AgreeId
		,	HolderId		= isnull(h.MemberNbr, 0) 
		,	IssueId			= isnull(h.IssueNbr	, 0) 
		,	CardHolderNbr	= isnull(h.PersNbr	, 0)
		,	CardHolder		= isnull(h.CardHolder, 'Not Found')
		,	h.CurrStatusCd
		,	h.IssueDate
		,	h.ExpireDate
		,	h.Address1
		,	h.Address2
		,	h.City
		,	h.State
		,	h.ZipCode
		,	h.Phone
		,	h.Mobile
	from	risk.CompromiseCard				c
	join	risk.CompromiseCard_load		l
			on	c.AlertId = l.AlertId
	left join
			#cardHolders					h
			on	c.AgreeId = h.AgreeNbr
	left join	risk.CompromiseCardHolder	ch
			on	ch.CardId	= c.CardId
			and	ch.HolderId	= isnull(h.MemberNbr, 0)
	where	ch.CardId is null;

	--	drop the card holder information...
	drop table #cardHolders;

	--	update the card with the "primary" card holder
	update	c
	set		PrimaryHolderId		= h.HolderId
		,	OSIStatusCode		= h.StatusCode
		,	InitialStatusCode	= h.StatusCode
		,	UpdatedBy			= c.UpdatedBy
		,	UpdatedOn			= c.UpdatedOn
	from	risk.CompromiseCard			c
	join	risk.CompromiseCard_load	l
			on	c.AlertId = l.AlertId
	join(	select	h.CardId
				,	min(h.HolderId) as HolderId	--	use the lowest MemberNbr from the CardMember table
			from	risk.CompromiseCard			c
			join	risk.CompromiseCard_load	a
					on	c.AlertId = a.AlertId
			join	risk.CompromiseCardHolder	h
					on	c.AgreeId = h.AgreeId
			where	h.HolderId > 0
			group by h.CardId
		)	p	on	c.CardId = p.CardId
	join	risk.CompromiseCardHolder	h
			on	p.CardId	= h.CardId
			and	p.HolderId	= h.HolderId;

	--	collect the details for the outbound email...
	set	@message	= tcu.fn_ProcessParameter(@ProcessId, 'Message Body');
	set	@detail		= '';

	select	@detail = @detail
		+	'<tr><td class="txt">'	+ l.Alert
		+	'</td><td>'	+ cast(count(distinct c.CardNumber) as varchar(10))
		+	'</td><td>'	+ cast(count(c.CardId) as varchar(10))
		+	'</td><td>'	+ cast(sum(cast(c.IsInitialReport as int)) as varchar(10))
		+	'</td><td>'	+ cast(sum(case when c.OSIStatusCode in ('ACT','ISS') then 1 else 0 end) as varchar(10))
		+	'</td></tr>'
		,	@result		= 2	--	informational message
	from	risk.CompromiseCard_load	l
	join	risk.CompromiseCard			c
			on	l.AlertId		= c.AlertId
			and	l.CardNumber	= c.CardNumber
	join	risk.CompromiseCardHolder	h
			on	c.CardId = h.CardId
	group by l.Alert
	order by l.Alert;

	--	wrap the results in a table
	set	@detail = '<table><tr><th>Alert'
				+ '</th><th>Unique<br>Cards'
				+ '</th><th>Card<br>Holders'
				+ '</th><th>New<br>Reports'
				+ '</th><th>Active &amp;<br/>Issued'
				+ '</th></tr>' + @detail + '</table>';

	set	@detail	= replace(@message, '#DETAIL#', @detail);

end;	--	card loaded routine...

--	get the ending result of all actions...
set	@result = isnull(nullif(@error, 0), @result);

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