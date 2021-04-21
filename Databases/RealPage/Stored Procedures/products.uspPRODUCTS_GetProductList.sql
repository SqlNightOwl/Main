SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  Products
-- Procedure Name  :  [uspPRODUCTS_GetProductList]
-- Description     :  This procedure gets the Price Cap Details 
--                    for the specified Price Cap ID.
-- Input Parameters: 	1. @IPBI_PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec CUSTOMERS.DBO.uspPRODUCTS_GetProductList  @IPBI_PriceCapIDSeq = 1
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 02/15/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [products].[uspPRODUCTS_GetProductList] (@IPC_PlatformCode varchar(3),
                                                      @IPC_FamilyCode varchar(3),
                                                      @IPC_PriceCapIDSeq varchar(11),
                                                      @IPC_SOCFlag        bit
                                                     )
AS
BEGIN
      if (@IPC_SOCFlag = 0)
      BEGIN
        select 
              ltrim(rtrim(prod.Code)) as ProductCode,
              prod.DisplayName        as ProductName,
              prod.SOCFlag            as SOCFlag
        from  Products.dbo.Product prod  with (nolock) 
        where prod.PlatformCode   = @IPC_PlatformCode
        and   prod.FamilyCode     = @IPC_FamilyCode
        and   prod.DisabledFlag   = 0
        and   not exists (select top 1 1 
                          from   Customers.dbo.PriceCapProducts X with (nolock)
                          where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                          and    X.productCode   = prod.Code 
                          )
        order by prod.DisplayName ASC
      END
     ELSE
     BEGIN
        select 
              ltrim(rtrim(prod.Code)) as ProductCode,
              prod.DisplayName        as ProductName,
              prod.SOCFlag            as SOCFlag
        from  Products.dbo.Product prod  with (nolock) 
        where prod.PlatformCode   = @IPC_PlatformCode
        and   prod.FamilyCode     = @IPC_FamilyCode
        and   prod.DisabledFlag   = 0
        and   not exists (select top 1 1 
                          from   Customers.dbo.PriceCapProducts X with (nolock)
                          where  X.PriceCapIDSeq = @IPC_PriceCapIDSeq
                          and    X.productCode   = prod.Code 
                          )
        and   prod.SOCFlag               = 1
        order by prod.DisplayName ASC
     END
END


--exec dbo.uspPRODUCTS_GetProductList 'DMD','OSD','',1

--select * from products.dbo.product where  like  '%PRM%'
GO
