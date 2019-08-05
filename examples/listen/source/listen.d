module rabbitmq.examples.listen;
import std.stdio;
import std.string;
import std.exception;
import std.conv:to;
import std.getopt;

import kaleidic.api.rabbitmq;

struct Options
{
	string hostname;
	int port;
	string exchange;
	string bindingKey;
	bool useSSL = false;
	string caCert;
	bool verifyPeer = false;
	bool verifyHostname = false;
	string keyFile;
	string certFile;
}

int main(string[] args)
{
	Options options;
	int status;
	amqp_socket_t *socket;
	amqp_connection_state_t conn;

	amqp_bytes_t queuename;

	auto helpInformation = getopt(	args,
					std.getopt.config.required,
					"hostname",	&options.hostname,
					std.getopt.config.required,
					"port",		&options.port,
					std.getopt.config.required,
					"exchange",	&options.exchange,
					std.getopt.config.required,
					"use-ssl",	&options.useSSL,
					"binding-key",	&options.bindingKey,
					"cacert",	&options.caCert,
					"verify-peer",	&options.verifyPeer,
					"verify-hostname", &options.verifyHostname,
					"key-file",	&options.keyFile,
					"cert-file",	&options.certFile,
	);
	
	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("listen",helpInformation.options);
		return -1;
	}

	conn = amqp_new_connection();
	socket = options.useSSL ? amqp_ssl_socket_new(conn) : amqp_tcp_socket_new(conn);
	enforce(socket !is null, options.useSSL? "creating SSL/TLS socket" : "creating TCP socket");

	if (options.useSSL)
	{
		amqp_ssl_socket_set_verify_peer(socket, options.verifyPeer ? 1: 0);
		amqp_ssl_socket_set_verify_hostname(socket, options.verifyHostname ? 1 : 0);

		if (options.caCert.length > 0)
		{
			enforce(amqp_ssl_socket_set_cacert(socket, options.caCert.toStringz) == 0, "setting CA certificate");
		}

		if (options.keyFile.length > 0)
		{
			enforce (options.certFile.length > 0, "if you specify key-file you must specify cert-file");
			enforce( amqp_ssl_socket_set_key(socket, options.certFile.toStringz, options.keyFile.toStringz) == 0, "setting client cert");
		}
		else
		{
			enforce(options.certFile.length == 0, "you cannot specify cert-file if you do not specify key-file");
		}
	}

	status = amqp_socket_open(socket, options.hostname.toStringz, options.port);
	enforce(status	== 0, "opening socket: " ~ amqp_error_string2(status).fromStringz);

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	{
		amqp_queue_declare_ok_t *r = amqp_queue_declare(conn, 1, cast(amqp_bytes_t)amqp_empty_bytes, 0, 0, 0, 1, cast(amqp_table_t) amqp_empty_table);
		die_on_amqp_error(amqp_get_rpc_reply(conn), "Declaring queue");
		queuename = amqp_bytes_malloc_dup(r.queue);
		enforce(queuename.bytes !is null, "Out of memory while copying queue name");
	}

	amqp_queue_bind(conn, 1, queuename, amqp_string(options.exchange), amqp_string(options.bindingKey), cast(amqp_table_t) amqp_empty_table);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Binding queue");

	amqp_basic_consume(conn, 1, queuename, cast(amqp_bytes_t) amqp_empty_bytes, 0, 1, 0, cast(amqp_table_t) amqp_empty_table);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Consuming");

	{
		for (;;)
		{
			amqp_rpc_reply_t res;
			amqp_envelope_t envelope;

			amqp_maybe_release_buffers(conn);

			res = amqp_consume_message(conn, &envelope, null, 0);

			if (AMQP_RESPONSE_NORMAL != res.reply_type) {
				break;
			}

			writefln("Delivery %s, exchange %s routingkey %s",
			     envelope.delivery_tag,
			     fromBytes(envelope.exchange.bytes,envelope.exchange.len),
			     fromBytes(envelope.routing_key.bytes, envelope.routing_key.len));

			if (envelope.message.properties._flags & AMQP_BASIC_CONTENT_TYPE_FLAG) {
				writefln("Content-type: %s", fromBytes(envelope.message.properties.content_type.bytes,
						envelope.message.properties.content_type.len));
			}
			writef("----\n");
			amqp_dump(cast(ubyte[])fromBytes(envelope.message.body_.bytes,envelope.message.body_.len));
			amqp_destroy_envelope(&envelope);
		}
	}

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");

	return 0;
}

private char[] fromBytes(void* ptr, ulong len)
{
	return (cast(char*)ptr)[0..len].dup;
	/+
	import std.array:Appender;
	Appender!(char[]) ret;
	auto cPtr = cast(char*) ptr;
	foreach(i; 0 .. len)
		ret.put(cPtr[len]);
	writefln("fromBytes: %s, %s, %s ",len, (cast(char*)ptr)[0..len],ret.data);
	return ret.data;
	+/
}

