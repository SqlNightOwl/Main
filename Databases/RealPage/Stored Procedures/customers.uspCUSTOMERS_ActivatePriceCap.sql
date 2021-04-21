SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ActivatePriceCap](
                                                          @IPVC_PriceCapIDSeq     varchar(4)
                                                     ) 

AS
BEGIN
        UPDATE Customers.dbo.PriceCap
        SET ActiveFlag = 1
        WHERE IDSeq         = @IPVC_PriceCapIDSeq
END                

--Exec uspCUSTOMERS_ActivatePriceCap '47'



GO
