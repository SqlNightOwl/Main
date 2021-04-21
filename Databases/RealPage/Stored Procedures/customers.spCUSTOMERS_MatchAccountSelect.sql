
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure customers.spCustomers_MatchAccountSelect
	@IPVC_AccountName	varchar(100)
,	@IPVC_ProductCodes	varchar(1000)
as
/*
--------------------------------------------------------------------------------------------------
Database  Name  : ORDERS
Procedure Name  : spCustomers_MatchAccountSelect
Description     : Associates the transactions with existing properties
Input Parameters: 

----------------------------------------------------------------------------------------------------
Revision History:
Author          : Davon Cannon 
----------------------------------------------------------------------------------------------------
exec customers.spCustomers_MatchAccountSelect 'Autum','LASI'
*/
begin

	set nocount on;

	declare @tblAccount table
		(	CompanyIDSeq	char(11)
		,	PropertyIDSeq	char(11)
		,	AccountIDSeq	char(11)
		,	AccountName		varchar(100)
		,	SiteMasterID	varchar(30)
		,	AccountType		varchar(5)
		,	ErrorCode		varchar(1)
		);

	--	collect accounts at the Company level
	insert	@tblAccount
		(	CompanyIDSeq
		,	PropertyIDSeq
		,	AccountIDSeq
		,	AccountName
		,	AccountType
		,	SiteMasterID
		,	ErrorCode
		)
	select	top 8
			c.IDSeq
		,	''
		,	a.IDSeq
		,	c.Name
		,	at.Name
		,	c.SiteMasterID
		,	case
			when exists (	select	1
							from	orders.[Order]		o with (nolock)
							inner
							join	orders.OrderItem	oi with (nolock)
									on	oi.OrderIDSeq = o.OrderIDSeq
									and	charindex(rtrim(oi.ProductCode), @IPVC_ProductCodes) > 0
									and	oi.StatusCode = 'FULF'
							where	o.AccountIDSeq = a.IDSeq) then 'S' else 'P' end
	from	customers.Company		c	with (nolock) 
	inner
	join	customers.Account		a	with (nolock)
			on	a.CompanyIDSeq	= c.IDSeq
			and a.PropertyIDSeq	is null
			and a.ActiveFlag	= 1
	inner
	join	customers.AccountType	at	with (nolock) 
			on	a.AccountTypeCode = at.Code
	where	((len(@IPVC_AccountName) > 5)
		and	 (c.[Name] like '%' + replace(left(@IPVC_AccountName, 15), ' ', '%') + '%'))
		or	c.[Name] like '%' + left(@IPVC_AccountName, 15) + '%'
		or	@IPVC_AccountName like '%' + replace(c.[Name], ' ', '%') + '%';

	--	collect accounts at the Property (Site) level
	insert	@tblAccount
		(	CompanyIDSeq
		,	PropertyIDSeq
		,	AccountIDSeq
		,	AccountName
		,	AccountType
		,	SiteMasterID
		,	ErrorCode
		)
	select	top 8
			a.CompanyIDSeq
		,	p.IDSeq
		,	a.IDSeq
		,	p.Name
		,	at.Name
		,	p.SiteMasterID
		,	case
			when exists(select	1
						from	orders.[Order]		o with (nolock)
						join	orders.OrderItem	oi with (nolock)
								on	oi.OrderIDSeq	= o.OrderIDSeq
								and	charindex(rtrim(oi.ProductCode), @IPVC_ProductCodes) > 0
								and	oi.StatusCode	= 'FULF'
						where	o.AccountIDSeq = a.IDSeq) then 'S' else 'P' end
	from	customers.Property		p with (nolock)
	inner
	join	customers.Account		a with (nolock)
			on	a.PropertyIDSeq	= p.IDSeq
			and	a.ActiveFlag	= 1
	inner
	join	customers.AccountType	at with (nolock) 
			on	at.Code = a.AccountTypeCode
	where ((len(@IPVC_AccountName) > 5) 
		and (p.[Name] like '%' + replace(left(@IPVC_AccountName, 15), ' ', '%') + '%'))
		or	p.[Name] like '%' + left(@IPVC_AccountName, 15) + '%'
		or	@IPVC_AccountName like '%' + replace(p.[Name], ' ', '%') + '%';

	--	return the top 8 accounts accounts
	select	top 8
			CompanyIDSeq
		,	PropertyIDSeq
		,	AccountIDSeq
		,	AccountName
		,	AccountType
		,	SiteMasterID
		,	ErrorCode
	from	@tblAccount
	order by AccountName;

end;
GO
