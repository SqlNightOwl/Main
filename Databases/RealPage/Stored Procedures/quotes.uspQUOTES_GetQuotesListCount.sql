SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuotesListCount
-- Description     : This procedure gets the Count of Quotes available.
--
-- Input Parameters: @IPVC_CustomerID         varchar(20) = null,
--                   @IPVC_CustomerName       varchar(200) = null,
--                   @IPVC_QuoteStatus        varchar(20) = null,
--                   @IPVC_QuoteExpiresBy     varchar(20) = null,
--                   @IPVC_CreatedDate        varchar(12),
--                   @IPVC_SalesAgentIDSeq    varchar(255),
--                   @IPVC_ModifiedByUser     varchar(255),                  
--                   @IPVC_QuoteTypeCode      varchar(20)='',
--				     @IPVC_CountryCode        varchar(20)=''       
-- 
-- OUTPUT          : A recordSet of QuoteID, CustomerID, CustomerName, 
--                   Status, ILF, Access, ExpiresOn, RowNumber
--
-- Code Example    : Exec QUOTES.[dbo].[uspQUOTES_GetQuotesListCount]
--                                                               @IPVC_CustomerID         = '',
--                                                               @IPVC_CustomerName       = '',
--                                                               @IPVC_QuoteStatus        = '',
--																 @IPVC_CreatedDate        = '',
--                                                               @IPVC_QuoteExpiresBy     = '',
--                                                               @IPVC_SalesAgentIDSeq    = '', 
--                                                               @IPVC_ModifiedByUser     = '',
--																 @IPVC_QuoteTypeCode      = '',
--																 @IPVC_CountryCode        = ''  
-- Revision History:
-- Author          : RealPage
--                 : Stored Procedure Created.
-- Mahaboob        : 10/17/2011 - TFS #1151 - CountryCode has been added in the Search criteria.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuotesListCount]
                 (
                   
                   @IPVC_CustomerID         varchar(11),
                   @IPVC_CustomerName       varchar(70),
                   @IPVC_QuoteStatus        varchar(20),
                   @IPVC_QuoteExpiresBy     varchar(20),
                   @IPVC_CreatedDate        varchar(12),
                   @IPVC_SalesAgentIDSeq    varchar(255),
                   @IPVC_ModifiedByUser     varchar(255),                  
                   @IPVC_QuoteTypeCode      varchar(20)='',
				   @IPVC_CountryCode        varchar(20)=''        
                 )  ---WITH RECOMPILE
