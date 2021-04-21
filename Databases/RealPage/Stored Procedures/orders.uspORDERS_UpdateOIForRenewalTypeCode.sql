SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_UpdateOIForRenewalTypeCode
-- Description     : Updates Orderitem's RenewalTypecode
-- Input Parameters: @IPVC_OrderIDSeq      varchar(50),
--                   @IPBI_GroupIDSeq      bigint,
--                   @IPBI_OrderItemIDSeq  bigint='',
--                   @IPVC_RenewalTypeCode varchar(20)
--                   
-- OUTPUT          : none
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_UpdateOIForRenewalTypeCode] parameters                                     
-- Revision History:
-- Author          : SRS
-- 11/30/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateOIForRenewalTypeCode] (@IPVC_OrderIDSeq      varchar(50),
                                                               @IPBI_GroupIDSeq      bigint,
                                                               @IPBI_OrderItemIDSeq  bigint='',
                                                               @IPDT_CurrentActivationEndDate datetime,
                                                               @IPVC_RenewalTypeCode varchar(20),
                                                               @IPI_RenewalReviewedFlag int = 0
                                                               )
AS
BEGIN
 set nocount on
 ------------------------------------------------------------------------------------------------------
 ---If @IPBI_GroupIDSeq is a custom stock bundle, then RenewalTypeCode change applies all 
 -- latest ACS orderitems in the bundle that have the same @IPDT_CurrentActivationEndDate
 If exists (select top 1 1 from ORDERS.dbo.OrderGroup with (nolock)
            where OrderIDSeq = @IPVC_OrderIDSeq
            and   IDSeq      = @IPBI_GroupIDSeq
            and   CustomBundleNameEnabledFlag = 1
            )
 begin
   Update D
   set    D.Renewaltypecode =  @IPVC_RenewalTypeCode,
          D.RenewalReviewedFlag = @IPI_RenewalReviewedFlag
   from   ORDERS.dbo.ORDERITEM D with (nolock)
   where  D.OrderIDSeq        = @IPVC_OrderIDSeq
   and    D.OrderGroupIDSeq   = @IPBI_GroupIDSeq 
   and    D.ActivationEnddate = @IPDT_CurrentActivationEndDate
   and    D.statuscode     <> 'PENR'
   and    D.ChargeTypeCode <> 'ILF'
   /* 
   and    D.IDseq   = (select MAX (X.IDSeq)
                       from   Orders.dbo.Orderitem X with (nolock)
                       where  X.OrderIDSeq      = D.OrderIDSeq
                       and    X.OrderGroupIDSeq = D.OrderGroupIDSeq
                       and    D.OrderIDSeq      = @IPVC_OrderIDSeq
                       and    D.OrderGroupIDSeq = @IPBI_GroupIDSeq 
                       and    X.OrderIDSeq      = @IPVC_OrderIDSeq
                       and    X.OrderGroupIDSeq = @IPBI_GroupIDSeq
                       and    X.statuscode      = D.statuscode
                       and    X.ActivationEnddate = D.ActivationEnddate
                       and    X.ActivationEnddate = @IPDT_CurrentActivationEndDate
                       and    D.statuscode     <> 'PENR'
                       and    X.statuscode     <> 'PENR'
                       and    X.productcode     = D.Productcode
                       and    X.chargetypecode  = D.Chargetypecode
                       and    X.Measurecode     = D.Measurecode
                       and    X.Frequencycode   = D.Frequencycode
                      )
    */
  end
  else
  begin
    ---Else if Group is not a custom stock bundle then renewaltypecode update is 
    --- specific to orderitem
    Update ORDERS.dbo.ORDERITEM
    set    Renewaltypecode     = @IPVC_RenewalTypeCode,
           RenewalReviewedFlag = @IPI_RenewalReviewedFlag
    where  OrderIDSeq        = @IPVC_OrderIDSeq
    and    OrderGroupIDSeq   = @IPBI_GroupIDSeq 
    and    IDSeq             = @IPBI_OrderItemIDSeq
  end
END
GO
