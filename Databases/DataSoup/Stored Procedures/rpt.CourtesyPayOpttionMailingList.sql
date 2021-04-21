use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[rpt].[CourtesyPayOpttionMailingList]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [rpt].[CourtesyPayOpttionMailingList]
GO
setuser N'rpt'
GO
create procedure rpt.CourtesyPayOpttionMailingList
	@ssrsUser	varchar(25)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/10/2010
Purpose  :	Returns members that have changed their Courtesy Pay Option during
			the prior day and have elected the mail option.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@return	int;

set	@ssrsUser = substring(@ssrsUser, charindex('\', @ssrsUser) + 1, 25)

exec ops.SSRSReportUsage_ins @@procid, @ssrsUser;

select	isnull(	ph.courtesy_pay_update_on
			,	getdate() -1)					as courtesy_pay_update_on
	,	'*****' + right(ph.serial_number, 5)	as account_number
	,	ph.courtesy_pay_option
	,	c.customer								as member_name
	,	a.address1
	,	a.address2
	,	a.locality1								as city
	,	rtrim(a.region_code)					as state_code
	,	case len(a.post_code)
		when 9 then	left(a.post_code, 5) + '-' 
				+	right(a.post_code, 4)
		else upper(a.post_code) end				as zip_code
from	onyx6_0.dbo.product_header	ph
join	onyx6_0.cs.customer_v		c
		on	ph.owner_id = c.customer_id
join	onyx6_0.dbo.address			a
		on	ph.owner_id			= a.owner_id
		and ph.owner_type_enum	= a.owner_type_enum
where	a.primary_address			= 1
and		c.contact_preference_did	= 126	--	mail
and		ph.product_code				like 'CK%'
and		ph.courtesy_pay_update_on	> convert(char(10), dateadd(day, -1, getdate()), 121)
order by
		c.secondary_id
	,	ph.courtesy_pay_option desc

set @return = @@error;

PROC_EXIT:
if @return != 0
begin
	declare	@errorProc sysname;
	set	@errorProc = object_schema_name(@@procid) + '.' + object_name(@@procid);
	raiserror(N'An error occured while executing the procedure "%s"', 15, 1, @errorProc) with log;
end

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO