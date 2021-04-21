SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_UnitBedPPUChangeOperation
-- Description     : This procedure takes care of rolling back open Invoiceitems that has different Units,Beds,PPU% for Re-Invoicing.
-- Input Parameters: @IPVC_CompanyIDSeq      as varchar(50)
--                   @IPVC_PropertyIDSeq     as varchar(50)
--                   Other Input attributes as below.
-- Syntax          : 
/*
EXEC ORDERS.dbo.uspORDERS_UnitBedPPUChangeOperation  @IPVC_CompanyIDSeq='C0901010086',@IPBI_UserIDSeq=123  
EXEC ORDERS.dbo.uspORDERS_UnitBedPPUChangeOperation  @IPVC_CompanyIDSeq='C0901000061',@IPBI_UserIDSeq=123  
*/
-- Revision History:
-- Author          : SRS
-- 02/14/2010      : SRS (TFS 526,615) Units,Bed,PPU% Propagation enhancement. SP Created.
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [orders].[uspORDERS_UnitBedPPUChangeOperation] (@IPVC_CompanyIDSeq           varchar(50),    --> Mandatory : This is the CompanyID
                                                              @IPVC_PropertyIDSeq          varchar(50),    --> Mandatory : This is PropertyID. Units,Beds,PPU% are associated only to property
                                                              @IPI_CurrentUnits            int,            --> Mandatory : This is the Units
                                                              @IPI_CurrentBeds             int,            --> Mandatory : This is the Beds
                                                              @IPI_CurrentPPUPercentage    int,            --> Mandatory : This is the PPUPercentage
                                                              @IPBI_UserIDSeq              bigint = -1     --> This is UserID of person logged on and intiating this operation(Mandatory)
                                                             )
