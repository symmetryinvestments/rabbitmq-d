module exchange_declare;
import std.stdio;
import std.string;
import std.exception;
import std.conv:to;

import kaleidic.api.rabbitmq;
import kaleidic.api.rabbitmq.utils;


int main(string[] args)
{
	if (args.length < 5)
	{
		stderr.writeln("Usage: amqp_exchange_declare host port exchange exchangetype");
		return 1;
	}

	auto hostname = args[1];
	auto port = args[2].to!int;
	auto exchange = args[3];
	auto exchangetype = args[4];

	amqp_connection_state_t conn = amqp_new_connection();

	auto socket = amqp_tcp_socket_new(conn);
	enforce(socket,"error creating TCP socket");
	auto status = amqp_socket_open(socket, hostname.toStringz, port);
	enforce(status, "opening TCP socket");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	amqp_exchange_declare(conn, 1, amqp_string(exchange), amqp_string(exchangetype),
			0, 0, 0, 0, cast(amqp_table_t) amqp_empty_table);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring exchange");

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	return 0;
}
