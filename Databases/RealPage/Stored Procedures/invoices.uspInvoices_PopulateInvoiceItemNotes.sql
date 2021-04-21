SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--Exec uspInvoices_PopulateInvoiceItemNotes @IPVC_InvoiceID = 'I0803000009'
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspInvoices_PopulateInvoiceItemNotes]  
-- Description     : This procedure deletes Item notes initially present in InvoiceItemNote Table and 
--                   Inserts Complete Notes again into InvoiceItemNote table from OrderItemItemNote table.
-- Input Parameters: @IPVC_InvoiceID
--                     
-- Code Example    : Exec Invoice.dbo.uspInvoices_PopulateInvoiceItemNotes 'I0803000036' 
--                     
-- Revision History:  
-- Author          : Shashi Bhushan
-- 03/27/2008      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspInvoices_PopulateInvoiceItemNotes] (@IPVC_InvoiceID    varchar(50),
                                                               @IPVC_OrderIDSeq   varchar(50)=''
                                                              )  
AS  
BEGIN
   set nocount on;
   if not exists (select top 1 1 
                  from   Invoices.dbo.Invoice I with (nolock)
                  where  I.Invoiceidseq     = @IPVC_InvoiceID
                  and    I.PrintFlag        = 0
                 )
   begin
     return;
   end;
   select @IPVC_OrderIDSeq = nullif(@IPVC_OrderIDSeq,'');
   ----------------------------------------------------------------------------------
   --  Deleting existing notes from InvoiceItemNote table
   --  for Orderitems pertaining to @IPVC_InvoiceID only when InvoiceIDSeq is Open
   ----------------------------------------------------------------------------------
   Delete IIN
   from   Invoices.dbo.InvoiceItemNote IIN  with (nolock)
   inner Join
          Invoices.dbo.InvoiceItem     II   with (nolock)    
   on     IIN.Invoiceidseq    = II.Invoiceidseq
   and    IIN.InvoiceItemIDSeq= II.IDSeq
   and    IIN.OrderIDSeq      = II.OrderIDSeq
   and    IIN.OrderItemIDSeq  = II.OrderItemIDSeq
   and    coalesce(IIN.OrderItemTransactionIDSeq,-999) = coalesce(II.OrderItemTransactionIDSeq,-999)    
   and    II.Invoiceidseq     = @IPVC_InvoiceID
   and    IIN.Invoiceidseq    = @IPVC_InvoiceID
   and    IIN.OrderIDSeq      = coalesce(@IPVC_OrderIDSeq,IIN.OrderIDSeq)
   and    II.OrderIDSeq       = coalesce(@IPVC_OrderIDSeq,II.OrderIDSeq)
   where  II.Invoiceidseq     = @IPVC_InvoiceID
   and    IIN.Invoiceidseq    = @IPVC_InvoiceID
   and    IIN.OrderIDSeq      = coalesce(@IPVC_OrderIDSeq,IIN.OrderIDSeq)
   and    II.OrderIDSeq       = coalesce(@IPVC_OrderIDSeq,II.OrderIDSeq);
   ----------------------------------------------------------------------------------
   -- Inserting all the notes into InvoiceItemNote table for the passed InvoiceIDSeq
   ----------------------------------------------------------------------------------
   Insert into Invoices.dbo.Invoiceitemnote
                  (InvoiceIDSeq,InvoiceItemIDSeq,OrderIDSeq,OrderItemIDSeq,OrderItemTransactionIDSeq,
                   Title,Description,MandatoryFlag,PrintOnInvoiceFlag,SortSeq,CreatedDate)
   SELECT          II.InvoiceIDSeq               as InvoiceIDSeq,
                   Min(II.IDSeq)                 as InvoiceItemIDSeq,
                   OIN.OrderIDSeq                as OrderIDSeq,
                   OIN.OrderItemIDSeq            as OrderItemIDSeq,
                   OIN.OrderItemTransactionIDSeq as OrderItemTransactionIDSeq,
                   OIN.Title                     as Title,
                   OIN.Description               as Description,
                   OIN.MandatoryFlag             as MandatoryFlag,
                   OIN.PrintOnInvoiceFlag        as PrintOnInvoiceFlag,
                   OIN.SortSeq                   as SortSeq,
                   getdate()                     as CreatedDate
   from    Invoices.dbo.InvoiceItem II     with (nolock)
   inner join
           Orders.dbo.OrderItemNote OIN    with (nolock)
   on      OIN.OrderIDSeq     = II.OrderIDSeq
   and     OIN.OrderItemIDSeq = II.OrderItemIDSeq
   and     coalesce(OIN.OrderItemTransactionIDSeq,-999) = coalesce(II.OrderItemTransactionIDSeq,-999)
   and     OIN.OrderIDSeq = coalesce(@IPVC_OrderIDSeq,OIN.OrderIDSeq)
   and     II.OrderIDSeq  = coalesce(@IPVC_OrderIDSeq,II.OrderIDSeq)
   and     OIN.PrintOnInvoiceFlag = 1
   and     II.Invoiceidseq    = @IPVC_InvoiceID
   where   II.Invoiceidseq    = @IPVC_InvoiceID
   and     II.OrderIDSeq  = coalesce(@IPVC_OrderIDSeq,II.OrderIDSeq)
   and     OIN.OrderIDSeq = coalesce(@IPVC_OrderIDSeq,OIN.OrderIDSeq)
   group by
           II.InvoiceIDSeq,OIN.OrderIDSeq,OIN.OrderItemIDSeq,OIN.OrderItemTransactionIDSeq,
           OIN.Title,OIN.Description,OIN.MandatoryFlag,OIN.PrintOnInvoiceFlag,OIN.SortSeq
   Order by OIN.OrderIDSeq DESC,OIN.OrderItemIDSeq DESC,OIN.SortSeq ASC;
END  
-----------------------------------------------------------------------------------------------
GO
