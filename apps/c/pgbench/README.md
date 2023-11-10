Instruction for upload pgbench data to YDB benchmark postgres layer.

# Prepare data

## Simple way
Download already prepared data from [gist](https://gist.githubusercontent.com/rekby/95e0f0c2fd6ff595054c03c2c2ae776a/raw/pgbench.sql)

```
# Short dataset (10 records)
wget https://gist.githubusercontent.com/rekby/95e0f0c2fd6ff595054c03c2c2ae776a/raw/pgbench-short.sql -O tmp/pgbench.sql

# Dataset with scale factor 1
wget https://gist.githubusercontent.com/rekby/95e0f0c2fd6ff595054c03c2c2ae776a/raw/pgbench.sql -O tmp/pgbench.sql

# Dataset with scale factor 9, near 100MB
wget https://gist.githubusercontent.com/rekby/95e0f0c2fd6ff595054c03c2c2ae776a/raw/pgbench-9.sql -O tmp/pgbench.sql
```

## Generate new data with script

Run create-pgbench-data-dump.sh. The script require installed docker.

```bash
cd <git-root>
./apps/c/pgbench/create-pgbench-data-dump.bash > tmp/pgbench.sql
```

# Upload data to YDB.
It can be uploaded with psql command:

```bash
cat pgbtmp/pgbench.sql | PGPASSWORD=password psql -h localhost -U root -d local -p 5432
```
