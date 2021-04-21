SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_AccountList]
-- Description     : This procedure returns the accounts based on the parameters
-- Input Parameters: 	1. @IPI_PageNumber int 
--                  	2. @IPI_RowsPerPage int 
--                    3. @IPVC_CompanyIDSeq  varchar(11),
--                    4. @IPVC_CompanyName varchar(100) 
--                    5. @IPVC_PropertyName varchar(100)
--                    6. @IPVC_City varchar(100) 
--                    7. @IPVC_State varchar(100)
--                    8. @IPVC_ZipCode varchar(10)
-- 
-- OUTPUT          : RecordSet of ID,AccountName,City,State,Zip,AccountTypeCode,Units,PPU
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AccountList  @IPI_PageNumber  =1,
--                                                                @IPI_RowsPerPage =3,
--                                                                @IPVC_CompanyIDSeq = A0000001,
--                                                                @IPVC_CompanyName='',    
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
CREATE procedure [customers].[uspCUSTOMERS_AccountList] (
                                                   @IPI_PageNumber       int, 
												   @IPI_RowsPerPage      int,
                                                   -- @IPVC_AccountIDSeq    varchar(50) ='',
                                                   @IPVC_EpicorIDSeq     varchar(50) ='',
                                                   @IPVC_CompanyIDSeq    varchar(50) ='',
												   @IPVC_CompanyName     varchar(100)='', 
												   @IPVC_PropertyName    varchar(100)='', 
												   @IPVC_City            varchar(100)='', 
												   @IPVC_State           varchar(100)='',
												   @IPVC_ZipCode         varchar(10) ='',
												   @IPVC_AccountType     varchar(10) ='',
                                                   @IPB_PropertyIncluded bit         = 0,
                                                   @IPVC_ProductName     varchar(100)='',
						                           @IPVC_Address         varchar(200)='',
												   @IPB_ActiveFlag       varchar(5)='',
												   @IPVC_Country         varchar(100)=''
												   
						   )  --WITH RECOMPILE  -- THIS IS TO HANDLE CACHING AND LOCKING
