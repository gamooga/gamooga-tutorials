gamooga.onmessage("coordata", function(conn_id, msg)
    gamooga.broadcastexcept("coordata", {conn_id,msg}, conn_id)
end)