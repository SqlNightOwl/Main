SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_TemplateSelect

Purpose    :  Gets Data from Template table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_TemplateSelect

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_TemplateSelect]
(
  @IP_IDSeq bigint
)
AS
  Select
    IDSeq,
    Version,
    Name,
    FilePath,
    ItemCode,
    FamilyCode,
    ProductCode
  From
    Template
  Where
    IDSeq = @IP_IDSeq

GO
