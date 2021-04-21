SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_BeginTransactionImportDetail]
-- Description     : This Proc Imports XML into a TransactionImportBatchDetail for TransactionImportIDSeq : This is STEP 2
--                   Returned by Main Call of uspORDERS_BeginTransactionImport
--                   XML of all excel Records that have only ImportableTransactionFlag=1 and ValidationErrorFlag = 0
--                   TranEnablerRecordFoundFlag can be 1 if uspORDERS_PreImportExcelAnalysisConsolidated has reported as TRAN Order Found
--                   TranEnablerRecordFoundFlag can be 0,if uspORDERS_PreImportExcelAnalysisConsolidated has reported as TRAN Order Not Found


-- Input Parameters: 
--                     @IPI_UserID        bigint,@IPI_TransactionImportIDSeq (ie.Batch ID),@IPDT_TransactionImportDate (Datettime of BatchHeader)
--                     @IPXML_ExcelXML    xml
------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- Revision History:
-- Author          : SRS (Defect 7491)
-- 05/14/2010
------------------------------------------------------------------------------------------------------------------------------------
Create Procedure [orders].[uspORDERS_BeginTransactionImportDetail]  (@IPI_UserID                 bigint,   -->UserID of User to initiates the Import                                                         
                                                                  @IPI_TransactionImportIDSeq bigint,   -->BatchHeader ID
                                                                  @IPDT_TransactionImportDate datetime, -->Exact DateTime of Import Batch Header CreatedDate
                                                                  @IPXML_ValidatedXML         XML
                                                                  ) --WITH RECOMPILE
AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  ------------------------------------------------------------------------
  --local variables declaration
  declare @LVC_CodeSection varchar(4000);
  declare @idoc  int;
  ------------------------------------------------------------------------

  --Initial Validation 1: If Batch Header is already failed, throw error.
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 2
            )
  begin
    select @LVC_CodeSection = 'Import Batch Header : ' + convert(varchar(100),@IPI_TransactionImportIDSeq) + ' had failed previously.No new Transactions against this Batch can be accepted'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ------------------------------------------------------------------------
  --Initial Validation 2: If Batch Header is already posted, throw error.
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 1
            )
  begin
    select @LVC_CodeSection = 'Import Batch Header : ' + convert(varchar(100),@IPI_TransactionImportIDSeq) + ' had been posted previously.No new Transactions against this Batch can be accepted'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ------------------------------------------------------------------------
  --Initial Validation 3: If Batch Header is already unposted, allow 
  --                      to accept Batch Detail records
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 0
            )
  begin  
    --Create Handle to access newly created internal representation of the XML document
    -----------------------------------------------------------------------------------
    EXEC sp_xml_preparedocument @idoc OUTPUT,@IPXML_ValidatedXML;
    -----------------------------------------------------------------------------------

    BEGIN TRY
      BEGIN TRANSACTION IBD;
        Insert into ORDERS.dbo.TransactionImportBatchDetail(TransactionImportIDSeq,CreatedByIDSeq,CreatedDate,
                                                            DiscountAmount,DetailPostingStatusFlag,    
                                                            CompanyIDSeq,PropertyIDSeq,AccountIDSeq,CompanySiteMasterID,PropertySiteMasterID,
                                                            OrderIDSeq,OrderGroupIDSeq,OrderItemIDSeq,
                                                            ProductCode,PriceVersion,SourceTransactionID,TransactionServiceDate,TransactionItemName,
                                                            SOCChargeAmount,UserAmountOverrideFlag,ListPrice,
                                                            ExtChargeAmount,Quantity,NetChargeAmount,
                                                            ImportableTransactionFlag,TranEnablerRecordFoundFlag,PreValidationErrorFlag,PreValidationMessage
                                                            )
        select @IPI_TransactionImportIDSeq                                     as transactionimportidseq,
               @IPI_UserID                                                     as createdbyidseq,
               @IPDT_TransactionImportDate                                     as createddate,
               0                                                               as discountamount,
               0                                                               as detailpostingstatusflag,
               A.companyidseq                                                  as companyidseq,
               A.propertyidseq                                                 as propertyidseq,
               A.accountidseq                                                  as accountidseq,
               coalesce(COM.SiteMasterID,A.pmcid)                              as pmcid,
               coalesce(PRO.SiteMasterID,A.siteid)                             as siteid,
               A.orderidseq                                                    as orderidseq,
               A.ordergroupidseq                                               as ordergroupidseq,
               A.orderitemidseq                                                as orderitemidseq, 
               A.productcode                                                   as productcode,
               A.priceversion                                                  as priceversion,
               A.sourcetransactionid                                           as sourcetransactionid,
               A.transactionservicedate                                        as transactionservicedate,
               A.[description]                                                 as [description],
               A.socchargeamount                                               as socchargeamount,
               A.useramountoverrideflag                                        as useramountoverrideflag,
               A.listprice                                                     as listprice,
               A.listprice                                                     as extchargeamount,
               A.quantity                                                      as quantity,
               A.netchargeamount                                               as netchargeamount,
               A.importabletransactionflag                                     as importabletransactionflag,
               A.tranenablerrecordfoundflag                                    as tranenablerrecordfoundflag,
               A.prevalidationerrorflag                                        as prevalidationerrorflag,
               A.prevalidationmessage                                          as prevalidationmessage
        from  (select
                   companyidseq                                                as companyidseq,
                   propertyidseq                                               as propertyidseq,
                   accountidseq                                                as accountidseq,
                   pmcid                                                       as pmcid,
                   siteid                                                      as siteid,
                   NULLIF(ltrim(rtrim(orderidseq)),'')                         as orderidseq,
                   NULLIF(ltrim(rtrim(ordergroupidseq)),'')                    as ordergroupidseq,
                   NULLIF(ltrim(rtrim(orderitemidseq)),'')                     as orderitemidseq, 
                   productcode                                                 as productcode,
                   priceversion                                                as priceversion,
                   sourcetransactionid                                         as sourcetransactionid,
                   transactionservicedate                                      as transactionservicedate,
                   [description]                                               as [description],
                   socchargeamount                                             as socchargeamount,
                   useramountoverrideflag                                      as useramountoverrideflag,
                   listprice                                                   as listprice,                   
                   quantity                                                    as quantity,
                   netprice                                                    as netchargeamount,
                   importabletransactionflag                                   as importabletransactionflag,
                   tranenablerrecordfoundflag                                  as tranenablerrecordfoundflag,
                   prevalidationerrorflag                                      as prevalidationerrorflag,
                   validationerrormessage                                      as prevalidationmessage               
             from OPENXML (@idoc,'root/row',1) 
             with (companyidseq                 varchar(50),
                   propertyidseq                varchar(50), 
                   accountidseq                 varchar(50),                                
                   pmcid                        varchar(50),
                   siteid                       varchar(50),
                   tranid                       varchar(100),
                   orderidseq                   varchar(50),
                   ordergroupidseq              varchar(50),
                   orderitemidseq               varchar(50),
                   productcode                  varchar(50),
                   priceversion                 numeric(18,0),
                   sourcetransactionid          varchar(100),
                   transactionservicedate       datetime,
                   [description]                varchar(max),
                   socchargeamount              numeric(30,5),
                   useramountoverrideflag       int,
                   listprice                    numeric(30,5),
                   quantity                     numeric(30,5),
                   netprice                     numeric(30,5),
                   importabletransactionflag    int,
                   tranenablerrecordfoundflag   int,
                   prevalidationerrorflag       int,
                   validationerrormessage       varchar(max)
                 )
           ) A
        left outer join Customers.dbo.Company  COM with (nolock)
        on   A.CompanyIDSeq  = COM.IDSeq
        left outer join Customers.dbo.Property PRO with (nolock)
        on   A.PropertyIDSeq = PRO.IDSeq
      COMMIT TRANSACTION IBD;
    END TRY
    BEGIN CATCH;    
      -- XACT_STATE:
      -- If 1, the transaction is committable.
      -- If -1, the transaction is uncommittable and should be rolled back.
      -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
      if (XACT_STATE()) = -1
      begin
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IBD;
      end
      else if (XACT_STATE()) = 1
      begin
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION IBD;
      end 
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IBD;
      ------------------------
      ------Final Cleanup
      ------------------------
      if @idoc is not null
      begin
        EXEC sp_xml_removedocument @idoc
        set @idoc = NULL
      end
      ------------------------
      --Mark The Import Batch Header to Failure will be done by Mandatory Do Post Process.   
      ------------------------
      --Delete any Orphan Records if any from ORDERS.dbo.TransactionImportBatchDetail for @IPI_TransactionImportIDSeq
      delete from ORDERS.dbo.TransactionImportBatchDetail
      where  TransactionImportIDSeq = @IPI_TransactionImportIDSeq;
      ------------------------      
      select @LVC_CodeSection =  'Proc :uspORDERS_BeginTransactionImportDetail;Error Parsing XML for Batch Detail Import.Please check datatype of attributes in XML.'          
      ------------------------     
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return;                  
    END CATCH; 
  end
  ------------------------
  ------Final Cleanup
  ------------------------
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end
  ------------------------
END
GO
