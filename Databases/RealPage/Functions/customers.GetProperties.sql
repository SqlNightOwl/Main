SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[GetProperties](@IPVC_IDSeq varchar(22)) returns bigint 
as 
begin
    declare @LVB_PropertyCount bigint
    select @LVB_PropertyCount = count(*)  from Customers..property where PMCIDSeq=@IPVC_IDSeq and statustypecode = 'ACTIV'
    return @LVB_PropertyCount
end


GO
