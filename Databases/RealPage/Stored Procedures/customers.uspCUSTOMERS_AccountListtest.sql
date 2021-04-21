SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_AccountListtest]
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
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AccountListtest  @IPI_PageNumber  =1,
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
--
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_AccountListtest] 
                                                  (@IPI_PageNumber       int, 
												                           @IPI_RowsPerPage      int,
                                                   @IPVC_AccountIDSeq    varchar(50),
                                                   @IPVC_CompanyIDSeq    varchar(50),
												                           @IPVC_CompanyName     varchar(100), 
												                           @IPVC_PropertyName    varchar(100), 
												                           @IPVC_City            varchar(100), 
												                           @IPVC_State           varchar(100),
												                           @IPVC_ZipCode         varchar(10),
												                           @IPVC_AccountType     varchar(10),
                                                   @IPB_PropertyIncluded bit = 0,
                                                   @IPVC_ProductName     varchar(100),
												                           @IPVC_Address         varchar(200)	
													)
AS
BEGIN      
  set nocount on;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  WITH tablefinal AS 
       (select tableinner.*
        from
          (select  row_number() over(order by source.CompanyIDSeq) as RowNumber,
                   source.*
           from
            (select  
                convert(varchar(50),c.IDSeq)        as CompanyIDSeq
                from customers.dbo.company C with (nolock)
            ) source
          ) tableinner
       where tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       and   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       ) 
       select  tablefinal.RowNumber,
               tablefinal.CompanyIDSeq as CompanyIDSeq
      from     tablefinal

 

  /*
  ----------------------------------------------------------------
  ---Get Total count for the search criteria
  ---This will go as a separate proc called 
  ---  uspCUSTOMERS_AccountListtestCount with the same parameters as uspCUSTOMERS_AccountListtest
  ----------------------------------------------------------------
  select sum(TBL.rcount) as totalcount
  from (select  
                count(c.IDSeq)        as rcount                
            from    Company     c with (nolock)              
            inner join  Address a with (nolock)
            on        a.CompanyIDSeq = c.IDSeq 
            and       a.PropertyIDSeq is null
            and       a.AddressTypeCode   =     'COM' 
            and       c.Name              like '%'+ @IPVC_CompanyName   + '%'
            and       c.IDSeq             like '%'+ @IPVC_CompanyIDSeq  + '%'            
            and       a.City              like '%'+ @IPVC_City          + '%'
            and       a.State             like '%'+ @IPVC_State         + '%' 
            and       a.Zip               like '%'+ @IPVC_ZipCode       + '%'                                    
            inner join  Account acct with (nolock)
            on        acct.CompanyIDSeq = c.IDSeq
            and       acct.PropertyIDSeq is null
            and       acct.IDSeq          like '%'+ @IPVC_AccountIDSeq  + '%'                                          
            ----------------------------------------------------------
            union
            ----------------------------------------------------------
            select    count(p.PMCIDSeq)  as rcount
            from    Property p  with (nolock)            
            inner join  Company c  with (nolock)            
            on        p.PMCIDSeq  = c.IDSeq  and (@IPB_PropertyIncluded = 1)
            and       p.Name      like '%'+ @IPVC_PropertyName  + '%'
            and       c.Name      like '%'+ @IPVC_CompanyName   + '%'
            and       c.IDSeq     like '%'+ @IPVC_CompanyIDSeq  + '%'
            inner join  Address a  with (nolock)
            on        a.AddressTypeCode   = 'PRO' 
            and       a.CompanyIDSeq      = c.IDSeq
            and       a.PropertyIDSeq     = p.IDSeq
            and       a.City      like '%'+ @IPVC_City          + '%'
            and       a.State     like '%'+ @IPVC_State         + '%' 
            and       a.Zip       like '%'+ @IPVC_ZipCode       + '%'
            inner join  Account acct  with (nolock)
            on        acct.CompanyIDSeq = c.IDSeq
            and       acct.PropertyIDSeq = p.IDSeq
            and       acct.IDSeq  like '%'+ @IPVC_AccountIDSeq  + '%'                  
            ----------------------------------------------------------
        ) AS TBL
  */
END

--Exec CUSTOMERS.DBO.uspCUSTOMERS_AccountListtest 1,20,'','','','','','','','',1,'','Premium Support'


GO
