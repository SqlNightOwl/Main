SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec Orders.dbo.uspORDERS_Orderlist 
                               @IPI_PageNumber       =   1,
                               @IPI_RowsPerPage      =   21, 
                               @IPVC_CustomerName    =   '',
                               @IPVC_City            =   '',
                               @IPVC_State           =   '', 
                               @IPVC_ZipCode         =   '',
                               @IPVC_PropertyName    =   '',
                               @IPVC_OptionSelected  =   '0',
                               @IPVC_StatusType      =   '',
                               @IPVC_AccountID       =   '',
                               @IPVC_CompanyID       =   '',
                               @IPVC_QuoteID         =   '',
                               @IPVC_ProductName     =   '',
                               @IPVC_Address         =   '',
							   @IPVC_CountryCode     =   ''
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : test
-- Description     : This procedure gets Order Details pertaining to passed 
--                        CustomerName,City,State,ZipCode,PropertyID and StatusType
-- Input Parameters: @IPI_PageNumber      as    integer 
--                   @IPI_RowsPerPage     as    integer 
--                   @IPVC_CustomerName   as    varchar 
--                   @IPVC_City           as    varchar
--                   @IPVC_State          as    varchar
--                   @IPVC_ZipCode        as    varchar
--                   @IPVC_PropertyName   as    varchar
--                   @IPVC_OptionSelected as    varchar
--                   @IPVC_StatusType     as    varchar
--                   @IPVC_AccountID      as    varchar
--                   @IPVC_CompanyID      as    varchar
--                   @IPVC_QuoteID        as    varchar
--                   @IPVC_QuoteID        as    varchar
--                   @IPVC_ProductName    as    varchar
--                   @IPVC_Address        as    varchar
--      			 @IPVC_CountryCode    as    varchar   
-- 
-- OUTPUT          : RecordSet of ID,CompanyName,CompanyIDSeq,
--                                StatusName,AccountIDSeq,CreatedDate,Period,LastInvoice
-- Code Example    : exec Orders.dbo.uspORDERS_Orderlist 
--                                                  @IPI_PageNumber       =   1,
--                                                  @IPI_RowsPerPage      =   200, 
--                                                  @IPVC_CustomerName    =   '',
--                                                  @IPVC_City            =   '',
--                                                  @IPVC_State           =   '', 
--                                                  @IPVC_ZipCode         =   '',
--                                                  @IPVC_PropertyName    =   '',
--                                                  @IPVC_OptionSelected  =   '0',
--                                                  @IPVC_StatusType      =   '',
--                                                  @IPVC_AccountID       =   '',
--                                                  @IPVC_CompanyID       =   '',
--                                                  @IPVC_QuoteID         =   '',
--                                                  @IPVC_ProductName     =   '',
--                                                  @IPVC_Address         =   '',
--													@IPVC_CountryCode     =   ''
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 11/25/2006      : Stored Procedure Created.
-- 11/28/2006      : Changed by KISHORE KUMAR A S. Changed Variable Names.
-- 12/22/2006      : Changed by STA. The search errors are fixed.
-- 12/27/2006      : Changed by KRK. Fine tuned for execution speed.
-- 01/05/2007      : Changed by STA. The search errors wrt DateTime are fixed.
-- 01/22/2007      : Changed by KRK. The conditions implementations have been changed
-- 06/08/2007      : Changed by SRS. No change in BL.Rearranged Search conditions for performance.
-- 10/17/2011      : Changed by Mahaboob - TFS #1151 - CountryCode has been added in the Search criteria.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_Orderlist] (@IPI_PageNumber       int, 
                                              @IPI_RowsPerPage      int,
                                              @IPVC_CustomerName    varchar(100), 
                                              @IPVC_City            varchar(70), 
                                              @IPVC_State           varchar(2), 
                                              @IPVC_ZipCode         varchar(10),
                                              @IPVC_PropertyName    varchar(100),
                                              @IPVC_OptionSelected  varchar(1),
                                              @IPVC_StatusType      varchar(5), 
                                              @IPVC_AccountID       varchar(50),
                                              @IPVC_CompanyID       varchar(50),
                                              @IPVC_QuoteID         varchar(50),
                                              @IPVC_ProductName     varchar(100),
											  @IPVC_Address	        varchar(200),
											  @IPVC_CountryCode     varchar(20)=''   	   	
					     )	---WITH RECOMPILE -- THIS IS TO HANDLE CACHING AND LOCKING
