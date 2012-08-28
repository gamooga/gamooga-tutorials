LiveDraw
========

Introduction
------------
In this tutorial we create a realtime collaborative draw-as-you-like application in HTML5 using Gamooga. Langauges: HTML/javascript (client side), lua (server side)

Implementation
--------------
We will have no room functionality in this demo. We will solely use sessions to create independent drawing instances between a set of users.

Any number of users can connect to a session. We collect the drawing coordinates by one user and transport them to all other users. To collect the drawing coordinates, we use the canvas mousedown, mousemove and mouseup events. When the collected coordinates are received by other users, we draw them on their own canvas. Easy right!

Setup
-----
1. To develop using Gamooga, you require to download and install the SDK from http://www.gamooga.com/dev/docs/sdk.html.
2. Create a folder called 'LiveDraw' with in 'gamooga-sdk' folder created in step 1.
3. With in 'LiveDraw', create two folders: 'gamlet' and 'html'.
4. Now start Terminal/Command Prompt(cmd) and cd into 'gamooga-sdk' folder
5. Run the development server::

    path\to\python.exe dev-server/gamooga.py LiveDraw\gamlet             #(Windows)
    python ./dev-server/gamooga.py ./LiveDraw/gamlet ./LiveDraw/html     #(Linux/Mac Snow Leapord)
    python2.6 ./dev-server/gamooga.py ./LiveDraw/gamlet ./LiveDraw/html  #(Mac Lion)
6. Now from 'gamooga-sdk/api/javascript', copy the two files - gamooga.js and sock_bridge.swf - into 'LiveDraw/html' folder.

The final folder structure will look like this::

    gamooga-sdk
    |-- VERSION
    |-- api
    |-- demos
    |-- dev-server
    |-- LiveDraw                (created)
    |   |-- gamlet              (created)
    |   |-- html                (created)
    |   |   |-- gamooga.js      (copied from 'gamooga-sdk/api/javascript')
    |   |   |-- sock_bridge.swf (copied from 'gamooga-sdk/api/javascript')

Initial page
------------
Create a file called ``index.html`` with in "LiveDraw/html" and add the following html into it.

index.html:

.. code-block:: html

    <!DOCTYPE html>
    <html>
    <head>
    <script type="text/javascript" src="./gamooga.js"></script>
    <script src="//ajax.googleapis.com/ajax/libs/jquery/1.8.0/jquery.min.js"></script>
    <script type="text/javascript">
    // TODO
    </script>
    </head>
    <body>
    <table>
    <tr><td>
    <button onclick="javascript:erase()">Clear</button><br>
    <canvas id="canvas" style="border:1px solid black"></canvas>
    </td><td style="padding-left:100px">
    <div id="connwait"><h1>Connecting, please wait...</h1></div>
    <div id="info" style="display:none"><h1>Joined session: <span id="sessid">-</span></h1><div style="text-align:left">To experience live drawing collaboration demo, you can<br>
    <a id="newsess" href="javascript:void(0)" target="_blank">Click here</a> to open the same session in another browser.
    </td></tr>
    </table>
    </body>
    </html>

The above html is the layout of our page. You can open the above file in a browser to see the layout.

Initialize Canvas and GamoogaClient
-----------------------------------

