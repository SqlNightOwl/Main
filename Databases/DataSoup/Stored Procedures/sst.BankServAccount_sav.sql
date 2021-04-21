use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[BankServAccount_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[BankServAccount_sav]
GO
setuser N'sst'
GO
CREATE procedure sst.BankServAccount_sav
	@overRide	bit		= 0
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/03/2007
Purpose  :	Loads the BankServ_GFX from table prior to exporting for BankServ.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@lastRun	varchar(255)
,	@return		int;

set	@lastRun = tcu.fn_Dictionary('BankServ', 'GFX Last Run');

if datediff(day, @lastRun, getdate()) > 0
or @overRide = 1
begin

	truncate table sst.bankservaccount;

	--	perform the initial data load...
	insert	sst.BankServAccount
		(	OsiCustomerId
		,	OsiCustomerType
		,	AccountNumber
		,	Institution
		,	AccountName1
		,	AccountName2
		,	CustomerId
		,	AccountType
		,	AnalyzedFlag
		,	HoldFlag
		,	FrozenFlag
		,	LockedFlag
		,	AccountBalance
		)
	select	isnull(CustomerId		, 0)
		,	isnull(CustomerType		, '')
		,	isnull(AccountNumber	, 0)
		,	isnull(Institution		, '01')
		,	isnull(AccountName1		, '')
		,	isnull(AccountName2		, '')
		,	isnull(MemberNumber		, 0)
		,	isnull(AccountType		, '')
		,	isnull(AnalyzedFlag		, 'N')
		,	isnull(HoldFlag			, 'N')
		,	isnull(FrozenFlag		, 'N')
		,	isnull(LockedFlag		, 0)
		,	isnull(AccountBalance	, 0)
	from	openquery(OSI, '
			select	CustomerId
				,	CustomerType
				,	AccountNumber
				,	Institution
				,	AccountName1
				,	AccountName2
				,	MemberNumber
				,	AccountType
				,	AnalyzedFlag
				,	HoldFlag
				,	FrozenFlag
				,	LockedFlag
				,	AccountBalance
			from	texans.BankServ_Acct_GFX_vw');

	--	update the Address information
	update	bsa
	set		AddressLine1	= left(isnull(ca.Address1, ''), 35)
		,	AddressLine2	= left(isnull(ca.Address2, ''), 35)
		,	CityName		= left(isnull(ca.CityName, ''), 25)
		,	StateCode		= left(isnull(ca.StateCd,  ''),  2)
		,	ZipCode			= left(isnull(ca.ZipCd, '') + isnull(ca.ZipSuf, ''), 9)
	from	sst.BankServAccount	bsa
	join	openquery(OSI, '
			select	CustomerId
				,	CustomerType
				,	Address1
				,	Address2
				,	CityName
				,	StateCd
				,	ZipCd
				,	ZipSuf
			from	texans.CustomerAddress_vw
			where	AddrUseCd = ''PRI'''
		)	ca	on	ca.CustomerId	= bsa.OsiCustomerId
				and	ca.CustomerType	= bsa.OsiCustomerType;

	--	update the Email Address information
	update	bsa
	set		Email = isnull(lower(left(isnull(ca.Address1, ''), 40)), '')
	from	sst.BankServAccount	bsa
	join	openquery(OSI, '
			select	CustomerId
				,	CustomerType
				,	Address1
			from	texans.CustomerAddress_vw
			where	AddrUseCd	= ''EML'''
		)	ca	on	ca.CustomerId	= bsa.OsiCustomerId
				and	ca.CustomerType	= bsa.OsiCustomerType;

	--	update the phone number
	update	bsa
	set		Phone	= isnull(cp.AreaCd	, '   ') + '-'
					+ isnull(cp.Exchange, '   ') + '-'
					+ isnull(cp.PhoneNbr, '    ')
	from	sst.BankServAccount	bsa
	join	openquery(OSI, '
			select	CustomerId
				,	CustomerType
				,	AreaCd
				,	Exchange
				,	PhoneNbr
			from	texans.CustomerPhone_vw
			where	PhoneUseCd	= decode(CustomerType, ''PERS'', ''PER'', ''BUS'')
			and		PhoneUseCd	in (''BUS'', ''PER'')'
		)	cp	on	cp.CustomerId	= bsa.OsiCustomerId
				and	cp.CustomerType	= bsa.OsiCustomerType;

	--	update the fax number
	update	bsa
	set		Fax	= isnull(cp.AreaCd	, '   ') + '-'
				+ isnull(cp.Exchange, '   ') + '-'
				+ isnull(cp.PhoneNbr, '    ')
	from	sst.BankServAccount	bsa
	join	openquery(OSI, '
			select	CustomerId
				,	CustomerType
				,	AreaCd
				,	Exchange
				,	PhoneNbr
			from	texans.CustomerPhone_vw
			where	PhoneUseCd	= ''FAX'''
		)	cp	on	cp.CustomerId	= bsa.OsiCustomerId
				and	cp.CustomerType	= bsa.OsiCustomerType;

	set	@lastRun = convert(char(10), getdate(), 101);

	exec tcu.Dictionary_sav 'BankServ', 'GFX Last Run', @lastRun;

	set	@return = @@error;
end;
else
begin
	set	@return = -1;
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO