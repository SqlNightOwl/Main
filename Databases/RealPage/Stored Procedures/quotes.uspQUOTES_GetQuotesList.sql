SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuotesList
-- Description     : This procedure gets the list of Quotes available.
--
-- Input Parameters: @PageNumber              int,
--                   @RowsPerPage             int, 
--                   @IPVC_CustomerID         varchar(11),
--                   @IPVC_CustomerName       varchar(70),
--                   @IPVC_QuoteStatus        varchar(20),
--                   @IPVC_QuoteExpiresBy     varchar(20),
--                   @IPVC_CreatedDate        varchar(12),
--                   @IPVC_SalesAgentIDSeq    varchar(255),
--                   @IPVC_ModifiedByUser     varchar(255),
--					 @IPVC_QuoteTypeCode      varchar(20)='',
--				     @IPVC_CountryCode        varchar(20)=''  
-- 
-- OUTPUT          : A recordSet of QuoteID, CustomerID, CustomerName, 
--                   Status, ILF, Access, ExpiresOn, RowNumber
--
-- Code Example    : Exec QUOTES.[dbo].[uspQUOTES_GetQuotesList]
--                                                               @IPI_PageNumber          = 1,
--                                                               @IPI_RowsPerPage         = 20, 
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
-- Larry Wilson    : Add Prepaid to result set
-- Larry Wilson    : Also add [ExternalQuoteIIFlag] to result set (W/I-1315)
-- Mahaboob        : 10/17/2011 - TFS #1151 - CountryCode has been added in the Search criteria.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuotesList]
                 (
                   @IPI_PageNumber          int,
                   @IPI_RowsPerPage         int, 
                   @IPVC_CustomerID         varchar(11),
                   @IPVC_CustomerName       varchar(70),
                   @IPVC_QuoteStatus        varchar(20),
                   @IPVC_QuoteExpiresBy     varchar(20),
                   @IPVC_CreatedDate        varchar(12),
                   @IPVC_SalesAgentIDSeq    varchar(255),
                   @IPVC_ModifiedByUser     varchar(255),
                   @IPVC_QuoteTypeCode      varchar(20)='',
				   @IPVC_CountryCode        varchar(20)=''      
                 ) --WITH RECOMPILE 
