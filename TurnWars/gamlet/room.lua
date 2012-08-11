-- store the pending sessions in this array
    sessions_pending = {}

    -- callback called when a new user connects to room
    -- conn_id is the connection identifier
    gamooga.onconnect(function(conn_id)
        -- if there is no session pending
        if sessions_pending[1] == nil then
            -- send a "join" message to connecting user with data '-1'
            -- meaning that there is no pending session and he should create new
            gamooga.send(conn_id, "join", -1)
        else
        -- if there is a session pending
            -- pop the session id from the pending list
            sess_id = table.remove(sessions_pending, 1)
            -- and send it as part to the "join" message to the user
            gamooga.send(conn_id, "join", sess_id)
        end
    end)

    -- callback called when a 'create' message is sent from a session to room
    -- sess_id is the session id of the session which sent the message
    -- (ignore the second variable _ )
    gamooga.onsessionmsg("create", function(sess_id, _)
        -- this message is sent when a new session is created which is waiting for
        -- another user, hence we add the sess_id to pending session list
        table.insert(sessions_pending, sess_id)
    end)
