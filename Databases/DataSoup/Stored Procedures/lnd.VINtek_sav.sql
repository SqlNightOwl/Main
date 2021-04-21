use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[VINtek_sav]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[VINtek_sav]
GO
setuser N'lnd'
GO
CREATE procedure lnd.VINtek_sav
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/22/2010
Purpose  :	Process to extract and load new loans from OSI into the VINtek table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/19/2010	Paul Hunter		Added new Collateral Type column.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@today	datetime

--	initialize the variable...
set	@today = convert(char(10), getdate(), 121);

--	create an empty mirror of the production table...
select	top 0 *
into	#vintek_new
from	lnd.VINtek;

--	extract the loans from "yesterday" controlled in the OSI view...
insert	#vintek_new
	(	RecordType
	,	ETLAction
	,	AcctNbr
	,	PropId
	,	PropYear
	,	PropMake
	,	PropModel
	,	DealerNbr
	,	Borrower
	,	BorrowerNbr
	,	CoBorrower
	,	CoBorrowerNbr
	,	Address1
	,	Address2
	,	City
	,	StateCd
	,	ZipCd
	,	AddrNbr
	,	AddressUpdatedOn
	,	ContractDate
	,	MaturesOn
	,	TitleStateCd
	,	StatusCd
	,	PropVehicleOdometer
	,	CollateralType
	,	MemberNbr
	,	LoadedOn
	)
select	*
	,	@today	as LoadedOn
from	openquery(OSI, '
		select	RecordType
			,	ETLAction
			,	AcctNbr
			,	nvl(PropId, ''MISSING'')	as PropId
			,	nvl(PropYear, ''0000'')		as PropYear
			,	PropMake
			,	PropModel
			,	DealerNbr
			,	Borrower
			,	BorrowerNbr
			,	CoBorrower
			,	CoBorrowerNbr
			,	nvl(Address1, ''MISSING'')	as Address1
			,	Address2
			,	nvl(CityName, ''MISSING'')	as CityName
			,	nvl(StateCd, ''XX'')		as StateCd
			,	ZipCd
			,	nvl(AddrNbr, 0)				as AddrNbr
			,	nvl(AddressUpdateOn, cast(''01/01/1900'' as date))	as AddressUpdateOn
			,	ContractDate
			,	MaturesOn
			,	TitleState
			,	StatusCd
			,	PropVehicleOdometer
			,	CollateralType
			,	MemberAgreeNbr
		from	texans.lnd_VINtek_vw');

--	if any loans were loaded then load them into the prermanent table...
if exists (	select top 1 RecordId from #vintek_new )
begin
	--	move existing loans up to the current load date...
	update	o
	set		RecordType	= n.RecordType
		,	ETLAction	= n.ETLAction
		,	UpdatedOn	= @today
	from	lnd.VINtek	o	--	original
	join	#vintek_new	n	--	new data
			on	o.AcctNbr	= n.AcctNbr
			and	o.PropId	= n.PropId;

	--	add the new loans...
	insert	lnd.VINtek
		(	RecordType
		,	ETLAction
		,	AcctNbr
		,	PropId
		,	PropYear
		,	PropMake
		,	PropModel
		,	DealerNbr
		,	Borrower
		,	BorrowerNbr
		,	CoBorrower
		,	CoBorrowerNbr
		,	Address1
		,	Address2
		,	City
		,	StateCd
		,	ZipCd
		,	AddrNbr
		,	AddressUpdatedOn
		,	ContractDate
		,	MaturesOn
		,	TitleStateCd
		,	StatusCd
		,	PropVehicleOdometer
		,	CollateralType
		,	MemberNbr
		,	LoadedOn
		)
	select	n.RecordType
		,	n.ETLAction
		,	n.AcctNbr
		,	n.PropId
		,	n.PropYear
		,	n.PropMake
		,	n.PropModel
		,	n.DealerNbr
		,	n.Borrower
		,	n.BorrowerNbr
		,	n.CoBorrower
		,	n.CoBorrowerNbr
		,	n.Address1
		,	n.Address2
		,	n.City
		,	n.StateCd
		,	n.ZipCd
		,	n.AddrNbr
		,	n.AddressUpdatedOn
		,	n.ContractDate
		,	n.MaturesOn
		,	n.TitleStateCd
		,	n.StatusCd
		,	n.PropVehicleOdometer
		,	n.CollateralType
		,	n.MemberNbr
		,	@today
	from	lnd.VINtek	o	--	original
	right join
			#vintek_new	n	--	new data
			on	o.AcctNbr	= n.AcctNbr
			and	o.PropId	= n.PropId
	where	o.AcctNbr is null;
end;

drop table #vintek_new;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO