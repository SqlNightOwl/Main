SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransactionItemList]
-- Description     : Lists the detailed items from a batch import
-- Input Parameters: @IPI_TransactionImportIDSeq 
-- Syntax          : Exec ORDERS.dbo.uspORDERS_ImportTransactionItemList @IPI_PageNumber=1,@IPI_RowsPerPage=21,@IPI_TransactionImportIDSeq=699,@IPI_ExportOnly=0
--                   For Export to Excel: Exec ORDERS.dbo.uspORDERS_ImportTransactionItemList @IPI_TransactionImportIDSeq=699,@IPI_ExportOnly=1
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- Revision History:
-- 05/17/2010      : SRS (Defect 7491)
------------------------------------------------------------------------------------------------------------------------------------------
-- exec [uspORDERS_ImportTransactionItemList] 21, 500, 12
CREATE PROCEDURE [orders].[uspORDERS_ImportTransactionItemList] (@IPI_PageNumber             int=1, 
                                                              @IPI_RowsPerPage            int=999999999,
                                                              @IPI_TransactionImportIDSeq bigint,
                                                              @IPI_ExportOnly             int = 0
                                                             )
AS
BEGIN 
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  if exists (select top 1 1 
             from  Orders.dbo.TransactionImportBatchDetail with (nolock)
             where TransactionImportIDSeq = @IPI_TransactionImportIDSeq             
            ) 
  and (@IPI_ExportOnly = 0)
  Begin
    ;WITH tablefinal AS
         (Select    TIBD.TransactionImportIDSeq           as ImportBatchID,
                    TIBD.CompanyIDSeq                     as CompanyIDSeq,
                    COM.SiteMasterID                      as CompanySiteMasterID,
                    COM.Name                              as CompanyName,
                    TIBD.PropertyIDSeq                    as PropertyIDSeq,
                    PRO.SiteMasterID                      as PropertySiteMasterID,
                    PRO.Name                              as PropertyName,
                    TIBD.AccountIDSeq                     as AccountIDSeq,
                    coalesce(PRO.Name,COM.Name)           as AccountName,
                    TIBD.OrderIDSeq                       as OrderIDSeq,
                    TIBD.OrderGroupIDSeq                  as OrderGroupIDSeq,
                    TIBD.OrderItemIDSeq                   as OrderItemIDSeq,
                    TIBD.OrderItemTransactionIDSeq        as OrderItemTransactionIDSeq,
                    TIBD.ProductCode                      as ProductCode,
                    TIBD.PriceVersion                     as PriceVersion,
                    PRD.DisplayName                       as ProductName,
                    TIBD.SourceTransactionID              as SourceTransactionID,
                    TIBD.TransactionItemName              as TransactionItemName,
                    TIBD.TransactionServiceDate           as TransactionServiceDate,
                    TIBD.SOCChargeAmount                  as SOCChargeAmount, 
                    TIBD.ListPrice                        as ListPrice,
                    TIBD.Quantity                         as Quantity,
                    TIBD.NetChargeAmount                  as NetChargeAmount,
                    TIBD.UserAmountOverrideFlag           as UserAmountOverrideFlag,
                    TIBD.PreValidationMessage                               as PreValidationMessage,
                    TIBD.DetailPostingStatusFlag                            as DetailPostingStatusFlag,
                    coalesce(TIBD.DetailPostingErrorMessage,'')             as  DetailPostingErrorMessage,
                    ltrim(rtrim(U.FirstName + ' ' + U.LastName))            as  ImportedByUserName,
                    convert(varchar(50),TIBD.CreatedDate)                   as  ImportedDate,
                    row_number() OVER(ORDER BY TIBD.[IDSeq] asc)            as  [RowNumber],
                    Count(1) OVER()                                         as  TotalRecordsThisBatchForPaging
          From      ORDERS.dbo.TransactionImportBatchDetail   TIBD with (nolock)
          inner join 
                    CUSTOMERS.dbo.Company COM with (nolock)
          on        TIBD.CompanyIDSeq = COM.IDSeq
          and       TIBD.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
          and       TIBD.DetailPostingStatusFlag <> 0 
          left outer join
                    Products.dbo.Product PRD with (nolock)
          ON        TIBD.ProductCode = PRD.Code
          and       TIBD.PriceVersion= PRD.PriceVersion
          left  outer join Customers.dbo.Property PRO with (nolock)
          on        TIBD.PropertyIDSeq = PRO.IDSeq
          left outer join
                    Security.dbo.[User] U with (nolock)
          on        TIBD.CreatedByIDSeq = U.IDSeq
          where     TIBD.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
          and       TIBD.DetailPostingStatusFlag <> 0
         )   
    select tablefinal.ImportBatchID,
           tablefinal.CompanyIDSeq,
           tablefinal.CompanySiteMasterID,
           tablefinal.CompanyName,
           tablefinal.PropertyIDSeq,
           tablefinal.PropertySiteMasterID,
           tablefinal.PropertyName,
           tablefinal.AccountIDSeq,
           tablefinal.AccountName,
           tablefinal.OrderIDSeq,
           tablefinal.OrderGroupIDSeq,
           tablefinal.OrderItemIDSeq,
           tablefinal.OrderItemTransactionIDSeq,
           tablefinal.ProductCode,
           tablefinal.PriceVersion,
           tablefinal.ProductName,
           tablefinal.SourceTransactionID,
           tablefinal.TransactionItemName,
           tablefinal.TransactionServiceDate,
           tablefinal.SOCChargeAmount,
           tablefinal.ListPrice,
           tablefinal.Quantity,
           tablefinal.NetChargeAmount, 
           tablefinal.UserAmountOverrideFlag,
           tablefinal.PreValidationMessage,
           tablefinal.DetailPostingStatusFlag,
           tablefinal.DetailPostingErrorMessage,
           tablefinal.ImportedByUserName,
           tablefinal.TotalRecordsThisBatchForPaging
    from   tablefinal
    where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
    and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage; 
    -----------------------------------------------   
  end
  else if exists (select top 1 1 
             from  Orders.dbo.TransactionImportBatchDetail with (nolock)
             where TransactionImportIDSeq = @IPI_TransactionImportIDSeq             
            ) 
  and (@IPI_ExportOnly = 1)
  Begin
    SET ROWCOUNT 0;
    ;WITH tablefinal AS
         (Select    TIBD.TransactionImportIDSeq           as ImportBatchID,
                    TIBD.CompanyIDSeq                     as CompanyIDSeq,
                    COM.SiteMasterID                      as CompanySiteMasterID,
                    COM.Name                              as CompanyName,
                    TIBD.PropertyIDSeq                    as PropertyIDSeq,
                    PRO.SiteMasterID                      as PropertySiteMasterID,
                    PRO.Name                              as PropertyName,
                    TIBD.AccountIDSeq                     as AccountIDSeq,
                    coalesce(PRO.Name,COM.Name)           as AccountName,
                    TIBD.OrderIDSeq                       as OrderIDSeq,
                    TIBD.OrderGroupIDSeq                  as OrderGroupIDSeq,
                    TIBD.OrderItemIDSeq                   as OrderItemIDSeq,
                    TIBD.OrderItemTransactionIDSeq        as OrderItemTransactionIDSeq,
                    TIBD.ProductCode                      as ProductCode,
                    TIBD.PriceVersion                     as PriceVersion,
                    PRD.DisplayName                       as ProductName,
                    TIBD.SourceTransactionID              as SourceTransactionID,
                    TIBD.TransactionItemName              as TransactionItemName,
                    TIBD.TransactionServiceDate           as TransactionServiceDate,
                    TIBD.SOCChargeAmount                  as SOCChargeAmount, 
                    TIBD.ListPrice                        as ListPrice,
                    TIBD.Quantity                         as Quantity,
                    TIBD.NetChargeAmount                  as NetChargeAmount,
                    TIBD.UserAmountOverrideFlag           as UserAmountOverrideFlag,
                    TIBD.PreValidationMessage                               as  PreValidationMessage,
                    TIBD.DetailPostingStatusFlag                            as  DetailPostingStatusFlag,
                    coalesce(TIBD.DetailPostingErrorMessage,'')             as  DetailPostingErrorMessage,
                    ltrim(rtrim(U.FirstName + ' ' + U.LastName))            as  ImportedByUserName,
                    convert(varchar(50),TIBD.CreatedDate)                   as  ImportedDate,
                    ltrim(rtrim(UR.FirstName + ' ' + UR.LastName))          as  RollBackByUserName,
                    coalesce(convert(varchar(50),TIBH.RollbackDate),'')     as  RollBackDate,            
                    coalesce(R.ReasonName,'')                               as  RollBackReason
          From      ORDERS.dbo.TransactionImportBatchDetail   TIBD with (nolock)
          inner join
                    ORDERS.dbo.TransactionImportBatchHeader TIBH with (nolock)
          on        TIBD.TransactionImportIDSeq = TIBH.IDSeq
          and       TIBH.IDSeq                  = @IPI_TransactionImportIDSeq
          and       TIBD.TransactionImportIDSeq = @IPI_TransactionImportIDSeq 
          and       TIBH.BatchPostingStatusFlag  <> 0
          and       TIBD.DetailPostingStatusFlag <> 0
          inner join 
                    CUSTOMERS.dbo.Company COM with (nolock)
          on        TIBD.CompanyIDSeq = COM.IDSeq
          and       TIBD.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
          left outer join
                    Products.dbo.Product PRD with (nolock)
          ON        TIBD.ProductCode = PRD.Code
          and       TIBD.PriceVersion= PRD.PriceVersion
          left  outer join Customers.dbo.Property PRO with (nolock)
          on        TIBD.PropertyIDSeq = PRO.IDSeq
          left outer join
                    Security.dbo.[User] U with (nolock)
          on        TIBD.CreatedByIDSeq = U.IDSeq
          left outer join
                    Security.dbo.[User] UR with (nolock)
          on        TIBH.RollBackByIDSeq = UR.IDSeq
          left outer Join
                    ORDERS.dbo.Reason R with (nolock)
           on       TIBH.RollbackReasonCode = R.Code
          where     TIBD.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
         )   
    select tablefinal.ImportBatchID,
           tablefinal.CompanyIDSeq,
           tablefinal.CompanySiteMasterID,
           tablefinal.CompanyName,
           tablefinal.PropertyIDSeq,
           tablefinal.PropertySiteMasterID,
           tablefinal.PropertyName,
           tablefinal.AccountIDSeq,
           tablefinal.AccountName,
           tablefinal.OrderIDSeq,
           tablefinal.OrderGroupIDSeq,
           tablefinal.OrderItemIDSeq,
           tablefinal.OrderItemTransactionIDSeq,
           tablefinal.ProductCode,
           tablefinal.PriceVersion,
           tablefinal.ProductName,
           tablefinal.SourceTransactionID,
           tablefinal.TransactionItemName,
           tablefinal.TransactionServiceDate,
           tablefinal.SOCChargeAmount,
           tablefinal.ListPrice,
           tablefinal.Quantity,
           tablefinal.NetChargeAmount, 
           tablefinal.UserAmountOverrideFlag,
           tablefinal.PreValidationMessage,
           tablefinal.DetailPostingStatusFlag,
           tablefinal.DetailPostingErrorMessage,
           tablefinal.ImportedByUserName,
           tablefinal.ImportedDate,
           tablefinal.RollBackByUserName,
           tablefinal.RollBackDate,
           tablefinal.RollBackReason                      
    from   tablefinal    
    -----------------------------------------------   
  end
    
END
GO