Add the following code between '<script>' and '</script>' (those with a // TODO):

.. code-block:: javascript

    var canvasMinX, canvasMinY;
    var ctx;
    var gc;
    
    function canvas_init() {
        canvasMinX = $("#canvas").offset().left;
        canvasMinY = $("#canvas").offset().top;
        ctx = document.getElementById('canvas').getContext('2d');
        ctx.canvas.width = 600;
        ctx.canvas.height = 600;
        ctx.strokeStyle = "#000000";
        ctx.lineWidth = 1;
        ctx.lineJoin = "round";
        ctx.lineCap = "round";
        ctx.beginPath();
    }

    function oninit() {
        canvas_init();
        gc = new GamoogaClient("127.0.0.1");
        gc.onconnect(function() {
            // TODO
        });
        if (window.location.hash) {
            sess_id = window.location.hash.substr(1);
            gc.connectToSession(sess_id-0, "-dummy-");
        } else {
            gc.createConnectToSession(0,"-dummy-");
        }
    }

    GamoogaClient.init("./sock_bridge.swf", oninit);

The above code does the following:

1. Initializes ``GamoogaClient`` and adds ``oninit`` as a callback to be called after initialization.
2. ``oninit`` calls ``canvas_init`` which initializes canvas and sets other parameters.
3. ``oninit`` then creates an instance of ``GamoogaClient``.
4. Adds an ``onconnect`` callback (a TODO).
5. Creates and connects to a session.

Also notice that if we have a session id in the url hash, we join that session instead of creating anew. Hence opening the html page without any url hash creates a new session and opening it with a url hash containing a session id joins it into that session.

You can now open this page by going to http://localhost:10000/ (assuming the development server is already running). Gamooga client library when connected to development server populates the developer console with all the events like connected, messages sent/received, disconnected and any other errors that occur. Open up developer console and you can see a "GAMOOGA: connected" as shown below. As you go through the next sections and send/receive messages from Gamooga backend, you can also see those messages in the developer console.

.. image:: //raw.github.com/gamooga/gamooga-tutorials/master/LiveDraw/img/connected.png

Onconnect callback
------------------

Fill the ``onconnect`` callback now:

.. code-block:: javascript

    gc.onconnect(function() {
        window.location.hash = "#"+gc.getSessId(); 
        document.getElementById("sessid").innerHTML = window.location.hash.substring(1);
        document.getElementById("newsess").href = window.location.href;
        document.getElementById("connwait").style.display="none";
        document.getElementById("info").style.display="block";  
        start();
    });

In the above code, we provide visual feedback that the user is connected. We update our page url to add the session id so it can be copy-pasted in a new browser tab/window. We also update the join link in the right side of the page so you can click it to open a new page that connects to the same session.

Since we are connected to the backend now, we can start drawing on the canvas. Add the ``start`` function:

.. code-block:: javascript

    function start() {
        $("#canvas").mousemove(onMouseMove);
        $("#canvas").mousedown(onMouseDown);
        $("#canvas").mouseup(onMouseUp);
        setInterval(sendData, 250);
    }

In the above code we add callbacks to ``mousemove``, ``mousedown`` and ``mouseup`` events of the canvas. We also register a function ``sendData`` to be called every 250ms.

Mouse events
------------

Add the following global variables at the start of the script tag:

.. code-block:: javascript

    var mousedown = false;
    var coorData = "";
    var newpath = true;

Now add the following functions:

.. code-block:: javascript

    function onMouseDown(evt) {
        mousedown = true;
    }
    function onMouseUp(evt) {
        mousedown = false;
        newpath = true;
        coorData += "-1,-1;";
    }
    function onMouseMove(evt) {
        if (!mousedown) return;
        var x = evt.pageX - canvasMinX;
        var y = evt.pageY - canvasMinY;
        if (newpath) {
            ctx.moveTo(x, y);
            newpath = false;
        } else {
            ctx.lineTo(x, y);
        }
        ctx.stroke();
        coorData += x+","+y+";";
    }

When the user holds the mouse down we set ``mousedown`` to ``true``. When he moves it with mouse down, ``onMouseMove`` is executed, which essentially draws paths as user moves his mouse. We also collect the move coordinates in a variable ``coorData``. When he releases the mouse, we set ``mousedown`` to false and add a "-1,-1;" to ``coorData``.

``coorData`` collects the coordinates seperated by a ';' with the ``x`` and ``y`` values seperated by a ','. Also to distinguish a new path from an old one, we add a "-1,-1;" to ``coorData`` in ``mouseup`` so we can replicate the same output at other connected users.

Coordinate transport
--------------------

Remember we set an interval for ``sendData`` function to be called every 250ms, we now fill that function:

.. code-block:: javascript

    function sendData() {
        if (coorData != "") {
            gc.send("coordata", coorData);
            coorData = "";
        }
    }

In the above code, we send the coordiante data to the server using ``gc.send`` accompanied with message type ``coordata``.

Server side
-----------

We have sent coordinate data from client side to server side, we now need to send that to other connected users. Add the following code to ``session.lua`` file in "LiveDraw/gamlet" folder.

.. code-block:: lua

    gamooga.onmessage("coordata", function(conn_id, msg)
        gamooga.broadcastexcept("coordata", msg, conn_id)
    end)

In the above code, we just broadcast the "coordata" type message received from one user to all other users except him. These are the only three lines of server side code required for this application. Easy, it really is, right?

Handle "coordata"
-----------------

At this point, when one user draws in his canvas, it is transported to all other users in the session. We now need to handle the transported coordinate data.

Add the following global variables at the top of the script tag:

.. code-block:: javascript

    var othernewpath = true;

Add an ``onmessage`` callback to ``oninit`` function.

.. code-block:: javascript

    function oninit() {
        ...
        // add the following after gc.onconnect callback
        gc.onmessage("coordata", function(d) {
            coors = d.split(";");
            for (var i=0;i<coors.length-1;i++) {
                var xy = coors[i].split(",");
                var x = xy[0];
                var y = xy[1];
                if (x=="-1") {
                    othernewpath = true;
                } else {
                    if (othernewpath) {
                        ctx.moveTo(x, y);
                        othernewpath = false;
                    } else {
                        ctx.lineTo(x, y);
                    }
                    ctx.stroke();
                }
            }
        });
        // more code already here
        ...
    }

The above code is mostly similar to ``onMouseMove`` function above. We attach a callback to be called on receiving a ``coordata`` type message. We split the received coordinate data at ';' and replicate the drawings in this canvas too.

The code is mostly complete now. Start the development server (if not already) as per step 5 in `Setup`_ section above. Open your browser and load up http://localhost:10000/. Once it connects you can open another tab/window to the same session by copy-pasting the url or clicking the "Click here" link on the right side of the page. Now try and draw in both the tabs. It works! Also open the developer console. You can see the messages being sent/received from the backend.

.. image:: //raw.github.com/gamooga/gamooga-tutorials/master/LiveDraw/img/messages.png

We are mostly done at this point, however there is a small issue when two or more users draw simultaneously (obviously from multiple computers). We fix that now.

Tiny caveat
-----------

You can see that ``ctx`` provides you with a single pointer on the canvas to extend the paths being drawn. Because of this, when mulitple users' paths are simultaneously drawn on your canvas, they are not drawn properly (``lineTo`` of different users intermingle and you see unneeded lines).

To fix that add the following global variables in script tag:

.. code-block:: javascript

    //var othernewpath = true // comment this line, change it to a dict as below
    var othernewpath = {};
    var mylastpoint;
    var hislastpoint = {};

Change ``session.lua`` like below:

.. code-block:: lua

    gamooga.onmessage("coordata", function(conn_id, msg)
        gamooga.broadcastexcept("coordata", {conn_id,msg}, conn_id) -- sending 'conn_id' too along with 'msg'
        -- also note that 'conn_id' is guaranteed to be unique for each of the connected users and hance
        -- can be used to identify different users on the client side as we see below.
    end)
    
Change ``onMouseMove`` like below:

.. code-block:: javascript

    function onMouseMove(evt) {
        if (!mousedown) return;
        var x = evt.pageX - canvasMinX;
        var y = evt.pageY - canvasMinY;
        if (newpath) {
            ctx.moveTo(x, y);
            newpath = false;
            mylastpoint = [x,y]; //added
        } else {
            ctx.moveTo(mylastpoint[0], mylastpoint[1]); //added
            ctx.lineTo(x, y);
            mylastpoint = [x,y]; //added
        }
        ctx.stroke();
        coorData += x+","+y+";";
    }

Change ``onmessage`` callback for ``coordata`` like below:

.. code-block:: javascript

    function oninit() {
        ...
        gc.onmessage("coordata", function(d) {
            coors = d[1].split(";"); //changed
            for (var i=0;i<coors.length-1;i++) {
                var xy = coors[i].split(",");
                var x = xy[0];
                var y = xy[1];
                if (x=="-1") {
                    othernewpath[d[0]] = true; //changed
                } else {
                    if (!(d[0] in othernewpath) || othernewpath[d[0]]) { //changed
                        ctx.moveTo(x, y);
                        othernewpath[d[0]] = false; //changed
                        hislastpoint[d[0]] = [x,y]; //added
                    } else {
                        ctx.moveTo(hislastpoint[d[0]][0], hislastpoint[d[0]][1]); //added
                        ctx.lineTo(x, y);
                        hislastpoint[d[0]] = [x,y]; //added
                    }
                    ctx.stroke();
                }
            }
        });
        ...
    }

Essentially in the above code, we made sure that before extending an user's path we move to the end of his already drawn path regardless of what we were drawing before. ``mylastpoint`` and ``hislastpoint`` store the end of already drawn paths of respective users. Please note that d[0] contained the 'conn_id' of the user (sent from server side) and since its unique, we use it to store user specific data in ``othernewpath`` and ``hislastpoint``.

With the above changes, the application is completely ready for collaborative realtime simultaneous drawing of as many users that may have joined the session. We are all done, except for one feature: the "clear" button. We implement it below.

Clear button
------------

When clear button is clicked, we want the canvases of all the users to clear up. Fill up the ``erase`` function that is called when "Clear" button is clicked.

.. code-block:: javascript

    function erase() {
        ctx.clearRect(0, 0, $('#canvas').width(), $('#canvas').height());
        ctx.closePath();
        ctx.beginPath();
        gc.send("coordata", "-2,-2;");
    }

We clear the rectangle and add a "-2,-2;" to coordinate data to be sent to other users. It is detected at other users and similar clear up is performed. Change ``onmessage`` callback for ``coordata`` like below:

.. code-block:: javascript

    function oninit() {
        ...
        gc.onmessage("coordata", function(d) {
            coors = d[1].split(";");
            for (var i=0;i<coors.length-1;i++) {
                var xy = coors[i].split(",");
                var x = xy[0];
                var y = xy[1];
                if (x=="-1") {
                    othernewpath[d[0]] = true;
                } else if (x=="-2") {                                                 //added
                    ctx.clearRect(0, 0, $('#canvas').width(), $('#canvas').height()); //added
                    ctx.closePath();                                                  //added
                    ctx.beginPath();                                                  //added
                } else {
                    if (othernewpath[d[0]]) {
                        ctx.moveTo(x, y);
                        othernewpath[d[0]] = false;
                        hislastpoint[d[0]] = [x,y];
                    } else {
                        ctx.moveTo(hislastpoint[d[0]][0], hislastpoint[d[0]][1]);
                        ctx.lineTo(x, y);
                        hislastpoint[d[0]] = [x,y];
                    }
                    ctx.stroke();
                }
            }
        });
        ...
    }

And with this we have the complete app ready. Test it out. Fire up browsers and go to http://localhost:10000/ in multiple tabs/windows and experience collaborative drawing. You can also load up the app in another machine by doing the following:

1. Change ``gc = new GamoogaClient("127.0.0.1");`` to ``gc = new GamoogaClient("<LAN ip of dev server>");`` in ``oninit`` function.
2. Go to \http://<LAN ip of dev server>:10000/.

Deployment
----------

To deploy to production, follow the steps:

1. Register in http://www.gamooga.com/ and login.
2. Click "Upload new gamlet" in "My gamlets" page.
3. Zip ``gamlet`` folder in 'LiveDraw/' and upload it.
4. Go the uploaded gamlet's dashboard and note the gamlet id and gamlet uuid.
5. Change ``gc.connectToSession(sess_id-0, "-dummy-");`` to ``gc.connectToSession(sess_id-0, "<noted gamlet uuid>");`` in ``oninit`` function.
6. Change ``gc.createConnectToSession(0,"-dummy-");`` to ``gc.createConnectToSession(<noted gamlet id>,"<noted gamlet uuid>");`` in ``oninit`` function.
7. Change ``gc = new GamoogaClient("<ip address>");`` to ``gc = new GamoogaClient();`` in ``oninit`` function.

Done, make your frontend (the 'LiveDraw/html' folder) public and when you open "index.html" it connects to production gamlet in Gamooga cluster.

Queires
-------

If you have any queries, please file an issue into the repository so anyone can respond to it. If you want to contact us you can mail us at: support [at] gamooga [dot] com