as
BEGIN --> : Main Begin
  set nocount on;
  ------------------------------------------
   --Local Variables.
  declare @LDT_SystemDate         datetime,
          @LVC_CodeSection        varchar(1000),
          @LVC_InvoiceID          varchar(50),
          @LVC_RollbackReasonCode varchar(10),
          @LI_Min                 int,
          @LI_Max                 int;
  ------------------------------------------
  select  @LDT_SystemDate = Getdate(),
          @LI_Min         = 1,
          @LI_Max         = 0;

  select Top 1 @LVC_RollbackReasonCode = R.Code 
  from   ORDERS.dbo.Reason R with (nolock)
  where  R.Code = 'BUMC'
  ----------------------------------------------------------------------------------------------
  Create table #LT_InvoicestoSyncup (Seq       int not null identity(1,1)  Primary Key,
                                     InvoiceID varchar(50)
                                    );  

  create table #LT_CurrentOpenOrderItems(Seq                       int not null identity(1,1)  Primary Key,
                                         companyidseq              varchar(50),
                                         accountidseq              varchar(50),
                                         invoiceidseq              varchar(50),
                                         invoicegroupidseq         bigint,
                                         invoiceitemidseq          bigint,
                                         orderidseq                varchar(50),
                                         ordergroupidseq           bigint,
                                         orderitemidseq            bigint,                                         
                                         productcode               varchar(50)
                                        );  
  ----------------------------------------------------------------------------------------------
  --Step 1 : Get Open invoiceitems to Roll back for Re-Invoicing.
  ----------------------------------------------------------------------------------------------
  insert into #LT_CurrentOpenOrderItems(companyidseq,accountidseq,invoiceidseq,invoicegroupidseq,invoiceitemidseq,
                                        orderidseq,ordergroupidseq,orderitemidseq,productcode)
  select I.companyidseq,I.accountidseq,I.invoiceidseq,II.invoicegroupidseq,II.IDSeq as invoiceitemidseq,
         II.orderidseq,II.ordergroupidseq,II.orderitemidseq,II.productcode
  from   Invoices.dbo.Invoice I with (nolock)
  inner join
         Invoices.dbo.Invoiceitem II with (nolock)
  on     II.InvoiceIDSeq    = I.InvoiceIDSeq
  and    I.Printflag        = 0
  and    I.PrePaidFlag      = 0
  and    I.CompanyIDSeq     = @IPVC_CompanyIDSeq 
  and    I.PropertyIDSeq    = @IPVC_PropertyIDSeq 
  and    II.MeasureCode     in ('UNIT','BED')
  and    II.orderitemtransactionidseq is null 
  inner join
         Orders.dbo.OrderItem OI with (nolock)
  on     II.OrderIDSeq      = OI.OrderIDSeq
  and    II.OrderGroupIDSeq = OI.OrderGroupIDSeq
  and    II.orderitemidseq  = OI.IDSeq
  and    OI.MeasureCode     in ('UNIT','BED')
  and   (
         (II.Units <> @IPI_CurrentUnits)
            OR
         (II.Beds  <> @IPI_CurrentBeds)
            OR
         (II.PPUPercentage <> @IPI_CurrentPPUPercentage 
            AND
          OI.FamilyCode = 'LSD'
         )
        )
  where  I.Printflag        = 0
  and    I.CompanyIDSeq     = @IPVC_CompanyIDSeq
  and    I.PropertyIDSeq    = @IPVC_PropertyIDSeq; 
  ----------------------------------------------------------------------------------------------
  --Step 2 : Get Distinct InvoiceID for the operation
  ----------------------------------------------------------------------------------------------
  insert into #LT_InvoicestoSyncup(invoiceid)
  select invoiceidseq
  from   #LT_CurrentOpenOrderItems LT with (nolock)
  group by invoiceidseq;
  ------------------------------------------------------------------
  --Step 2.1: Do Rollback of Open InvoiceItems
  ------------------------------------------------------------------
  select @LI_Min=1,@LI_Max =count(InvoiceID)
  from   #LT_InvoicestoSyncup with (nolock);
  if (@LI_Max > 0)
  begin --> Begin for Open InvoiceItems if
    BEGIN TRY      
        Delete D
        from  Invoices.dbo.InvoiceitemNote D  with (nolock)
        inner join
              #LT_CurrentOpenOrderItems    LT with (nolock)
        on    D.InvoiceIDSeq      = LT.InvoiceIDSeq
        and   D.invoiceitemidseq  = LT.invoiceitemidseq
        and   D.Orderidseq        = LT.Orderidseq
        and   D.OrderItemIDSeq    = LT.OrderItemIDSeq
        and   D.orderitemtransactionidseq is null

        Delete D
        from   Invoices.dbo.Invoiceitem    D  with (nolock)
        inner join
              #LT_CurrentOpenOrderItems    LT with (nolock)
        on    D.InvoiceIDSeq      = LT.InvoiceIDSeq
        and   D.invoicegroupidseq = LT.invoicegroupidseq
        and   D.IDSeq             = LT.invoiceitemidseq
        and   D.Orderidseq        = LT.Orderidseq
        and   D.ordergroupidseq   = LT.ordergroupidseq
        and   D.OrderItemIDSeq    = LT.OrderItemIDSeq
        and   D.Productcode       = LT.ProductCode
 
        Update OI
        set    OI.LastBillingPeriodFromDate = OI.POILastBillingPeriodFromDate,
               OI.LastBillingPeriodToDate   = OI.POILastBillingPeriodToDate,
               OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
               OI.RollbackReasonCode        = @LVC_RollbackReasonCode, 
               OI.RollbackByIDSeq           = @IPBI_UserIDSeq,
               OI.RollbackDate              = @LDT_SystemDate,
               OI.ModifiedDate              = @LDT_SystemDate,         
               OI.SystemLogDate             = @LDT_SystemDate 
        from   ORDERS.DBO.OrderItem     OI with (nolock)
        inner join
               #LT_CurrentOpenOrderItems S with (nolock) 
        on    OI.Orderidseq      = S.Orderidseq
        and   OI.OrderGroupIDSeq = S.OrderGroupIDSeq
        and   OI.IDSeq           = S.OrderItemIDSeq
        and   OI.Productcode     = S.ProductCode      
    END TRY
    BEGIN CATCH           
    END CATCH;
  end --> end for Open InvoiceItems if
  ------------------------------------------------------------------
  --Step 2.3: Do Rollback of Open InvoiceItems
  ------------------------------------------------------------------
  while @LI_Min <= @LI_Max
  begin
    select @LVC_InvoiceID = Invoiceid 
    from #LT_InvoicestoSyncup with (nolock)
    where Seq = @LI_Min
    Exec Invoices.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID = @LVC_InvoiceID;
    select @LI_Min = @LI_Min + 1
  end
  ----------------------------------------------------------------------------
  --Final Cleanup
  ----------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_CurrentOpenOrderItems') is not null) 
  begin
    drop table #LT_CurrentOpenOrderItems;
  end 
  if (object_id('tempdb.dbo.#LT_InvoicestoSyncup') is not null) 
  begin
    drop table #LT_InvoicestoSyncup;
  end   
  -----------------------------------------------------------------------------   
END --->: Main End
GO