AS
BEGIN--->Main Begin
  set nocount on;  
  --------------------------------------
  declare @LN_CHECKSUM  numeric(30,0)
  ---------------------------------------
  select @LN_CHECKSUM = checksum(coalesce(@IPVC_CustomerID,''),
                                 coalesce(@IPVC_CustomerName,''),
                                 coalesce(@IPVC_QuoteExpiresBy,''),
                                 coalesce(@IPVC_CreatedDate,''),
                                 coalesce(@IPVC_SalesAgentIDSeq,''),
                                 coalesce(@IPVC_ModifiedByUser,''),
								 coalesce(@IPVC_CountryCode,'')
                                );
  ---------------------------------------
  select @IPVC_CustomerID = nullif(@IPVC_CustomerID,''),
         @IPVC_QuoteStatus= nullif(@IPVC_QuoteStatus,''),
         @IPVC_QuoteExpiresBy = nullif(@IPVC_QuoteExpiresBy,''),
         @IPVC_CreatedDate    = nullif(@IPVC_CreatedDate,''),
         @IPVC_SalesAgentIDSeq=nullif(coalesce(@IPVC_SalesAgentIDSeq,''),''),
         @IPVC_ModifiedByUser = nullif(@IPVC_ModifiedByUser,''),
         @IPVC_QuoteTypeCode  = nullif(@IPVC_QuoteTypeCode,''),
		 @IPVC_CountryCode    = nullif(@IPVC_CountryCode, '');
  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  if @LN_CHECKSUM = 0
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT count(tableinner.[ID])  as [Count]
        FROM
           ---------------------------------------------------------- 
          (select  *
           from
             ----------------------------------------------------------
            (select distinct            
                 Q.QuoteIDSeq as  [ID]
             FROM  Quotes.dbo.Quote Q With (nolock)
             Where Q.QuoteStatusCode = coalesce(@IPVC_QuoteStatus,Q.QuoteStatusCode)
             and   Q.QuoteTypeCode   = coalesce(@IPVC_QuoteTypeCode,Q.QuoteTypeCode)
             and EXISTS 
                      ( SELECT  TOP 1 1 
                        FROM    QUOTES.dbo.[Quoteitem] QI  with (nolock)
                        WHERE   QI.QuoteIDSeq = Q.QuoteIDSeq
                      )                                     
              ----------------------------------------------------------               
             ) source
           -------------------------------------------------------------------
           ) tableinner
          ---------------------------------------------------------------------
        )
        SELECT  tablefinal.[Count]    
        from    tablefinal 
  end
  else
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT count(tableinner.[ID])  as [Count]
        FROM
           ---------------------------------------------------------- 
          (select  *
           from
             ----------------------------------------------------------
            (select distinct            
                 Q.QuoteIDSeq as  [ID]
             FROM  Quotes.dbo.Quote Q With (nolock)
			 Where Q.QuoteStatusCode = coalesce(@IPVC_QuoteStatus,Q.QuoteStatusCode)
             and   Q.QuoteTypeCode   = coalesce(@IPVC_QuoteTypeCode,Q.QuoteTypeCode)            
             and   Q.CustomerIDSeq    = coalesce(@IPVC_CustomerID,Q.CustomerIDSeq)
             and   Q.CompanyName like '%' + @IPVC_CustomerName + '%'         
             and  coalesce(Q.CreatedByIDSeq,'0')  = coalesce(@IPVC_ModifiedByUser,coalesce(Q.CreatedByIDSeq,'0'))  
             and  convert(varchar(20),Q.ExpirationDate,101) = coalesce(@IPVC_QuoteExpiresBy,convert(varchar(20),Q.ExpirationDate,101))
             and  convert(varchar(20),Q.CreateDate,101) = coalesce(@IPVC_CreatedDate,convert(varchar(20),Q.CreateDate,101)) 
             and EXISTS 
                      ( SELECT  TOP 1 1 
                        FROM    QUOTES.dbo.[Quoteitem] QI  with (nolock)
                        WHERE   QI.QuoteIDSeq = Q.QuoteIDSeq
                      )            
             AND ((coalesce(@IPVC_SalesAgentIDSeq,0) = 0) 
                             OR 
                  EXISTS(select 1 from QuoteSaleAgent qsa with (nolock)
                         where SalesAgentIDSeq = @IPVC_SalesAgentIDSeq 
                         and   qsa.QuoteIDSeq = Q.QuoteIDSeq)
                 )
		     AND exists (select top 1 1
                 from   Customers.dbo.Address A with (nolock)
                 where  A.CompanyIDSeq      = coalesce(@IPVC_CustomerID,Q.CustomerIDSeq) 
                 and    A.CountryCode       = coalesce(@IPVC_CountryCode,A.CountryCode)
                 and    (A.AddressTypeCode = 'COM' or A.AddressTypeCode   = 'PRO') 
                 )            
              ----------------------------------------------------------               
             ) source
           -------------------------------------------------------------------
           ) tableinner
          ---------------------------------------------------------------------
        )
        SELECT  tablefinal.[Count]    
        from    tablefinal 
  end
END--->Main End

-- exec uspQUOTES_GetQuotesListCount '','','','','','','',@IPVC_QuoteTypeCode = 'NEWQ'
GO
