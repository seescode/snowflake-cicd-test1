-- Set context
USE WAREHOUSE <%wh%>;

!source tables/claims.sql
!source tables/members.sql
!source tables/providers.sql

!source views/vw_claims_summary.sql

!source stored_procedures/process_claim.sql
