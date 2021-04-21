SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_UnprintedInvoiceSelect
-- Description     : This procedure gets the invoices that haven't been printed
-- Revision History:
-- Author          : DC
-- 4/5/2007        : Stored Procedure Created.
-- 27/11/2007	   : Naval Kishore Modified Proc to add @IPVC_PullListIDSeq
-- 04/23/2008      : Defect #4947
-- 10/23/2008      : Aligned the Code.Included SnH amount in TotalAmount column calculation
--------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UnprintedInvoiceSelect] 
                                                           (
                                                             @IPI_PageNumber     int, 
                                                             @IPI_RowsPerPage    int,
                                                             @IPVC_CustomerIDSeq varchar(20),
                                                             @IPVC_AccountIDSeq  varchar(20),                                                             
                                                             @IPVC_PullListIDSeq varchar(20) = ''
                                                           )
AS
BEGIN
  set nocount on;
  ------------------------------------------------------
  if (@IPVC_PullListIDSeq ='')
  Begin 
    WITH tablefinal AS 
    ----------------------------------------------------------  
    (SELECT tableinner.*
     FROM
     ---------------------------------------------------------- 
     (select  row_number() over(order by source.InvoiceIDSeq) as RowNumber,
              source.*
      from
      ---------------------------------------------------------- 
     (SELECT DISTINCT  Ivc.InvoiceIDSeq,
                       Ivc.CompanyIDSeq, 
                       isnull(Ivc.PropertyName,Ivc.CompanyName) AS AccountName,  
                       Ivc.CompanyName,
                       Ivc.AccountIDSeq, 
                       Ivc.ILFChargeAmount,  
                       Ivc.AccessChargeAmount,
                       Ivc.TransactionChargeAmount,  
                       Ivc.TaxAmount                     AS TaxAmount,
                       (
                          Ivc.ILFChargeAmount 
                        + Ivc.AccessChargeAmount 
                        + Ivc.TransactionChargeAmount 
                        + Ivc.TaxAmount
                        + Ivc.ShippingAndHandlingAmount
                       )                                 AS TotalAmount,
                       coalesce(IRM.ReportDefinitionFile,'Invoice1')    as ReportDefinitionFile  
      FROM   Invoices.dbo.Invoice     Ivc    WITH (NOLOCK)
      Left outer Join
             Products.dbo.InvoiceReportMapping IRM with (nolock)
      on     Ivc.SeparateInvoiceGroupNumber = IRM.SeparateInvoiceGroupNumber   			   
      WHERE  Ivc.PrintFlag = 0
      AND   ((@IPVC_CustomerIDSeq = '') or (Ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))  
      AND ((@IPVC_AccountIDSeq = '')  or (Ivc.AccountIDSeq = @IPVC_AccountIDSeq))                                 
      ---------------------------------------------------------------
      ) source
      --------------------------------------------------------------------
    )tableinner
      ------------------------------------------------------------------------
    WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
    AND  tableinner.RowNumber <= (@IPI_PageNumber)  * @IPI_RowsPerPage    
    ----------------------------------------------------------------------------
    )
    ----------------------------------------------------------------------------
    --  Selecting data from TABLEFINAL
    ----------------------------------------------------------------------------
    select InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
           ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
           ReportDefinitionFile
    from   tablefinal 
    ----------------------------------------------------------------------------
  End
  ELSE
  Begin 
    WITH tablefinal AS 
    ----------------------------------------------------------  
    (SELECT tableinner.*
     FROM
     ---------------------------------------------------------- 
     (select  row_number() over(order by source.InvoiceIDSeq) as RowNumber,
              source.*
      from
      ---------------------------------------------------------- 
      (select ivc.InvoiceIDSeq, 
              ivc.CompanyIDSeq, 
              isnull(Ivc.PropertyName, Ivc.CompanyName) as AccountName,
              CompanyName,
              ivc.AccountIDSeq,
              ivc.ILFChargeAmount,
              ivc.AccessChargeAmount,
              ivc.TransactionChargeAmount,
              ivc.TaxAmount                     as TaxAmount,
             (
                Ivc.ILFChargeAmount 
              + Ivc.AccessChargeAmount 
              + Ivc.TransactionChargeAmount 
              + Ivc.TaxAmount
              + Ivc.ShippingAndHandlingAmount
             )                                 AS TotalAmount,
             coalesce(IRM.ReportDefinitionFile,'Invoice1')    as ReportDefinitionFile 
      from   Invoices.dbo.Invoice         ivc with (nolock)
      INNER JOIN 
             INVOICES.dbo.PullListAccounts pa with (nolock)
      on     pa.AccountIDSeq        = ivc.AccountIDSeq
      AND    pa.PullListIDSeq       = @IPVC_PullListIDSeq
      AND    ivc.PrintFlag          = 0
      Left outer Join
             Products.dbo.InvoiceReportMapping IRM with (nolock)
      on     Ivc.SeparateInvoiceGroupNumber = IRM.SeparateInvoiceGroupNumber   	
      WHERE  Ivc.PrintFlag    = 0  
      AND    pa.PullListIDSeq = @IPVC_PullListIDSeq
      AND    ((@IPVC_CustomerIDSeq = '') or (Ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))  
      AND    ((@IPVC_AccountIDSeq = '')  or (Ivc.AccountIDSeq = @IPVC_AccountIDSeq))                                 
      ---------------------------------------------------------------
     ) source
     --------------------------------------------------------------------
     )tableinner
     ------------------------------------------------------------------------
     WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
     AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage    
     ---------------------------------------------------------------------------
     )
     ----------------------------------------------------------------------------
     --  Selecting data from TABLEFINAL
     ----------------------------------------------------------------------------
     select InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
            ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
            ReportDefinitionFile
     from   tablefinal 
     ----------------------------------------------------------------------------
  End
  ---------------------------------------------------------- 
  ---Counts --Second RecordSet
  IF (@IPVC_PullListIDSeq ='')
  Begin 
    SELECT count(DISTINCT Ivc.InvoiceIDSeq)      as TotalCount, 
           coalesce(sum (  Ivc.ILFChargeAmount 
                         + Ivc.AccessChargeAmount 
                         + Ivc.TransactionChargeAmount 
                         + Ivc.TaxAmount 
                         + Ivc.ShippingAndHandlingAmount
                         ),0)                     as TotalAmount
    FROM Invoices.dbo.Invoice Ivc WITH (NOLOCK)  
    WHERE Ivc.PrintFlag          = 0
    AND ((@IPVC_CustomerIDSeq = '') or (Ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))  
    AND ((@IPVC_AccountIDSeq = '')  or (Ivc.AccountIDSeq = @IPVC_AccountIDSeq))
  End
  ELSE
  Begin
    SELECT count(DISTINCT Ivc.InvoiceIDSeq)       as TotalCount, 
           coalesce(sum (  Ivc.ILFChargeAmount 
                         + Ivc.AccessChargeAmount 
                         + Ivc.TransactionChargeAmount 
                         + Ivc.TaxAmount 
                         + Ivc.ShippingAndHandlingAmount
                         ),0)                     as TotalAmount                  
    FROM Invoices.dbo.Invoice           ivc with (nolock)
    INNER JOIN 
         INVOICES.dbo.PullListAccounts  pa with (nolock)
    ON   pa.AccountIDSeq        = ivc.AccountIDSeq
    AND  ivc.PrintFlag          = 0
    AND  pa.PullListIDSeq       = @IPVC_PullListIDSeq            
    WHERE Ivc.PrintFlag = 0 
    AND  pa.PullListIDSeq=@IPVC_PullListIDSeq 
    AND ((@IPVC_CustomerIDSeq = '') or (Ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))  
    AND ((@IPVC_AccountIDSeq = '')  or (Ivc.AccountIDSeq = @IPVC_AccountIDSeq))                                 
  End
END
GO
