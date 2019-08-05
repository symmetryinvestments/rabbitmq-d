module rabbitmq.examples.listenq;
import std.stdio;
import std.string;
import std.exception;
import std.conv:to;
import std.getopt;

import symmetry.api.rabbitmq;

struct Options
{
	string hostname;
	ushort port;
	string queuename;
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
					"queuename",	&options.queuename,
					"cacert",	&options.caCert,
					"verify-peer",	&options.verifyPeer,
					"verify-hostname", &options.verifyHostname,
					"keyFile",	&options.keyFile,
					"certFile",	&options.certFile,
	);
	
	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("listenq", helpInformation.options);
		return -1;
	}

	conn = amqp_new_connection();
	socket = amqp_ssl_socket_new(conn);
	enforce(socket !is null, "creating SSL/TLS socket");

	amqp_ssl_socket_set_verify_peer(socket, options.verifyPeer ? 1 : 0);
	amqp_ssl_socket_set_verify_hostname(socket, options.verifyHostname ? 1: 0);

	if (options.caCert.length > 0)
	{
		enforce (amqp_ssl_socket_set_cacert(socket, options.caCert.toStringz) == 0, "setting CA certificate");
	}
	
	if (options.keyFile.length >0)
	{
		enforce(options.certFile.length > 0, "must specify a cert-file if you specify a key-file");
		enforce(amqp_ssl_socket_set_key(socket, options.certFile.toStringz, options.keyFile.toStringz) ==0, "setting client cert");
	}

	enforce(amqp_socket_open(socket, options.hostname.toStringz, options.port) == 0, "opening SSL/TLS connection");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	amqp_basic_consume(conn, 1, amqp_string(options.queuename), cast(amqp_bytes_t)amqp_empty_bytes, 0, 0, 0, cast(amqp_table_t)amqp_empty_table);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Consuming");

	{
		for (;;) {
			amqp_rpc_reply_t res;
			amqp_envelope_t envelope;

			amqp_maybe_release_buffers(conn);

			res = amqp_consume_message(conn, &envelope, null, 0);

			if (AMQP_RESPONSE_NORMAL != res.reply_type) {
				break;
			}

			writefln("Delivery %s, exchange %s routingkey %s",
			     envelope.delivery_tag,
			     cast(char[]) envelope.exchange.bytes[0..envelope.exchange.len],
			     cast(char[]) envelope.routing_key.bytes[0.. envelope.routing_key.len]);

			if (envelope.message.properties._flags & AMQP_BASIC_CONTENT_TYPE_FLAG) {
				writefln("Content-type: %s",
			        cast(char[]) envelope.message.properties.content_type.bytes
		       				[0..envelope.message.properties.content_type.len]);
			}
			writefln("----");

			amqp_dump(cast(ubyte[]) envelope.message.body_.bytes[0.. envelope.message.body_.len]);

			amqp_destroy_envelope(&envelope);
		}
	}

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");

	return 0;
}
