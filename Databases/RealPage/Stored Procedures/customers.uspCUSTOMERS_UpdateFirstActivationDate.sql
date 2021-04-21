SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_UpdateFirstActivationDate]
-- Description     : This procedure Updates BillTo in OrderItem Table
--Input Parameter  : @IPVC_AccountID           varchar(50), 
--                   @IPVC_ProductCode         varchar(50),
--                   @IPVC_ProductCustomerSinceDate varchar(20)
--
-- Code Example    : Products..[uspCUSTOMERS_UpdateFirstActivationDate] 
--
-- Revision History:
-- Author          : SRS
-- 11/13/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_UpdateFirstActivationDate] (@IPVC_AccountID                varchar(50),                                                                  
                                                                 @IPVC_ProductCode              varchar(30),
                                                                 @IPVC_ProductCustomerSinceDate varchar(20)
                                                               )     
AS
BEGIN 
  set nocount on;
  If isdate(@IPVC_ProductCustomerSinceDate) = 1
  begin
    Update OI
    set    OI.FirstActivationStartDate = @IPVC_ProductCustomerSinceDate
    from   Orders.dbo.[ORDER]     O  with (nolock)
    inner join
           Orders.dbo.[ORDERITEM] OI with (nolock)
    on     O.Orderidseq   = OI.Orderidseq
    and    O.AccountIDSeq = @IPVC_AccountID
    and    OI.Productcode = @IPVC_ProductCode
    where  O.Orderidseq   = OI.Orderidseq
    and    O.AccountIDSeq = @IPVC_AccountID
    and    OI.Productcode = @IPVC_ProductCode
  end
END

GO
