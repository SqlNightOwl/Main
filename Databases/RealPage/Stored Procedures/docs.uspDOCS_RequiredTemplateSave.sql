SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_RequiredTemplateSave

Purpose    :  Saves Data into RequiredTemplate table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_RequiredTemplateSave

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_RequiredTemplateSave]
(
  @IP_IDSeq bigint,
  @IP_TemplateIDSeq bigint,
  @IP_FamilyCode varchar (3),
  @IP_ProductCode varchar (30) 
)
AS
  IF ( @IP_IDSeq is not null )
  BEGIN
    UPDATE RequiredTemplate SET
      TemplateIDSeq=@IP_TemplateIDSeq
      , FamilyCode=@IP_FamilyCode, ProductCode=@IP_ProductCode
    OUTPUT 
      INSERTED.IDSeq as IDSeq
    Where 
      IDSeq = @IP_IDSeq
  END
  ELSE
  BEGIN
    INSERT INTO RequiredTemplate
      (TemplateIDSeq
       , FamilyCode, ProductCode)
    OUTPUT 
       INSERTED.IDSeq as IDSeq
    VALUES
      (@IP_TemplateIDSeq
       , @IP_FamilyCode, @IP_ProductCode)
  END

GO
