SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PropertyListSelectCount
-- Description     : This procedure gets the list of Properties 
--                   for the specific Customer.
--
-- Input Parameters: 
--                   1. @IPVC_CompanyID     varchar(11),
--                   2. @IPVC_PropertyID    varchar(11),
--                   3. @IPVC_AccountID     varchar(20),
--                   4. @IPVC_PropertyName  varchar(100),
--                   5. @IPVC_City          varchar(70),
--                   6. @IPVC_State         varchar(2),
--                   7. @IPVC_Zip           varchar(10)
-- 
-- OUTPUT          : RecordSet of Count
--
-- Code Example    : Exec uspCUSTOMERS_PropertyListSelectCount 
--                                                          @IPVC_CompanyID     = '',
--                                                          @IPVC_PropertyID    = '',
--                                                          @IPVC_AccountID     = '',
--                                                          @IPVC_PropertyName  = '',
--                                                          @IPVC_City          = '',
--                                                          @IPVC_State         = '',
--                                                          @IPVC_Zip           = ''
-- 
-- 
-- Revision History:
-- Author          : TMN.
-- 12/20/2006      : Changed by STA. Implemented Search functionality.
-- 12/22/2006      : Modified by STA. Implemented Search functionality to search for properties 
--                   that does not have an account also.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyListSelectCount]
                                                         (@IPVC_CompanyID     varchar(50),
                                                          @IPVC_PropertyID    varchar(50),
                                                          @IPVC_AccountID     varchar(20),
                                                          @IPVC_PropertyName  varchar(100),
                                                          @IPVC_City          varchar(70),
                                                          @IPVC_State         varchar(2),
                                                          @IPVC_Zip           varchar(10),
                                                          @IPVC_Statustypecode varchar(50) = '', --- Default is '' which is ALL. 
                                                           @IPVC_Country      varchar(20) =''                              --- Else it Should be 'ACTIV' or 'INACT' only
														
                                                         ) --WITH RECOMPILE                                                          
AS
BEGIN        
  set nocount on;  
  ----------------------------------------------------------------
  set @IPVC_CompanyID  = nullif(ltrim(rtrim(@IPVC_CompanyID)),'');
  set @IPVC_PropertyID = nullif(ltrim(rtrim(@IPVC_PropertyID)),'');
  set @IPVC_AccountID  = nullif(ltrim(rtrim(@IPVC_AccountID)),'');
  set @IPVC_Statustypecode = nullif(ltrim(rtrim(@IPVC_Statustypecode)),'');
  ----------------------------------------------------------------
  SET ROWCOUNT 0;
  -------******************************************************************************--------
    WITH tablecountfinal AS 
    ----------------------------------------------------------------------------  
       (SELECT count(tableinner.[ID])   as [Count]
        FROM
         ----------------------------------------------------------------------------
         (select  source.*
          from
          (select P.IDSeq                             as ID,
                  coalesce(ACCT.IDSeq,'')             as AccountID, 
                  coalesce(ADDR.City,'')              as City, 
                  coalesce(ADDR.State,'')             as State, 
                  coalesce(ADDR.Zip,'')               as Zip,
				  coalesce(ADDR.CountryCode,'')       as CountryCode
           from   CUSTOMERS.dbo.Property P    with (nolock)
           inner join
                  CUSTOMERS.dbo.StatusType ST with (nolock)
           on     P.StatusTypeCode = ST.Code
           and    ST.Code          = coalesce(@IPVC_Statustypecode,ST.Code)
           and    P.PMCIDSeq       = @IPVC_CompanyID           
           and    P.IDSeq          = coalesce(@IPVC_PropertyID,P.IDSeq)
           and    P.[Name]   like '%' + @IPVC_PropertyName  + '%'
           left outer join 
                  CUSTOMERS.dbo.Address ADDR with (nolock)
           on     ADDR.CompanyIDSeq    = P.PMCIDSeq
           and    ADDR.CompanyIDSeq    = @IPVC_CompanyID           
           and    ADDR.PropertyIDSeq   = P.IDSeq          
           and    ADDR.AddressTypeCode = 'PRO'
           and    ADDR.City            like  '%' + @IPVC_City  + '%' 
           and    ADDR.State           like  '%' + @IPVC_State + '%' 
           and    ADDR.Zip             like  '%' + @IPVC_Zip   + '%' 
		   and    ADDR.CountryCode     like  '%' + @IPVC_Country   + '%'  
           left outer join
                  (select Max(XACCT.IDSEQ) as IDSEQ,XACCT.CompanyIDSeq,XACCT.PropertyIDSeq,XACCT.Accounttypecode
                   from   CUSTOMERS.dbo.Account XACCT with (nolock)
                   where  XACCT.CompanyIDSeq = @IPVC_CompanyID
                   and    XACCT.Accounttypecode = 'APROP'
                   and    XACCT.IDSEQ = coalesce(@IPVC_AccountID,XACCT.IDSEQ) 
                   and    XACCT.PropertyIDSeq = coalesce(@IPVC_PropertyID,XACCT.PropertyIDSeq) 
                   group by XACCT.CompanyIDSeq,XACCT.PropertyIDSeq,XACCT.Accounttypecode
                   ) ACCT
           on     ACCT.CompanyIDSeq = @IPVC_CompanyID
           and    ACCT.PropertyIDSeq= P.IDSeq           
           and    ACCT.Accounttypecode = 'APROP'
           and    ACCT.IDSEQ           = coalesce(@IPVC_AccountID,ACCT.IDSEQ)
          ) source
          where source.City         like  '%' + @IPVC_City  + '%' 
           and  source.State        like  '%' + @IPVC_State + '%' 
           and  source.Zip          like  '%' + @IPVC_Zip   + '%' 
			and    source.CountryCode  like  '%' + @IPVC_Country   + '%'  
           and  source.AccountID    = coalesce(@IPVC_AccountID,source.AccountID) 
          -----------------------------------------------------------------------------------
         )tableinner          
    )
    SELECT  tablecountfinal.[Count] 
    FROM    tablecountfinal
    -------******************************************************************************--------
END
GO
