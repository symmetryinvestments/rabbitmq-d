module kaleidic.api.rabbitmq.examples.bind;
import std.stdio;
import std.string;

import kaleidic.api.rabbitmq.rabbitmq;
import utils;

int main(string[] args)
{
  amqp_socket_t *socket;
  amqp_connection_state_t conn;
  timeval tval;
  timeval* tv;

  if (args.length < 3)
  {
    stderr.writeln("Usage: amqp_connect_timeout host port [timeout_sec [timeout_usec=0]]");
    return 1;
  }

  if (args.length > 3)
  {
    tv = &tval;

    tv.tv_sec = args[3].to!int;

    if (argc > 4 ) {
      tv.tv_usec = args[4].to!int;
    } else {
      tv.tv_usec = 0;
    }

  } else {
    tv = null;
  }


  auto hostname = args[1];
  auto port = args[2].to!int;
  conn = amqp_new_connection();
  socket = amqp_tcp_socket_new(conn);

  enforce(socket,"errorcreating TCP socket");
  die_on_error(amqp_socket_open_noblock(socket, hostname.toStringZ, port, tv), "opening TCP socket".toStringZ);
  die_on_amqp_error(amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, "guest", "guest"), "Logging in");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connection");
  writeln("Done");
  return 0;
}
