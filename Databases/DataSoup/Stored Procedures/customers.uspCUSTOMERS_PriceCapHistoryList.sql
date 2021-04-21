SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_PriceCapHistoryList]  @CompanyID varchar(11)
AS
BEGIN 
   SELECT           PriceCapIDSeq                                  AS  PriceCapIDSeq,

                    row_number() over(order by IDSeq)             AS  RowNumber
                    
    FROM            Customers.dbo.PriceCapHistory PC with (nolock)

    LEFT OUTER JOIN Products.dbo.PriceCapBasis PCB with (nolock)
      ON            PC.PriceCapBasisCode = PCB.Code

    WHERE           CompanyIDSeq = @CompanyID

                               
                                    
             
END

GO
