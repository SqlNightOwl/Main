SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ValidateEndDate](
                                                          @IPVC_PriceCapTerm      int,
                                                          @IPVC_PriceCapStartDate datetime                                                          
                                                     ) 

AS
BEGIN
          DECLARE @LVI_PriceCapEndDate DATETIME

          SET @LVI_PriceCapEndDate = DATEADD(YEAR,@IPVC_PriceCapTerm,@IPVC_PriceCapStartDate)
      
          SELECT Convert(varchar(12),@LVI_PriceCapEndDate ,101) AS PriceCapEndDate

END                


--Exec Customers..uspCUSTOMERS_ValidateEndDate 1,'10/22/2006'
GO
