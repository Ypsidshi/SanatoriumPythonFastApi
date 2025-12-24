USE sanatorium;
GO
EXEC sp_spaceused;
GO
-- детально по таблицам:
EXEC sp_spaceused 'manager';
EXEC sp_spaceused 'administrator';
EXEC sp_spaceused 'pansionat';
EXEC sp_spaceused 'room';
EXEC sp_spaceused 'resident';
EXEC sp_spaceused 'contract';
EXEC sp_spaceused 'service';
EXEC sp_spaceused 'provision_of_services';
EXEC sp_spaceused 'using_service';
