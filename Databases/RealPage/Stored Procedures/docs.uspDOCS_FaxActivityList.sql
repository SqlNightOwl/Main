SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
Procedure  : uspDOCS_FaxActivityList

Purpose    :  Gets data from FaxActivity table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/29/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_FaxActivityList

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE PROCEDURE [docs].[uspDOCS_FaxActivityList]
(
  @IP_PageNumber int, 
  @IP_RowsPerPage int,
  @IP_CompanyName varchar(255),
  @IP_FaxTypeCode varchar (3),
  @IP_FaxStatusCode varchar (3),
  @IP_CreatedBy varchar(255),
  @IP_CreatedDate varchar(20)
 )
AS

  DECLARE @rowstoprocess bigint;

  SET @IP_CompanyName   = ISNULL(@IP_CompanyName, '');
  SET @IP_CreatedBy     = ISNULL(@IP_CreatedBy, '');
  SET @IP_CreatedDate   = ISNULL(@IP_CreatedDate, '');
  SET @IP_FaxTypeCode   = ISNULL(@IP_FaxTypeCode, '');
  SET @IP_FaxStatusCode = ISNULL(@IP_FaxStatusCode, '');
 
  IF @IP_FaxTypeCode = 'NUL'
  SET @IP_FaxTypeCode   = ''
 
  IF @IP_FaxStatusCode = 'NUL'
  SET @IP_FaxStatusCode   = ''

  SELECT @rowstoprocess = @IP_PageNumber * @IP_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  WITH Temp_List AS (
    SELECT  
      Count(*) OVER() as _TotalRows_, -- Adding this for Paging.  This will avoid multiple hits to table to get total count.
      ROW_NUMBER() OVER (ORDER BY FA.IDSeq)AS RowNumber,     
      FA.IDSeq,
      JobID,
      Cust.Name as CompanyName,
      Cust.IDSeq as CustomerIDSeq,
      PRP.Name  as PropertyName,
      FA.DocumentIDSeq,
      faxtype.Name as FaxTypeName,
      faxstatus.Name as FaxStatusName,
      FA.FaxTypeCode,
      FA.FaxStatusCode,
      FilePath,
      CASE WHEN PageCount is null THEN 0
      ELSE PageCount
      END                    AS PageCount, 
      FaxNumber,
      FaxRecipient,
      FA.CreatedDate,
      FA.CreatedBy,
      IsActive,
      JobStatus,
      FA.ErrorDescription
   
    From
                     FaxActivity FA
     left outer join Docs..Document Doc           ON   Doc.DocumentIDSeq = FA.DocumentIDSeq
     left outer join Customers..Company Cust      ON   Cust.IDSeq = Doc.CompanyIDSeq
     left outer join Customers..Property PRP      ON   PRP.IDSeq = Doc.PropertyIDSeq
     left outer join Docs..FaxStatus   faxstatus  ON   faxstatus.Code = FA.FaxStatusCode
     left outer join Docs..FaxType     faxtype    ON   faxtype.Code = FA.FaxTypeCode

    Where
          (((@IP_CreatedBy <> '') and (FA.CreatedBy like '%' + @IP_CreatedBy + '%'))  OR (@IP_CreatedBy =  ''))
      AND (((@IP_CompanyName <> '') and (Cust.Name like '%' + @IP_CompanyName + '%'))OR (@IP_CompanyName =  ''))
      AND (((@IP_CreatedDate <> '') and ((convert(varchar(12),FA.CreatedDate,101)) like '%' + @IP_CreatedDate + '%'))OR (@IP_CreatedDate =  ''))
      AND (((@IP_FaxTypeCode <> '') and (FA.FaxTypeCode like '%' + @IP_FaxTypeCode + '%'))OR (@IP_FaxTypeCode =  ''))
      AND (((@IP_FaxStatusCode <> '') and (FA.FaxStatusCode like '%' + @IP_FaxStatusCode + '%'))OR (@IP_FaxStatusCode =  ''))
          
    )
    Select  
      *
    From
      Temp_List
    WHERE 
      RowNumber > (@IP_PageNumber-1) * @IP_RowsPerPage
      and RowNumber <= (@IP_PageNumber)  * @IP_RowsPerPage
      

GO
