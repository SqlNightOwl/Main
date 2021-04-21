SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  Customers
-- Procedure Name  :  [uspCUSTOMERS_GetAvailableProducts]
-- Description     :  This procedure gets the Price Cap Details 
--                    for the specified Price Cap ID.
-- Input Parameters: 	1. @IPBI_PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetAvailableProducts  
-- 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 06/10/2008      : Stored Procedure Created.
-- 10/20/2009      : Changed to display product names alphabetically
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetAvailableProducts] 
                                                     (@IPC_PlatformCode   varchar(3),
                                                      @IPC_FamilyCode     varchar(3),
                                                      @IPC_PriceCapIDSeq  varchar(11),
                                                      @IPC_SOCFlag        bit,
                                                      @AvailableProduct   char(4)
                                                     )
AS
BEGIN
     
   if(@AvailableProduct = 'PMC')
   BEGIN 
      if (@IPC_SOCFlag = 0)
      BEGIN
        SELECT  P.DisplayName AS productName,ltrim(rtrim(P.Code)) as ProductCode,P.SOCFlag as SOCFlag
        FROM    Products.dbo.Product P WITH (NOLOCK)
        Where   P.disabledflag        = 0
        and     P.PriceCapEnabledFlag = 1
        and     P.PlatformCode   = @IPC_PlatformCode
	and     P.FamilyCode     = @IPC_FamilyCode
        and     Exists (select Top 1 1
                        from   Products.dbo.Charge C WITH (NOLOCK)
                        where  P.Code = C.ProductCode 
                        and    P.priceversion = C.Priceversion
                        and    P.disabledflag = C.disabledflag
                        and C.displaytype in ('PMC','BOTH')
                        )
        and not exists (select top 1 1 
                        from   Customers.dbo.PriceCapProducts X with (nolock)
                        where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                        and    X.productCode   = P.Code 
                        )
        Order by P.DisplayName ASC;
      END
     ELSE
     BEGIN
        SELECT  P.DisplayName AS productName,ltrim(rtrim(P.Code)) as ProductCode,P.SOCFlag as SOCFlag
        FROM    Products.dbo.Product P WITH (NOLOCK)
        Where   P.disabledflag        = 0
        and     P.PriceCapEnabledFlag = 1
        and     P.PlatformCode   = @IPC_PlatformCode
	and     P.FamilyCode     = @IPC_FamilyCode
        and     P.SOCFlag        = 1
        and     Exists (select Top 1 1
                        from   Products.dbo.Charge C WITH (NOLOCK)
                        where  P.Code = C.ProductCode 
                        and    P.priceversion = C.Priceversion
                        and    P.disabledflag = C.disabledflag
                        and C.displaytype in ('PMC','BOTH')
                        )
        and not exists (select top 1 1 
                        from   Customers.dbo.PriceCapProducts X with (nolock)
                        where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                        and    X.productCode   = P.Code 
                        )
        Order by P.DisplayName ASC;
     END
   END
  ELSE
  BEGIN
  if (@IPC_SOCFlag = 0)
      BEGIN
        SELECT  P.DisplayName AS productName,ltrim(rtrim(P.Code)) as ProductCode,P.SOCFlag as SOCFlag
        FROM    Products.dbo.Product P WITH (NOLOCK)
        Where   P.disabledflag        = 0
        and     P.PriceCapEnabledFlag = 1
        and     P.PlatformCode   = @IPC_PlatformCode
	and     P.FamilyCode     = @IPC_FamilyCode
        and     Exists (select Top 1 1
                        from   Products.dbo.Charge C WITH (NOLOCK)
                        where  P.Code = C.ProductCode 
                        and    P.priceversion = C.Priceversion
                        and    P.disabledflag = C.disabledflag
                        and C.displaytype in ('SITE','BOTH')
                        )
        and not exists (select top 1 1 
                        from   Customers.dbo.PriceCapProducts X with (nolock)
                        where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                        and    X.productCode   = P.Code 
                        )
        Order by P.DisplayName ASC;
      END
     ELSE
     BEGIN
       SELECT  P.DisplayName AS productName,ltrim(rtrim(P.Code)) as ProductCode,P.SOCFlag as SOCFlag
       FROM    Products.dbo.Product P WITH (NOLOCK)
       Where   P.disabledflag        = 0
       and     P.PriceCapEnabledFlag = 1
       and     P.PlatformCode   = @IPC_PlatformCode
       and     P.FamilyCode     = @IPC_FamilyCode
       and     P.SOCFlag        = 1
       and     Exists (select Top 1 1
                        from   Products.dbo.Charge C WITH (NOLOCK)
                        where  P.Code = C.ProductCode 
                        and    P.priceversion = C.Priceversion
                        and    P.disabledflag = C.disabledflag
                        and C.displaytype in ('SITE','BOTH')
                        )
       and not exists (select top 1 1 
                        from   Customers.dbo.PriceCapProducts X with (nolock)
                        where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                        and    X.productCode   = P.Code 
                        )
        Order by P.DisplayName ASC;
     END
 
  END

END
GO
