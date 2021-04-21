SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_UpdateOIForReviewedFlag
-- Description     : Updates Orderitem's RenewalTypecode
-- Input Parameters: @IPVC_OrderIDSeq      varchar(50),
--                   @IPBI_GroupIDSeq      bigint,
--                   @IPBI_OrderItemIDSeq  bigint='',
--                   @IPVC_RenewalTypeCode varchar(20)
--                   
-- OUTPUT          : none
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_UpdateOIForReviewedFlag] parameters                                     
-- Revision History:
-- Author          : SRS
-- 11/30/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateOIForReviewedFlag]  (@IPVC_OrderIDSeq                 varchar(50),
                                                             @IPBI_GroupIDSeq                 bigint,
                                                             @IPBI_OrderItemIDSeq             bigint,
                                                             @IPVC_recordtype                 varchar(5),
                                                             @IPI_custombundlenameenabledflag int,
                                                             @IPBI_renewalcount               bigint,                                                                                                
                                                             @IPI_RenewalReviewedFlag         int = 0,
                                                             @IPBI_RenewedByUserIDSeq         bigint
                                                             )
AS
BEGIN
 set nocount on
 ------------------------------------------------------------------------------------------------------
  if (@IPI_custombundlenameenabledflag=0)
  begin
    Update ORDERS.dbo.ORDERITEM
    set    RenewalReviewedFlag         = @IPI_RenewalReviewedFlag,
           RenewedByUserIDSeq          = @IPBI_RenewedByUserIDSeq
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
    Update ORDERS.dbo.ORDERITEM
    set    RenewalReviewedFlag         = @IPI_RenewalReviewedFlag,
           RenewedByUserIDSeq          = @IPBI_RenewedByUserIDSeq
    where  OrderIDSeq      = @IPVC_OrderIDSeq
    and    OrderGroupIDSeq = @IPBI_GroupIDSeq    
    and    RenewalCount    = @IPBI_renewalcount
    and    StatusCode      = 'FULF'
    and    ChargeTypeCode  = 'ACS'
    and    (FrequencyCode <> 'OT' and FrequencyCode <> 'SG')
    and    @IPVC_recordtype = 'CB'  
  end
END


GO
