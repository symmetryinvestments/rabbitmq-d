module rabbitmq.examples.connect_timeout;
import std.stdio;
import std.string;
import std.conv:to;
import std.exception;
import std.getopt;

import symmetry.api.rabbitmq;

struct Options
{
	string hostname;
	ushort port;
	int timeoutSec;
	int timeoutMicros;
}

int main(string[] args)
{
	Options options;
	amqp_socket_t *socket;
	amqp_connection_state_t conn;
	timeval tval;
	timeval* tv;

	auto helpInformation = getopt(	args,
		      			"hostname",	&options.hostname,
					"port",		&options.port,
					"timeout-sec",	&options.timeoutSec,
					"timeout-micros", &options.timeoutMicros,
	);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("connect_timeout", helpInformation.options);
		return -1;
	}

	tval.tv_sec = options.timeoutSec;
	tval.tv_usec = options.timeoutMicros;
	tv = (options.timeoutSec ==0 && options.timeoutMicros ==0) ? null : &tval;
  
	conn = amqp_new_connection();
	socket = amqp_tcp_socket_new(conn);
	enforce(socket !is null ,"errorcreating TCP socket");

	die_on_error(amqp_socket_open_noblock(socket, options.hostname.toStringz, options.port, tv), "opening TCP socket");
	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	writeln("Done");
	return 0;
}
