SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_UpdateFirstActivationDate]
-- Description     : This procedure Updates FirstActivationDate in OrderItem Table
--Input Parameter  : 
--
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_UpdateFirstActivationDate] 
--
-- Revision History:
-- Author          : SRS
-- 11/13/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateFirstActivationDate]  (@IPVC_CompanyIDSeq  varchar(50)=Null
                                                              )
AS
BEGIN 
  set nocount on;
  SET ANSI_WARNINGS OFF;  
  -----------------------------------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate    = Getdate(),
          @IPVC_CompanyIDSeq = nullif(@IPVC_CompanyIDSeq,'')

  Create Table #LT_OrderProductCustomerSince(SEQ                       bigint Not Null identity(1,1) primary Key,
                                             AccountIDSeq              varchar(50),
                                             ProductCode               varchar(50),
                                             FirstActivationStartDate  varchar(20)
                                            )

  Insert into #LT_OrderProductCustomerSince(AccountIDSeq,ProductCode,FirstActivationStartDate)
  Select OInner.AccountIDSeq,OIInner.Productcode,(case when  (isdate(Min(OIInner.FirstActivationStartDate))=1  and
                                                               isdate(Min(OIInner.ActivationStartDate))     =1  and
                                                               Min(OIInner.FirstActivationStartDate) <= Min(OIInner.ActivationStartDate)
                                                              )
                                                             then Convert(varchar(20),Min(OIInner.FirstActivationStartDate),101)
                                                        when  (isdate(Min(OIInner.FirstActivationStartDate))=1  and
                                                               isdate(Min(OIInner.ActivationStartDate))     =1  and
                                                               Min(OIInner.FirstActivationStartDate) > Min(OIInner.ActivationStartDate)
                                                              )
                                                            then Convert(varchar(20),Min(OIInner.ActivationStartDate),101)
                                                        when isdate(Min(OIInner.FirstActivationStartDate))=1 
                                                            then Convert(varchar(20),Min(OIInner.FirstActivationStartDate),101)
                                                        when isdate(Min(OIInner.ActivationStartDate))=1 
                                                            then Convert(varchar(20),Min(OIInner.ActivationStartDate),101)
                                                        else NULL
                                                        end) as FirstActivationStartDate
  from   ORDERS.dbo.[ORDER]     OInner   with (nolock)              
  inner  join
         ORDERS.dbo.[OrderItem] OIInner  with (nolock)
  on     OInner.Orderidseq   = OIInner.Orderidseq
  and    OInner.CompanyIDSeq = coalesce(@IPVC_CompanyIDSeq,OInner.CompanyIDSeq)
  and    OIInner.chargetypecode = 'ACS'
  and    (isdate(OIInner.FirstActivationStartDate) = 1 
                 OR
          isdate(OIInner.ActivationStartDate) = 1
         )
  group  by OInner.AccountIDSeq,OIInner.Productcode
  Order  by OInner.AccountIDSeq asc,OIInner.Productcode asc
  ----------------------------------------------------------- 
  Update OI
  set    OI.FirstActivationStartDate = S.FirstActivationStartDate,
         OI.SystemLogdate = (case when (OI.FirstActivationStartDate <>S.FirstActivationStartDate) then  @LDT_SystemDate
                                  else OI.SystemLogdate
                             end)
  from   Orders.dbo.[ORDER]     O  with (nolock)
  inner join
         Orders.dbo.[ORDERITEM] OI with (nolock)
  on     O.Orderidseq   = OI.Orderidseq
  and    O.CompanyIDSeq = coalesce(@IPVC_CompanyIDSeq,O.CompanyIDSeq)
  inner Join
         #LT_OrderProductCustomerSince S with (nolock)
  on     O.AccountIDSeq = S.AccountIDSeq
  and    OI.Productcode = S.Productcode
  where  O.Orderidseq   = OI.Orderidseq
  and    O.AccountIDSeq = S.AccountIDSeq
  and    OI.Productcode = S.Productcode    
  -----------------------------------------------------------
  ---Final Cleanup
  if (object_id('tempdb.dbo.#LT_OrderProductCustomerSince') is not null) 
  begin
    drop table #LT_OrderProductCustomerSince;
  end; 
  -----------------------------------------------------------
END
GO
