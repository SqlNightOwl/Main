SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactTypeCodesSelect] 
as
begin
  select Code, Name
  from ContactType
  order by Name
end

GO