AS
BEGIN      
  set nocount on;
  ---------------------------------------
  declare @customerid   varchar(50)
  declare @LN_CHECKSUM  numeric(30,0)
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
  IF ((@IPVC_PropertyName = '') and (@customerid is null) and (@IPVC_CompanyIDSeq is null) and (@IPVC_EpicorIDSeq is not null))
  BEGIN
  set @IPB_PropertyIncluded = 1
  END       
  set @customerid     = nullif(@customerid,'');  
  ----------------------------------------------------------------
  if (coalesce(@IPVC_ProductName,'') <> '')
  begin
    select O.AccountIDSeq as AccountID,identity(int,1,1) as sortseq
    into   #Temp_ProductsAccount
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
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  If (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.CompanyIDSeq) as RowNumber,
                   source.*
           from            
            (
             Select S.CompanyIDSeq,S.PropertyIDSeq,S.AccountName,S.CompanyName,
                    a.City,a.State,a.zip,
                    S.Units,S.PPU,S.AccountID,S.AccountTypeCode
             from 
             (select  
                c.IDSeq                             as CompanyIDSeq, 
                '0'                                 as PropertyIDSeq, 
                c.Name                              as AccountName, 
                c.Name                              as CompanyName,                
                0                                   as Units, 
                0                                   as PPU, 
                acct.IDSeq                          as AccountID, 
                'Home Office'                       as AccountTypeCode
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
                c.IDSeq                           as CompanyIDSeq, 
                p.IDSeq                           as PropertyIDSeq, 
                p.Name                            as AccountName, 
                c.Name                            as CompanyName,                      
                p.Units                           as Units,
                isnull(p.PPUPercentage,0)         as PPU, 
                acct.IDSeq                        as AccountID,
                'Property'                        as AccountTypeCode                
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
             inner join
                   Customers.dbo.Address a with (nolock)
             on    a.companyidseq                = S.companyidseq            
             and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
             and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')             
            ----------------------------------------------------------            
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.AccountID    as ID,
	       tablefinal.AccountName  as AccountName,
               tablefinal.CompanyName  as CompanyName,
               tablefinal.CompanyIDSeq as CompanyIDSeq,
               tablefinal.City         as City,
	       tablefinal.State        as State, 
	       tablefinal.Zip          as Zip,
	       tablefinal.AccountTypeCode   as AccountTypeCode,
     	       tablefinal.Units        as Units,
	       tablefinal.PPU          as PPU
      from     tablefinal;
  end 
  else if (@LN_CHECKSUM = 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.CompanyIDSeq) as RowNumber,
                   source.*
           from            
            (
             Select S.CompanyIDSeq,S.PropertyIDSeq,S.AccountName,S.CompanyName,
                    a.City,a.State,a.zip,
                    S.Units,S.PPU,S.AccountID,S.AccountTypeCode 
             from
             (select  
                c.IDSeq                             as CompanyIDSeq, 
                '0'                                 as PropertyIDSeq, 
                c.Name                              as AccountName, 
                c.Name                              as CompanyName,                
                0                                   as Units, 
                0                                   as PPU, 
                acct.IDSeq                          as AccountID, 
                'Home Office'                       as AccountTypeCode
              from Customers.dbo.Account acct with (nolock)
              inner join
                   Customers.dbo.Company c    with (nolock)
              on   acct.companyidseq = c.idseq 
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)              
             -- and  acct.idseq        = coalesce(@IPVC_AccountIDSeq,acct.idseq)               
              and (((isnull(acct.EpicorCustomerCode,'')   = coalesce(@IPVC_EpicorIDSeq,isnull(acct.EpicorCustomerCode,''))))
              or  ((@IPB_PropertyIncluded = 1) AND Acct.CompanyIDSeq  = coalesce(@customerid,acct.CompanyIDSeq) AND (@customerid is not null)))
			  AND ((@IPB_ActiveFlag='')or  (acct.ActiveFlag LIKE '%' + @IPB_ActiveFlag + '%'))	          
			  and  acct.accounttypecode = 'AHOFF'
              and  acct.AccountTypeCode = coalesce(@IPVC_AccountType,acct.AccountTypeCode)
              ----------------------------------------------------------
              union all
              ----------------------------------------------------------
              select 
                c.IDSeq                           as CompanyIDSeq, 
                p.IDSeq                           as PropertyIDSeq, 
                p.Name                            as AccountName, 
                c.Name                            as CompanyName,                      
                p.Units                           as Units,
                isnull(p.PPUPercentage,0)         as PPU, 
                acct.IDSeq                        as AccountID,
                'Property'                        as AccountTypeCode                
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
             inner join
                   Customers.dbo.Address a with (nolock)
             on    a.companyidseq                = S.companyidseq            
             and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
             and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')
             where S.AccountID in (select TPA.AccountID from  #Temp_ProductsAccount TPA with (nolock))                          
            ----------------------------------------------------------            
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.AccountID    as ID,
	       tablefinal.AccountName  as AccountName,
               tablefinal.CompanyName  as CompanyName,
               tablefinal.CompanyIDSeq as CompanyIDSeq,
               tablefinal.City         as City,
	       tablefinal.State        as State, 
	       tablefinal.Zip          as Zip,
	       tablefinal.AccountTypeCode   as AccountTypeCode,
     	       tablefinal.Units        as Units,
	       tablefinal.PPU          as PPU
      from     tablefinal;
      ---------------------------------
      drop table #Temp_ProductsAccount;
      ---------------------------------
  end
  else If (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') = '')
  begin
    WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.CompanyIDSeq) as RowNumber,
                   source.*
           from            
            (

             Select S.CompanyIDSeq,S.PropertyIDSeq,S.AccountName,S.CompanyName,
                    a.City,a.State,a.zip,
                    S.Units,S.PPU,S.AccountID,S.AccountTypeCode 
             from
             (select  
                c.IDSeq                             as CompanyIDSeq, 
                '0'                                 as PropertyIDSeq, 
                c.Name                              as AccountName, 
                c.Name                              as CompanyName,                
                0                                   as Units, 
                0                                   as PPU, 
                acct.IDSeq                          as AccountID, 
                'Home Office'                       as AccountTypeCode
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
                c.IDSeq                           as CompanyIDSeq, 
                p.IDSeq                           as PropertyIDSeq, 
                p.Name                            as AccountName, 
                c.Name                            as CompanyName,                      
                p.Units                           as Units,
                isnull(p.PPUPercentage,0)         as PPU, 
                acct.IDSeq                        as AccountID,
                'Property'                        as AccountTypeCode                
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
              and  p.Name             like '%'  + @IPVC_PropertyName  + '%'              
             ) S
             inner join
                   Customers.dbo.Address a with (nolock)
             on    a.companyidseq                = S.companyidseq            
             and   coalesce(a.propertyidseq,'0') = coalesce(S.propertyidseq,'0') 
             and  (a.AddressTypeCode   =  'PRO' or a.AddressTypeCode = 'COM')
             and  coalesce(a.City,'')              like '%'+ @IPVC_City          + '%'
             and  coalesce(a.State,'')             like '%'+ @IPVC_State         + '%' 
             and  coalesce(a.Zip,'')               like '%'+ @IPVC_ZipCode       + '%' 
			       and	((@IPVC_Country='' and 1=1) 
			        or 
				        (@IPVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@IPVC_Country,'')) 
             and  coalesce(a.AddressLine1,'')      like '%'+ @IPVC_Address       + '%'
             and  coalesce(S.AccountName,'') like '%' + @IPVC_PropertyName + '%'  
             where coalesce(S.AccountName,'') like '%' + @IPVC_PropertyName + '%'                               
             ----------------------------------------------------------
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.AccountID    as ID,
	       tablefinal.AccountName  as AccountName,
               tablefinal.CompanyName  as CompanyName,
               tablefinal.CompanyIDSeq as CompanyIDSeq,
               tablefinal.City         as City,
	       tablefinal.State        as State, 
	       tablefinal.Zip          as Zip,
	       tablefinal.AccountTypeCode   as AccountTypeCode,
     	       tablefinal.Units        as Units,
	       tablefinal.PPU          as PPU
      from     tablefinal; 
  end
  else If (@LN_CHECKSUM <> 0 and coalesce(@IPVC_ProductName,'') <> '')
  begin
    WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.CompanyIDSeq) as RowNumber,
                   source.*
           from            
            (

             Select S.CompanyIDSeq,S.PropertyIDSeq,S.AccountName,S.CompanyName,
                    a.City,a.State,a.zip,
                    S.Units,S.PPU,S.AccountID,S.AccountTypeCode 
             from
             (select  
                c.IDSeq                             as CompanyIDSeq, 
                '0'                                 as PropertyIDSeq, 
                c.Name                              as AccountName, 
                c.Name                              as CompanyName,                
                0                                   as Units, 
                0                                   as PPU, 
                acct.IDSeq                          as AccountID, 
                'Home Office'                       as AccountTypeCode
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
                c.IDSeq                           as CompanyIDSeq, 
                p.IDSeq                           as PropertyIDSeq, 
                p.Name                            as AccountName, 
                c.Name                            as CompanyName,                      
                p.Units                           as Units,
                isnull(p.PPUPercentage,0)         as PPU, 
                acct.IDSeq                        as AccountID,
                'Property'                        as AccountTypeCode                
              from  Customers.dbo.Account acct  with (nolock)
              inner join
                    Customers.dbo.Company c     with (nolock)
              on   (@IPB_PropertyIncluded = 1)
              and  acct.companyidseq    = c.idseq
              and  c.idseq           = coalesce(@IPVC_CompanyIDSeq,c.idseq)
              and  c.Name            like '%'  + @IPVC_CompanyName  + '%'
              and  acct.companyidseq = coalesce(@IPVC_CompanyIDSeq,acct.companyidseq)
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
             and  coalesce(a.City,'')              like '%'+ @IPVC_City          + '%'
             and  coalesce(a.State,'')             like '%'+ @IPVC_State         + '%' 
			      and	((@IPVC_Country='' and 1=1) 
			        or 
				        (@IPVC_Country<>'') AND  coalesce(a.CountryCode,'')	  =    coalesce(@IPVC_Country,''))  
             and  coalesce(a.Zip,'')               like '%'+ @IPVC_ZipCode       + '%' 
             and  coalesce(a.AddressLine1,'')      like '%'+ @IPVC_Address       + '%'    
             and  coalesce(S.AccountName,'') like '%' + @IPVC_PropertyName + '%'  
             where coalesce(S.AccountName,'') like '%' + @IPVC_PropertyName + '%'           
             and   S.AccountID in (select TPA.AccountID from  #Temp_ProductsAccount TPA with (nolock))              
             ----------------------------------------------------------
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.AccountID    as ID,
	       tablefinal.AccountName  as AccountName,
               tablefinal.CompanyName  as CompanyName,
               tablefinal.CompanyIDSeq as CompanyIDSeq,
               tablefinal.City         as City,
	       tablefinal.State        as State, 
	       tablefinal.Zip          as Zip,
	       tablefinal.AccountTypeCode   as AccountTypeCode,
     	       tablefinal.Units        as Units,
	       tablefinal.PPU          as PPU
      from     tablefinal;
      ---------------------------------
      drop table #Temp_ProductsAccount;
      ---------------------------------
  end  
END
GO
