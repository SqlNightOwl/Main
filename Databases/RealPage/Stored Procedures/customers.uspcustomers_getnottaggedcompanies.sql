SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [customers].[uspcustomers_getnottaggedcompanies]
as
begin
select top 100 upper(idseq) 'Customer ID', upper([name]) 'Name', upper(space(3) + idseq + space(10) + [name]) 'Text Field' from company where statustypecode='activ' and multifamilyflag=1
end
GO
