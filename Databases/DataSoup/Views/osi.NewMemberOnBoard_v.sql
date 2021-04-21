use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[NewMemberOnBoard_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[NewMemberOnBoard_v]
GO
setuser N'osi'
GO
create view osi.NewMemberOnBoard_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Vivian Liu
Created  :	04/22/20008
Purpose  :	Retrieve everyday new account opened for New Member On-Boarding.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
07/02/2008	Paul Hunter		Changed to a union query to facilitate BCP exports.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

--	header record
select	'NAI  '										-- File Identifier
	+	'1'											-- record type
	+	'H0318'										-- client Id
	+	cast('New Account Integration' as char(40))	-- File Name
	+	cast('4.0' as char(10))						-- File Version
	+	left(replace(replace( convert(varchar, getdate(), 120)
			, ' ', ''), ':', ''), 14)				-- File Date/Time
	+	tcu.fn_ZeroPad(Value, 5)					-- File Sequence Number
	+	space(820)		as record					-- reserved for future use	
	,	1				as rowType
	,	ProcessId
from	tcu.ProcessParameter
where	Parameter = 'File Sequence Number'

union all

--	detail records
select	'NAI  ' 						--	File Identifier
	+	'5'								--	record type
	+	'311987786'						--	TRN Number 		
	+	a.AcctNbr						--	AccountNumber
	+	'0000000'						--	BankNumber
	+	'000000'						--	Region Number 
	+	a.BranchNumber					--	BranchNumber
	+	space(12)						--	CustomerId
	+	a.Name1							--	name1
	+	space(100)						--	name 2 & 3
	+	a.Address1						--	address1
	+	space(100)						--	address 2 & 3
	+	a.CityName						--	city
	+	a.StateCd						--	State
	+	a.ZipCd							--	Zip
	+	space(150)						--	Mailing address 1, 2  & 3
	+	space(41)						--	mailing city(30), state(2) & zip(9)
	+	a.Phone							--	phone
	+	space(19)						--	alternate phone number (10) & reserved field (9)
	+	a.EmailAddress					--	email address
	+	space(10)						--	DOB
	+	EmployeeFlag					--	employee Flag
	+	'N'								--	business flag
	+	ForeignFlag						--	foreign flag
	+	AccountStatus					--	account status		
	+	'N'		 						--	customer status 			
	+	space(5)						--	club code (2) & account type code (3)
	+	a.ContractDate					--	account open date
	+	'0000000000'					--	account balance
	+	'B'								--	open channel				
	+	'0000000000'					--	credit limit		
	+	space(10)						--	maturity date			
	+	'N'								--	debit card flag
	+	'N'								--	direct deposit flag
	+	'N'								--	online banking flag
	+	'N'								--	online bill pay flag
	+	a.CloseDate						--	account close date			
	+	' '								--	language preference		
	+	a.AcctLength					--	account number length
	+	space(6)						--	SIC code
	+	'N'								--	do not call flag
	+	a.DoNotMail 					--	do not mail flag
	+	'N'								--	do not email flag
	+	space(3)						--	reserved for future use
	+	'N'								--	credit card flag
	+	a.CurrMiAcctTypCd				--	Account Type Code (Customer Segment)    
	+	'N'								--	statement suppression flag
	+	space(76)			as Record	--	reserved for future use (46) & Harland Clarke error processing
	,	2					as rowType
	,	p.ProcessId
from(	select	AcctNbr
			,	case
				when BranchNumber between '00004' and '00047' then stuff(BranchNumber, 3 ,1, '1')
				else BranchNumber end	as BranchNumber
			,	Name1
			,	Address1
			,	CityName
			,	StateCd
			,	ZipCd
			,	Phone
			,	EmailAddress
			,	EmployeeFlag
			,	ForeignFlag
			,	AccountStatus
			,	ContractDate
			,	CloseDate
			,	DoNotMail
			,	CurrMiAcctTypCd
			,	AcctLength
		from	osi.NewMemberOnBoard
	)	a
cross join	tcu.Process	p

union all

--	trialer record
select	'NAI  '					--	File Identifier					
	+	'9'						--	record type
	+	'H0318'					--	client Id
	+	n.Accounts				--	Record Count
	+	space(879)	as record	--	reserved for future use
	,	3			as rowType
	,	p.ProcessId
from(	select	tcu.fn_ZeroPad(max(rowId), 10) as Accounts
		from	osi.NewMemberOnBoard ) n
cross join	tcu.Process	p;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO