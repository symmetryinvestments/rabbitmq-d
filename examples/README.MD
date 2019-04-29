Arrange for a RabbitMQ or other AMQP server to be running on localhost at TCP port number 5672.

In one terminal, run

./examples/listen --hostname localhost --port 5672 --exchange amq.direct --binding-key test --use-ssl=false
In another terminal,

./examples/sendstring --hostname localhost --port 5672 --exchange amq.direct --routing-key test --message-body "hello world" --use-ssl=false

You should see output similar to the following in the listener's terminal window:

Delivery 1, exchange amq.direct routingkey test
Content-type: text/plain
----
00000000: 68 65 6C 6C 6F 20 77 6F : 72 6C 64                 hello world
0000000B:
