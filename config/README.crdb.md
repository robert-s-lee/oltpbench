-- Split district and warehouse tables every 10 warehouses.
ALTER TABLE warehouse SPLIT AT select generate_series(1,10, 10);
ALTER TABLE district SPLIT AT select generate_series(1,10, 10), 0;
-- Split the item table every 100 items.
ALTER TABLE item SPLIT AT select generate_series(1, 100000*10, 100);
-- Split the history table into 1000 ranges.
ALTER TABLE history split at select gen_random_uuid() from generate_series(1, 1000);

