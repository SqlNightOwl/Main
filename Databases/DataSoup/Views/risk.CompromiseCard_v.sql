use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[CompromiseCard_v]
GO
setuser N'risk'
GO
CREATE view risk.CompromiseCard_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/16/2009
Purpose  :	Used to generate the mailing that goes to members when credit/debit
			cards are compromised.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	'Card Id'			as CardId
	,	'Alert'				as Alert
	,	'Card Number'		as CardNumber
	,	'Agree Type Code'	as AgreeTypeCode
	,	'Member Number'		as MemberNumber
	,	'Member Name'		as Member
	,	'Member Group'		as MemberGroup
	,	'Owner Name'		as Owner
	,	'Primary Holder'	as IsPrimaryHolder
	,	'Agree Nbr'			as AgreeNbr
	,	'Card Member Nbr'	as MemberNbr
	,	'Issue Nbr'			as IssueNbr
	,	'Card Holder'		as CardHolder
	,	'Status w/Loaded'	as StatusCode
	,	'Current Status'	as CurrentStatusCode
	,	'Status Reason'		as StatusReason
	,	'Eff. Date/Time'	as EffectiveDateTime
	,	'Issued On'			as IssuedOn
	,	'Expires On'		as ExpiresOn
	,	'Address 1'			as Address1
	,	'Address 2'			as Address2
	,	'City'				as City
	,	'State'				as State
	,	'Zip Code'			as Zip
	,	'Phone'				as Phone
	,	'Mobile'			as Mobile
	,	'CuttOf Group'		as CutOffGroup
	,	'CutOff On'			as CutOffOn
	,	'Loaded On'			as LoadedOn
	,	0					as RowType

union all

select	cast(c.CardId as varchar(10))				as CardId
	,	f.Alert
	,	cast(f.CardNumber as char(16))				as CardNumber
	,	c.AgreeTypeCode
	,	cast(c.MemberNumber as varchar(20))			as MemberNumber
	,	c.Member
	,	c.MemberGroup
	,	c.Owner
	,	case h.HolderId
		when c.PrimaryHolderId then 'yes'
		else 'no' end								as IsPrimaryHolder
	,	cast(h.AgreeId	as varchar(10))				as AgreeNbr
	,	cast(h.HolderId as varchar(10))				as MemberNbr
	,	cast(h.IssueId	as varchar(10))				as IssueNbr
	,	h.CardHolder
	,	h.StatusCode
	,	h.CurrentStatusCode
	,	h.StatusReason
	,	convert(char(11), h.EffDateTime	, 101)	+
		convert(char(5) , h.EffDateTime	, 8)		as EffDateTime
	,	convert(char(10), h.IssuedOn	, 101)		as IssuedOn
	,	convert(char(10), h.ExpiresOn	, 101)		as ExpiresOn
	,	h.Address1
	,	h.Address2
	,	h.City
	,	h.State
	,	h.ZipCode
	,	h.Phone
	,	h.Mobile
	,	cast(c.CutOffGroup as varchar(10))			as CutOffGroup
	,	convert(char(10), c.CutOffOn, 101)			as CutOffOn
	,	convert(char(10), f.LoadedOn, 101)			as LoadedOn
	,	c.AlertId									as RowType
from(	--	collect the first listing of a card within each compromise
		select	min(a.AlertId)	as AlertId
			,	min(a.Alert)	as Alert
			,	min(a.LoadedOn)	as LoadedOn
			,	c.CardNumber
		from	risk.CompromiseAlert	a
		join	risk.CompromiseCard		c
				on	a.AlertId = c.AlertId
		group by a.CompromiseId, c.CardNumber
	)	f
join	risk.CompromiseCard			c
		on	c.AlertId		= f.AlertId
		and	c.CardNumber	= f.CardNumber
left join
		risk.CompromiseCardHolder	h
		on	c.CardId			= h.CardId
		and	c.AgreeId			= h.AgreeId
		--	status for only the primary holder
		and	c.PrimaryHolderId	= h.HolderId;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO