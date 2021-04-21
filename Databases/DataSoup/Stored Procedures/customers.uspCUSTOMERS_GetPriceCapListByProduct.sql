SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_GetPriceCapList
-- Description     :  This procedure gets the list of Price Cap 
--                    for the specified Company ID.
-- Input Parameters: 	1. @PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetPriceCapList  
--                        @IPI_PageNumber       1, 
--                        @IPI_RowsPerPage      10,
--                        @IPVC_CompanyIDSeq    'C000000001'
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 02/15/2007      : Stored Procedure Created.
-- 11/12/2008      : Naval Kishore Modified for defect 5566
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [customers].[uspCUSTOMERS_GetPriceCapListByProduct]   
                
                  @IPVC_CompanyIDSeq    char(11),
                  @IPVC_PriceCapIDSeq   varchar(11),
                  @IPVC_PropertyIDSeq   varchar(11)

AS
BEGIN

  -------------------------------------------------------------------------------------
  SELECT  DISTINCT    pprod.PriceCapIDSeq                               as PriceCapIDSeq,  
              pprod.ProductCode                                 as ProductCode,  
              prod.Name                                         as ProductName,   
              pbasis.Name                                       as PriceCapBasis,  
              convert(numeric(6,2),pcap.PriceCapPercent)          as PriceCapPercent,  
           convert(varchar(10),pcap.PriceCapStartDate,101)   as PriceCapStartDate,  
           convert(varchar(10),pcap.PriceCapEndDate,101)     as PriceCapEndDate,  
           pcap.Activeflag                           as ActiveFlag  
       
  
  FROM        Customers.dbo.PriceCapProducts pprod with (nolock)  
  
  INNER JOIN  Customers.dbo.PriceCap pcap  
    ON        pprod.PriceCapIDSeq = pcap.IDSeq  
   
  INNER JOIN  Products.dbo.Product prod with (nolock)  
    ON        prod.Code = pprod.ProductCode  
    and       Prod.DisabledFlag = 0  
  INNER JOIN  Products.dbo.PriceCapBasis pbasis  
    ON        pbasis.Code = pcap.PriceCapBasisCode

  LEFT JOIN Customers.dbo.PriceCapProperties pcproperties
  ON   pcproperties.PriceCapIDSeq = pcap.IDSeq
  
  
  WHERE       pprod.companyidseq = @IPVC_CompanyIDSeq  
    and       (  
                (@IPVC_PriceCapIDSeq <> '' and pprod.PriceCapIDSeq = @IPVC_PriceCapIDSeq)  
       or   
                (@IPVC_PriceCapIDSeq = '')  
              ) 
	and        (  
                (@IPVC_PropertyIDSeq <> '' and isnull(pcproperties.propertyIDSeq,0) = @IPVC_PropertyIDSeq)  
       or   
                (@IPVC_PropertyIDSeq = '')  
              ) 
  -------------------------------------------------------------------------------------

SELECT DISTINCT   products.PriceCapIDSeq as PriceCapIDSeq,
				  products.ProductCode   as ProductCode,
				  isnull(prop.IDSeq,0)		as PropertyIDSeq,
				  isnull(prop.Name,C.Name)  as PropertyName	
FROM Customers.dbo.PriceCapProducts products with (nolock) 
LEFT JOIN Customers.dbo.PriceCapProperties properties  with (nolock) 
	ON products.PriceCapIDSeq = properties.PriceCapIDSeq
	AND ((@IPVC_PropertyIDSeq  <> '' AND properties.PropertyIDSeq = @IPVC_PropertyIDSeq )
		  OR
		  (@IPVC_PropertyIDSeq = '')) 
LEFT JOIN Customers.dbo.[Property] prop	with (nolock)		
	ON properties.PropertyIDSeq = prop.IDSeq
LEFT JOIN  Customers.dbo.Company C with (nolock)
	ON products.CompanyIDSeq = C.IDSeq
WHERE products.CompanyIDSeq = @IPVC_CompanyIDSeq 
AND ((@IPVC_PriceCapIDSeq <> '' AND products.PriceCapIDSeq = @IPVC_PriceCapIDSeq)
      OR 
     (@IPVC_PriceCapIDSeq = ''))

/*
  -------------------------------------------------------------------------------------
  SELECT DISTINCT     tbl.PriceCapIDSeq as PriceCapIDSeq,
					  tbl.ProductCode   as ProductCode,
					  isnull(prop.IDSeq,0)		as PropertyIDSeq,
					  isnull(prop.Name,C.Name)  as PropertyName	
  FROM      (
						  SELECT	products.PriceCapIDSeq,
								    products.ProductCode,
									properties.PropertyIDSeq,
									products.CompanyIDseq 
              FROM	  
                      Customers.dbo.PriceCapProducts products with (nolock) left join 
                      Customers.dbo.PriceCapProperties properties  with (nolock) on products.PriceCapIDSeq = properties.PriceCapIDSeq 
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
	ON          TBL.PropertyIDSeq  =   prop.IDSeq
LEFT JOIN  Customers.dbo.Company C on TBL.CompanyIDSeq = C.IDSeq

  WHERE           (
                    (@IPVC_PropertyIDSeq  <> '' and TBL.PropertyIDSeq  =    @IPVC_PropertyIDSeq )
                  or
                    (@IPVC_PropertyIDSeq = '')
                  )*/
  -------------------------------------------------------------------------------------
END


-- exec Customers.dbo.[uspCUSTOMERS_GetPriceCapListByProduct] 'C0901000018', '','0'
--select top 10 * from dbo.PriceCapProducts where companyidseq='C0901001467'
--Select top 10 * from dbo.PriceCapProperties where companyidseq='C0901001467'


GO
