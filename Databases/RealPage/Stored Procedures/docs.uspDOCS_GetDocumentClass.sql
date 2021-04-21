SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_GetDocumentClass

Purpose    :  Gets Data from Document table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_GetDocumentClass

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_GetDocumentClass]
(
  @IP_StructureCode varchar(3),
  @IP_TypeCode varchar(3),
  @IP_SourceCode varchar(3),
  @IP_CategoryCode varchar(3),
  @IP_ItemCode varchar(3)
)
AS
  Select TOP 1
    IDSeq,
    StructureCode,
    TypeCode,
    SourceCode,
    CategoryCode,
    ItemCode,
    SharePointFlag,
    CustomerPortalFlag
  From
    DocumentClass
  Where
    StructureCode=@IP_StructureCode AND TypeCode=@IP_TypeCode AND
    SourceCode=@IP_SourceCode AND CategoryCode=@IP_CategoryCode AND
    ItemCode=@IP_ItemCode

GO
