module kaleidic.api.rabbitmq.examples.bind;
import std.stdio;
import std.string;

import symmetry.api.rabbitmq.rabbitmq;
import utils;

int main(string[] args)
{
  char const *hostname;
  int port, status;
  char const *exchange;
  char const *exchangetype;
  amqp_socket_t *socket;
  amqp_connection_state_t conn;

  if (argc < 5) {
    fprintf(stderr, "Usage: amqps_exchange_declare host port exchange "
            "exchangetype [cacert.pem [verifypeer] [verifyhostname] "
            "[key.pem cert.pem]]\n");
    return 1;
  }

  hostname = argv[1];
  port = atoi(argv[2]);
  exchange = argv[3];
  exchangetype = argv[4];

  conn = amqp_new_connection();

  socket = amqp_ssl_socket_new(conn);
  if (!socket) {
    die("creating SSL/TLS socket");
  }

  amqp_ssl_socket_set_verify_peer(socket, 0);
  amqp_ssl_socket_set_verify_hostname(socket, 0);

  if (argc > 5) {
    int nextarg = 6;
    status = amqp_ssl_socket_set_cacert(socket, argv[5]);
    if (status) {
      die("setting CA certificate");
    }
    if (argc > nextarg && !strcmp("verifypeer", argv[nextarg])) {
      amqp_ssl_socket_set_verify_peer(socket, 1);
      nextarg++;
    }
    if (argc > nextarg && !strcmp("verifyhostname", argv[nextarg])) {
      amqp_ssl_socket_set_verify_hostname(socket, 1);
      nextarg++;
    }
    if (argc > nextarg + 1) {
      status =
          amqp_ssl_socket_set_key(socket, argv[nextarg + 1], argv[nextarg]);
      if (status) {
        die("setting client key/cert");
      }
    }
  }

  status = amqp_socket_open(socket, hostname, port);
  if (status) {
    die("opening SSL/TLS connection");
  }

  die_on_amqp_error(amqp_login(conn, "/", 0, 131072, 0, AMQP_SASL_METHOD_PLAIN, "guest", "guest"),
                    "Logging in");
  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

  amqp_exchange_declare(conn, 1, amqp_cstring_bytes(exchange), amqp_cstring_bytes(exchangetype),
                        0, 0, 0, 0, amqp_empty_table);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring exchange");

  die_on_amqp_error(amqp_channel_close(conn, 1, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connection");
  return 0;
}
