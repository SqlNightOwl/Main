use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[UsageReport_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[UsageReport_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.UsageReport_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/14/2008
Purpose  :	Process that loads the ActiveUser and BoardReport monthly files from
			the Voyager IHB system.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archCmd	nvarchar(255)
,	@archFile	varchar(255)
,	@archPeriod	char(9)
,	@fileName	varchar(50)
,	@detail		varchar(4000)
,	@period		int
,	@result		int

set @result	= 0;

--	reload the Active Users
truncate table ihb.ActiveUser;

insert	ihb.ActiveUser
	(	Period
	,	MemberNumber
	,	UserId
	,	LastSuccessfulLogin
	,	FirstName
	,	LastName
	,	TaxId
	,	EMail
	,	DayPhone
	,	EvePhone
	,	EnrolledOn
	,	BillPayEnrolledOn
	,	LastUpdateOn
	,	BillPayFeeAccountType
	,	ServiceType
	,	FromAccountId
	,	FromHostAccount1
	,	PaymentCount
	,	PaymentAmount
	,	FailedCount
	,	FailedAmount
	,	MaxProcessOn
	,	TransferCount
	,	TransferAmount
	,	NumberOfSignOns
	,	LastBillPayOn
	)
select	distinct
		CurrentPeriod
	,	cast(AuthRelationshipName as bigint)
	,	UserId
	,	DateLastSuccessfulLogin
	,	FirstName
	,	LastName
	,	TaxId
	,	EMail
	,	DayPhone
	,	EvePhone
	,	DateEnrolled
	,	DateBillPayEnrolled
	,	DateLastUpdated
	,	BillPayFeeAccountType
	,	ServiceType
	,	FromAccountId
	,	FromHostAccount1
	,	PaidCount
	,	PaidAmount
	,	FailedCount
	,	FailedAmount
	,	MaxProcessDate
	,	TransferCount
	,	TransferAmount
	,	NumberOfSignOns
	,	LastBillPayOn
from	VOYAGER.tcu_Workspace.dbo.rptActiveUser_v n
where	isnumeric(AuthRelationshipName) = 1
and		len(AuthRelationshipName)		< 18
order by cast(AuthRelationshipName as bigint);

set	@result = @@error;

--	add the new board report statistics...
insert	ihb.BoardReport
	(	Period
	,	ActiveUsers
	,	BusinessUsers
	,	ActiveUsersLast90Days
	,	BusinessUsersLast90Days
	,	BillPayUsers
	)
select	n.Period
	,	n.ActiveUsers
	,	n.BusinessUsers
	,	n.ActiveUsers_Last90Days
	,	n.BusinessUsers_Last90Days
	,	n.BillPayUsers
from	VOYAGER.tcu_Workspace.dbo.BoardUsageCounts_v n
left join
		ihb.BoardReport l
		on	n.Period = l.Period
where	l.Period	is null
and		@result		= 0;

--	send the usage reports...
if	@@rowcount	> 0
and	@result		= 0
begin
	exec @result = ihb.UsageReport_send @ProcessId;
end;

PROC_EXIT:
if @result != 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= null
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