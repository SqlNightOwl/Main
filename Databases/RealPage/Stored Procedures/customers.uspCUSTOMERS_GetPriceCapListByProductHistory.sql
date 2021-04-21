SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE  [customers].[uspCUSTOMERS_GetPriceCapListByProductHistory]
(
                  @IPVC_CompanyIDSeq    char(11),
                  @IPVC_PriceCapIDSeq   varchar(11),
                  @IPVC_PropertyIDSeq   varchar(11)
)
AS
BEGIN
  -------------------------------------------------------------------------------------
  SELECT      pprod.PriceCapIDSeq                               as PriceCapIDSeq,
              pprod.ProductCode                                 as ProductCode,
              prod.Name                                         as ProductName, 
              pbasis.Name                                       as PriceCapBasis,
              convert(numeric(6,2),pcap.PriceCapPercent)        as PriceCapPercent,
			        convert(varchar(10),pcap.PriceCapStartDate,101)   as PriceCapStartDate,
			        convert(varchar(10),pcap.PriceCapEndDate,101)     as PriceCapEndDate,
			        pcap.Activeflag									                  as ActiveFlag
				 

  FROM        Customers.dbo.PriceCapProductsHistory pprod with (nolock)

  INNER JOIN  Customers.dbo.PriceCapHistory pcap
    ON        pprod.PriceCapIDSeq = pcap.PriceCapIDSeq
 
  INNER JOIN  Products.dbo.Product prod with (nolock)
    ON        prod.Code = pprod.ProductCode
    and       Prod.DisabledFlag = 0
  INNER JOIN  Products.dbo.PriceCapBasis pbasis
    ON        pbasis.Code = pcap.PriceCapBasisCode

  WHERE       pprod.companyidseq = @IPVC_CompanyIDSeq
    and       (
                (@IPVC_PriceCapIDSeq <> '' and pprod.PriceCapIDSeq = @IPVC_PriceCapIDSeq)
      	or 
                (@IPVC_PriceCapIDSeq = '')
              )
  -------------------------------------------------------------------------------------

  -------------------------------------------------------------------------------------
  SELECT DISTINCT     tbl.PriceCapIDSeq as PriceCapIDSeq,
					  tbl.ProductCode   as ProductCode,
					  prop.IDSeq        as PropertyIDSeq,
					  prop.Name         as PropertyName	
  FROM      (
						  SELECT	properties.PriceCapIDSeq,
								      products.ProductCode,
                      properties.PropertyIDSeq 
              FROM	  
                      Customers.dbo.PriceCapProductsHistory products with (nolock),
                      Customers.dbo.PriceCapPropertiesHistory properties  with (nolock)
              WHERE
                      (		
                        (
                          products.companyidseq = @IPVC_CompanyIDSeq 
                          AND
                            (
                              (@IPVC_PriceCapIDSeq <> '' 
                                and products.PriceCapIDSeq = @IPVC_PriceCapIDSeq)
                            OR 
                              (@IPVC_PriceCapIDSeq = '')
									          )
								        )
								      AND
                        (
                          properties.companyidseq = @IPVC_CompanyIDSeq
                          AND 
                            (
                              (@IPVC_PriceCapIDSeq <> '' 
                                and properties.PriceCapIDSeq = @IPVC_PriceCapIDSeq)
                            OR 
                              (@IPVC_PriceCapIDSeq = '')
                            )
                        )
                      )							

				    )as TBL
  
  LEFT OUTER JOIN Customers.dbo.[Property] prop	with (nolock)		
		ON            TBL.PropertyIDSeq = prop.IDSeq

  WHERE           (
                    (@IPVC_PropertyIDSeq  <> '' and  prop.IDSeq = @IPVC_PropertyIDSeq)
                  or
                    (@IPVC_PropertyIDSeq = '')
                  )
  -------------------------------------------------------------------------------------
END

GO
