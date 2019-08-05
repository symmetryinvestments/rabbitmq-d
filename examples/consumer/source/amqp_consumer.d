module rabbitmq.examples.amqp_consumer;
import std.stdio;
import std.string;
import std.conv:to;

import symmetry.api.rabbitmq;


enum SUMMARY_EVERY_US = 1000000;

void run(amqp_connection_state_t conn)
{
  ulong start_time = now_microseconds();
  int received = 0;
  int previous_received = 0;
  ulong previous_report_time = start_time;
  ulong next_summary_time = start_time + SUMMARY_EVERY_US;

  amqp_frame_t frame;

  ulong now;

  while(true)
  {
    amqp_rpc_reply_t ret;
    amqp_envelope_t envelope;

    now = now_microseconds();
    if (now > next_summary_time) {
      int countOverInterval = received - previous_received;
      double intervalRate = countOverInterval / ((now - previous_report_time) / 1000000.0);
      printf("%d ms: Received %d - %d since last report (%d Hz)\n",
             cast(int)(now - start_time) / 1000, received, countOverInterval, cast(int) intervalRate);

      previous_received = received;
      previous_report_time = now;
      next_summary_time += SUMMARY_EVERY_US;
    }

    amqp_maybe_release_buffers(conn);
    ret = amqp_consume_message(conn, &envelope, null, 0);

    if (AMQP_RESPONSE_NORMAL != ret.reply_type) {
      if (AMQP_RESPONSE_LIBRARY_EXCEPTION == ret.reply_type &&
          AMQP_STATUS_UNEXPECTED_STATE == ret.library_error) {
        if (AMQP_STATUS_OK != amqp_simple_wait_frame(conn, &frame)) {
          return;
        }

        if (AMQP_FRAME_METHOD == frame.frame_type) {
          switch (frame.payload.method.id) {
            case AMQP_BASIC_ACK_METHOD:
              /* if we've turned publisher confirms on, and we've published a message
               * here is a message being confirmed
               */

              break;
            case AMQP_BASIC_RETURN_METHOD:
              /* if a published message couldn't be routed and the mandatory flag was set
               * this is what would be returned. The message then needs to be read.
               */
              {
                amqp_message_t message;
                ret = amqp_read_message(conn, frame.channel, &message, 0);
                if (AMQP_RESPONSE_NORMAL != ret.reply_type) {
                  return;
                }

                amqp_destroy_message(&message);
              }

              break;

            case AMQP_CHANNEL_CLOSE_METHOD:
              /* a channel.close method happens when a channel exception occurs, this
               * can happen by publishing to an exchange that doesn't exist for example
               *
               * In this case you would need to open another channel redeclare any queues
               * that were declared auto-delete, and restart any consumers that were attached
               * to the previous channel
               */
              return;

            case AMQP_CONNECTION_CLOSE_METHOD:
              /* a connection.close method happens when a connection exception occurs,
               * this can happen by trying to use a channel that isn't open for example.
               *
               * In this case the whole connection must be restarted.
               */
              return;

            default:
              stderr.writefln("An unexpected method was received: %s", frame.payload.method.id);
              return;
          }
        }
      }

    } else {
      amqp_destroy_envelope(&envelope);
    }

    received++;
  }
}

int main(string[] args)
{
  int status;
  string exchange, bindingKey;
  amqp_socket_t *socket = null;
  amqp_connection_state_t conn;

  amqp_bytes_t queuename;

  if (args.length< 3) {
    stderr.writeln("Usage: amqp_consumer host port\n");
    return 1;
  }

  auto hostname = args[1];
  auto port = args[2].to!ushort;
  exchange = "amq.direct"; /* argv[3]; */
  bindingKey = "test queue"; /* argv[4]; */

  conn = amqp_new_connection();

  socket = amqp_tcp_socket_new(conn);
  if (!socket) {
    die("creating TCP socket");
  }

  status = amqp_socket_open(socket, hostname.toStringz, port);
  if (status) {
    die("opening TCP socket");
  }

  die_on_amqp_error(amqp_login(conn, "/".toStringz, 0, 131072, 0, SaslMethod.plain, "guest".toStringz, "guest".toStringz),
                    "Logging in".toStringz);
  amqp_channel_open(conn, 1);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

  {
    amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1.to!ushort, cast(amqp_bytes_t)amqp_empty_bytes, 0, 0, 0, 1,
                                 cast(amqp_table_t) amqp_empty_table);
    die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring queue");
    queuename = amqp_bytes_malloc_dup(r.queue);
    if (queuename.bytes is null) {
      stderr.writeln("Out of memory while copying queue name");
      return 1;
    }
  }

  amqp_queue_bind(conn, 1.to!ushort, queuename, amqp_cstring_bytes(exchange.toStringz), amqp_cstring_bytes(bindingKey.toStringz),
                  cast(amqp_table_t) amqp_empty_table);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Binding queue");

  amqp_basic_consume(conn, 1.to!ushort, queuename,cast(amqp_bytes_t) amqp_empty_bytes, 0, 1, 0, cast(amqp_table_t)amqp_empty_table);
  die_on_amqp_error(amqp_get_rpc_reply(conn), "Consuming");

  run(conn);

  die_on_amqp_error(amqp_channel_close(conn, 1.to!ushort, AMQP_REPLY_SUCCESS), "Closing channel");
  die_on_amqp_error(amqp_connection_close(conn, AMQP_REPLY_SUCCESS), "Closing connection");
  die_on_error(amqp_destroy_connection(conn), "Ending connection");

  return 0;
}
