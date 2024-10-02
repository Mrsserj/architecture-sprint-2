#!/bin/bash

###
# Инициализируем бд
###

docker compose exec -i configSrv mongosh --port 27016 <<EOF

rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27016" }
    ]
  }
);
EOF

docker exec -i shard1_0 mongosh --port 27017 <<EOF

rs.initiate(
    {
      _id : "shard1",
      members: [
        {_id: 0, host: "shard1_0:27017"},
	    {_id: 1, host: "shard1_1:27018"},
	    {_id: 2, host: "shard1_2:27019"}
      ]
    }
);
EOF

docker exec -i shard2_0 mongosh --port 27021 <<EOF

rs.initiate(
    {
      _id : "shard2",
      members: [
        {_id: 0, host: "shard2_0:27021"},
	    {_id: 1, host: "shard2_1:27022"},
	    {_id: 2, host: "shard2_2:27023"}
      ]
    }
  );
EOF

docker exec -i mongos_router mongosh --port 27020 <<EOF

sh.addShard( "shard1/shard1_0:27017");
sh.addShard( "shard2/shard2_0:27021");

sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

use somedb

for(var i = 0; i < 1000; i++) db.helloDoc.insertOne({age:i, name:"ly"+i})
EOF
