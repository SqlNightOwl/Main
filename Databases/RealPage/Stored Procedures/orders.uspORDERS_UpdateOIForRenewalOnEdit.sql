SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_UpdateOIForRenewalOnEdit
-- Description     : Updates Orderitem's RenewalTypecode
-- Input Parameters: @IPVC_OrderIDSeq      varchar(50),
--                   @IPBI_GroupIDSeq      bigint,
--                   @IPBI_OrderItemIDSeq  bigint='',
--                   @IPVC_RenewalTypeCode varchar(20)
--                   
-- OUTPUT          : none
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_UpdateOIForRenewalOnEdit] parameters                                     
-- Revision History:
-- Author          : SRS
-- 11/30/2007      : Stored Procedure Created.
-- 07/02/2010      : ShashiBhushan - Modified to revert #7923 changes
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateOIForRenewalOnEdit] (@IPVC_OrderIDSeq                 varchar(50),
                                                             @IPBI_GroupIDSeq                 bigint,
                                                             @IPBI_OrderItemIDSeq             bigint,
                                                             @IPVC_recordtype                 varchar(5),
                                                             @IPI_custombundlenameenabledflag int,
                                                             @IPBI_renewalcount               bigint,
                                                             @IPBI_orderitemcount             bigint,
                                                             @IPN_renewalchargeamount         money,
                                                             @IPN_Originalrenewaladjustedchargeamount money,
                                                             @IPN_renewaladjustedchargeamount money,
                                                             @IPI_RenewalUserOverrideFlag     int = 0,
                                                             @IPVC_RenewalTypeCode            varchar(20),                                   
                                                             @IPI_RenewalReviewedFlag         int = 0,
                                                             @IPDT_RenewalStartDate           varchar(50)  ='',
                                                             @IPVC_renewalnotes               varchar(1000)='',
                                                             @IPBI_RenewedByUserIDSeq         bigint
                                                             )
