SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ExpirePriceCap](
                                                          @IPVC_PriceCapIDSeq     varchar(4)
                                                     ) 

AS
BEGIN
        delete from Customers.dbo.PriceCapProperties where PriceCapIDSeq = @IPVC_PriceCapIDSeq        
        delete from Customers.dbo.PriceCapProducts   where PriceCapIDSeq = @IPVC_PriceCapIDSeq
		delete from Customers.dbo.PriceCapNote       where PriceCapIDSeq = @IPVC_PriceCapIDSeq
        delete from Customers.dbo.PriceCap           where IDSeq         = @IPVC_PriceCapIDSeq
end                

--Exec uspCUSTOMERS_ExpirePriceCap

GO
