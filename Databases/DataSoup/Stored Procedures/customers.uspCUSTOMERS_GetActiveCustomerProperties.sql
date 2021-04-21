SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetActiveCustomerProperties]
-- Description     : This procedure Selects CustomBundlesProductBreakDownTypeCode in Customer and Property Table
--Input Parameter  : @IPVC_CompanyIDSeq           bigint, 
--                  
--
-- Code Example    : EXEC Customers..[uspCUSTOMERS_GetActiveCustomerProperties] @IPVC_CompanyIDSeq = 'C0901000003'
--                   
--
-- Revision History:
-- Author          : Naval Kishore
-- 05/25/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetActiveCustomerProperties] (@IPVC_CompanyIDSeq   varchar(50)                                                                                                                 
								  )     
AS
BEGIN 
  set nocount on;
  -------------------------------------------------
  CREATE TABLE #tempTblActiveRecords
    ( RowNumber              int identity(1,1) not null primary key,
      IDSeq                  varchar(50),
      [Name]                 varchar(255),
      AccountIDSeq           varchar(50),
      CancelQuoteCount       int not null default(0), ---> For future release to show metrics in UI
      CancelOrderItemCount   int not null default(0)  ---> For future release to show metrics in UI
    )
  ------------------------------------------------------------------------------------
  ---Step 1 : Get Company Active Record for the input Company, along with metrics
  ------------------------------------------------------------------------------------
  insert into #tempTblActiveRecords(IDSeq, [Name],AccountIDSeq,CancelQuoteCount,CancelOrderItemCount)
  select C.IDSeq                              as CompanyIDSeq,
         C.[Name]                             as CompanyName,
         A.IDSeq                              as AccountIDSeq,
         coalesce(QX.CancelQuoteCount,0)      as CancelQuoteCount,
         coalesce(OIX.CancelOrderItemCount,0) as CancelOrderItemCount
  from CUSTOMERS.dbo.Company            C WITH (NOLOCK)
  left outer join CUSTOMERS.dbo.Account A WITH (NOLOCK) 
  ON   C.IDSeq = A.CompanyIDSeq 
  and  A.CompanyIDSeq    = @IPVC_CompanyIDSeq
  and  C.IDSeq           = @IPVC_CompanyIDSeq
  and  C.StatusTypeCode  = 'ACTIV' 
  and  A.AccountTypeCode = 'AHOFF'
  and  A.ActiveFlag      = 1
  Left outer join 
       (select @IPVC_CompanyIDSeq as CustomerIDSeq,count(1) as CancelQuoteCount
        from   Quotes.dbo.Quote Q with (nolock)
        where  Q.CustomerIDSeq  = @IPVC_CompanyIDSeq
        and    Q.QuoteStatuscode not in ('APR','CNL')
        group by Q.CustomerIDSeq
       ) QX
  on   C.IDSeq          = QX.CustomerIDSeq
  and  QX.CustomerIDSeq = @IPVC_CompanyIDSeq
  Left outer join 
       (select @IPVC_CompanyIDSeq as CompanyIDSeq,count(OI.IDSeq) as CancelOrderItemCount
        from   Orders.dbo.[Order]     O with (nolock)
        inner Join
               Orders.dbo.[OrderItem] OI with (nolock)
        on     O.Orderidseq     = OI.Orderidseq
        and    O.CompanyIDSeq   = @IPVC_CompanyIDSeq
        and    O.PropertyIDSeq  is null
        and    OI.Statuscode    not in ('CNCL','EXPD')
        group by O.CompanyIDSeq
       ) OIX
  on   C.IDSeq           = OIX.CompanyIDSeq
  and  OIX.CompanyIDSeq  = @IPVC_CompanyIDSeq
  Where C.StatusTypeCode = 'ACTIV'
  and   C.IDSeq          = @IPVC_CompanyIDSeq
  ------------------------------------------------------------------------------------
  ---Step2 : Get Property Active Records for the input Company , along with metrics
  ------------------------------------------------------------------------------------
  insert into #tempTblActiveRecords(IDSeq, [Name],AccountIDSeq,CancelQuoteCount,CancelOrderItemCount)
  select P.IDSeq                  as PropertyIDSeq,
         P.[Name]                 as PropertyName,
         A.IDSeq                  as AccountIDSeq,
         0                        as CancelQuoteCount,
         coalesce(OIX.CancelOrderItemCount,0) as CancelOrderItemCount
  from CUSTOMERS.dbo.Property     P WITH (NOLOCK)
  LEFT JOIN CUSTOMERS.dbo.Account A WITH (NOLOCK) 
  ON   P.PMCIDSeq        = A.CompanyIDSeq
  and  P.IDSeq           = A.PropertyIDSeq 
  and  A.CompanyIDSeq    = @IPVC_CompanyIDSeq
  and  P.PMCIDSeq        = @IPVC_CompanyIDSeq
  and  P.StatusTypeCode  = 'ACTIV' 
  and  A.AccountTypeCode = 'APROP'
  and  A.ActiveFlag      = 1
  Left outer join 
       (select @IPVC_CompanyIDSeq as CompanyIDSeq,O.PropertyIDSeq,count(OI.IDSeq) as CancelOrderItemCount
        from   Orders.dbo.[Order]     O with (nolock)
        inner Join
               Orders.dbo.[OrderItem] OI with (nolock)
        on     O.Orderidseq     = OI.Orderidseq
        and    O.CompanyIDSeq   = @IPVC_CompanyIDSeq
        and    O.PropertyIDSeq  is not null
        and    OI.Statuscode   not in ('CNCL','EXPD')
        group by O.CompanyIDSeq,O.PropertyIDSeq
       ) OIX
  on   P.PMCIDSeq = OIX.CompanyIDSeq
  and  P.IDSeq    = OIX.PropertyIDSeq 
  Where P.StatusTypeCode = 'ACTIV'
  and   P.PMCIDSeq = @IPVC_CompanyIDSeq
  ------------------------------------------------------------------------------------
  ---Step 3 : Get Other Property Account Records for the input Company, along with metrics
  ------------------------------------------------------------------------------------
  insert into #tempTblActiveRecords(IDSeq, [Name],AccountIDSeq,CancelQuoteCount,CancelOrderItemCount)
  select P.IDSeq                  as PropertyIDSeq,
         P.[Name]                 as PropertyName,
         OIX.AccountIDSeq         as AccountIDSeq,
         0                        as CancelQuoteCount,
         coalesce(OIX.CancelOrderItemCount,0) as CancelOrderItemCount
  from CUSTOMERS.dbo.Property     P WITH (NOLOCK)
  inner join
       (select @IPVC_CompanyIDSeq as CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq,count(OI.IDSeq) as CancelOrderItemCount
        from   Orders.dbo.[Order]     O with (nolock)
        inner Join
               Orders.dbo.[OrderItem] OI with (nolock)
        on     O.Orderidseq     = OI.Orderidseq
        and    O.CompanyIDSeq   = @IPVC_CompanyIDSeq
        and    O.PropertyIDSeq  is not null
        and    OI.Statuscode   not in ('CNCL','EXPD')
        group by O.CompanyIDSeq,O.PropertyIDSeq,O.AccountIDSeq
       ) OIX
  on    P.PMCIDSeq = OIX.CompanyIDSeq
  and   P.IDSeq    = OIX.PropertyIDSeq
  and   P.PMCIDSeq = @IPVC_CompanyIDSeq
  Where P.PMCIDSeq = @IPVC_CompanyIDSeq
  and   not exists (select top 1 1 
                    from   #tempTblActiveRecords T with (nolock)
                    where  P.IDSeq          = T.IDSeq
                    and    OIX.AccountIDSeq = T.AccountIDSeq
                   )
  -------------------------------------------------
  SELECT RowNumber,IDSeq as OMSIDSeq,[Name] as [Name],
         AccountIDSeq,
         CancelQuoteCount,CancelOrderItemCount
  From   #tempTblActiveRecords with (nolock) 
  Order by RowNumber ASC
  -------------------------------------------------
  if (object_id('tempdb.dbo.#tempTblActiveRecords') is not null) 
  begin
    drop table #tempTblActiveRecords
  end 
  -------------------------------------------------
END
GO
