SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_ContractList

Purpose    :  Gets data from Contract table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_ContractList 1, 20

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_ContractList]
(
  @IP_PageNumber int = null,
  @IP_RowsPerPage int = null,
  @IP_IDSeq numeric (30, 0) = null,
  @IP_CompanyName varchar(100) = null,
  @IP_DocumentIDSeq varchar(30) = null,
  @IP_Status varchar(3) = null
)
AS
  DECLARE @TotalRows int;
  declare @rowstoprocess bigint;

  IF ( ISNULL(@IP_IDSeq, 0) = 0 )
    SET @IP_IDSeq = null;
    
  IF ( LTRIM(RTRIM(ISNULL(@IP_CompanyName, ''))) = '' )
    SET @IP_CompanyName = null;

  IF ( LTRIM(RTRIM(ISNULL(@IP_DocumentIDSeq, ''))) = '' )
    SET @IP_DocumentIDSeq = null;
    
  select  @rowstoprocess = @IP_PageNumber * @IP_RowsPerPage

  SET ROWCOUNT @rowstoprocess;
  WITH Temp_ContractList AS (
    SELECT  
      Count(*) OVER() as _TotalRows_, -- Adding this for Paging.  This will avoid multiple hits to table to get total count.
      ROW_NUMBER() OVER (ORDER BY cont.IDSeq)AS RowNumber,     
      cont.IDSeq,
      cont.CompanyIDSeq,
      comp.Name as CompanyName,
      cont.OwnerIDSeq,
      owner.Name as OwnerName,
      cont.PropertyIDSeq,
      cont.DocumentIDSeq,
      cont.TypeCode,
      itm.Name as TypeName,
      cont.FamilyCode,
      fam.Name as FamilyName,
      cont.ProductCode,
      cont.Title,
      cont.TemplateIDSeq,
      cont.TemplateVersion,
      cont.Author,
      cont.PMCSignBy,
      cont.PMCSignByTitle,
      cont.OwnerSignBy,
      cont.OwnerSignByTitle,
      cont.RealPageSignBy,
      cont.RealPageSignByTitle,
      cont.CreatedDate,
      cont.SubmittedDate,
      cont.ReceivedDate,
      cont.ExecutedDate,
      cont.BeginDate,
      cont.ExpireDate,
      cont.CreatedBy,
      cont.ModifiedDate,
      cont.ModifiedBy
    From
      DOCS.dbo.Contract cont WITH (NOLOCK)
        INNER JOIN DOCS.dbo.Document doc WITH (NOLOCK) ON cont.DocumentIDSeq=doc.DocumentIDSeq
        INNER JOIN DOCS.dbo.DocumentClass docClass WITH (NOLOCK) ON doc.DocumentClassIDSeq=docClass.IDSeq
        INNER JOIN DOCS.dbo.Item itm WITH (NOLOCK) ON itm.Code=cont.TypeCode
        INNER JOIN Products.dbo.Family fam WITH (NOLOCK) ON cont.FamilyCode=fam.Code
        INNER JOIN Customers.dbo.Company comp WITH (NOLOCK) ON cont.CompanyIDSeq = comp.IDSeq
        LEFT JOIN Customers.dbo.Company owner WITH (NOLOCK) ON cont.OwnerIDSeq = owner.IDSeq
        LEFT JOIN Customers.dbo.Property prpty WITH (NOLOCK) ON cont.PropertyIDSeq = prpty.IDSeq
    WHERE 
      ( ( @IP_IDSeq is null ) OR ( @IP_IDSeq is not null and cont.IDSeq=@IP_IDSeq) )
      AND ( @IP_CompanyName is null OR ( @IP_CompanyName is not null and comp.Name like '%' + @IP_CompanyName + '%') )
      AND ( @IP_Status is null OR ( @IP_Status is not null and doc.StatusCode = @IP_Status) )
      AND ( @IP_DocumentIDSeq is null OR ( @IP_DocumentIDSeq is not null and doc.DocumentIDSeq = @IP_DocumentIDSeq) )
    )
    Select  
      *
    From
      Temp_ContractList
    WHERE 
      RowNumber > (@IP_PageNumber-1) * @IP_RowsPerPage
      and RowNumber <= (@IP_PageNumber)  * @IP_RowsPerPage

GO
