SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyList]  (@CompanyID varchar(50))
AS
BEGIN 
  set nocount on;
  --------------------------------
  /*select isnull(Max(P.Name),(select [name] from company where idseq=@CompanyID))   as [Name],
         isnull(P.IDSeq,0)       as [ID]
  from   Customers.dbo.PriceCapProducts PCP with (nolock)
  left join
         Customers.dbo.PriceCapProperties PP with (nolock)
  on     PCP.PriceCapIDSeq       = PP.PriceCapIDSeq
  left join  [Property] P on P.idseq=PP.PropertyIDseq
  and    P.IDSeq          = PP.PropertyIDSeq
  and    P.PMCIDSeq       = @CompanyID
  and    PP.CompanyIDSeq  = @CompanyID
  and    P.StatusTypeCode = 'ACTIV'
  group by P.IDSeq
  Order by [Name] asc*/
  --------------------------------     

  select isnull(Max(P.Name), max(C.Name))   as [Name],
         isnull(P.IDSeq, 0)       as [ID]
  from   Customers.dbo.PriceCapProducts PCP with (nolock)
  left join Customers.dbo.PriceCapProperties PP with (nolock)
  on     PCP.PriceCapIDSeq = PP.PriceCapIDSeq and PCP.CompanyIDSeq = PP.CompanyIDSeq
  left join  Customers.dbo.[Property] P on PP.PropertyIDseq = P.IDSeq
  and    PP.CompanyIDSeq  = P.PMCIDSeq
  and    P.StatusTypeCode = 'ACTIV'
  left join  Customers.dbo.Company C on PCP.CompanyIDSeq = C.IDSeq
  where PCP.CompanyIDSeq = @CompanyID
  group by P.IDSeq
  Order by [Name] asc
END
GO
