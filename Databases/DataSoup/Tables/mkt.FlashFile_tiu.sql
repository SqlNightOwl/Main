use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'mkt'
GO
CREATE trigger mkt.FlashFile_tiu
on	mkt.FlashFile
for insert, update
as

set nocount on

if update(CreatedOn)
or update(CreatedBy)
begin
	update	o
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	mkt.FlashFile	o
	join	deleted			d
			on	o.FlashFileId = d.FlashFileId
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	o
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	mkt.FlashFile	o
	join	inserted		i
			on	o.FlashFileId = i.FlashFileId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO