first_user = nil
    second_user = nil

    -- callback called as soon as a new user connects to the session
    gamooga.onconnect(function(conn_id)
        -- if first user is not nil, implying this is the second user joining
        if first_user ~= nil then
            -- store the second user's connection id
            second_user = conn_id
            -- send a "start" message to both the users with their player ids
            gamooga.send(first_user, "start", 1)
            gamooga.send(second_user, "start", 2)
        else
        -- if its the first user joining the session
            -- store the first user's connection id
            first_user = conn_id
            -- send a "wait" message to the first user since he is waiting for another user
            gamooga.send(first_user, "wait", "")
            -- also send a message to room, to let it know that this session is a pending session
            gamooga.sendtoroom("create", "")
        end
    end)

-- Callback executed when a message of type "move" is received from client
    -- the second argument is the dictionary sent from the client side
    gamooga.onmessage("move", function(conn_id, move)
        -- if we received the message from first user
        if first_user == conn_id then
            -- send the same dictionary received to the second user
            gamooga.send(second_user, "move", move)
        else
            -- else (we received the message from second user), send the dictionary to the first user
            gamooga.send(first_user, "move", move)
        end
    end)

    -- on receiving "endturn" send the message to other user
    gamooga.onmessage("endturn", function(conn_id, _)
        if first_user == conn_id then
            gamooga.send(second_user, "endturn", _)
        else
            gamooga.send(first_user, "endturn", _)
        end
    end)

    gamooga.onmessage("moveattack", function(conn_id, move)
        if first_user == conn_id then
            gamooga.send(second_user, "moveattack", move)
        else
            gamooga.send(first_user, "moveattack", move)
        end
    end)