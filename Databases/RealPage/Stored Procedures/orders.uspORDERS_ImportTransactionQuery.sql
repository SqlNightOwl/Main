SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransactionQuery]
-- Description     : Associates the transactions with existing properties
-- Input Parameters: 
--                     @IPVC_ProductCode       varchar(2000), 
--                     @IPB_ImportType  varchar (3), 'STD'=Standard, 'OLD'= Old format, 'LNT'=Lotus notes
--                     @xmlTrans xml
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------
create PROCEDURE [orders].[uspORDERS_ImportTransactionQuery] @IPVC_ProductCode       varchar(2000), 
                                                          -- @IPB_CompanyLookupFlag  bit, 
                                                          @IPVC_ImportType        varchar (3), 
      --                                                  @IPVC_CompanyNameNode   varchar(100),
--                                                        @IPVC_QuantityNode      varchar(100),
--                                                        @IPVC_AmountNode        varchar(100),
--                                                        @IPVC_BillDateNode      varchar(100),    
                                                          @xmlTrans               XML WITH RECOMPILE
AS
BEGIN
  set nocount on;
  declare @LB_PMCOnlyFlag bit
  set @LB_PMCOnlyFlag = 1

  SET QUOTED_IDENTIFIER ON;

  create table #temptblTrans  (
              CompanyIDSeq        varchar(50) NULL, 
              PropertyIDSeq       varchar(50) DEFAULT (''), 
              AccountIDSeq        varchar(50) NULL, 
              SourceTransactionID varchar(50) NULL, 
              AccountName         varchar(255), 
              SearchAccountName   varchar(255), 
              AccountType         varchar(40) NULL,
              UnitCost as  convert(numeric(30,2),(Amount) * (case when Quantity = 0 then 1 else Quantity end)
                                   ),
              Quantity           numeric(30,0),
              Amount             numeric(30,2),              
              [Description]      varchar(70) DEFAULT (''),
              OverrideAmountFlag tinyint DEFAULT (1), -- Use the amount in the XML instead of the amount on the order
              BillDate           datetime NULL, -- Convert the date on the client side
              MatchingName       varchar(255),
              ExactMatchCount    int NULL, -- The number of companies with the same name
              CloseMatchCount    int NULL, -- Account like '%' xls name '%'
              ReverseCloseMatchCount int NULL, -- xls name like '%' account '%'
              ErrorCode          char(1) DEFAULT ('S') -- 'S' = Success 'P' = Product missing
          )

  if @IPVC_ImportType = 'OLD'-- Will remove section later --@IPB_CompanyLookupFlag = 1 and @IPB_StandardFlag = 0
  begin
