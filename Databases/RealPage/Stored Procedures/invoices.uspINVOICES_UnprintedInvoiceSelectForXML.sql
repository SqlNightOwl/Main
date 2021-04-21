SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_UnprintedInvoiceSelectForXML
-- Description     : This procedure accepts Input XML and returns Qualifying Open Invoices for Lanvera Outbound
-- Input Parameters: @IPXML_filterlist   as XML
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_UnprintedInvoiceSelectForXML @IPXML_filterlist = xml
-- Syntax for call :
/* 
Exec INVOICES.dbo.uspINVOICES_UnprintedInvoiceSelectForXML @IPXML_filterlist = 
'<filterlist>
  <accounts>
    <accountid>A0901022542</accountid>
    <accountid>A1010001317</accountid>
  </accounts>
  <customers>
    <customerid>C1105000055</customerid>
  </customers>
  <invoices>
    <invoiceid>I1105030889</invoiceid>
    <invoiceid>I1105030888</invoiceid>
  </invoices>
</filterlist>'

Exec INVOICES.dbo.uspINVOICES_UnprintedInvoiceSelectForXML @IPXML_filterlist =
'<filterlist>
  <accounts>
    <accountid/>
  </accounts>
  <customers>
    <customerid/>
  </customers>
  <invoices>
    <invoiceid/>
  </invoices>
</filterlist>'
*/
-- 
-- Revision History:
-- Author          : 
-- 02/16/2010      : Stored Procedure Created. Terry Sides
-- 03/12/2010      : Defect 7550 (enhance for accepting xml filterlist)
-- 05/20/2011      : TFS 592 SRS - After XML Generate process, Core Attributes of Invoice header should not be touched.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UnprintedInvoiceSelectForXML] (@IPXML_filterlist  XML)
AS
BEGIN
  set nocount on;
  ----------------------------------------
  -- Table Declaration
  declare @LT_FilterList table(accountid   varchar(50),
                               customerid  varchar(50),
                               invoiceid   varchar(50)
                              );
  -----------------------------------------------------------------------------------
  Update Invoices.dbo.Invoice
  set    InvoiceDate    = Convert(varchar(50),getdate(),101),
         InvoiceDueDate = Convert(varchar(50),dateadd(mm,1,getdate()),101)
  WHERE  PrintFlag = 0;
  ----------------------------------------------------------------------------------- 
  --OPENXML to read XML and Insert Data into @LT_FilterList
  -----------------------------------------------------------------------------------   
  begin TRY  
    insert into @LT_FilterList(accountid)
    select S.accountid
    from   (
            select NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(.)')))),'') as accountid
            from   @IPXML_filterlist.nodes('/filterlist/accounts/accountid') as EXD(NewDataSet)
           ) S 
    where  S.accountid is not null
    group by S.accountid;
    -----  
    insert into @LT_FilterList(customerid)
    select S.customerid
    from   (
            select NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(.)')))),'') as customerid
            from   @IPXML_filterlist.nodes('/filterlist/customers/customerid') as EXD(NewDataSet)
           ) S
    where  S.customerid is not null
    group by S.customerid;
    -----  
    insert into @LT_FilterList(invoiceid)
    select S.invoiceid
    from   (
            select NULLIF(ltrim(rtrim(convert(varchar(100),EXD.NewDataSet.query('data(.)')))),'') as invoiceid
            from   @IPXML_filterlist.nodes('/filterlist/invoices/invoiceid') as EXD(NewDataSet)
           ) S
    where  S.invoiceid is not null
    group by S.invoiceid;
    -----------------------------------------
    if (select count(1) from @LT_FilterList)=0
    begin
      insert into @LT_FilterList(accountid)  select NULL as accountid;
      insert into @LT_FilterList(customerid) select NULL as customerid;
      insert into @LT_FilterList(invoiceid)  select NULL as invoiceid;
    end
  end TRY
  begin CATCH    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc: uspINVOICES_UnprintedInvoiceSelectForXML : //filterlist/... XML ReadSection failed'    
    return
  end CATCH; 
  ------------------------------------------------------------------
  ---Final Select based on Filter XML values
  ------------------------------------------------------------------
  select X.InvoiceIDSeq
  from   (select I.InvoiceIDSeq,I.AccountIDSeq,I.CompanyIDSeq
          from   Invoices.dbo.Invoice I WITH (NOLOCK)          
          where  I.PrintFlag = 0
          and    exists (select top 1 1 
                         from   INVOICES.DBO.InvoiceItem II with (nolock)
                         where  II.InvoiceIDSeq = I.InvoiceIDSeq
                        )
          group by I.InvoiceIDSeq,I.AccountIDSeq,I.CompanyIDSeq
         ) X
  where exists (select top 1 1
                from   @LT_FilterList       FL 
                where  X.InvoiceIDSeq  = coalesce(FL.invoiceid,X.InvoiceIDSeq)
                and    X.AccountIDSeq  = coalesce(FL.accountid,X.AccountIDSeq)
                and    X.CompanyIDSeq  = coalesce(FL.customerid,X.CompanyIDSeq)
               )
  group by X.InvoiceIDSeq --> Group by is needed to avoid costly distinct operation.
  Order by X.InvoiceIDSeq asc;
  ------------------------------------------------------------------
END
GO
