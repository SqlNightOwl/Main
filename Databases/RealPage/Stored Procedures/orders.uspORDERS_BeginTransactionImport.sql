SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_BeginTransactionImport]
-- Description     : Inserts an entry into the batch Header table to begin the import transaction process
--                  On Click of Final import button from UI, This SP is called as STEP 1
-- Returns         : TransactionImportIDSeq if Batch Header Record is Created Successfully, which
--                     will be used to pass as parameter to STEP 2 uspORDERS_BeginTransactionImportDetail
--                   If Batch Header Record is not successful, then fatal error is reported which UI will
--                    have to catch and log into customers.dbo.ErrorLog table and also Report in UI
-- Input Parameters: @IPI_UserID,@IPVC_BatchName,@IPVC_ImportSource,@IPVC_ImportedFileName
-- Return          : TransactionImportIDSeq (ie BatchID),TransactionImportDate
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : SRS (Defect 7491)
-- 05/14/2010
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_BeginTransactionImport] (@IPI_UserID                         bigint,            -->UserID of User to initiates the Import 
                                                           @IPVC_BatchName                     varchar(255),      -->Batch Header Name for Import that User Keys in
                                                           @IPVC_ImportSource                  varchar(100),      -->Indicates ImportSource 'EXCEL', 'Appirio SalesForce' etc
                                                           @IPVC_ImportedFileName              varchar(255),      -->Name of Excel File used if applicable to be saved into OMS for final Import
                                                           @IPVC_EstimatedImportCount          bigint = 0,        -->This is total count of Records that Total Qualifies to be imported, passed from UI.
                                                           @IPVC_EstimatedTotalNetChargeAmount numeric(18,4)=0.00 -->This is EstimatedTotalNetChargeAmount corresponding to that Total Qualifies Rows to be imported, passed from UI.
                                                          )					
AS
BEGIN 
  set nocount on; 
  -----------------------------------------------
  declare @LDT_CreatedDate datetime;
  declare @LVC_CodeSection varchar(4000);
  select  @LDT_CreatedDate = convert(varchar(50),getdate(),20)
  -----------------------------------------------
  --Validation 1 : For @IPI_UserID to be valid.
  if not exists (select top 1 1 
                 from   Security.dbo.[User] U with (nolock)
                 where  U.IDSeq = @IPI_UserID
                )
  begin
    select @LVC_CodeSection = 'UserID : ' + Convert(varchar(100),@IPI_UserID) + ' is Invalid. Error Creating Transaction Import Batch Header'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  -----------------------------------------------
  --Validation 2 : For @IPVC_BatchName to be valid.
  if (@IPVC_BatchName is NULL or @IPVC_BatchName = '')
  begin
    select @LVC_CodeSection = 'BatchName Cannot be Blank. Error Creating Transaction Import Batch Header'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  -----------------------------------------------
  --Validation 3 : For ImportSource to be valid.
  if (@IPVC_ImportSource is NULL or @IPVC_ImportSource = '')
  begin
    select @LVC_CodeSection = 'ImportSource Cannot be Blank. Error Creating Transaction Import Batch Header'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  -----------------------------------------------
  --Validation 4 : For @IPVC_ImportedFileName to be valid when @IPVC_ImportSource = 'EXCEL'
  if ((@IPVC_ImportedFileName is NULL or @IPVC_ImportedFileName = '') and (@IPVC_ImportSource = 'EXCEL'))
  begin
    select @LVC_CodeSection = 'ImportedFileName Cannot be Blank when Import Source is EXCEL. Error Creating Transaction Import Batch Header'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  -----------------------------------------------
  --Validation 5 : For @IPVC_EstimatedImportCount and @IPVC_EstimatedTotalNetChargeAmount to be greater than 0
  if (@IPVC_EstimatedImportCount <= 0 or @IPVC_EstimatedTotalNetChargeAmount <= 0.0000 )
  begin
    select @LVC_CodeSection = 'EstimatedImportCount and EstimatedTotalNetChargeAmount should be greater than 0. Error Creating Transaction Import Batch Header'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  -----------------------------------------------
  ---After all above Validations are passed, proceed to create TransactionImportBatchHeader record.
  BEGIN TRY    
    BEGIN TRANSACTION IBH;
      insert into ORDERS.dbo.TransactionImportBatchHeader (BatchName,ImportSource,ImportedFileName,EstimatedImportCount,EstimatedNetChargeAmount,BatchPostingStatusFlag,CreatedByIDSeq,CreatedDate)
      select @IPVC_BatchName as BatchName,@IPVC_ImportSource as ImportSource,@IPVC_ImportedFileName as ImportedFileName,
             @IPVC_EstimatedImportCount as EstimatedImportCount,@IPVC_EstimatedTotalNetChargeAmount as EstimatedNetChargeAmount,
             0 as BatchPostingStatusFlag,
             @IPI_UserID     as CreatedByIDSeq,@LDT_CreatedDate as CreatedDate

      select SCOPE_IDENTITY() as TransactionImportIDSeq,@LDT_CreatedDate as TransactionImportDate
    COMMIT TRANSACTION IBH;
  END TRY
  BEGIN CATCH;    
     -- XACT_STATE:
     -- If 1, the transaction is committable.
     -- If -1, the transaction is uncommittable and should be rolled back.
     -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
     if (XACT_STATE()) = -1
     begin
       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IBH;
     end
     else if (XACT_STATE()) = 1
     begin
       IF @@TRANCOUNT > 0 COMMIT TRANSACTION IBH;
     end 
     IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IBH;
     select @LVC_CodeSection = 'Proc:uspORDERS_BeginTransactionImport - Error Creating Transaction Import Batch Header'
     Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
     return;                  
  END CATCH;
END
GO