--    select replace(replace(convert(varchar(200), A2.NewDataSet.query('data(sql:variable("@IPVC_CompanyNameNode"))')), char(10), ''), char(13), ''),
    insert #temptblTrans (AccountName, SearchAccountName, Quantity, Amount, BillDate)
    select replace(replace(convert(varchar(200), A2.NewDataSet.query('data(./Customer_x0020_Name)')), char(10), ''), char(13), ''),
      '%' + replace(left(replace(replace(convert(varchar(200), A2.NewDataSet.query('data(./Customer_x0020_Name)')), char(10), ''), char(13), ''), 15), ' ', '%') + '%',
      convert(numeric(5,2), convert(varchar(10), A2.NewDataSet.query('data(./Hours_x0020_Billed)'))),
      convert(numeric(8,2), convert(varchar(10), A2.NewDataSet.query('data(./Amount_x0020_Expenses_x0020_Billed)'))),
      convert(datetime, replace(left(convert(varchar(30),A2.NewDataSet.query('data(./Bill_x0020_Date)')), 19), 'T', ' '))
    from @xmlTrans.nodes('/NewDataSet/Table') as A2(NewDataSet)

    if @LB_PMCOnlyFlag = 1
    begin
      update tt
      set ExactMatchCount = (select count(*) from Customers..Company c with (nolock) inner join Customers..Account a with (nolock) on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where tt.[AccountName] = c.[Name])--,
  --        CloseMatchCount = (select count(*) from Customers..Company c inner join Customers..Account a on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where c.[Name] like tt.[SearchAccountName]) ,
  --        CloseMatchCount = (select count(*) from Customers..Company c inner join Customers..Account a on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where c.[Name] like '%' + replace(left(tt.[AccountName], 15), ' ', '%') + '%') ,
  --        CloseMatchCount = (select count(*) from (select top 2 1 as c1 from Customers..Company c inner join Customers..Account a on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where c.[Name] like '%' + replace(left(tt.[AccountName], 15), ' ', '%') + '%') as tbl) --,
  --        ReverseCloseMatchCount = (select count(*) from Customers..Company c inner join Customers..Account a on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where len(c.[Name]) > 4 and tt.[AccountName] like '%' + replace(c.[Name], ' ', '%') + '%')
      from #temptblTrans tt

      update tt
      set CloseMatchCount = (select count(*) from Customers..Company c  with (nolock) inner join Customers..Account a with (nolock) on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where c.[Name] like tt.[SearchAccountName])
      from #temptblTrans tt
      where tt.ExactMatchCount = 0

      update tt
      set ReverseCloseMatchCount = (select count(*) from Customers..Company c with (nolock) inner join Customers..Account a with (nolock) on c.IDSeq = a.CompanyIDSeq and a.PropertyIDSeq is null where len(c.[Name]) > 4 and tt.[AccountName] like '%' + replace(c.[Name], ' ', '%') + '%')
      from #temptblTrans tt
      where tt.CloseMatchCount = 0
      and   tt.ExactMatchCount = 0

      update tt
      set AccountType = at.[Name],
          CompanyIDSeq = c.IDSeq,
          MatchingName = c.[Name],
          AccountIDSeq = a.IDSeq
      from #temptblTrans tt inner join Customers..Company c  with (nolock)
      on tt.AccountName = c.[Name] 
      inner join Customers..Account a with (nolock)
      on a.CompanyIDSeq = c.IDSeq
      and a.PropertyIDSeq is null
      and a.ActiveFlag = 1
      inner join Customers..AccountType at  with (nolock)
      on at.Code = a.AccountTypeCode
      where tt.CompanyIDSeq is null
      and  tt.ExactMatchCount = 1

      update tt
      set AccountType = at.[Name],
          CompanyIDSeq = c.IDSeq,
          MatchingName = c.[Name],
          AccountIDSeq = a.IDSeq
      from #temptblTrans tt inner join Customers..Company c  with (nolock)
      on c.[Name] like tt.[SearchAccountName]
      inner join Customers..Account a with (nolock)
      on a.CompanyIDSeq = c.IDSeq
      and a.PropertyIDSeq is null
      and a.ActiveFlag = 1
      inner join Customers..AccountType at  with (nolock)
      on at.Code = a.AccountTypeCode
      where tt.CompanyIDSeq is null
      and tt.CloseMatchCount = 1

      update tt
      set AccountType = at.[Name],
          CompanyIDSeq = c.IDSeq,
          MatchingName = c.[Name],
          AccountIDSeq = a.IDSeq
      from #temptblTrans tt inner join Customers..Company c  with (nolock)
      on tt.[AccountName] like '%' + replace(c.[Name], ' ', '%') + '%'
      inner join Customers..Account a with (nolock)
      on a.CompanyIDSeq = c.IDSeq
      and a.PropertyIDSeq is null
      and a.ActiveFlag = 1
      inner join Customers..AccountType at with (nolock) 
      on at.Code = a.AccountTypeCode
      where tt.CompanyIDSeq is null
      and tt.ReverseCloseMatchCount = 1
    end
  end
  else if @IPVC_ImportType = 'STD' --if @IPB_StandardFlag = 1
  begin
    insert #temptblTrans (CompanyIDSeq, AccountIDSeq, AccountName, AccountType, SearchAccountName, 
      Quantity, Amount, [Description], OverrideAmountFlag, BillDate, ExactMatchCount, SourceTransactionID)
    select isnull(c.IDSeq, ''), a.IDSeq, 
      isnull(c.[Name], convert(varchar(100), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./PMC_x0020_Name)')))),1,100))),     
      at.[Name], 
      isnull(c.[Name], convert(varchar(100), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./PMC_x0020_Name)')))),1,100))),    
      (case when (ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) = '' or 
                 ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) is NULL or
                 ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) = 0
                ) 
             then 1
           else  convert(numeric(30,0),ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))))
       end),      
      convert(numeric(30,2),ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Amount)'))))),      
      convert(varchar(70), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./Description)')))),1,70)),  
      convert(int, convert(varchar(10), A2.NewDataSet.query('data(./Override)'))),
      convert(datetime, replace(left(convert(varchar(30),A2.NewDataSet.query('data(./Date)')), 19), 'T', ' ')),
      case when c.IDSeq is null then 0 else 1 end,
      convert(varchar(30), A2.NewDataSet.query('data(./Tran_x0020_ID)'))
    from @xmlTrans.nodes('/NewDataSet/Table') as A2(NewDataSet)
    left outer join 
         Customers.dbo.Company c  with (nolock)
    on   (c.SiteMasterID = convert(varchar(50),A2.NewDataSet.query('data(./PMC_x0020_ID)'))
              or
          c.IDSeq = convert(varchar(50),A2.NewDataSet.query('data(./PMC_x0020_ID)'))
         )
    left outer join Customers.dbo.Account a with (nolock)
    on  a.CompanyIDSeq    = c.IDSeq
    and a.PropertyIDSeq   is null
    and a.ActiveFlag      = 1
    and a.AccountTypeCode = 'AHOFF'
    left outer join 
        Customers.dbo.AccountType at with (nolock) 
    on at.Code = a.AccountTypeCode
    where 
          (convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) = ''
                 or    
           convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) = 'NULL'
                 or
           convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) IS NULL
          )
    ----------------------------------------------------------------------------------------------------------------------
    insert #temptblTrans (CompanyIDSeq, PropertyIDSeq, AccountIDSeq, AccountName, AccountType, SearchAccountName, 
      Quantity, Amount, [Description], OverrideAmountFlag, BillDate, ExactMatchCount, SourceTransactionID)
    select a.CompanyIDSeq, isnull(p.IDSeq, ''), a.IDSeq, 
           isnull(p.[Name], convert(varchar(100), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./Site_x0020_Name)')))),1,100))), 
           at.[Name], 
           isnull(p.[Name], convert(varchar(100), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./Site_x0020_Name)')))),1,100))), 
       (case when (ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) = '' or 
                 ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) is NULL or
                 ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))) = 0
                ) 
             then 1
           else  convert(numeric(30,0),ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Quantity)')))))
       end),      
      convert(numeric(30,2),ltrim(rtrim(convert(varchar(20),A2.NewDataSet.query('data(./Amount)'))))),

      convert(varchar(70), substring(ltrim(rtrim(convert(varchar(4000),A2.NewDataSet.query('data(./Description)')))),1,70)),
      convert(int, convert(varchar(10), A2.NewDataSet.query('data(./Override)'))),
      convert(datetime, replace(left(convert(varchar(30),A2.NewDataSet.query('data(./Date)')), 19), 'T', ' ')),
      case when p.IDSeq is null then 0 else 1 end,
      convert(varchar(30), A2.NewDataSet.query('data(./Tran_x0020_ID)'))
    from @xmlTrans.nodes('/NewDataSet/Table') as A2(NewDataSet)
    left outer join 
         Customers.dbo.[Property] p with (nolock)
    on   (p.SiteMasterID = convert(varchar(50), A2.NewDataSet.query('data(./Site_x0020_ID)'))
              or
          p.IDSeq        = convert(varchar(50), A2.NewDataSet.query('data(./Site_x0020_ID)'))
         )
    left outer join 
         Customers.dbo.Account a with (nolock)
    on   a.PropertyIDSeq = p.IDSeq
    and  a.ActiveFlag    = 1
    and a.PropertyIDSeq  is not null
    and a.AccountTypeCode = 'APROP'
    left outer join 
         Customers.dbo.AccountType at with (nolock) 
    on at.Code = a.AccountTypeCode
    where 
          (convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) != ''
              and 
           convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) != 'NULL'
              and
           convert(varchar(20), A2.NewDataSet.query('data(./Site_x0020_ID)')) IS NOT NULL
          )
