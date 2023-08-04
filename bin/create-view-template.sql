-- Active: 1683965438922@@127.0.0.1@3306
CREATE VIEW view_classic_ESXiHosts 
AS
SELECT 
    o."ID",
    o."HostName", 
    o."Version",
    o."ConnectionState",
    o."PhysicalLocation",
    o."Manufacturer",
    o."Model",
    o."vCenterServer",
    o."Cluster",
    o."Created",
    i."Notes" 
FROM classic_ESXiHosts AS o
LEFT JOIN classic_ESXiHostsNotes AS i
ON o.HostName = i.HostName
