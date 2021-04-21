SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[spXmlTestSelect] @xml xml
AS
BEGIN
  declare @LB_PMCOnlyFlag bit
  set @LB_PMCOnlyFlag = 1

  declare @tblTrans  TABLE (
              CompanyIDSeq varchar(20) NULL, 
              PropertyIDSeq varchar(20) DEFAULT (space(0)), 
              AccountIDSeq varchar(20) NULL, 
              AccountName varchar(200), 
              AccountType varchar(40) NULL,
              Quantity numeric(5,2),
              Amount numeric(8, 2),
              BillDate datetime NULL, -- Convert the date on the client side
              MatchingName varchar(200),
              ExactMatchCount int NULL, -- The number of companies with the same name
              CloseMatchCount int NULL, -- Account like '%' xls name '%'
              ReverseCloseMatchCount int NULL -- xls name like '%' account '%'
          )

  insert @tblTrans (AccountName, Quantity, Amount, BillDate)
  select replace(replace(convert(varchar(230), A2.NewDataSet.query('data(./Customer_x0020_Name)')), char(10), ''), char(13), ''),
    convert(numeric(5,2), convert(varchar(10), A2.NewDataSet.query('data(./Hours_x0020_Billed)'))),
    convert(numeric(8,2), convert(varchar(10), A2.NewDataSet.query('data(./Total_x0020_Expenses_x0020_Billed)'))),
    convert(datetime, replace(left(convert(varchar(30),A2.NewDataSet.query('data(./Bill_x0020_Date)')), 19), 'T', ' '))
  from @xml.nodes('/NewDataSet/Table') as A2(NewDataSet)

  if @LB_PMCOnlyFlag = 1
  begin
    update tt
    set ExactMatchCount = (select count(*) from Customers..Company c where tt.[AccountName] = c.[Name]),
        CloseMatchCount = (select count(*) from Customers..Company c where c.[Name] like '%' + replace(left(tt.[AccountName], 15), ' ', '%') + '%'),
        ReverseCloseMatchCount = (select count(*) from Customers..Company c where len(c.[Name]) > 4 and tt.[AccountName] like '%' + replace(c.[Name], ' ', '%') + '%')
    from @tblTrans tt

    update tt
    set AccountType = at.[Name],
        CompanyIDSeq = c.IDSeq,
        MatchingName = c.[Name],
        AccountIDSeq = a.IDSeq
    from @tblTrans tt inner join Customers..Company c 
    on tt.AccountName = c.[Name] 
    inner join Customers..Account a
    on a.CompanyIDSeq = c.IDSeq
    and a.PropertyIDSeq is null
    and a.ActiveFlag = 1
    inner join Customers..AccountType at 
    on at.Code = a.AccountTypeCode
    where tt.CompanyIDSeq is null
    and  tt.ExactMatchCount = 1

    update tt
    set AccountType = at.[Name],
        CompanyIDSeq = c.IDSeq,
        MatchingName = c.[Name],
        AccountIDSeq = a.IDSeq
    from @tblTrans tt inner join Customers..Company c 
    on c.[Name] like '%' + replace(left(tt.[AccountName], 15), ' ', '%') + '%'
    inner join Customers..Account a
    on a.CompanyIDSeq = c.IDSeq
    and a.PropertyIDSeq is null
    and a.ActiveFlag = 1
    inner join Customers..AccountType at 
    on at.Code = a.AccountTypeCode
    where tt.CompanyIDSeq is null
    and tt.CloseMatchCount = 1

    update tt
    set AccountType = at.[Name],
        CompanyIDSeq = c.IDSeq,
        MatchingName = c.[Name],
        AccountIDSeq = a.IDSeq
    from @tblTrans tt inner join Customers..Company c 
    on tt.[AccountName] like '%' + replace(c.[Name], ' ', '%') + '%'
    inner join Customers..Account a
    on a.CompanyIDSeq = c.IDSeq
    and a.PropertyIDSeq is null
    and a.ActiveFlag = 1
    inner join Customers..AccountType at 
    on at.Code = a.AccountTypeCode
    where tt.CompanyIDSeq is null
    and tt.ReverseCloseMatchCount = 1

  end


  select  CompanyIDSeq, PropertyIDSeq, AccountIDSeq, AccountName, AccountType, Quantity,
              Amount, BillDate, MatchingName, 
          case when ExactMatchCount = 1 
            then 'E'
          when CloseMatchCount = 1 or ReverseCloseMatchCount = 1 
            then 'C'
          when CloseMatchCount + ReverseCloseMatchCount > 1 
            then 'S'
          else 'N' end as MatchType 
  from @tblTrans

/*
  select c.IDSeq, c.[Name]
  from #tmpImport ti left outer join Company c
  on ti.[Name] like '%' + c.[Name] + '%'

  select convert(varchar(230), A2.NewDataSet.query('data(./Customer_x0020_Name)')), A2.NewDataSet.query('Customer_x0020_Name') 
  from @xml.nodes('/NewDataSet/Table') as A2(NewDataSet)
*/
END

GO
