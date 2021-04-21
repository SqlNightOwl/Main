SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyHistoryList]  (@IPVC_CompanyID     varchar(50),
                                                            @IPVC_PriceCapIDSeq varchar(50)
                                                            )
AS
BEGIN 
  set nocount on;
  --------------------------------
  select Max(P.Name)   as [Name],
         P.IDSeq       as [ID]
  from   Customers.dbo.Property P with (nolock)
  inner join
         Customers.dbo.PriceCapPropertiesHistory PP with (nolock)
  on     P.PMCIDSeq       = PP.CompanyIDSeq
  and    P.IDSeq          = PP.PropertyIDSeq
  and    P.PMCIDSeq       = @IPVC_CompanyID
  and    PP.CompanyIDSeq  = @IPVC_CompanyID
  and    P.StatusTypeCode = 'ACTIV'
  and    pp.PriceCapIDSeq = @IPVC_PriceCapIDSeq
  group by P.IDSeq
  Order by [Name] asc
  --------------------------------           
END
GO
