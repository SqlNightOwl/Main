SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_AccountListCount]
-- Description     : This procedure returns the accounts based on the parameters
-- Input Parameters: 	@IPVC_CompanyIDSeq  varchar(11),
--                    @IPVC_CompanyName varchar(100) 
--                    @IPVC_PropertyName varchar(100)
--                    @IPVC_City varchar(100) 
--                    @IPVC_State varchar(100)
--                    @IPVC_ZipCode varchar(10)
-- 
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AccountListCount @IPVC_CompanyName='',    
--                                                                @IPVC_PropertyName='',   
--                                                                @IPVC_City='',    
--                                                                @IPVC_State='',    
--                                                                @IPVC_ZipCode=''    
-- 
-- 
-- Revision History:
-- Author          : ABCDEF 
-- 11/22/2006      : Stored Procedure Created.
-- 12/07/2006      : Modified by STA. The Account ID Sequence is included as a search criteria.
-- 12/12/2006      : Modified by STA. A boolean value to indicate whether the Property is included 
--                   or not Sequence is added as a search criteria.
-- 12/13/2006      : Modified by STA. The Company ID Sequence is included as a search criteria.
-- 05/17/2010      : Naval Kishore Modified to add Active Flag Filter Search, Defect #7750
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_AccountListCount] (
                                                        -- @IPVC_AccountIDSeq    varchar(50) ='',
                                                        @IPVC_EpicorIDSeq      varchar(50) ='',
					 									@IPVC_CompanyIDSeq    varchar(50) ='',
														@IPVC_CompanyName     varchar(100)='', 
														@IPVC_PropertyName    varchar(100)='', 
														@IPVC_City            varchar(100)='', 
														@IPVC_State           varchar(100)='',
														@IPVC_ZipCode         varchar(10) ='',
														@IPVC_AccountType     varchar(10) ='',
														@IPB_PropertyIncluded bit         = 0,
                                                        @IPVC_ProductName     varchar(100)='',
			 											@IPVC_Address	      varchar(200)='',
														@IPB_ActiveFlag       varchar(5)='',
														@IPVC_Country		 Varchar(100)=''
						        ) ---WITH RECOMPILE  -- THIS IS TO HANDLE CACHING AND LOCKING
