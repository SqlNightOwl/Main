SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_EligibilityCheckForRollback]
-- Description     : This procedure returns 1 or 0 for Eligibility.
--                    1 is eligible for Quote Rollback.
--                    0 is NOT ELIGIBLE for Quote Rollback.

--                   This proc should be called by UI when user initiates Quote Rollback and that Quote Status is APPROVED.
--                   If Quote Status is not Approved UI can make the determination to Not allow user to rollback the Quote at all.
--
-- OUTPUT          : RecordSet of EligibilityFlag
--
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_EligibilityCheckForRollback] @IPVC_QuoteIDSeq = 'Q1010000005'
-- Revision History:
-- Author          : SRS
-- 2010-10-13      : Stored Procedure Created.Defect 7745
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_EligibilityCheckForRollback] (@IPVC_QuoteIDSeq    varchar(50) --> This is QuoteID participating in Rollback from Approved State.
                                                               )

AS
BEGIN 
  set nocount on;
  declare @LI_EligibilityFlag  int,
          @LVC_Message         varchar(2000),
          @LI_Count            int

  select  @LI_EligibilityFlag = 1,
          @LVC_Message        = 'This Quote is Eligible for Rollback.' + char(13) + char(13)+
                                'Reason: All Orders of this Quote ' + char(13) +
                                'are either Pending to be fulfilled or if fulfilled ' + char(13) +
                                'have not been Invoiced, Printed and sent to client.'
  -----------------------------------------------------------------------------------
  --Step 1 : Check if the Quote exists
  -----------------------------------------------------------------------------------
  If not exists (select top 1 1
                 from   QUOTES.dbo.Quote Q with (nolock) 
                 where  Q.QuoteIDSeq  = @IPVC_QuoteIDSeq             
                )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This Quote is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This Quote does not exist in OMS System.' + char(13) 
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end 
  -----------------------------------------------------------------------------------
  --Step 2 : Check if the Quote exists and is already in a non approved state
  -----------------------------------------------------------------------------------
  else If exists (select top 1 1
                  from   QUOTES.dbo.Quote Q with (nolock) 
                  where  Q.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    Q.QuoteStatusCode <> 'APR'
                  )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This Quote is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This Quote is not Approved. ' + char(13) +
                                 'Only Approved Quotes can be rolled back to Open Submitted State.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end 
  -----------------------------------------------------------------------------------
  --Step 3 : Check if the Quote is in approved state and Atleast one Orderitem is 
  --         fulfilled and Invoiced to Client.
  -----------------------------------------------------------------------------------
  Else If exists (select top 1 1
                  from   Orders.dbo.[Order]     O  with (nolock)
                  inner join
                         Orders.dbo.[Orderitem] OI with (nolock)
                  on     OI.OrderIDSeq = O.OrderIDSeq
                  and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    OI.POILastBillingPeriodToDate is not null
                  and    isdate(OI.POILastBillingPeriodToDate) = 1
                  inner join
                         QUOTES.dbo.Quote Q with (nolock) 
                  on     O.QuoteIDSeq  = Q.QuoteIDSeq
                  and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    Q.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    Q.QuoteStatusCode = 'APR'
                 )              
  begin
    select @LI_Count = S.CountOfOrderitems
    from   (select count(1) as CountOfOrderitems
            from   Orders.dbo.[Order]     O  with (nolock)
            inner join
                   Orders.dbo.[Orderitem] OI with (nolock)
            on     OI.OrderIDSeq = O.OrderIDSeq
            and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
            and    OI.POILastBillingPeriodToDate is not null
            and    isdate(OI.POILastBillingPeriodToDate) = 1
            inner join
                   QUOTES.dbo.Quote Q with (nolock) 
            on     O.QuoteIDSeq  = Q.QuoteIDSeq
            and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
            and    Q.QuoteIDSeq  = @IPVC_QuoteIDSeq
           ) S


    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This Quote is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This Quote is Approved with at least ' + char(13) +
                                 'one or more pertinent Orderitem(s) fulfilled, Invoiced and sent to Client already.' + char(13)+
                                 'Orderitem(s) Invoiced and Printed : ' + convert(varchar(50),@LI_Count)
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end
  -----------------------------------------------------------------------------------
  --Step 3 : Check if the Quote is in approved state and Atleast one Orderitem is 
  --         fulfilled and Invoiced to Client by checking Invoicing System.
  -----------------------------------------------------------------------------------
  Else If exists (select top 1 1
                  from   Orders.dbo.[Order]     O  with (nolock)
                  inner join
                         Orders.dbo.[Orderitem] OI with (nolock)
                  on     OI.OrderIDSeq = O.OrderIDSeq
                  and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq                  
                  inner join
                         QUOTES.dbo.Quote Q with (nolock) 
                  on     O.QuoteIDSeq  = Q.QuoteIDSeq
                  and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    Q.QuoteIDSeq  = @IPVC_QuoteIDSeq
                  and    Q.QuoteStatusCode = 'APR'
                  inner join
                         Invoices.dbo.Invoiceitem II with (nolock)
                  on     II.Orderidseq     = OI.Orderidseq
                  and    II.OrderGroupIDSeq= OI.OrderGroupIDSeq
                  and    II.OrderitemIDSeq = OI.IDSeq
                  inner join
                         Invoices.dbo.Invoice I with (nolock)
                  on     II.InvoiceIDSeq = I.InvoiceIDSeq
                  and    I.PrintFlag     = 1
                 )              
  begin
    select @LI_Count = S.CountOfOrderitems
    from   (select count(distinct OI.IDSeq) as CountOfOrderitems
            from   Orders.dbo.[Order]     O  with (nolock)
            inner join
                   Orders.dbo.[Orderitem] OI with (nolock)
            on     OI.OrderIDSeq = O.OrderIDSeq
            and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq                  
            inner join
                   QUOTES.dbo.Quote Q with (nolock) 
            on     O.QuoteIDSeq  = Q.QuoteIDSeq
            and    O.QuoteIDSeq  = @IPVC_QuoteIDSeq
            and    Q.QuoteIDSeq  = @IPVC_QuoteIDSeq
            and    Q.QuoteStatusCode = 'APR'
            inner join
                   Invoices.dbo.Invoiceitem II with (nolock)
            on     II.Orderidseq     = OI.Orderidseq
            and    II.OrderGroupIDSeq= OI.OrderGroupIDSeq
            and    II.OrderitemIDSeq = OI.IDSeq
            inner join
                   Invoices.dbo.Invoice I with (nolock)
            on     II.InvoiceIDSeq = I.InvoiceIDSeq
            and    I.PrintFlag     = 1
            group  by OI.IDSeq
           ) S


    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This Quote is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This Quote is Approved with at least ' + char(13) +
                                 'one or more pertinent Orderitem(s) fulfilled, Invoiced and sent to Client already.' + char(13)+
                                 'Orderitem(s) Invoiced and Printed : ' + convert(varchar(50),@LI_Count)
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end
  -------------------------------------------------------------------------------------
  else 
  begin
    select  @LI_EligibilityFlag = 1,
            @LVC_Message        = 'This Quote is Eligible for Rollback.' + char(13) + char(13)+
                                'Reason: All Orders of this Quote ' + char(13) +
                                'are either Pending to be fulfilled or if fulfilled ' + char(13) +
                                'have not been Invoiced, Printed and sent to client.'
  end
  -----------------------------------------------------------------------------------
  --Final Select
  -----------------------------------------------------------------------------------
  select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
  -----------------------------------------------------------------------------------
END
GO