AS
BEGIN-->Main Begin
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

  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  if @LN_CHECKSUM = 0
  begin
    WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
          (select  row_number() over(order by source.sortdate       desc,
                                              source.Status         desc,
                                              source.customerName   asc                                                                                           
                                    ) as RowNumber,
                   source.*
           from
             ---------------------------------------------------------- 
            (    
            SELECT distinct 
              Q.QuoteIDSeq                                  as quoteid,
              Q.CustomerIDSeq                               as customerid,
              Q.CompanyName                                 as customername,
              Q.Description                                 as Description,
              QS.Name                                       as Status,
              QT.Name                                       as QuoteType, 
              Quotes.DBO.fn_FormatCurrency
                (Q.ILFNetExtYearChargeAmount,1,2)           as ilf,
              Quotes.DBO.fn_FormatCurrency
                (Q.AccessNetExtYear1ChargeAmount,1,2)       as access,  
              convert(varchar(20),Q.ExpirationDate, 101)    as expireson,
              u.FirstName + ' ' + u.LastName                as modifiedBy,
              Coalesce(Q.ModifiedDate,Q.CreateDate)         as sortdate
			  ,Coalesce(Q.PrePaidFlag,0)					as PrePaidFlag
			  ,Coalesce(Q.ExternalQuoteIIFlag,0)			as ExternalQuoteIIFlag
            FROM  Quotes.dbo.Quote Q With (nolock)
            INNER JOIN 
                  Quotes.dbo.QuoteStatus QS With (nolock)
            ON    Q.QuoteStatusCode = QS.Code
            and   Q.QuoteStatusCode = coalesce(@IPVC_QuoteStatus,Q.QuoteStatusCode)
            and   Q.QuoteTypeCode   = coalesce(@IPVC_QuoteTypeCode,Q.QuoteTypeCode)
            and   QS.Code           = coalesce(@IPVC_QuoteStatus,QS.Code)
            inner Join
                  Quotes.dbo.QuoteType QT With (nolock) 
            on    Q.QuoteTypeCode = QT.Code    
            and   QT.Code           = coalesce(@IPVC_QuoteTypeCode,QT.Code)                  
            and EXISTS 
                      ( SELECT  TOP 1 1 
                        FROM    QUOTES.dbo.[Quoteitem] QI  with (nolock)
                        WHERE   QI.QuoteIDSeq = Q.QuoteIDSeq
                      )    
            LEFT OUTER JOIN 
                   [Security].dbo.[User] u with (nolock)
            on   coalesce(Q.modifiedByIDSeq,Q.CreatedByIDSeq) = u.IDSeq  
          )source
          -------------------------------------------------------------------------
        )tableinner
        WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
        AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
        SELECT  tablefinal.RowNumber,
                tablefinal.quoteid                  as quoteid,
                tablefinal.customerid               as customerid,
	        tablefinal.customername             as customername,
                tablefinal.Description              as Description,
                tablefinal.Status                   as Status,
                tablefinal.QuoteType                as QuoteType, 
                tablefinal.ilf                      as ilf,
                tablefinal.access                   as access,
	        tablefinal.expireson                as expireson, 
	        tablefinal.modifiedBy               as modifiedBy
			,tablefinal.PrePaidFlag				as PrePaidFlag
			,tablefinal.[ExternalQuoteIIFlag]	as ExternalQuoteIIFlag
        FROM    tablefinal  
  end
  else
  begin
      WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
          (select  row_number() over(order by source.sortdate       desc,
                                              source.Status         desc,
                                              source.customerName   asc                                                                                           
                                    ) as RowNumber,
                   source.*
           from
             ---------------------------------------------------------- 
            (    
            SELECT distinct 
              Q.QuoteIDSeq                                  as quoteid,
              Q.CustomerIDSeq                               as customerid,
              Q.CompanyName                                 as customername,
              Q.Description                                 as Description,
              QS.Name                                       as Status,
              QT.Name                                       as QuoteType, 
              Quotes.DBO.fn_FormatCurrency
                (Q.ILFNetExtYearChargeAmount,1,2)           as ilf,
              Quotes.DBO.fn_FormatCurrency
                (Q.AccessNetExtYear1ChargeAmount,1,2)       as access,  
              convert(varchar(20),Q.ExpirationDate, 101)    as expireson,
              u.FirstName + ' ' + u.LastName                as modifiedBy,
              Coalesce(Q.ModifiedDate,Q.CreateDate)         as sortdate
			  ,Coalesce(Q.PrePaidFlag,0)					as PrePaidFlag
			  ,Coalesce(Q.ExternalQuoteIIFlag,0)			as ExternalQuoteIIFlag
		    FROM  Quotes.dbo.Quote Q With (nolock)
            INNER JOIN 
                  Quotes.dbo.QuoteStatus QS With (nolock)
            ON    Q.QuoteStatusCode = QS.Code
            and   Q.QuoteStatusCode = coalesce(@IPVC_QuoteStatus,Q.QuoteStatusCode)
            and   QS.Code           = coalesce(@IPVC_QuoteStatus,QS.Code)       
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
            inner Join
                  Quotes.dbo.QuoteType QT With (nolock) 
            on    Q.QuoteTypeCode = QT.Code    
            and   QT.Code           = coalesce(@IPVC_QuoteTypeCode,QT.Code) 
			LEFT OUTER JOIN 
                   [Security].dbo.[User] u with (nolock)
            on   coalesce(Q.modifiedByIDSeq,Q.CreatedByIDSeq) = u.IDSeq
			where  exists (select top 1 1
                 from   Customers.dbo.Address A with (nolock)
                 where  A.CompanyIDSeq      = coalesce(@IPVC_CustomerID,Q.CustomerIDSeq) 
                 and    A.CountryCode       = coalesce(@IPVC_CountryCode,A.CountryCode)
                 and    (A.AddressTypeCode = 'COM' or A.AddressTypeCode   = 'PRO') 
                 )            
                 
          )source
          -------------------------------------------------------------------------
        )tableinner
        WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
        AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
       )
        
	    SELECT  tablefinal.RowNumber,
                tablefinal.quoteid                  as quoteid,
                tablefinal.customerid               as customerid,
	        tablefinal.customername             as customername,
                tablefinal.Description              as Description,
                tablefinal.Status                   as Status,
                tablefinal.QuoteType                as QuoteType,   
                tablefinal.ilf                      as ilf,
                tablefinal.access                   as access,
	        tablefinal.expireson                as expireson, 
	        tablefinal.modifiedBy               as modifiedBy
			,tablefinal.PrePaidFlag				as PrePaidFlag
			,tablefinal.ExternalQuoteIIFlag		as ExternalQuoteIIFlag
	     FROM    tablefinal 
		 print @LN_CHECKSUM
  end
 
END-->Main End

-- exec uspQUOTES_GetQuotesList 1,20,'','','','','','',''




GO
