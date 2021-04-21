SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_BatchProcessList
-- Description     : This procedure returns the epicor batches
-- 
-- OUTPUT          : RecordSet of ID,CompanyName,CompanyIDSeq,
--                                StatusName,AccountIDSeq,CreatedDate,Period,LastInvoice
-- Code Example    : INVOICES.dbo.uspINVOICES_BatchProcessList @IPI_PageNumber=1,@IPI_RowsPerPage=22
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006        : Stored Procedure Created.
-- 03/11/2008      : Defect #4753
-- 4/6/2009		   : Naval Kishore Modified the SP to convert paramater as DateTime, defect#6259 
-- 08/10/2010	   : SRS   : Modified proc to return extra column TotalBatchCountForPaging for UI pagination. 
--                           The value of TotalBatchCountForPaging of the first row will be used by UI for pagination.
-- 09/23/2010 : Defect # 8245 Send Invoices and Credits to Epicor date range does not restrict results for the year
-- 02/24/2010 : Defect# 8685: Send to Epicor Issue --> When you enter the date range of 11.3.2010 for both start and 
--				end date in production oms it does not return the batch.  If you put an end date of 11.4.2010 instead 
--				then the 11/3 batch is returned.
-- 05/09/2011 :	Surya Kondapalli  Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
-------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BatchProcessList] (@IPI_PageNumber          int, 
                                                       @IPI_RowsPerPage         int,                        
                                                       @IPVC_EpicorBatchCode    varchar(50)='',
                                                       @IPVC_SentOn             varchar(1) ='A', 
                                                       @IB_ShowFailures         bit        =0,
                                                       @IPVC_Type               varchar(50)='', --> Possible Values are '' for all, 'INVOICE', 'CREDIT','REVERSE CREDIT'
                                                       @IPVC_StartDate          datetime = '01/01/1900',     
                                                       @IPVC_EndDate            datetime = '01/01/1900',   
                                                       @IPVC_ModifiedByUser     varchar(255)=''		
                                                      )   WITH RECOMPILE
AS
BEGIN
  set nocount on;
  select @IPVC_EpicorBatchCode = nullif(ltrim(rtrim(@IPVC_EpicorBatchCode)),''),
         @IPVC_ModifiedByUser  = nullif(ltrim(rtrim(@IPVC_ModifiedByUser)),''),
         @IPVC_Type            = nullif(nullif(ltrim(rtrim(@IPVC_Type)),''),'ALL')
         
 if (@IPVC_EndDate = '01/01/1900')
	set @IPVC_EndDate = GETDATE()         

  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------------------
  ;WITH tablefinal AS
       (select  BP.EpicorBatchCode                                                    as EpicorBatchCode,
                BP.BatchType                                                          as BatchType,
                BP.Status                                                             as Status,
                BP.InvoiceCount                                                       as InvoiceCount,
                BP.SuccessCount                                                       as SuccessCount,
                BP.FailureCount                                                       as FailureCount,      
                U.FirstName + ' ' + U.LastName                                        as CreatedBy,
                BP.CreatedDate                                                        as CreatedDate,
                (convert(varchar(12),BP.StartDate,101))                               as StartDate,
                (convert(varchar(12),BP.EndDate,101))                                 as EndDate,
                BP.EpicorCompanyName                                                  as EpicorCompany,
                (Case when BatchType='Invoice'
                      then coalesce(
                               Invoices.DBO.fn_FormatCurrency( 
                               (select  sum(I.ILFChargeAmount) + sum(I.AccessChargeAmount) +
                                        sum(I.TransactionChargeAmount) + sum(I.ShippingandHandlingAmount) + sum(I.TaxAmount)
                                from   Invoices.dbo.invoice I with (nolock)
                                where  I.Epicorbatchcode=BP.EpicorBatchCode
                                and    I.PrintFlag = 1
                                and    I.senttoEpicorFlag = 1
                                ),2,2),'0')
                      when BatchType<>'Invoice'
                       then coalesce(
                               Invoices.DBO.fn_FormatCurrency( 
                               (select  sum(CM.TotalNetCreditAmount)+
                                        sum(CM.ShippingAndHandlingCreditAmount)+sum(CM.TaxAmount)     
                                from   Invoices.dbo.CreditMemo CM with (nolock)
                                where  CM.Epicorbatchcode=BP.EpicorBatchCode
                                and    CM.CreditStatusCode   = 'APPR'                                
                                and    CM.senttoEpicorFlag = 1
                                ),2,2),'0') 
                      else '0'
                  end)                                                                as  batchTotal,
                  row_number() OVER(ORDER BY BP.CreatedDate desc)                     as  [RowNumber],
                  Count(1) OVER()                                                     as  TotalBatchCountForPaging
        ---------------------------------------------------------------
        from   Invoices.dbo.BatchProcess    BP with (nolock)
        inner join  Security.dbo.[User]     U  with (nolock)
        on     BP.CreatedByIDSeq = u.IDSeq
        and   (BP.EpicorBatchCode = coalesce(@IPVC_EpicorBatchCode,BP.EpicorBatchCode))
        and   (BP.CreatedBy =coalesce(@IPVC_ModifiedByUser,BP.CreatedBy))
        and   (BP.BatchType =coalesce(@IPVC_Type,BP.BatchType))
        and    BP.CreatedDate >= (case @IPVC_SentOn when 'W' then dateadd(week, -1, getdate())
                                                    when 'M' then dateadd(month, -1, getdate()) 
                                                    when 'A'  then (select min(createdDate) from Invoices.dbo.BatchProcess with (nolock))
                                    end)        
        and   ((@IB_ShowFailures = 0) or (FailureCount > 0))        
        and   (convert(int, convert(varchar(10), BP.CreatedDate, 112)) between convert(int, convert(varchar(10), @IPVC_StartDate, 112)) and convert(int, convert(varchar(10), @IPVC_EndDate, 112)))      
        
    ) 
  select tablefinal.EpicorBatchCode,
         tablefinal.BatchType,
         tablefinal.Status,
         tablefinal.InvoiceCount,
         tablefinal.SuccessCount,
         tablefinal.FailureCount,
         tablefinal.CreatedBy,
         tablefinal.StartDate,
         tablefinal.EndDate,
         tablefinal.EpicorCompany,
         tablefinal.batchTotal,         
         tablefinal.TotalBatchCountForPaging --->The value of TotalBatchCountForPaging of the first row will be used by UI for pagination.
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
