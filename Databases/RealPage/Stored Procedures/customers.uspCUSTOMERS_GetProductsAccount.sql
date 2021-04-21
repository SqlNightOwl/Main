SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetProductsAccount
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_Accoun tID   as varchar(20)
--                   2. @IPI_PageNumber  as integer
--                   3. @IPI_RowsPerPage as integer
-- 
-- OUTPUT          : RecordSet of OrderID,Status,CustomerID,CustomerName,AccountID,
--                                AccountName,OrderDate,OrderPeriod,LastInvoice,RowNumber
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetProductsAccount @IPI_AccountID  =1,
--                                                                   @IPI_PageNumber =3,
--                                                                   @IPI_RowsPerPage=20 
-- Author          : Naval Kishore 
-- 07/26/2007      : Stored Procedure Created.
-- 04/25/2008      : Naval Kishore Modified to Get ILFCHARGEAMOUNT and ACSChargeAmount
-- 01/10/2009      : Naval Kishore Modified to Get products for company bundle
------------------------------------------------------------------------------------------------------
Create PROCEDURE [customers].[uspCUSTOMERS_GetProductsAccount] (@IPI_AccountID     varchar(50), 
                                                          @IPI_PageNumber    int, 
                                                          @IPI_RowsPerPage   int
                                                          )
