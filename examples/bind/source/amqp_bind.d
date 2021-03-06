module rabbitmq.examples.bind;
import std.stdio;
import std.string;
import std.conv:to;
import std.exception;

import symmetry.api.rabbitmq;


int main(string[] args)
{
  if (args.length < 6) {
    stderr.writefln("Usage: amqp_bind host port exchange bindingkey queue\n");
    return 1;
  }

  auto hostname = args[1];
  auto port=args[2].to!ushort;
  auto exchange = args[3];
  auto bindingKey = args[4];
  auto queue = args[5];

  amqp_connection_state_t conn = amqp_new_connection();
  amqp_socket_t* socket = amqp_tcp_socket_new(conn);
  enforce(socket !is null, "error creating TCP socket");
  auto status = amqp_socket_open(socket, hostname.toStringz, port);
  enforce(status,"error opening TCP socket");
  die_on_amqp_error(amqp_login(conn, "/", 0, 131072, 0, SaslMethod.plain, "guest".toStringz, "guest".toStringz), "Logging in");
  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

  amqp_queue_bind(conn, 1.to!ushort,
                  amqp_cstring_bytes(queue.toStringz),
                  amqp_cstring_bytes(exchange.toStringz),
                  amqp_cstring_bytes(bindingKey.toStringz),
                  cast(amqp_table_t)amqp_empty_table);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Unbinding");

  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connection");
  return 0;
}
