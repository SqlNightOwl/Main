use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ncrRemoteCapture_savSWIM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ncrRemoteCapture_savSWIM]
GO
setuser N'osi'
GO
CREATE procedure osi.ncrRemoteCapture_savSWIM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/02/2007
Purpose  :	Creates the Process SWIM Detail records with the just loaded Remote
			Capture file and exports the SWIM file for loading into OSI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/10/2007	Paul Hunter		Added the GLOffset transaciton to the detail table.
01/14/2008	Paul Hunter		Changed logic to incorporate individual Merchants
							that have a specific ClearingCategoryCode, the Fed
							District of the Merchant and the age of the Merchants
							account.
03/03/2008	Paul Hunter		Removed the Fund Type and Fund Detail Type codes from
							the update code that had been added on Jan 14th.
07/02/2008	Paul Hunter		Changed to use the Merchant deposit records as the
							source for the SWIM file.
07/22/2008	Paul Hunter		Added Item counts to the SWIM Detail.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@CreatedBy		varchar(25)
,	@CreatedOn		datetime
,	@effectiveOn	datetime
,	@openedBefore	datetime
,	@procName		varchar(255)
,	@result			int;

--	initialize the effective date, date the
select	@CreatedBy		= tcu.fn_UserAudit()
	,	@CreatedOn		= getdate()
	,	@effectiveOn	= convert(char(10), getdate(), 121)
	,	@result			= 0;

if exists (	select	top 1 RunId from osi.ncrRemoteCapture
			where	RunId			= @RunId
			and		ProcessStatus	= 'Loaded'	)
begin
	--	load the each of the Merchant Deposits
	insert	tcu.ProcessSwimDetail
		(	RunId
		,	ProcessId
		,	EffectiveOn
		,	AccountNumber
		,	Amount
		,	Items
		,	IsComplete
		,	CreatedBy
		,	CreatedOn	)
	select	@RunId
		,	@ProcessId
		,	@effectiveOn
		,	src.DepositAccount
		,	sum(src.Amount)
		,	count(1)	--	Items
		,	0			--	IsComplete
		,	@CreatedBy
		,	@CreatedOn
	from	osi.ncrRemoteCapture	src
	join(	--	aggregate items by merchant deposit
			select	s.AccountNumber
				,	StartId	= s.RemoteCaptureId
				,	EndId	= (	select	min(RemoteCaptureId)
								from	osi.ncrRemoteCapture
								where	RunId			= s.RunId
								and		RemoteCaptureId	> s.RemoteCaptureId
								and		TransactionType = 'C'	)
			from	osi.ncrRemoteCapture	s
			where	s.RunId				= @RunId
			and		s.TransactionType	= 'C'
		)	dep	on	src.DepositAccount	= dep.AccountNumber
				and	src.RemoteCaptureId	between	dep.StartId 
										and		isnull(dep.EndId, src.RemoteCaptureId)
	where	src.RunId			= @RunId
	and		src.TransactionType	= 'D'
	group by src.DepositAccount, dep.StartId;

	--	create a GL Offset and SWIM file if records were inserted...
	if @@rowcount > 0
	begin
		--	create the GL offset record
		insert	tcu.ProcessSwimDetail
			(	RunId
			,	ProcessId
			,	EffectiveOn
			,	AccountNumber
			,	Amount
			,	Items
			,	TransactionCd
			,	TransactionDescription
			,	ClearingCategoryCd
			,	IsComplete
			,	CreatedBy
			,	CreatedOn	)
		select	@RunId
			,	@ProcessId
			,	@effectiveOn
			,	ps.GLOffsetAccount
			,	rc.Amount
			,	rc.Items
			,	ps.GLOffsetTransactionCd
			,	ps.GLOffsetDescription
			,	ps.ClearingCategoryCd
			,	IsComplete	= 0
			,	CreatedBy	= @CreatedBy
			,	CreatedOn	= @CreatedOn
		from	tcu.ProcessSwim		ps
		cross join
			(	--	calculate the total Amount loaded in the step above
				select	Amount	= sum(Amount)
					,	Items	= sum(Items)
				from	tcu.ProcessSwimDetail
				where	RunId		= @RunId
				and		ProcessId	= @ProcessId
			)	rc
		where	ps.ProcessId		= @ProcessId
		and		ps.GLOffsetAccount	> 0;

		--	export the SWIM file
		exec @result = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
														,	@ProcessId	= @ProcessId
														,	@ScheduleId	= @ScheduleId;

		--	update the RemoteCapture data if the swim file was sucessfully created
		if @result = 0
		begin
			--	consider the request as "complete" if the run is found in the detail table
			update	rc
			set		ProcessStatus =	case sd.IsComplete
									when 1 then 'Completed'
									else 'ERROR' end
			from	osi.ncrRemoteCapture	rc
			join	tcu.ProcessSwimDetail	sd
					on	rc.RunId	= sd.RunId
			where	rc.RunId		= @RunId
			and		sd.ProcessId	= @ProcessId;
		end;
	end;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO