SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_ContractTypeList

Purpose    :  Gets data from ContractType table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_ContractTypeList

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_ContractTypeList]
AS
  Select DISTINCT
    Code,
    [Name],
    Description,
    SortSeq
  From
    ContractType
  Order by
    SortSeq

GO