AS
BEGIN -->Main Begin
  set nocount on;
  --------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  ---------------------------------------
  select @LN_CHECKSUM = checksum(coalesce(@IPVC_CustomerName,''),
                                 coalesce(@IPVC_City,''),
                                 coalesce(@IPVC_State,''),
                                 coalesce(@IPVC_ZipCode,''),
                                 coalesce(@IPVC_PropertyName,''),                                                              
                                 coalesce(@IPVC_Address,''),
								 coalesce(@IPVC_CountryCode,'')
								 );

  set @IPVC_QuoteID    = nullif(ltrim(rtrim(@IPVC_QuoteID)),'')
  set @IPVC_AccountID  = nullif(ltrim(rtrim(@IPVC_AccountID)),'')
  set @IPVC_CompanyID  = nullif(ltrim(rtrim(@IPVC_CompanyID)),'')
  set @IPVC_StatusType = nullif(ltrim(rtrim(@IPVC_StatusType)),'')
  ---------------------------------------
  select I.AccountIDSeq,IG.OrderIDSeq,
         convert(varchar(20),max(I.InvoiceDate),101) as LastInvoiceDate
  Into  #TEMP_InvoiceDates
  from   Invoices.dbo.Invoice I with (nolock) 
  inner join
         Invoices.dbo.InvoiceGroup IG with (nolock) 
  on    I.InvoiceIDSeq = IG.InvoiceIDSeq  
  and   I.printflag    = 1                     
  group by I.AccountIDSeq,IG.OrderIDSeq;
  ---------------------------------------
  If (@LN_CHECKSUM <> 0)
  begin
    select S.CompanyIDSeq,S.PropertyIDSeq,S.AccountIDSeq,S.AccountName,
           S.CompanyName,S.accounttypecode,
           identity(int,1,1) as sortseq
    into #TEMP_Account
    From
    (select c.IDSeq           as CompanyIDSeq, 
            '0'               as PropertyIDSeq,
            acct.IDSeq        as AccountIDSeq, 
            c.Name            as AccountName, 
            c.Name            as CompanyName,
            'AHOFF'           as accounttypecode
     from Customers.dbo.Account acct with (nolock)
     inner join
          Customers.dbo.Company c    with (nolock)
     on   acct.companyidseq = c.idseq
     and  c.idseq           = coalesce(@IPVC_CompanyID,c.idseq)
     and  c.Name            like '%'  + @IPVC_CustomerName  + '%'
     and  acct.companyidseq = coalesce(@IPVC_CompanyID,acct.companyidseq)
     and  acct.idseq        = coalesce(@IPVC_AccountID,acct.idseq)
     and  acct.accounttypecode = 'AHOFF'
	
     ----------
     Union ALL
     ----------
     select 
           c.IDSeq             as CompanyIDSeq, 
           p.IDSeq             as PropertyIDSeq,
           acct.IDSeq          as AccountIDSeq,  
           p.Name              as AccountName, 
           c.Name              as CompanyName,
           'APROP'             as accounttypecode
     from  Customers.dbo.Account acct  with (nolock)
     inner join
           Customers.dbo.Company c     with (nolock)
     on   acct.companyidseq    = c.idseq
     and  c.idseq           = coalesce(@IPVC_CompanyID,c.idseq)
     and  c.Name            like '%'  + @IPVC_CustomerName  + '%'
     and  acct.companyidseq = coalesce(@IPVC_CompanyID,acct.companyidseq)
     and  acct.idseq        = coalesce(@IPVC_AccountID,acct.idseq) 
     and  acct.accounttypecode = 'APROP'
     inner join
          Customers.dbo.Property p  with (nolock)
     on   c.idseq            = p.pmcidseq
     and  acct.companyidseq  = p.pmcidseq
     and  acct.propertyidseq = p.IDSeq 
     and  p.pmcidseq         = coalesce(@IPVC_CompanyID,p.pmcidseq)
     and  p.Name             like '%'  + @IPVC_PropertyName  + '%' 
     ) S
     inner join
          Customers.dbo.Address a with (nolock)
     on    a.companyidseq                = S.companyidseq            
     and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
     and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')
     and  a.City              like '%'+ @IPVC_City          + '%'
     and  a.State             like '%'+ @IPVC_State         + '%' 
     and  a.Zip               like '%'+ @IPVC_ZipCode       + '%' 
     and  a.AddressLine1      like '%'+ @IPVC_Address       + '%'
     and  S.AccountName like '%' + @IPVC_PropertyName + '%' 
	 and  a.CountryCode  like '%' + @IPVC_CountryCode  + '%'  
     where S.AccountName like '%' + @IPVC_PropertyName + '%'
  end;
  ----------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ---------------------------------------------
  if (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') = '' and coalesce(@IPVC_StatusType,'') = '')
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
            (select 
             ---------------------------------------------------------- 
             O.[OrderIDSeq]                           as [ID],             
             Max(C.Name)                              as CompanyName,  
             (case when O.Propertyidseq is null then 'APORP'
                   else 'AHOFF'
              end)                                    as accounttypecode,
             O.CompanyIDSeq                           as CompanyIDSeq,
             coalesce(Max(P.[Name]),Max(C.[Name]))    as AccountName,
             Max(OST.[Name])                          as StatusName, 
             O.AccountIDSeq                           as AccountIDSeq,
             Convert(varchar(10),Max(O.CreatedDate),101)   as CreatedDate,
             'N/A'                                         as Period, 
             coalesce(Max(T.LastInvoiceDate),'N/A')        as LastInvoice,
                    row_number() over(order by O.OrderIDSeq desc                                          
                                    ) as RowNumber
             ----------------------------------------------------------
             From  Orders.dbo.[Order]           O    with (nolock) 
             inner join   Orders.dbo.[OrderStatusType] OST  with (nolock) 
             on    O.StatusCode   = OST.Code   
             and   O.AccountIDSeq = coalesce(@IPVC_AccountID,O.AccountIDSeq)
             and   coalesce(O.QuoteIDSeq,'')   = coalesce(@IPVC_QuoteID,coalesce(O.QuoteIDSeq,''))            
             and        ( (@IPVC_OptionSelected ='0')
                                    or
                          ((@IPVC_OptionSelected ='1') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) = 
                                    convert(datetime,convert(varchar(20),GETDATE(),101))
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='2') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(week,-1,GETDATE()),101))  
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='3') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(m,-1,GETDATE()),101))  
                                   )
                          )
                        )                                    
             inner  join
                       Customers.dbo.Company C with (nolock)
             on        C.IDSeq              =O.CompanyIDSeq 
             and       C.IDSeq = coalesce(@IPVC_CompanyID,C.IDSeq)
			 left outer join
                       Customers.dbo.Property P    with (nolock) 
             on        P.IDSeq              = O.PropertyIDSeq
             and       P.PMCIDSeq           = O.CompanyIDSeq             
             left outer join
                       #TEMP_InvoiceDates  T with (nolock)
             on        O.Orderidseq        = T.Orderidseq
             and       O.AccountIdSeq      = T.AccountIdSeq                      
          ----------------------------------------------------------
      group by O.OrderIDSeq,O.AccountIdSeq,O.CompanyIdseq,O.Propertyidseq
          ) tableinner
       ---------------------------------------------------------- 
       WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
       SELECT  tablefinal.RowNumber,
               tablefinal.[ID]                     as [ID],
               tablefinal.accounttypecode          as accounttypecode,
	       tablefinal.CompanyName              as CompanyName,
               tablefinal.CompanyIDSeq             as CompanyIDSeq,
               tablefinal.AccountName              as AccountName,
               tablefinal.StatusName               as StatusName,
	       tablefinal.AccountIDSeq             as AccountIDSeq, 
	       tablefinal.CreatedDate              as CreatedDate,
	       tablefinal.Period                   as Period,
     	       tablefinal.LastInvoice              as LastInvoice                  
      from     tablefinal;
  end
  else if (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
            (select 
             ---------------------------------------------------------- 
             O.[OrderIDSeq]                           as [ID],             
             Max(C.Name)                              as CompanyName,  
             (case when O.Propertyidseq is null then 'APORP'
                   else 'AHOFF'
              end)                                    as accounttypecode,
             O.CompanyIDSeq                           as CompanyIDSeq,
             coalesce(Max(P.[Name]),Max(C.[Name]))    as AccountName,
             Max(OST.[Name])                          as StatusName, 
             O.AccountIDSeq                           as AccountIDSeq,
             Convert(varchar(10),Max(O.CreatedDate),101)   as CreatedDate,
             'N/A'                                         as Period, 
             coalesce(Max(T.LastInvoiceDate),'N/A')        as LastInvoice,
                    row_number() over(order by O.OrderIDSeq desc                                          
                                    ) as RowNumber
             ----------------------------------------------------------
             From  Orders.dbo.Orderitem OI with (nolock)                       
             inner join
                   Orders.dbo.[Order]           O    with (nolock) 
             on    OI.OrderIdSeq  = O.Orderidseq  
             and   O.AccountIDSeq = coalesce(@IPVC_AccountID,O.AccountIDSeq)             
             and   coalesce(O.QuoteIDSeq,'')   = coalesce(@IPVC_QuoteID,coalesce(O.QuoteIDSeq,''))
             and   OI.StatusCode = coalesce(@IPVC_StatusType,OI.StatusCode)              
             and        ( (@IPVC_OptionSelected ='0')
                                    or
                          ((@IPVC_OptionSelected ='1') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) = 
                                    convert(datetime,convert(varchar(20),GETDATE(),101))
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='2') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(week,-1,GETDATE()),101))  
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='3') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(m,-1,GETDATE()),101))  
                                   )
                          )
                        )                       
             inner join   Orders.dbo.[OrderStatusType] OST  with (nolock) 
             on           O.StatusCode   = OST.Code                         
             inner  join
                       Customers.dbo.Company C with (nolock)
             on        C.IDSeq              =O.CompanyIDSeq 
             and       C.IDSeq = coalesce(@IPVC_CompanyID,C.IDSeq)
			 left outer join
                       Customers.dbo.Property P    with (nolock) 
             on        P.IDSeq              = O.PropertyIDSeq
             and       P.PMCIDSeq           = O.CompanyIDSeq             
             left outer join
                       #TEMP_InvoiceDates  T with (nolock)
             on        O.Orderidseq        = T.Orderidseq
             and       O.AccountIdSeq      = T.AccountIdSeq                      
          ----------------------------------------------------------
      group by O.OrderIDSeq,O.AccountIdSeq,O.CompanyIdseq,O.Propertyidseq
          ) tableinner
       ---------------------------------------------------------- 
       WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
       SELECT  tablefinal.RowNumber,
               tablefinal.[ID]                     as [ID],
               tablefinal.accounttypecode          as accounttypecode,
	       tablefinal.CompanyName              as CompanyName,
               tablefinal.CompanyIDSeq             as CompanyIDSeq,
               tablefinal.AccountName              as AccountName,
               tablefinal.StatusName               as StatusName,
	       tablefinal.AccountIDSeq             as AccountIDSeq, 
	       tablefinal.CreatedDate              as CreatedDate,
	       tablefinal.Period                   as Period,
     	       tablefinal.LastInvoice              as LastInvoice                  
      from     tablefinal;
  end
  else if (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
            (select 
             ---------------------------------------------------------- 
             O.[OrderIDSeq]                           as [ID],             
             Max(C.Name)                              as CompanyName,  
             (case when O.Propertyidseq is null then 'APORP'
                   else 'AHOFF'
              end)                                    as accounttypecode,
             O.CompanyIDSeq                           as CompanyIDSeq,
             coalesce(Max(P.[Name]),Max(C.[Name]))    as AccountName,
             Max(OST.[Name])                          as StatusName, 
             O.AccountIDSeq                           as AccountIDSeq,
             Convert(varchar(10),Max(O.CreatedDate),101)   as CreatedDate,
             'N/A'                                         as Period, 
             coalesce(Max(T.LastInvoiceDate),'N/A')        as LastInvoice,
                    row_number() over(order by O.OrderIDSeq desc                                          
                                    ) as RowNumber
             ----------------------------------------------------------
             From  Orders.dbo.Orderitem OI with (nolock)                       
             inner join
                   Orders.dbo.[Order]           O    with (nolock) 
             on    OI.OrderIdSeq  = O.Orderidseq 
             and   O.AccountIDSeq = coalesce(@IPVC_AccountID,O.AccountIDSeq)             
             and   coalesce(O.QuoteIDSeq,'')   = coalesce(@IPVC_QuoteID,coalesce(O.QuoteIDSeq,'')) 
             and   OI.StatusCode = coalesce(@IPVC_StatusType,OI.StatusCode)              
             and        ( (@IPVC_OptionSelected ='0')
                                    or
                          ((@IPVC_OptionSelected ='1') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) = 
                                    convert(datetime,convert(varchar(20),GETDATE(),101))
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='2') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(week,-1,GETDATE()),101))  
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='3') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(m,-1,GETDATE()),101))  
                                   )
                          )
                        )                       
             inner join   Orders.dbo.[OrderStatusType] OST  with (nolock) 
             on           O.StatusCode   = OST.Code                         
             inner  join
                       Customers.dbo.Company C with (nolock)
             on        C.IDSeq              =O.CompanyIDSeq  
             and       C.IDSeq = coalesce(@IPVC_CompanyID,C.IDSeq) 
             left outer join
                       Customers.dbo.Property P    with (nolock) 
             on        P.IDSeq              = O.PropertyIDSeq
             and       P.PMCIDSeq           = O.CompanyIDSeq             
             left outer join
                       #TEMP_InvoiceDates  T with (nolock)
             on        O.Orderidseq        = T.Orderidseq
             and       O.AccountIdSeq      = T.AccountIdSeq   
      where OI.Productcode in (select PROD.Code from products.dbo.product PROD with (nolock)
                                where  PROD.[DisplayName] like '%'+ @IPVC_ProductName +'%'
                               )                    
          ----------------------------------------------------------
      group by O.OrderIDSeq,O.AccountIdSeq,O.CompanyIdseq,O.Propertyidseq
          ) tableinner
       ---------------------------------------------------------- 
       WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
       SELECT  tablefinal.RowNumber,
               tablefinal.[ID]                     as [ID],
               tablefinal.accounttypecode          as accounttypecode,
	       tablefinal.CompanyName              as CompanyName,
               tablefinal.CompanyIDSeq             as CompanyIDSeq,
               tablefinal.AccountName              as AccountName,
               tablefinal.StatusName               as StatusName,
	       tablefinal.AccountIDSeq             as AccountIDSeq, 
	       tablefinal.CreatedDate              as CreatedDate,
	       tablefinal.Period                   as Period,
     	       tablefinal.LastInvoice              as LastInvoice                  
      from     tablefinal;
  end
  else if (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
           (select 
             ---------------------------------------------------------- 
             O.[OrderIDSeq]                           as [ID],             
             Max(TA.CompanyName)                      as CompanyName,  
             Max(TA.accounttypecode)                  as accounttypecode,
             O.CompanyIDSeq                           as CompanyIDSeq,
             coalesce(O.PropertyIDSeq,'0')            as PropertyIDSeq,
             Max(TA.AccountName)                      as AccountName,
             Max(OST.[Name])                          as StatusName, 
             O.AccountIDSeq                           as AccountIDSeq,
             Convert(varchar(10),Max(O.CreatedDate),101)   as CreatedDate,
             'N/A'                                         as Period, 
             coalesce(Max(T.LastInvoiceDate),'N/A')        as LastInvoice,
                    row_number() over(order by O.OrderIDSeq desc                                          
                                    ) as RowNumber
             ----------------------------------------------------------
             From  Orders.dbo.Orderitem OI with (nolock)              
             inner join
                   Orders.dbo.[Order]           O    with (nolock) 
             on    OI.OrderIdSeq  = O.Orderidseq                          
             and   coalesce(O.QuoteIDSeq,'')   = coalesce(@IPVC_QuoteID,coalesce(O.QuoteIDSeq,''))
             and   OI.StatusCode = coalesce(@IPVC_StatusType,OI.StatusCode)
             and        ( (@IPVC_OptionSelected ='0')
                                    or
                          ((@IPVC_OptionSelected ='1') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) = 
                                    convert(datetime,convert(varchar(20),GETDATE(),101))
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='2') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(week,-1,GETDATE()),101))  
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='3') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(m,-1,GETDATE()),101))  
                                   )
                          )
                        )                       
             inner join   Orders.dbo.[OrderStatusType] OST  with (nolock) 
             on           O.StatusCode   = OST.Code                         
             inner  join
                       #TEMP_Account TA with (nolock)
             on     O.AccountIDseq = TA.AccountIDSeq
             and    TA.AccountIDSeq = coalesce(@IPVC_AccountID,TA.AccountIDSeq)
             and    TA.CompanyIDSeq = coalesce(@IPVC_CompanyID,TA.CompanyIDSeq)
             left outer join
                       #TEMP_InvoiceDates  T with (nolock)
             on        O.Orderidseq        = T.Orderidseq
             and       O.AccountIdSeq      = T.AccountIdSeq         
        group by O.OrderIDSeq,O.AccountIdSeq,O.CompanyIdseq,O.Propertyidseq        
        ----------------------------------------------------------      
       ) tableinner
       ---------------------------------------------------------- 
       WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
       SELECT  tablefinal.RowNumber,
               tablefinal.[ID]                     as [ID],
               tablefinal.accounttypecode          as accounttypecode,
	       tablefinal.CompanyName              as CompanyName,
               tablefinal.CompanyIDSeq             as CompanyIDSeq,
               tablefinal.AccountName              as AccountName,
               tablefinal.StatusName               as StatusName,
	       tablefinal.AccountIDSeq             as AccountIDSeq, 
	       tablefinal.CreatedDate              as CreatedDate,
	       tablefinal.Period                   as Period,
     	       tablefinal.LastInvoice              as LastInvoice                  
      from     tablefinal;
      ---------------------------
      drop table #TEMP_Account;
      --------------------------- 
  end 
  else if (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM         
          (select 
             ---------------------------------------------------------- 
             O.[OrderIDSeq]                           as [ID],             
             Max(TA.CompanyName)                      as CompanyName,  
             Max(TA.accounttypecode)                  as accounttypecode,
             O.CompanyIDSeq                           as CompanyIDSeq,
             coalesce(O.PropertyIDSeq,'0')            as PropertyIDSeq,
             Max(TA.AccountName)                      as AccountName,
             Max(OST.[Name])                          as StatusName, 
             O.AccountIDSeq                           as AccountIDSeq,
             Convert(varchar(10),Max(O.CreatedDate),101)   as CreatedDate,
             'N/A'                                         as Period, 
             coalesce(Max(T.LastInvoiceDate),'N/A')        as LastInvoice,
                    row_number() over(order by O.OrderIDSeq desc                                          
                                    ) as RowNumber
             ----------------------------------------------------------
             From  Orders.dbo.Orderitem OI with (nolock)              
             inner join
                   Orders.dbo.[Order]           O    with (nolock) 
             on    OI.OrderIdSeq  = O.Orderidseq             
             and   coalesce(O.QuoteIDSeq,'')   = coalesce(@IPVC_QuoteID,coalesce(O.QuoteIDSeq,''))
             and   OI.StatusCode = coalesce(@IPVC_StatusType,OI.StatusCode)
             and        ( (@IPVC_OptionSelected ='0')
                                    or
                          ((@IPVC_OptionSelected ='1') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) = 
                                    convert(datetime,convert(varchar(20),GETDATE(),101))
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='2') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(week,-1,GETDATE()),101))  
                                   )
                          )
                                    or
                          ((@IPVC_OptionSelected ='3') 
                               and (
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) <=
                                    convert(datetime,convert(varchar(20),GETDATE(),101))                                     
                                    and
                                    convert(datetime,convert(varchar(20),O.CreatedDate,101)) >=
                                    convert(datetime,convert(varchar(20),DATEADD(m,-1,GETDATE()),101))  
                                   )
                          )
                        )                       
             inner join   Orders.dbo.[OrderStatusType] OST  with (nolock) 
             on           O.StatusCode   = OST.Code                         
             inner  join
                       #TEMP_Account TA with (nolock)
             on        O.AccountIDseq = TA.AccountIDSeq 
             and      TA.AccountIDSeq = coalesce(@IPVC_AccountID,TA.AccountIDSeq)
             and      TA.CompanyIDSeq = coalesce(@IPVC_CompanyID,TA.CompanyIDSeq)
             left outer join
                       #TEMP_InvoiceDates  T with (nolock)
             on        O.Orderidseq        = T.Orderidseq
             and       O.AccountIdSeq      = T.AccountIdSeq 
        where OI.Productcode in (select PROD.Code from products.dbo.product PROD with (nolock)
                                 where  PROD.[DisplayName] like '%'+ @IPVC_ProductName +'%'
                                )        
        group by O.OrderIDSeq,O.AccountIdSeq,O.CompanyIdseq,O.Propertyidseq            
       ) tableinner
       ---------------------------------------------------------- 
       WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
       SELECT  tablefinal.RowNumber,
               tablefinal.[ID]                     as [ID],
               tablefinal.accounttypecode          as accounttypecode,
	       tablefinal.CompanyName              as CompanyName,
               tablefinal.CompanyIDSeq             as CompanyIDSeq,
               tablefinal.AccountName              as AccountName,
               tablefinal.StatusName               as StatusName,
	       tablefinal.AccountIDSeq             as AccountIDSeq, 
	       tablefinal.CreatedDate              as CreatedDate,
	       tablefinal.Period                   as Period,
     	       tablefinal.LastInvoice              as LastInvoice                  
      from     tablefinal;
      ---------------------------
      drop table #TEMP_Account;
      ---------------------------
  end 
  ----------------------------------------------------------------------------
  --Final cleanup
  drop table #TEMP_InvoiceDates;  
  ----------------------------------------------------------------------------
END---Main End

GO