AS
BEGIN
 set nocount on;
 declare @LN_BundleTotal       money
 declare @LDT_SystemDate       datetime
 declare @LI_ChangeIndicator   int
 ------------------------------------------------------------------------------------------------------
 set @IPDT_RenewalStartDate = (case when isdate(nullif(@IPDT_RenewalStartDate,'')) = 1 then nullif(@IPDT_RenewalStartDate,'')
                                     else NULL
                               end)
 set @IPVC_renewalnotes     = ltrim(rtrim(nullif(@IPVC_renewalnotes,'')))
 set @IPN_renewaladjustedchargeamount = (case when @IPI_RenewalUserOverrideFlag = 1 then @IPN_renewaladjustedchargeamount
                                              when @IPI_RenewalUserOverrideFlag = 0 then NULL
                                              Else NULL
                                         end)
 set @LDT_SystemDate = Getdate()
 set @LI_ChangeIndicator = 0
 ------------------------------------------------------------------------------------------------------

  if (@IPI_custombundlenameenabledflag=0)
  begin
    if exists(select top 1 1
              from   ORDERS.dbo.OrderItem OI with (nolock)
              where  OI.OrderIDSeq      = @IPVC_OrderIDSeq
              and    OI.OrderGroupIDSeq = @IPBI_GroupIDSeq
              and    OI.IDSeq           = @IPBI_OrderItemIDSeq
              and    OI.RenewalCount    = @IPBI_renewalcount
              and    OI.StatusCode      = 'FULF'
              and    OI.ChargeTypeCode  = 'ACS'
              and    (OI.FrequencyCode <> 'OT' and OI.FrequencyCode <> 'SG')
              and    @IPVC_recordtype = 'PR' 
              and   (binary_checksum(convert(money,coalesce(OI.RenewalAdjustedChargeAmount,0)),
                                      convert(int,RenewalUserOverrideFlag),convert(varchar(5),RenewalTypeCode),convert(varchar(50),coalesce(RenewalStartDate,'01/01/1900'),101),convert(int,RenewalReviewedFlag),convert(varchar(8000),coalesce(RenewalNotes,''))
                                      ) <>
                     binary_checksum(convert(money,coalesce(@IPN_renewaladjustedchargeamount,0)),
                                       convert(int,@IPI_RenewalUserOverrideFlag),convert(varchar(5),@IPVC_RenewalTypeCode),convert(varchar(50),coalesce(@IPDT_RenewalStartDate,'01/01/1900')),convert(int,@IPI_RenewalReviewedFlag),convert(varchar(8000),coalesce(@IPVC_renewalnotes,''))
                                      )
                    )
            )
    begin
      select @LI_ChangeIndicator = 1
    end
    else
    begin
      select @LI_ChangeIndicator = 0
    end

    Update ORDERS.dbo.OrderItem
    set    RenewalAdjustedChargeAmount = @IPN_renewaladjustedchargeamount,
           RenewalUserOverrideFlag     = @IPI_RenewalUserOverrideFlag,
           RenewalTypeCode             = @IPVC_RenewalTypeCode,
           RenewalStartDate            = @IPDT_RenewalStartDate,
           RenewalReviewedFlag         = @IPI_RenewalReviewedFlag,
           RenewalNotes                = @IPVC_renewalnotes,
           RenewedByUserIDSeq          = (case when @LI_ChangeIndicator = 1 
                                                 then @IPBI_RenewedByUserIDSeq
                                               else RenewedByUserIDSeq
                                          end),
           RenewalReviewedDate         = (case when @LI_ChangeIndicator = 1 
                                                 then @LDT_SystemDate
                                               else RenewalReviewedDate
                                          end),
           ModifiedByUserIDSeq         = (Case when (RenewalTypeCode <> @IPVC_RenewalTypeCode)
                                                then @IPBI_RenewedByUserIDSeq
                                               else ModifiedByUserIDSeq
                                          end),
           ModifiedDate                = (Case when (RenewalTypeCode <> @IPVC_RenewalTypeCode)
                                                then @LDT_SystemDate
                                               else ModifiedDate
                                          end),
           SystemLogDate               = @LDT_SystemDate
    where  OrderIDSeq      = @IPVC_OrderIDSeq
    and    OrderGroupIDSeq = @IPBI_GroupIDSeq
    and    IDSeq           = @IPBI_OrderItemIDSeq
    and    RenewalCount    = @IPBI_renewalcount
    and    StatusCode      = 'FULF'
    and    ChargeTypeCode  = 'ACS'
    and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG')
    and    @IPVC_recordtype = 'PR' 
  end
  else if (@IPI_custombundlenameenabledflag=1)
  begin
    --For a Custom Stock Bundle, the change applies to all applicable Orderitems.
    if exists(select top 1 1
              from   ORDERS.dbo.OrderItem OI with (nolock)
              where  OI.OrderIDSeq      = @IPVC_OrderIDSeq
              and    OI.OrderGroupIDSeq = @IPBI_GroupIDSeq              
              and    OI.RenewalCount    = @IPBI_renewalcount
              and    OI.StatusCode      = 'FULF'
              and    OI.ChargeTypeCode  = 'ACS'
              and    (OI.FrequencyCode <> 'OT' and OI.FrequencyCode <> 'SG')
              and    @IPVC_recordtype = 'CB'
              and    ( binary_checksum(convert(money,coalesce(OI.RenewalAdjustedChargeAmount,0)),
                                       convert(int,RenewalUserOverrideFlag),convert(varchar(5),RenewalTypeCode),convert(varchar(50),coalesce(RenewalStartDate,'01/01/1900'),101),convert(int,RenewalReviewedFlag),convert(varchar(8000),coalesce(RenewalNotes,''))
                                      ) <>
                       binary_checksum(convert(money,
                                                  convert(float,(coalesce(@IPN_renewaladjustedchargeamount,0)))
                                                      /
                                                  convert(float,(case when @IPBI_orderitemcount > 0 then @IPBI_orderitemcount else 1 end))
                                              ),
                                       convert(int,@IPI_RenewalUserOverrideFlag),convert(varchar(5),@IPVC_RenewalTypeCode),convert(varchar(50),coalesce(@IPDT_RenewalStartDate,'01/01/1900')),convert(int,@IPI_RenewalReviewedFlag),convert(varchar(8000),coalesce(@IPVC_renewalnotes,''))
                                      )
                      )
            )
    begin
      select @LI_ChangeIndicator = 1
    end
    else
    begin
      select @LI_ChangeIndicator = 0
    end



    Update ORDERS.dbo.OrderItem
    set    RenewalAdjustedChargeAmount = NULL,
           RenewalUserOverrideFlag     = @IPI_RenewalUserOverrideFlag,
           RenewalTypeCode             = @IPVC_RenewalTypeCode,
           RenewalStartDate            = @IPDT_RenewalStartDate,
           RenewalReviewedFlag         = @IPI_RenewalReviewedFlag,
           RenewalNotes                = @IPVC_renewalnotes,
           RenewedByUserIDSeq          = (case when @LI_ChangeIndicator = 1 
                                                 then @IPBI_RenewedByUserIDSeq
                                               else RenewedByUserIDSeq
                                          end),
           RenewalReviewedDate         = (case when @LI_ChangeIndicator = 1 
                                                 then @LDT_SystemDate
                                               else RenewalReviewedDate
                                          end),
           ModifiedByUserIDSeq         = (Case when (RenewalTypeCode <> @IPVC_RenewalTypeCode)
                                                then @IPBI_RenewedByUserIDSeq
                                               else ModifiedByUserIDSeq
                                          end),
           ModifiedDate                = (Case when (RenewalTypeCode <> @IPVC_RenewalTypeCode)
                                                then @LDT_SystemDate
                                               else ModifiedDate
                                          end),           
           SystemLogDate               = @LDT_SystemDate 
    where  OrderIDSeq      = @IPVC_OrderIDSeq
    and    OrderGroupIDSeq = @IPBI_GroupIDSeq    
    and    RenewalCount    = @IPBI_renewalcount
    and    StatusCode      = 'FULF'
    and    ChargeTypeCode  = 'ACS'
    and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG') 
    and    @IPVC_recordtype = 'CB' 
 
    -- Update for RenewalAdjustedChargeAmount distribution
    if (@IPN_renewaladjustedchargeamount is not null and @IPI_RenewalUserOverrideFlag = 1)
    begin
      Update ORDERS.dbo.OrderItem
      set    RenewalAdjustedChargeAmount = convert(money,
                                                       convert(float,(@IPN_renewaladjustedchargeamount))
                                                                   /
                                                       convert(float,(case when @IPBI_orderitemcount > 0 then @IPBI_orderitemcount else 1 end))
                                                   )
      where  OrderIDSeq      = @IPVC_OrderIDSeq
      and    OrderGroupIDSeq = @IPBI_GroupIDSeq    
      and    RenewalCount    = @IPBI_renewalcount
      and    StatusCode      = 'FULF'
      and    ChargeTypeCode  = 'ACS'
      and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG')
      and    @IPVC_recordtype = 'CB' 
      --- Get the Bundle total based on distributed RenewalAdjustedChargeAmount
      select @LN_BundleTotal      = coalesce(sum(OI.RenewalAdjustedChargeAmount),0),
             @IPBI_OrderItemIDSeq = Max(OI.IDSeq)
      from   ORDERS.dbo.OrderItem OI with (nolock)
      where  OrderIDSeq      = @IPVC_OrderIDSeq
      and    OrderGroupIDSeq = @IPBI_GroupIDSeq    
      and    RenewalCount    = @IPBI_renewalcount
      and    StatusCode      = 'FULF'
      and    ChargeTypeCode  = 'ACS'
      and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG')
      and    @IPVC_recordtype = 'CB'
      group by OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.RenewalCount 

      if (@IPN_renewaladjustedchargeamount <> @LN_BundleTotal)
      begin
        ---Plug for the last Orderitem
        Update ORDERS.dbo.OrderItem
        set    RenewalAdjustedChargeAmount = RenewalAdjustedChargeAmount + (case when (@IPN_renewaladjustedchargeamount <> @LN_BundleTotal)
                                                                                   then (@IPN_renewaladjustedchargeamount - @LN_BundleTotal)                                                                                 
                                                                                 else 0
                                                                            end)
        where  OrderIDSeq      = @IPVC_OrderIDSeq
        and    OrderGroupIDSeq = @IPBI_GroupIDSeq  
        and    IDSeq           = @IPBI_OrderItemIDSeq  
        and    RenewalCount    = @IPBI_renewalcount
        and    StatusCode      = 'FULF'
        and    ChargeTypeCode  = 'ACS'
        and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG')
        and    @IPVC_recordtype = 'CB' 
      end         
    end
  end
END
GO
