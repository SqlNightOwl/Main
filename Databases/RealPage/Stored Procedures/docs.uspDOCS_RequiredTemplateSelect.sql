SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_RequiredTemplateSelect

Purpose    :  Gets Data from RequiredTemplate table based on primary key.
             
Parameters : 


Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_RequiredTemplateSelect

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_RequiredTemplateSelect]
(
  @IP_IDSeq bigint
)
AS
  Select
    IDSeq,
    TemplateIDSeq,
    FamilyCode,
    ProductCode
  From
    RequiredTemplate
  Where
    IDSeq = @IP_IDSeq

GO
