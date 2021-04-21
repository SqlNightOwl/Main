SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [customers].[GetPropertiesName](@IPVC_IDSeq bigint,@IPVC_PropertyIDSeq varchar(11)) returns varchar(200)
as 
begin
   declare @LVB_PropertyName varchar(200)

 select @LVB_PropertyName= p.[Name]  from Customers..PriceCapProperties pp 
left outer join Customers..[Property] p
on pp.PropertyIDSeq = p.IDSeq
where pp.PriceCapIDseq = convert(varchar(100),@IPVC_IDSeq)
and (@IPVC_PropertyIDSeq    is not null and pp.PropertyIDSeq  like '%' +@IPVC_PropertyIDSeq + '%')
and p.ActiveFlag = 1
  
    return @LVB_PropertyName
end

--exec [dbo].[GetPropertiesName]



GO