AS
BEGIN 
  set nocount on;
  set ansi_warnings off;
  create table #LT_ORPRODUCTS ( 
                                AccountIDSeq								varchar(50)   not null,
				CompanyIDSeq								varchar(50)   not null,
                                --PropertyIDSeq								varchar(50)   not null,
				OrderIDSeq								varchar(50)   not null,
                                OrderGroupIDSeq								bigint,
                                OrderItemId								bigint,
                                IsCustomBundle								int           not null default(0),   
				ProductCode								varchar(30)   not null,
				ProductName								varchar(255)  not null,
				Status									varchar(70)   not null ,   
				OrderDate								datetime  default getdate(),
				ILFNetChargeAmount							money ,
				ACSNetChargeAmount							money ,
                                BillToAddressTypeCode						        varchar(20),
                                chargetypecode								varchar(20),
                                LastInvoice								varchar(50),
                                FirstActivationStartDate					        varchar(20),
                                MaxAllowableFirstActivationStartDate		                        varchar(20),
                                FrequencyName								char(20)                                
                              )

  -------------------------------------------------------------------------------------------
  INSERT INTO #LT_ORPRODUCTS  (AccountIDSeq,CompanyIDSeq,--PropertyIDSeq,
							   OrderIDSeq,OrderGroupIDSeq,OrderItemId,IsCustomBundle,
                               ProductCode,ProductName,
                               Status,OrderDate,ILFNetChargeAmount,ACSNetChargeAmount,BillToAddressTypeCode,chargetypecode,
                               LastInvoice,FirstActivationStartDate,MaxAllowableFirstActivationStartDate,FrequencyName)
  SELECT O.AccountIDSeq, 
         O.CompanyIDSeq, 
         --O.PropertyIDSeq,
         O.OrderIDSeq           as OrderIDSeq, 
         OI.OrderGroupIDSeq     as OrderGroupIDSeq,
         OI.IDseq               as OrderItemId,
         Max(convert(int,OG.CustomBundleNameEnabledFlag)) as IsCustomBundle,
         OI.ProductCode,
         Max(Pr.DisplayName)    as ProductName,	
         CONVERT(varchar(20),Max(OST.Name)) AS [Status],
         Max(OI.CreatedDate)                as OrderDate,
         sum((Case when OI.Chargetypecode = 'ILF' 
                 then OI.NetChargeAmount
               else 0
              end)
             )                   as ILFNetChargeAmount,
         sum((Case when OI.Chargetypecode = 'ACS' 
                 then OI.NetChargeAmount
               else 0
              end)
             )                   as ACSNetChargeAmount,
          Max(OI.BillToAddressTypeCode)    as BillToAddressTypeCode,
          OI.Chargetypecode                as Chargetypecode,
          '-'                              as LastInvoice,
          (case when isdate(Min(OI.FirstActivationStartDate)) = 1 then convert(varchar(50),Min(OI.FirstActivationStartDate),101)
                else '-'
           end)                            as FirstActivationStartDate,
          (case when isdate(Max(OI.ActivationStartDate)) = 1 then convert(varchar(50),Max(OI.ActivationStartDate),101)
                else '-'
           end)                            as MaxAllowableFirstActivationStartDate,
           Freq.Name                       as FrequencyName
  FROM [Orders].dbo.[Order]  O  with (nolock)
  inner join
       Orders.dbo.OrderGroup OG with (nolock)
  on   OG.Orderidseq = O.Orderidseq
  and  O.accountidseq=@IPI_AccountID
  inner join
       [Orders].dbo.[OrderItem] OI with (nolock)
  on   O.Orderidseq  = OI.Orderidseq 
  and  OG.Orderidseq = OI.Orderidseq
  and  OG.IDSeq      = OI.Ordergroupidseq
  Inner join
       Products.dbo.Product Pr with (nolock)
  on   Pr.Code=OI.ProductCode
  and  Pr.PriceVersion = OI.PriceVersion
  Inner join  
       Products.dbo.Frequency Freq with (nolock)  
  on   Freq.Code=OI.FrequencyCode 
  Inner Join
       Orders.dbo.OrderStatusType OST with (nolock)
  on   OST.Code=OI.StatusCode
  where O.accountidseq=@IPI_AccountID
  group by O.AccountIDSeq,O.CompanyIDSeq,--O.PropertyIDSeq,
		   O.OrderIDSeq,OI.OrderGroupIDSeq,OI.IDseq,
           OI.ProductCode,OI.Chargetypecode,Freq.Name  
  order by OrderDate desc,ProductName asc,Chargetypecode desc;
 ----------------------------------------------------------------------------------
 Update D
 set    D.LastInvoice = S.InvoiceDate
 from   #LT_ORPRODUCTS D with (nolock)
 inner join
        (select II.OrderIDSeq,II.OrderitemIDSeq,
                convert(varchar(15),max(I.InvoiceDate),101) as InvoiceDate
         from   Invoices.dbo.Invoice I with (nolock)
         inner join
                Invoices.dbo.Invoiceitem II with (nolock)
         on     I.InvoiceIDSeq = II.InvoiceIDSeq
         and    I.AccountIDSeq = @IPI_AccountID
         group by II.OrderIDSeq,II.OrderitemIDSeq
        ) S
 on     D.OrderIDSeq     = S.OrderIDSeq
 and    D.OrderItemId    = S.OrderitemIDSeq; 
 
 ---------------------------------------------------------------------------------- 
   WITH Temp_RecordList AS (  
    SELECT    
      Count(*) OVER() as TotalRows,  
      row_number() over(order by OrderDate desc,ProductName asc,Chargetypecode desc ) as RowNumber,
      O.AccountIDSeq,
      O.CompanyIDSeq,
      --O.PropertyIDSeq,
      O.OrderIdSeq                                            as ID,
                      (case when O.BillToAddressTypeCode = 'CBT' then 'Company'
                            else 'Property' end)                              as BillTo,
                  
                      O.[ProductName]                                         as ProductName,
                      
                      O.[ProductCode]                                         as ProductCode,

                      O.Status                                                as Status,
                      (case when O.ILFNetChargeAmount = 0 then '-'
                              else Quotes.DBO.fn_FormatCurrency (O.ILFNetChargeAmount,1,2)
                            end 
                      )                                                       as ILF,   
                      (case when O.ACSNetChargeAmount = 0 then '-'
                              else Quotes.DBO.fn_FormatCurrency (O.ACSNetChargeAmount,1,2)
                            end 
                      )                                                       as Access,                                      
                      Convert(varchar(20),O.OrderDate,101)                    as OrderDate,

                      
                      O.LastInvoice                                           as LastInvoice,
                      '-'                                                     as NextInvoice,
                      O.OrderItemId                                           as OrderItemId,
                      O.OrderGroupIDSeq                                       as OrderGroupIDSeq,
                      O.IsCustomBundle                                        as IsCustomBundle,
                      O.chargetypecode                                        as chargetypecode,
                      coalesce(O.FirstActivationStartDate,'-')                as ProductCustomerSinceDate,
                      coalesce(O.MaxAllowableFirstActivationStartDate,'-')    as MaxAllowableFirstActivationStartDate,
                      O.FrequencyName                                         as FrequencyName                              
        FROM   #LT_ORPRODUCTS O with (nolock)     
      ) 

  SELECT *  FROM Temp_RecordList  
  WHERE   
      RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage  
  and RowNumber <= (@IPI_PageNumber)  * @IPI_RowsPerPage  
  ------------------------------------------------------------------------------------------------
  --SELECT COUNT(*) as linecount FROM   #LT_ORPRODUCTS  with (nolock)
  ------------------------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_ORPRODUCTS') is not null) 
  begin
    drop table #LT_ORPRODUCTS 
  end 
END

GO
