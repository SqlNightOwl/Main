use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
setuser N'tcu'
GO
CREATE trigger tcu.LocationHour_tiu
on	tcu.LocationHour
for insert, update
as

set nocount on

if update(DaysOfWeek)
begin
	declare @i int
	set @i = 0
	--	each location may only have one record if it's a 24-hour location
	select	@i = min(i.LocationId)
	from	inserted			i
	join	tcu.LocationHour	h
			on	i.LocationId		=	h.LocationId
			and	i.LocationHourId	!=	h.LocationHourId
	where	i.DaysOfWeek & 1 = 1
	if @i != 0
	begin
		rollback tran
		raiserror('Location Id %d can have only one record for Hours of Operation if the Location is open 24-hours.', 16, 1, @i)
		return
	end
	set @i = 0
	select	@i = min(i.LocationId)
	from	inserted			i
	join	tcu.LocationHour	h
			on	i.LocationId		=	h.LocationId
			and	i.LocationHourId	!=	h.LocationHourId
			and	i.DaysOfWeek & 1	!=	1
	where	i.DaysOfWeek & 1 = 1
	if @i != 0
	begin
		rollback tran
		raiserror('Location Id %d has a record for Hours of Operation identifying it as a 24-hour Location.  You must update that record.', 16, 1, @i)
		return
	end

	--	each location may only have one record if it's only open during an Event
	set @i = 0
	select	@i = min(i.LocationId)
	from	inserted			i
	join	tcu.LocationHour	h
			on	i.LocationId		=	h.LocationId
			and	i.LocationHourId	!=	h.LocationHourId
	where	i.DaysOfWeek & 256 = 256
	if @i != 0
	begin
		rollback tran
		raiserror('Location Id %d can have only one record for Hours of Operation if the Location is only open during an Event.', 16, 1, @i)
		return
	end
	set @i = 0
	select	@i = min(i.LocationId)
	from	inserted		i
	join	tcu.LocationHour h
			on	i.LocationId		=	h.LocationId
			and	i.LocationHourId	!=	h.LocationHourId
			and	i.DaysOfWeek & 256	!=	256
	where	i.DaysOfWeek & 256 = 256
	if @i != 0
	begin
		rollback tran
		raiserror('Location Id %d can have only one record for Hours of Operation if the Location is only open during an Event.', 16, 1, @i)
		return
	end

	--	each location may have each days bit set only once
	--	ex:  each location may have one open/close schedule for Monday.
	while @i < 8
	begin
		if exists ( select	1 from tcu.LocationHour h join inserted i
						on	h.LocationId		=	i.LocationId
						and	h.LocationHourId	!=	i.LocationHourId
						and	h.DaysOfWeek & power(2, @i) = i.DaysOfWeek & power(2, @i)
						and	i.DaysOfWeek & power(2, @i)	= power(2, @i)	)
		begin
			declare @l int
			select	@l = min(h.LocationId)
			from	tcu.LocationHour	h
			join	inserted		i
				on	h.LocationId		=	i.LocationId
				and	h.LocationHourId	!=	i.LocationHourId	
				and	h.DaysOfWeek & power(2, @i) = i.DaysOfWeek & power(2, @i)
				and	i.DaysOfWeek & power(2, @i)	= power(2, @i)
			set	@i	= power(2, @i)
			rollback tran
			raiserror('The bit value:%d allready exists for Location %d. The entire batch has been rolled back', 16, 1, @i, @l)
			return
		end
		set @i = @i + 1
	end
end

if update(CreatedOn)
or update(CreatedBy)
begin
	update	h
	set		CreatedOn	= d.CreatedOn
		,	CreatedBy	= d.CreatedBy
	from	tcu.LocationHour	h
	join	deleted				d
			on	h.LocationHourId = d.LocationHourId
end

if not update(UpdatedOn)
or not update(UpdatedBy)
begin
	update	h
	set		UpdatedOn	= getdate()
		,	UpdatedBy	= tcu.fn_UserAudit()
	from	tcu.LocationHour	h
	join	inserted			i
			on	h.LocationHourId = i.LocationHourId
end
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO