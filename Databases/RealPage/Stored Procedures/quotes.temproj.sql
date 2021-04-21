SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [quotes].[temproj]
as
begin
  declare @tab table (fees varchar(30), listprice varchar(10), discountpercent varchar(10))

  insert into @tab (fees, listprice, discountpercent)
  values ('Initial License Fees', '0.00', '0.00')

  insert into @tab (fees, listprice, discountpercent)
  values ('Access Fees - Year I', '0.00', '0.00')

  insert into @tab (fees, listprice, discountpercent)
  values ('Access Fees - Year II', '0.00', '0.00')

  insert into @tab (fees, listprice, discountpercent)
  values ('Access Fees - Year III', '0.00', '0.00')

  insert into @tab (fees, listprice, discountpercent)
  values ('Total', '0.00', '0.00')

  select * from @tab
end


GO