--    order by isnull(p.[Name], convert(varchar(100), A2.NewDataSet.query('data(./Site_x0020_Name)')))
  end
  ----------------------------------------------------------------------------------------------------------------------
  -- Make sure there is an account
  update tt
  set ErrorCode = 'A'
  from #temptblTrans tt
  where tt.AccountIDSeq is null
  and ExactMatchCount = 1

  -- Make sure the accounts have active products
  update tt
  set ErrorCode = 'P'
  from #temptblTrans tt
  where tt.CompanyIDSeq is not null
  and ErrorCode = 'S'
  and NOT EXISTS (select 1 from [Order] o with (nolock)
                  inner join OrderItem oi with (nolock)
                  on    o.OrderIDSeq = oi.OrderIDSeq
                  and   charindex(rtrim(oi.ProductCode), @IPVC_ProductCode) > 0
--                  and   oi.StatusCode = 'FULF'
				   and   (oi.StatusCode = 'FULF' OR (oi.StatusCode = 'CNCL' AND CONVERT(INT, CONVERT(VARCHAR, ISNULL(CancelDate, GETDATE()), 112)) >= CONVERT(INT, CONVERT(VARCHAR, tt.BillDate, 112))))
                  where o.AccountIDSeq = tt.AccountIDSeq)

  -- Check to see if a duplicate transaction exist
  update tt
  set ErrorCode = 'D'
  from #temptblTrans tt
  where tt.CompanyIDSeq is not null
  and ErrorCode = 'S'
  and EXISTS (select 1 from [Order] o with (nolock)
                  inner join OrderItemTransaction oit with (nolock)
                  on    o.OrderIDSeq = oit.OrderIDSeq
                  and   oit.ProductCode = @IPVC_ProductCode
                  and   oit.SourceTransactionID = tt.SourceTransactionID
                  where o.AccountIDSeq = tt.AccountIDSeq)


  select  CompanyIDSeq, PropertyIDSeq, AccountIDSeq, AccountName, AccountType, UnitCost as Amount,Quantity,
          Amount as UnitCost, convert(varchar(10), BillDate, 101) as BillDate, MatchingName, 
          case when ExactMatchCount = 1 
            then 'E'
          when CloseMatchCount = 1 or ReverseCloseMatchCount = 1 
            then 'C'
          when CloseMatchCount + ReverseCloseMatchCount > 1 
            then 'S'
          else 'N' end as MatchType, 
          case when ExactMatchCount = 1 
            then 'Exact Match'
          when CloseMatchCount = 1 or ReverseCloseMatchCount = 1 
            then 'Close Match'
          when CloseMatchCount + ReverseCloseMatchCount > 1 
            then 'Several Matches'
          else 'No Match' end as MatchTypeText,

          ErrorCode, 
          case when ErrorCode = 'P' 
            then 'No active order.'
          when ErrorCode = 'D'
            then 'Duplicate found'
          when ErrorCode = 'A'
            then 'No account exists'
          else '' end as ErrorCodeText,
          [Description], OverrideAmountFlag, SourceTransactionID
  from #temptblTrans with (nolock)
--  order by AccountName
 
  -------------------------------------------------
  drop table #temptblTrans
  -------------------------------------------------

/*
  select c.IDSeq, c.[Name]
  from #tmpImport ti left outer join Company c
  on ti.[Name] like '%' + c.[Name] + '%'

  select convert(varchar(230), A2.NewDataSet.query('data(./Customer_x0020_Name)')), A2.NewDataSet.query('Customer_x0020_Name') 
  from @xml.nodes('/NewDataSet/Table') as A2(NewDataSet)
*/
  SET QUOTED_IDENTIFIER OFF;

END
GO
