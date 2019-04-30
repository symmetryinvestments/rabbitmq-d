module rpc_client_sendstring;
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
	bool useSSL = false;
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
	amqp_bytes_t reply_to_queue;

	auto helpInformation = getopt(	args,
					"hostname",	&options.hostname,
					"port",		&options.port,
					"exchange",	&options.exchange,
					"routing-key",	&options.routingKey,
					"message-body",	&options.messageBody,
					"use-ssl",	&options.useSSL,
					"cacert",	&options.caCert,
					"verify-peer",	&options.verifyPeer,
					"verify-hostname", &options.verifyHostname,
					"key-file",	&options.keyFile,
					"cert-file",	&options.certFile
	);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("rpc_client_sendstring",helpInformation.options);
		return -1;
	}

	conn = amqp_new_connection();
	socket = options.useSSL ? amqp_ssl_socket_new(conn): amqp_tcp_socket_new(conn);
	enforce(socket !is null, options.useSSL? "creating ssl/tls socket" : "creating tcp socket");

	if(options.useSSL)
	{
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
	}

	enforce(amqp_socket_open(socket, options.hostname.toStringz, options.port) == 0, "opening connection");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");
	
	// create private reply_to queue
	{
		amqp_queue_declare_ok_t* r = amqp_queue_declare(conn,1,amqp_empty_bytes, 0,0,0,1,amqp_empty_table);
		die_on_amqp_error(amqp_get_rpc_reply(conn),"Declaring queue");
		reply_to_queue = amqp_bytes_malloc_dup(r.queue);
		enforce(reply_to_queue.bytes !is null, "out of memory whilst copying queue name");
	}

	// send the message
	{
		amqp_basic_properties_t props;
		props._flags = AMQP_BASIC_CONTENT_TYPE_FLAG | AMQP_BASIC_DELIVERY_MODE_FLAG | AMQP_BASIC_REPLY_TO_FLAG |
				AMQP_BASIC_CORRELATION_ID_FLAG;
		props.content_type = amqp_string("text/plain");
		props.delivery_mode = 2; /* persistent delivery mode */
		props.reply_to = amqp_bytes_malloc_dup(reply_to_queue);
		enforce(props.reply_to.bytes !is null, "out of memory whilst copying queue name");
		props.correlation_id = amqp_string("1");

		// publish
		die_on_error(amqp_basic_publish(conn,
					    1,
					    amqp_string(options.exchange),
					    amqp_string(options.routingKey),
					    0,
					    0,
					    &props,
					    amqp_string(options.messageBody)),
			 "Publishing");
		amqp_bytes_free(props.reply_to);
	}
	
	// wait for an answer
	{
		amqp_basic_consume(conn,1,reply_to_queue,amqp_empty_bytes,0,1,0,amqp_empty_table);
		die_on_amqp_error(amqp_get_rpc_reply(conn),"Consuming");
		amqp_bytes_free(reply_to_queue);
		{
			amqp_frame_t frame;
			int result;

			amqp_basic_deliver_t* d;
			amqp_basic_properties_t* p;
			size_t body_target;
			size_t body_received;
			for (;;)
			{
				amqp_maybe_release_buffers(conn);
				result = amqp_simple_wait_frame(conn,&frame);
				writefln("Result: %s",result);
				if(result < 0)
					break;

				writefln("Frame type: %s channel: %s", frame.frame_type,frame.channel);
				if (frame.frame_type != AMQP_FRAME_METHOD)
					continue;
				writefln("Method: %s",amqp_method_name(frame.payload.method.id).fromStringz);
				if (frame.payload.method.id !=AMQP_BASIC_DELIVER_METHOD)
					continue;

				d= cast(amqp_basic_deliver_t*) frame.payload.method.decoded;

				writefln("Delivery: %s exchange: %s routingKey: %s", d.delivery_tag,
					asString(d.exchange), asString(d.routing_key));

				result = amqp_simple_wait_frame(conn,&frame);
				if (result < 0)
					break;
				enforce(frame.frame_type == AMQP_FRAME_HEADER, "Expected header");
				p = cast(amqp_basic_properties_t*) frame.payload.properties.decoded;
				if (p._flags & AMQP_BASIC_CONTENT_TYPE_FLAG)
				{
					writefln("Content-type: %s", p.content_type.asString);
				}
				writefln("----");

				body_target = cast(size_t) frame.payload.properties.body_size;
				body_received = 0;

				while(body_received < body_target)
				{
					result = amqp_simple_wait_frame(conn,&frame);
					if (result <0)
						break;
					enforce(frame.frame_type == AMQP_FRAME_BODY, "expected body");
					body_received += frame.payload.body_fragment.len;
					enforce(body_received <=body_target);
					amqp_dump((cast(ubyte*)frame.payload.body_fragment.bytes)[0..frame.payload.body_fragment.len]);
				}
				if (body_received !=body_target)
					break;
				break;
			}
		}

	}
	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	return 0;
}

string asString(amqp_bytes_t bytes)
{
	return (cast(char*)bytes.bytes)[0..bytes.len].idup;
}
