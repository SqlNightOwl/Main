SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_CreateOrModifySystemGeneratedPriceCaps
-- Description     : Updates Orderitem's RenewalTypecode
-- Input Parameters: @IPVC_OrderIDSeq      varchar(50),
--                   @IPBI_GroupIDSeq      bigint,
--                   @IPBI_OrderItemIDSeq  bigint='',
--                   @IPVC_RenewalTypeCode varchar(20)
--                   
-- OUTPUT          : none
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_CreateOrModifySystemGeneratedPriceCaps] parameters                                     
-- Revision History:
-- Author          : SRS
-- 11/30/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_CreateOrModifySystemGeneratedPriceCaps] 
                                                              (@IPVC_OrderIDSeq        varchar(50),
                                                               @IPBI_GroupIDSeq        bigint,
                                                               @IPBI_OrderItemIDSeq    bigint='',
                                                               @IPN_PricecapPercent    numeric(30,5) = 0,
                                                               @IPDT_CurrentActivationEndDate datetime,
                                                               @IPDT_RenewalActivationStartDate datetime,
                                                               @IPBI_CreatePCIndicator int = 0,
                                                               @IPBI_ModifiedByID      bigint
                                                               )
AS
BEGIN
 set nocount on
 ------------------------------------------------------------------------------------------------------
 --Declaring local variables
 declare @LBI_NewPriceCapIDSeq bigint
 declare @LVC_PricecapName     varchar(255)
 ------------------------------------------------------------------------------------------------------
 create table #temp_sysgenpricecaps (pricecapidseq  bigint)

 create table #temp_Orderrelatedinfo(companyidseq   varchar(50),
                                     propertyidseq  varchar(50),
                                     productcode    varchar(50),
                                     familycode     varchar(20),
                                     productname    varchar(255),
                                     Priceversion   numeric(18,0)
                                    )
  ------------------------------------------------------------------------------------------------------  
  If exists (select top 1 1 from ORDERS.dbo.OrderGroup with (nolock)
             where OrderIDSeq = @IPVC_OrderIDSeq
             and   IDSeq      = @IPBI_GroupIDSeq
             and   CustomBundleNameEnabledFlag = 1
             )
  begin 
    ---Get Order related Info for Orderid,Ordergroupid with CustomBundleNameEnabledFlag=1
    Insert into #temp_Orderrelatedinfo(companyidseq,propertyidseq,productcode,Priceversion)
    select distinct O.CompanyIDSeq,O.PropertyIDSeq,OI.Productcode,OI.Priceversion
    from   ORDERS.dbo.[Order] O with (nolock)
    inner join
           ORDERS.dbo.OrderItem OI with (nolock)
    on     O.OrderIDSeq       = OI.OrderIDSeq
    and    O.OrderIDSeq       = @IPVC_OrderIDSeq
    and    OI.OrderGroupIDSeq = @IPBI_GroupIDSeq
    and    OI.ActivationEnddate = @IPDT_CurrentActivationEndDate
    and    OI.statuscode     <> 'PENR'
    and    OI.ChargeTypeCode <> 'ILF'        
  end
  else
  begin
    Insert into #temp_Orderrelatedinfo(companyidseq,propertyidseq,productcode,Priceversion)
    select distinct O.CompanyIDSeq,O.PropertyIDSeq,OI.Productcode,OI.Priceversion
    from   ORDERS.dbo.[Order] O with (nolock)
    inner join
           ORDERS.dbo.OrderItem OI with (nolock)
    on     O.OrderIDSeq       = OI.OrderIDSeq
    and    O.OrderIDSeq       = @IPVC_OrderIDSeq
    and    OI.OrderGroupIDSeq = @IPBI_GroupIDSeq
    and    OI.IDSeq             = @IPBI_OrderItemIDSeq
    and    OI.ActivationEnddate = @IPDT_CurrentActivationEndDate
    and    OI.statuscode     <> 'PENR'
    and    OI.ChargeTypeCode <> 'ILF'  
  end
  --------------------------------------------------------------------------------------
  ---Get PReviously created System Price cap based on info in #temp_Orderrelatedinfo
  Insert into #temp_sysgenpricecaps(pricecapidseq)
  select PC.IDSeq as pricecapidseq
  From   CUSTOMERS.dbo.PriceCap PC With (nolock)
  inner join
         CUSTOMERS.dbo.PriceCapProducts PCP With (nolock)
  on     PC.IDSeq        = PCP.PricecapIDSeq 
  and    PC.companyidseq = PCP.companyidseq
  and    PC.ActiveFlag   = 1
  and    PC.SystemGeneratedPriceCapFlag = 1
  and    PC.Pricecapstartdate = @IPDT_RenewalActivationStartDate
  and    PC.companyidseq in (select X.companyidseq from #temp_Orderrelatedinfo X with (nolock))
  and    ltrim(rtrim(PCP.ProductCode))
                       in (select ltrim(rtrim(T.productcode)) from #temp_Orderrelatedinfo T with (nolock))
  inner join
         CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
  on     PC.IDSeq          = PCPRP.PricecapIDSeq
  and    PC.companyidseq   = PCPRP.companyidseq
  and    PC.companyidseq    in (select X.companyidseq from #temp_Orderrelatedinfo   X with (nolock))
  and    PCPRP.PropertyIDSeq in (select X.propertyidseq from #temp_Orderrelatedinfo X with (nolock))
  and    PC.ActiveFlag     = 1
  and    PC.SystemGeneratedPriceCapFlag = 1
  and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
  and    PCP.companyidseq  = PCPRP.companyidseq
  and    PCP.companyidseq  in (select X.companyidseq from #temp_Orderrelatedinfo X with (nolock))
  ----------------------------------------------------------------------------------------

  IF @IPBI_CreatePCIndicator = 0
  begin
    --If @IPBI_CreatePCIndicator = 0, it means that Pricecapchange Checkbox in UI is unchecked and saved.
    --This means delete any related System Generated Pricecap for the passed parameters.
    --------------------------------------------------------------------------------------
    ---Delete all relevant Price caps with SystemGeneratedPriceCapFlag = 1
    delete D 
    from   Customers.dbo.PriceCapProperties D with (nolock) 
    inner join 
           #temp_sysgenpricecaps S with (nolock)
    on     D.pricecapidseq = S.pricecapidseq

    delete D 
    from   Customers.dbo.PriceCapProducts D with (nolock) 
    inner join 
           #temp_sysgenpricecaps S with (nolock)
    on     D.pricecapidseq = S.pricecapidseq

    delete D 
    from   Customers.dbo.PriceCap D with (nolock) 
    inner join 
           #temp_sysgenpricecaps S with (nolock)
    on     D.idseq = S.pricecapidseq
    --------------------------------------------------------------------------------------
  end
  else if @IPBI_CreatePCIndicator = 1
  begin
    --if @IPBI_CreatePCIndicator = 1, it measn the pricecapchange checkbox in UI is checked and saved.
    --This means Create a new system Generated PriceCap for the passed parameters if one is not present.
    --Else Update the new renewal% passed for existing pricecap.
    if exists (select top 1 1 from #temp_sysgenpricecaps with (nolock))
    begin

      update D 
      set    D.PriceCapPercent = @IPN_PricecapPercent,
             D.ModifiedByID    = @IPBI_ModifiedByID,
             D.ModifiedDate    = Getdate()
      from   Customers.dbo.PriceCap D with (nolock) 
      inner join 
             #temp_sysgenpricecaps S with (nolock)
      on     D.idseq = S.pricecapidseq
    end
    else
    begin
      Update D
      set    D.Familycode = S.FamilyCode, 
             D.ProductName= S.DisplayName
      from   #temp_Orderrelatedinfo D with (nolock)
      inner join
             Products.dbo.Product S with (nolock)
      on     D.Productcode = S.code
      and    D.Priceversion= S.Priceversion

      select @LVC_PricecapName = 'Renewal adjustment of OrderID: ' + @IPVC_OrderIDSeq + 
                                 ' OrderGroupID : ' + convert(varchar(50),@IPBI_GroupIDSeq) + 
                                 ' OrderitemID  : ' + convert(varchar(50),@IPBI_OrderItemIDSeq)
      ---------------------------------------------------------------
      ---Insert Customers.dbo.PriceCap.
      ---------------------------------------------------------------
      BEGIN TRANSACTION;
         insert into Customers.dbo.PriceCap(CompanyIDSeq,PriceCapName,PriceCapBasisCode,PriceCapPercent,
                                            PriceCapTerm,PriceCapStartDate,PriceCapEndDate,
                                            ActiveFlag,SystemGeneratedPriceCapFlag,
                                            CreatedByID,CreatedDate
                                            )
        select top 1 companyidseq,@LVC_PricecapName,'DISC',@IPN_PricecapPercent,1,
               @IPDT_RenewalActivationStartDate as PriceCapStartDate,
               dateadd(yy,1,@IPDT_RenewalActivationStartDate) as PriceCapEndDate,
               1 as ActiveFlag,1 as SystemGeneratedPriceCapFlag,
               @IPBI_ModifiedByID as CreatedByID,getdate() CreatedDate
        from #temp_Orderrelatedinfo with (nolock)

        select @LBI_NewPriceCapIDSeq = SCOPE_IDENTITY() 
      COMMIT TRANSACTION; 
      ---------------------------------------------------------------
      ---Insert Customers.dbo.PriceCappropeties
      ---------------------------------------------------------------
      Insert into Customers.dbo.PriceCapProperties(PriceCapIDSeq,CompanyIDSeq,PropertyIDSeq)
      select distinct @LBI_NewPriceCapIDSeq as PriceCapIDSeq,CompanyIDSeq,PropertyIDSeq
      from #temp_Orderrelatedinfo with (nolock)
      where PropertyIDSeq is not null
      ---------------------------------------------------------------
      ---Insert Customers.dbo.PriceCapproducts
      ---------------------------------------------------------------
      Insert into Customers.dbo.PriceCapproducts(PriceCapIDSeq,CompanyIDSeq,FamilyCode,ProductCode,ProductName)
      select distinct @LBI_NewPriceCapIDSeq as PriceCapIDSeq,CompanyIDSeq,FamilyCode,ProductCode,ProductName
      from #temp_Orderrelatedinfo with (nolock)
      ---------------------------------------------------------------
    end
  end
  ------------------------------------------------------------------------
  --Final Cleanup
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  drop table #temp_sysgenpricecaps
  drop table #temp_Orderrelatedinfo
  ------------------------------------------------------------------------  
END

----exec Orders.[dbo].[uspORDERS_CreateOrModifySystemGeneratedPriceCaps] 
--                @IPVC_OrderIDSeq = '38371', @IPBI_GroupIDSeq = 38371,@IPBI_OrderItemIDSeq= 171175,
--                @IPN_PricecapPercent = '10',@IPDT_CurrentActivationEndDate='2/1/2008',
--                @IPDT_RenewalActivationStartDate = '3/1/2008',@IPBI_CreatePCIndicator='1'

    

 
GO
