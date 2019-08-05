module rabbitmq.examples.producer;
import std.stdio;
import std.string;
import std.exception;
import symmetry.api.rabbitmq;
import std.conv:to;

enum SUMMARY_EVERY_US = 1000000;

void sendBatch(amqp_connection_state_t conn, string queueName, int rateLimit, int messageCount)
{
	ulong startTime = now_microseconds();
	int sent = 0;
	int previousSent = 0;
	ulong previousReportTime = startTime;
	ulong nextSummaryTime = startTime + SUMMARY_EVERY_US;

	char[256] message;
	amqp_bytes_t message_bytes;

	for(int i = 0; i < message.length; i++)
	{
		message[i] = i & 0xff;
	}

	message_bytes.len = message.length;
	message_bytes.bytes = message.ptr;

	for (int i = 0; i < messageCount; i++)
	{
		ulong now = now_microseconds();
		die_on_error(amqp_basic_publish(conn,
				    1,
				    amqp_string("amq.direct"),
				    amqp_string(queueName),
				    0,
				    0,
				    null,
				    message_bytes),
		 "Publishing");
		sent++;

		if (now > nextSummaryTime)
		{
			int countOverInterval = sent - previousSent;
			double intervalRate = countOverInterval / ((now - previousReportTime) / 1000000.0);
			writefln("%s ms: Sent %s - %s since last report (%s Hz)",
				(now - startTime) / 1000, sent, countOverInterval, intervalRate);

			previousSent = sent;
			previousReportTime = now;
			nextSummaryTime += SUMMARY_EVERY_US;
		}

		while (((i * 1000000.0) / (now - startTime)) > rateLimit) {
			microsleep(2000);
			now = now_microseconds();
		}
	}

	ulong stopTime = now_microseconds();
	int totalDelta = (stopTime - startTime).to!int;

	writefln("PRODUCER - Message count: %s", messageCount);
	writefln("Total time, milliseconds: %s", totalDelta / 1000);
	writefln("Overall messages-per-second: %s", (messageCount / (totalDelta / 1000000.0)));
}

struct Options
{
	string hostname;
	ushort port;
	int rateLimit;
	int messageCount;
	string caCert;
	bool verifyPeer;
	bool verifyHostname;
	string keyFile;
	string certFile;
}

int main(string[] args)
{
	import std.stdio: stderr, writef, writefln;
	import std.conv:to;
	import std.getopt;

	int status;
	Options options;
	amqp_socket_t *socket;
	amqp_connection_state_t conn;

	auto helpInformation = getopt(	args,
					"hostname",		&options.hostname,
					"port",			&options.port,
					"rate-limit",		&options.rateLimit,
					"message-count",	&options.messageCount,
					"cacert",		&options.caCert,
					"verify-peer",		&options.verifyPeer,
					"verify-hostname",	&options.verifyHostname,
					"key-file",		&options.keyFile,
					"cert-file",		&options.certFile,
	);

	if (helpInformation.helpWanted)
	{
		defaultGetoptPrinter("amqp_producer", helpInformation.options);
		return -1;
	}

	if (args.length < 5) {
		stderr.writef("Usage: amqp_producer host port rate_limit message_count " ~
		"[cacert.pem [verifypeer] [verifyhostname] [key.pem cert.pem]]\n");
		return 1;
	}

	options.hostname = args[1];
	options.port = args[2].to!ushort;
	options.rateLimit = args[3].to!int;
	options.messageCount = args[4].to!int;

	conn = amqp_new_connection();

	socket = amqp_ssl_socket_new(conn);
	enforce(socket !is null, "creating SSL/TLS socket");

	amqp_ssl_socket_set_verify_peer(socket, options.verifyPeer? 1: 0);
	amqp_ssl_socket_set_verify_hostname(socket, options.verifyHostname ? 1: 0);
	
	if(options.caCert.length >0)
	{
		status = amqp_ssl_socket_set_cacert(socket, options.caCert.toStringz);
		enforce(status == 0, "setting CA certificate");
	}

	if (options.keyFile.length > 0)
	{
		enforce(options.certFile.length > 0, "must specify a cert-file if you specify a key-file");
		status = amqp_ssl_socket_set_key(socket, options.certFile.toStringz, options.keyFile.toStringz);
		enforce(status ==0, "setting client cert");
	}
	else
	{
		enforce(options.certFile.length ==0, "must specify a key-file if you specify a cert-file");
	}

	status = amqp_socket_open(socket, options.hostname.toStringz, options.port);
	enforce(status == 0, "opening SSL/TLS connection");

	die_on_amqp_error(amqp_login(conn, "/".ptr, 0, 131072, 0, SaslMethod.plain, "guest".ptr, "guest".ptr), "Logging in");
	amqp_channel_open(conn, 1);
	die_on_amqp_error(amqp_get_rpc_reply(conn), "Opening channel");

	sendBatch(conn, "test queue", options.rateLimit, options.messageCount);

	die_on_amqp_error(amqp_channel_close(conn, 1, ReplySuccess), "Closing channel");
	die_on_amqp_error(amqp_connection_close(conn, ReplySuccess), "Closing connection");
	die_on_error(amqp_destroy_connection(conn), "Ending connection");
	return 0;
}
