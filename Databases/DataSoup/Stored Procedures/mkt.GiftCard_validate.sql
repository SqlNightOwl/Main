use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[mkt].[GiftCard_validate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [mkt].[GiftCard_validate]
GO
setuser N'mkt'
GO
CREATE procedure mkt.GiftCard_validate
	@MemberNumber	bigint
,	@DateOfBirth	datetime
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Neelima Ganapathineedi
Created  :	02/05/2008
Purpose  :	Validate the Member based on member number and date of birth.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@cmd		nvarchar(500)
,	@isValid	int;

--	build the command
set	@cmd = '
select	@isValid = IsValid
from	openquery(OSI, ''
		select count(1) as IsValid
		from	osiBank.MemberAgreement	ma
		join	osiBank.Pers			p
				on	ma.PrimaryPersNbr	= p.PersNbr
		where	MemberAgreeNbr	= ' + cast(@MemberNumber as varchar) + '
		and 	DateBirth 		= to_date(''''' + convert(char(10), @DateOfBirth, 101) + ''''', ''''MM/DD/YYYY'''')'')';

--	make the attempt...
exec sp_executesql	@cmd
				,	N'@isValid int output'
				,	@isValid output;

--	record the attempt
insert	mkt.GiftCard
	(	MemberNumber
	,	WasSuccessful
	,	CreatedOn
	)
values
	(	@MemberNumber
	,	@isValid
	,	getdate()
	);

if @isValid = 0
begin
	select	@isValid = count(1) * -1
	from	mkt.GiftCard
	where	CreatedOn	 > dateadd(hour, -1, getdate())
	and		MemberNumber = @MemberNumber;
end;

select isValid = @isValid;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [mkt].[GiftCard_validate]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [mkt].[GiftCard_validate]  TO [wa_Services]
GO