SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_InvoiceListCount
-- Description     : This procedure gets Count of Invoices pertaining to passed parameters.
--                        
-- Input Parameters: @IPI_PageNumber    as int 
--                   @IPI_RowsPerPage      as int 
--                   @IPVC_CompanyIDSeq    as varchar
--                   @IPVC_EpicorID        as varchar
--                   @IPVC_AccountIDSeq    as varchar
--                   @IPVC_PropertyName    as varchar                                   
--                   @IPVC_City            as varchar
--					 @IPVC_State           as varchar
--					 @IPVC_ZipCode         as varchar
--					 @IPI_PropertyIncluded as bit
--                   @IPVC_ProductName     as varchar
--	                 @IPVC_Address		   as varchar
--				     @IPD_StartDate	       as datetime
--				     @IPD_EndDate		   as datetime
--					 @IPI_PrintFlag        as varchar
--				     @IPVC_CountryCode     as varchar  
-- 
-- OUTPUT          : RecordSet contains "Count" of Invoices pertaining to passed parameters. 
--
-- Code Example    : Exec INVOICES.DBO.uspINVOICES_InvoiceListCount @IPVC_CompanyIDSeq    =   '',
--																	@IPVC_EpicorID        =   '',
--																	@IPVC_AccountIDSeq    =   '',
--																	@IPVC_PropertyName    =   '',                                   
--																	@IPVC_City            =   '',
--																	@IPVC_State           =   '',
--																	@IPVC_ZipCode         =   '',
--																	@IPI_PropertyIncluded =   1,
--																	@IPVC_ProductName     =   '',
--																	@IPVC_Address		  =   '',
--																	@IPD_StartDate	      =   '',
--																	@IPD_EndDate		  =   '',
--																	@IPI_PrintFlag        =   '',
--																	@IPVC_CountryCode     =   ''
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 11/30/2006      : Stored Procedure Created.
-- 10/18/2011      : Mahaboob - TFS #1151 - CountryCode has been added in the Search criteria.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceListCount] (                      
													   @IPVC_CompanyIDSeq    varchar(50) ='',                                                 
                                                       @IPVC_EpicorID        varchar(50) ='', 
                                                       @IPVC_AccountIDSeq    varchar(20) ='',
                                                       @IPVC_PropertyName    varchar(100)='',                                   
                                                       @IPVC_City            varchar(100)='', 
                                                       @IPVC_State           varchar(100)='',
                                                       @IPVC_ZipCode         varchar(10) ='',
                                                       @IPI_PropertyIncluded bit,
                                                       @IPVC_ProductName     varchar(100)='',
	       	 										   @IPVC_Address	     varchar(200)='',
													   @IPD_StartDate	     datetime,
													   @IPD_EndDate		     datetime,
													   @IPI_PrintFlag        varchar(5)='',
													   @IPVC_CountryCode     varchar(20)=''
                                                      )   WITH RECOMPILE
AS
BEGIN-- Main BEGIN starts at Col 01
  --Rest of the code starts at Col 03
  declare @customerid   varchar(50);
  select  @customerid = (select top 1 companyidseq from invoice I where ((I.accountidseq = @IPVC_AccountIDSeq)
														 or      (I.EpicorCustomerCode  = @IPVC_EpicorID ))
														 AND   I.AccountTypeCode = 'AHOFF')
  IF ((@IPVC_PropertyName = '') and (@customerid is null) and (@IPVC_CompanyIDSeq is null)  and (@IPI_PropertyIncluded = 1))
  BEGIN
  set @IPI_PropertyIncluded = 1
  END       
  set @customerid     = nullif(@customerid,'');  

  set nocount on;  
  set @IPVC_CompanyIDSeq = nullif(@IPVC_CompanyIDSeq,'');  
  set @IPVC_EpicorID     = nullif(@IPVC_EpicorID,'');  
  set @IPVC_AccountIDSeq = nullif(@IPVC_AccountIDSeq,'');  
  set @IPI_PrintFlag     = nullif(@IPI_PrintFlag,'');
  set @customerid        = nullif(@customerid,''); 
  
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT count(tableinner.[ID])                as [Count]
        FROM
           ---------------------------------------------------------- 
          (select  *
           from
             ---------------------------------------------------------- 
             (SELECT I.InvoiceIDSeq       as [ID]
              FROM        Invoices.dbo.Invoice I with (nolock)
              WHERE I.CompanyIDSeq  = coalesce(@IPVC_CompanyIDSeq,I.CompanyIDSeq)  
              and  ((I.AccountIDSeq  = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq))
              or  ((@IPI_PropertyIncluded = 1) AND I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) AND (@customerid is not null)))
              and (((I.CompanyName  LIKE '%' + @IPVC_PropertyName + '%') and @IPI_PropertyIncluded = 0 AND (PropertyIDSeq is null))    
              OR  (((I.CompanyName  LIKE '%' + @IPVC_PropertyName + '%') or (I.PropertyName LIKE '%' + @IPVC_PropertyName + '%')) and (@IPI_PropertyIncluded = 1)))    
			  and (((I.EpicorCustomerCode   = coalesce(@IPVC_EpicorID,I.EpicorCustomerCode)))-- and @IPI_PropertyIncluded = 0 AND (PropertyIDSeq is null))    )
              or  ((@IPI_PropertyIncluded = 1) AND I.CompanyIDSeq  = coalesce(@customerid,I.CompanyIDSeq) AND (@customerid is not null)))
              AND   I.BillToCity          LIKE '%' + @IPVC_City         + '%'  
              AND   I.BillToState         LIKE '%' + @IPVC_State        + '%'  
              AND   I.BillToZip           LIKE '%' + @IPVC_ZipCode      + '%'  
			  AND   I.BillToCountryCode   LIKE '%' + @IPVC_CountryCode  + '%'
              AND   I.BillToAddressLine1  LIKE '%' + @IPVC_Address      + '%'                
              and ((@IPVC_ProductName = '') or   
                     EXISTS (select 1 from Invoices.dbo.InvoiceItem ii   with (nolock)  
                             inner join products.dbo.product        prod with (nolock)  
                             on    prod.Code = ii.productCode  
                             and   prod.PriceVersion = ii.PriceVersion  
                             and   prod.[Name] like '%'+ @IPVC_ProductName +'%'  
                             and   ii.InvoiceIDSeq = I.InvoiceIDSeq  
                             where ii.InvoiceIDSeq = I.InvoiceIDSeq  
                            )  
                  ) 
	     AND
                 ((@IPD_StartDate is not null and 
                    convert(varchar(12),I.InvoiceDate,101) >= @IPD_StartDate)
                      or @IPD_StartDate     = '')
			  AND
                 ((@IPD_EndDate is not null and 
                    convert(varchar(12),I.InvoiceDate,101) <= @IPD_EndDate)
                      or @IPD_EndDate     = '')  
	    AND I.PrintFlag  =  coalesce(@IPI_PrintFlag,I.PrintFlag)
            ----------------------------------------------------------
            )source
          -----------------------------------------------------------------
          )tableinner
         -------------------------------------------------------------------
         )
         SELECT  tablefinal.[Count]    
         from     tablefinal   	
END-->Main End
--exec [dbo].[uspINVOICES_InvoiceListCount] '','','','','','','',0,'OneSite Accounting-Consolidations'

GO
