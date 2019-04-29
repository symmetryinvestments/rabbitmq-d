module sendstring;
import std.stdio;
import std.string;
import std.getopt;
import std.exception;

import kaleidic.api.rabbitmq;
import kaleidic.api.rabbitmq.utils;

struct Options
{
	string hostname;
	ushort port;
	string exchange;
	string routingKey;
	string messageBody;
	string caCert;
	bool verifyPeer;
	bool verifyHostname;
	string keyFile;
	string certFile;
}

int main(string[] args)
{
	Options options;

	int status;
	amqp_socket_t *socket;
	amqp_connection_state_t conn;

	auto helpInformation = getopt(	args,
					"hostname",	&options.hostname,
					"port",		&options.port,
					"exchange",	&options.exchange,
					"routing-key",	&options.routingKey,
					"message-body",	&options.messageBody,
					"cacert",	&options.caCert,
					"verify-peer",	&options.verifyPeer,
					"verify-hostname", &options.verifyHostname,
					"key-file",	&options.keyFile,
					"cert-file",	&options.certFile
	);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("sendstring",helpInformation.options);
		return -1;
	}

	conn = amqp_new_connection();
	socket = amqp_ssl_socket_new(conn);
	enforce(socket !is null, "creating ssl/tls socket");

	amqp_ssl_socket_set_verify_peer(socket, options.verifyPeer ? 1:0);
	amqp_ssl_socket_set_verify_hostname(socket, options.verifyHostname ? 1: 0);

	if(options.caCert.length > 0)
	{
		enforce(amqp_ssl_socket_set_cacert(socket, options.caCert.toStringz) == 0, "setting CA certificate");
	}

	if (options.keyFile.length > 0)
	{
		enforce(options.certFile.length > 0, "if you specify key-file you must also specify cert-file");
		enforce(amqp_ssl_socket_set_key(socket, options.certFile.toStringz, options.keyFile.toStringz) == 0, "setting client cert");
	}

	enforce(amqp_socket_open(socket, options.hostname.toStringz, options.port) == 0, "opening SSL/TLS connection");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	{
		amqp_basic_properties_t props;
		props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG;
		props.content_type = amqp_string("text/plain");
		props.delivery_mode = 2; /* persistent delivery mode */
		die_on_error(amqp_basic_publish(conn,
					    1,
					    amqp_string(options.exchange),
					    amqp_string(options.routingKey),
					    0,
					    0,
					    &props,
					    amqp_string(options.messageBody)),
			 "Publishing");
	}

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	return 0;
}
