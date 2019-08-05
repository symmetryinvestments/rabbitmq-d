module rabbitmq.examples.unbind;
import std.stdio;
import std.string;
import std.getopt;
import std.exception;
import std.conv:to;

import symmetry.api.rabbitmq;

struct Options
{
	string hostname;
	ushort port;
	string exchange;
	string bindingKey;
	string queue;
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
					std.getopt.config.required,
					"hostname",	&options.hostname,
					std.getopt.config.required,
					"port",		&options.port,
					std.getopt.config.required,
					"exchange",	&options.exchange,
					std.getopt.config.required,
					"binding-key",	&options.bindingKey,
					std.getopt.config.required,
					"queue",	&options.queue,
					"cacert",	&options.caCert,
					"verify-peer",	&options.verifyPeer,
					"verify-hostname", &options.verifyHostname,
					"key-file",	&options.keyFile,
					"cert-file",	&options.certFile,
	);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("unbind",helpInformation.options);
		return -1;
	}


	conn = amqp_new_connection();
	socket = amqp_ssl_socket_new(conn);
	enforce(socket !is null, "creating SSL/TLS socket");

	amqp_ssl_socket_set_verify_peer(socket, options.verifyPeer ? 1 : 0);
	amqp_ssl_socket_set_verify_hostname(socket, options.verifyHostname ? 1 : 0);

	if(options.caCert.length > 0)
	{
		enforce(amqp_ssl_socket_set_cacert(socket, options.caCert.toStringz) == 0, "setting CA cert");
	}
	
	if (options.keyFile.length > 0)
	{
		enforce(options.certFile.length > 0, "must specify a cert-file if you specify a key-file");
		enforce(amqp_ssl_socket_set_key(socket, options.certFile.toStringz, options.keyFile.toStringz) == 0, "setting client cert");
	}
	else
	{
		enforce(options.certFile.length == 0, "must specify a key-file if you specify a cert-file");
	}

	enforce(amqp_socket_open(socket, options.hostname.toStringz, options.port) ==0, "opening SSL/TLS connection");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	amqp_queue_unbind(conn, 1,
		    amqp_string(options.queue),
		    amqp_string(options.exchange),
		    amqp_string(options.bindingKey),
		    cast(amqp_table_t) amqp_empty_table);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Unbinding");

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	return 0;
}