AS
BEGIN      
  set nocount on;
  ---------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  declare @customerid   varchar(50)
  ---------------------------------------
  select @LN_CHECKSUM = checksum(coalesce(@IPVC_CompanyName,''),
                                 coalesce(@IPVC_PropertyName,''),
                                 coalesce(@IPVC_City,''),
                                 coalesce(@IPVC_State,''),
                                 coalesce(@IPVC_ZipCode,''),                                 
                                 coalesce(@IPVC_Address,''),
								                 coalesce(@IPB_ActiveFlag,''),
                                 coalesce(@IPVC_Country,'')
                                );

  select --@IPVC_AccountIDSeq = nullif(ltrim(rtrim(@IPVC_AccountIDSeq)),''),
         @IPVC_EpicorIDSeq = nullif(ltrim(rtrim(@IPVC_EpicorIDSeq)),''),
         @IPVC_CompanyIDSeq = nullif(ltrim(rtrim(@IPVC_CompanyIDSeq)),''),
         @IPVC_AccountType  = nullif(ltrim(rtrim(@IPVC_AccountType)),'');
  
  select  @customerid = (select top 1 companyidseq from account Act where ((Act.EpicorCustomerCode  = @IPVC_EpicorIDSeq ))
														 AND   Act.AccountTypeCode = 'AHOFF')

  IF ((@IPVC_PropertyName = '') and (@customerid is null) and (@IPVC_CompanyIDSeq is null) and (@IPVC_EpicorIDSeq is not null) )
  BEGIN
  set @IPB_PropertyIncluded = 1
  END       
  set @customerid     = nullif(@customerid,''); 
  ----------------------------------------------------------------
  if (coalesce(@IPVC_ProductName,'') <> '')
  begin
    select O.AccountIDSeq as AccountID,identity(int,1,1) as sortseq
    into   #Temp_ProductsAccounts
    from   Orders.dbo.[Order]      O  with (nolock)
    inner Join
           Orders.dbo.[OrderItem]  OI with (nolock)
    on     OI.Orderidseq = O.Orderidseq
    inner Join
           Products.dbo.Product    P  with (nolock)
    on     OI.ProductCode = P.Code
    and    OI.PriceVersion= P.PriceVersion
    and    P.DisplayName  like '%'+@IPVC_ProductName+'%'    
    group by  O.AccountIDSeq   
  end;  
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  If (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS        
          (select  count(source.[AccountID]) as [Count]                   
           from            
            (
             Select S.AccountID 
             from
             (select                  
                acct.IDSeq                          as AccountID
              from Customers.dbo.Account acct with (nolock)
              inner join
                   Customers.dbo.Company c    with (nolock)
              on   acct.companyidseq = c.idseq 
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))             
              and  acct.accounttypecode = 'AHOFF'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              ----------------------------------------------------------
              union all
              ----------------------------------------------------------
              select 
                acct.IDSeq                          as AccountID             
              from  Customers.dbo.Account acct  with (nolock)
              inner join
                    Customers.dbo.Company c     with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  acct.companyidseq    = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)                
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'APROP'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              inner join
                   Customers.dbo.Property p  with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  c.idseq            = p.pmcidseq
              and  acct.companyidseq  = p.pmcidseq              
              and  acct.propertyidseq = p.IDSeq          
             ) S                         
            ----------------------------------------------------------            
            ) source         
       ) 
       select  tablefinal.[Count]      as [Count]
      from     tablefinal;
  end 
  else if (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS        
          (select  count(source.[AccountID]) as [Count]                   
           from            
            (
             Select S.AccountID
             from
             (select                  
                acct.IDSeq                          as AccountID
              from Customers.dbo.Account acct with (nolock)
              inner join
                   Customers.dbo.Company c    with (nolock)
              on   acct.companyidseq = c.idseq    
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'AHOFF'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              ----------------------------------------------------------
              union all
              ----------------------------------------------------------
              select 
                acct.IDSeq                          as AccountID             
              from  Customers.dbo.Account acct  with (nolock)
              inner join
                    Customers.dbo.Company c     with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  acct.companyidseq    = c.idseq 
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)               
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'APROP'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              inner join
                   Customers.dbo.Property p  with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  c.idseq            = p.pmcidseq
              and  acct.companyidseq  = p.pmcidseq              
              and  acct.propertyidseq = p.IDSeq           
             ) S   
             where S.AccountID in (select TPA.AccountID from  #Temp_ProductsAccounts TPA with (nolock))                   
            ----------------------------------------------------------            
            ) source         
       ) 
       select  tablefinal.[Count]      as [Count]
       from    tablefinal;
      ---------------------------------
      drop table #Temp_ProductsAccounts;
      ---------------------------------
  end
  else If (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS 
        (select  count(source.[AccountID]) as [Count]    
         from            
            (
             Select S.AccountID,S.CompanyIDSeq,S.PropertyIDSeq
             from
             (select  
                acct.IDSeq                          as AccountID,
                c.IDSeq                             as CompanyIDSeq,
                '0'                                 as PropertyIDSeq,
                c.Name                              as AccountName 
              from Customers.dbo.Account acct with (nolock)
              inner join
                   Customers.dbo.Company c    with (nolock)
              on   acct.companyidseq = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)
              and  c.Name            like '%'  + @IPVC_CompanyName  + '%'              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'AHOFF'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              ----------------------------------------------------------
              union all
              ----------------------------------------------------------
              select 
                acct.IDSeq                          as AccountID,
                c.IDSeq                             as CompanyIDSeq,
                p.Idseq                             as PropertyIDSeq,
                p.Name                              as AccountName           
              from  Customers.dbo.Account acct  with (nolock)
              inner join
                    Customers.dbo.Company c     with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  acct.companyidseq    = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)
              and  c.Name            like '%'  + @IPVC_CompanyName  + '%'              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq) 
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'APROP'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              inner join
                   Customers.dbo.Property p  with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  c.idseq            = p.pmcidseq
              and  acct.companyidseq  = p.pmcidseq              
              and  acct.propertyidseq = p.IDSeq               
              and  p.Name            like '%'  + @IPVC_PropertyName  + '%'              
             ) S  
             inner join
                   Customers.dbo.Address a with (nolock)
             on    a.companyidseq                = S.companyidseq            
             and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
             and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')
             and  a.City              like '%'+ @IPVC_City          + '%'
             and  a.State             like '%'+ @IPVC_State         + '%' 
			 and	((@IPVC_Country='' and 1=1) 
			        or 
				        (@IPVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@IPVC_Country,'')) 
             and  a.Zip               like '%'+ @IPVC_ZipCode       + '%' 
             and  a.AddressLine1      like '%'+ @IPVC_Address       + '%' 
             and   S.AccountName like '%' + @IPVC_PropertyName + '%'  
             where S.AccountName like '%' + @IPVC_PropertyName + '%'                                            
             ----------------------------------------------------------
            ) source          
       ) 
       select  tablefinal.[Count]      as [Count]
       from    tablefinal;
  end
  else If (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS 
        (select  count(source.[AccountID]) as [Count]    
         from            
            (
             Select S.AccountID,S.CompanyIDSeq,S.PropertyIDSeq
             from
             (select  
                acct.IDSeq                          as AccountID,
                c.IDSeq                             as CompanyIDSeq,
                '0'                                 as PropertyIDSeq,
                c.Name                              as AccountName 
              from Customers.dbo.Account acct with (nolock)
              inner join
                   Customers.dbo.Company c    with (nolock)
              on   acct.companyidseq = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)
              and  c.Name            like '%'  + @IPVC_CompanyName  + '%'              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'AHOFF'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              ----------------------------------------------------------
              union all
              ----------------------------------------------------------
              select 
                acct.IDSeq                          as AccountID,
                c.IDSeq                             as CompanyIDSeq,
                p.Idseq                             as PropertyIDSeq,
                p.Name                              as AccountName          
              from  Customers.dbo.Account acct  with (nolock)
              inner join
                    Customers.dbo.Company c     with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  acct.companyidseq    = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)
              and  c.Name            like '%'  + @IPVC_CompanyName  + '%'              
              --and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq) 
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))
              and  acct.accounttypecode = 'APROP'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              inner join
                   Customers.dbo.Property p  with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  c.idseq            = p.pmcidseq
              and  acct.companyidseq  = p.pmcidseq              
              and  acct.propertyidseq = p.IDSeq               
              and  p.Name            like '%'  + @IPVC_PropertyName  + '%'              
             ) S   
             inner join
                   Customers.dbo.Address a with (nolock)
             on    a.companyidseq                = S.companyidseq            
             and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
             and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')
             and  a.City              like '%'+ @IPVC_City          + '%'
             and  a.State             like '%'+ @IPVC_State         + '%'
			  and	((@IPVC_Country='' and 1=1) 
			        or 
				        (@IPVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@IPVC_Country,''))   
             and  a.Zip               like '%'+ @IPVC_ZipCode       + '%' 
             and  a.AddressLine1      like '%'+ @IPVC_Address       + '%'   
             and   S.AccountName like '%' + @IPVC_PropertyName + '%'  
             where S.AccountName like '%' + @IPVC_PropertyName + '%'                  
             and   S.AccountID in (select TPA.AccountID from  #Temp_ProductsAccounts TPA with (nolock))                       
             ----------------------------------------------------------
            ) source          
       ) 
       select  tablefinal.[Count]      as [Count]
       from    tablefinal;
      ---------------------------------
      drop table #Temp_ProductsAccounts;
      ---------------------------------
  end  
END


--Exec Customers.dbo.uspCUSTOMERS_AccountListCount '', '', '', '', '', '', '', '', True,'',''
--Exec Customers.dbo.uspCUSTOMERS_AccountListCount '', '', '', 'monro', '', '', '', '', True,'',''
GO
