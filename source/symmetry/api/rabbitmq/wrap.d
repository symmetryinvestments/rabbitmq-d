module symmetry.api.rabbitmq.wrap;
import std.exception;

import symmetry.api.rabbitmq.bindings;
import symmetry.api.rabbitmq.enums;
import symmetry.api.rabbitmq.utils;
import symmetry.api.rabbitmq.platform_utils;

private template from(string moduleName)
{
  mixin("import from = " ~ moduleName ~ ";");
}

amqp_bytes_t amqp_string(string s)
{
	import std.string: toStringz;
	return s.toStringz.amqp_cstring_bytes;
}

amqp_bytes_t asRabbit(ubyte[] buf)
{
	amqp_bytes_t ret;
	ret.len = buf.length;
	ret.bytes = cast(void*) buf.ptr;
	return ret;
}

private string asString(amqp_bytes_t buf)
{
	import std.conv : to;
	import std.exception : enforce;
    enforce(buf.bytes !is null);
	auto p = cast(char*)buf.bytes;
	return p[0..buf.len].to!string;
}


struct RabbitCredentials
{
	string user;
	string pass;
}

struct ConnectionParams
{
	string hostname;
	ushort port = 5672;
	RabbitCredentials credentials;
	string exchange;
	ushort channel =1 ;
	int connectionAttempts = 10;
	int socketTimeout = 1;
	bool useSSL = false;
	string caCert;
	bool verifyPeer = false;
	bool verifyHostname = false;
	string keyFile;
	string certFile;
	string rpcQueue;
}



amqp_basic_properties_t basicProperties(RabbitBasicFlag flags, string contentType, RabbitDeliveryMode deliveryMode, string replyTo, string correlationID)
{
	import std.experimental.logger: tracef;
	tracef("basic properties: %s",flags);
	amqp_basic_properties_t props = {
						_flags: 		flags,
						content_type:		amqp_string(contentType),
						delivery_mode:		deliveryMode,
						reply_to:		amqp_string(replyTo),
						correlation_id:		amqp_string(correlationID),
	};
	return props;
}

struct AmqpConnectionState
{
	amqp_connection_state_t conn;
	alias conn this;

	ushort channel;
	bool isChannelOpen = false;

	this(amqp_connection_state_t conn)
	{
		this.conn = conn;
	}

	void openChannel(ushort channel)
	{
		this.channel = channel;
		conn.amqp_channel_open(channel);
		die_on_amqp_error(amqp_get_rpc_reply(conn),"opening channel");
		this.isChannelOpen = true;
	}

	~this()
	{
		if(conn !is null)
		{
			if (isChannelOpen)
            {
                amqp_channel_close(conn,1,ReplySuccess);
                amqp_connection_close(conn,ReplySuccess);
                amqp_destroy_connection(conn);
                conn = null;
            }
		}
	}
}

final class AmqpConnection
{
	import std.typecons: RefCounted;
	RefCounted!AmqpConnectionState conn;
	alias conn this;

	this(AmqpConnectionState conn)
	{
		this.conn = conn;
	}

	ushort channel()
	{
		return conn.channel;
	}

	void openChannel(ushort channel)
	{
		conn.openChannel(channel);
	}

	amqp_socket_t* openSocket(string hostname, ushort port, bool useSSL, bool verifyPeer, bool verifyHostname, string caCert, string certFile, string keyFile)
	{
		import std.experimental.logger : tracef;
		import std.string: toStringz;
		import std.exception : enforce;
		import std.format: format;
		tracef("opening new socket: hostname(%s), useSSL (%s), verifyPeer(%s), verifyHostName(%s), caCert(%s), certFile(%s), keyFile(%s)",
				hostname, useSSL,verifyPeer,verifyHostname,caCert,certFile, keyFile);
		enforce(conn !is null, "connection is null");
		version(OpenSSL)
			amqp_socket_t* socket = useSSL ? amqp_ssl_socket_new(conn) : amqp_tcp_socket_new(conn);
		else
		{
			enforce(!useSSL, "must build rabbitmq-d with OpenSSL version enabled");
			amqp_socket_t* socket = amqp_tcp_socket_new(conn);
		}
		enforce(socket !is null, "creating rabbit socket");
		version(OpenSSL)
		{
			if (useSSL)
			{
				amqp_ssl_socket_set_verify_peer(socket, verifyPeer ? 1:0);
				amqp_ssl_socket_set_verify_hostname(socket, verifyHostname ? 1: 0);
				enforce((caCert.length == 0) || (amqp_ssl_socket_set_cacert(socket, caCert.toStringz) == 0), "setting CA certificate");
				enforce((keyFile.length ==0 || certFile.length > 0), "if you specify key-file you must also specify cert-file");
				enforce((keyFile.length ==0) ||
					(amqp_ssl_socket_set_key(socket, certFile.toStringz, keyFile.toStringz) == 0),
					"setting client cert");
			}
		}
		enforce(amqp_socket_open(socket,hostname.toStringz, port)==0,
					format!"opening rabbit connection: useSSL %s, verifyPeer %s, verifyHostName %s, caCert %s, keyFile %s"
					(useSSL,verifyPeer,verifyHostname,caCert,keyFile)
		);
		return socket;
	}

	void login(string vhost, int channelMax, int frameMax, int heartBeat, SaslMethod saslMethod, string user, string pass)
	{
		import std.experimental.logger:infof;
		import std.range:repeat;
		import std.exception : enforce;
		import std.string: toStringz;
		infof("logging in as user %s, pass %s",user,'*'.repeat(pass.length));
		enforce(conn !is null, "connection is null");
		const(char)* pVhost = vhost.toStringz;
		const(char)* pUser = user.toStringz;
		const(char)* pPass = pass.toStringz;
		die_on_amqp_error(amqp_login(conn,pVhost,channelMax,frameMax,heartBeat,saslMethod,pUser,pPass),"Logging in");
	}

	void consumeQueue(string queueName, bool noLocal, bool noAck, bool exclusive)
	{
		import std.experimental.logger;
		import std.exception : enforce;
		tracef("consuming queue: %s", queueName);
		enforce(conn !is null, "connection is null");
		auto consumerTag = amqp_empty_bytes;
		auto amqpArguments = amqp_empty_table;

		auto tag = conn.amqp_basic_consume(channel,amqp_string(queueName),consumerTag,noLocal?1:0,noAck?1:0,exclusive?1:0,amqpArguments);
		enforce(tag !is null && (tag.consumer_tag.len >0), "basic consume of response to rpc message - tag = " ~ tag.consumer_tag.asString);
		die_on_amqp_error(amqp_get_rpc_reply(conn),"consuming");
		tracef("consumer tag: %s", tag.consumer_tag.asString);
	}

	amqp_queue_declare_ok_t*
	declareQueue(string queue, bool isPassive, bool isDurable, bool isExclusive, bool autoDelete, bool noWait, amqp_table_t arguments)
	{
		import std.exception : enforce;
		enforce(conn !is null, "connection is null");
		amqp_queue_declare_t req;
		req.ticket = 0;
		req.queue = (queue.length ==0 ) ? amqp_empty_bytes : amqp_string(queue);
		req.passive = isPassive ? 1:0;
		req.durable = isDurable ? 1:0;
		req.exclusive = isExclusive ? 1:0;
		req.auto_delete = autoDelete ? 1:0;
		req.nowait = noWait ? 1:0;
		req.arguments = arguments;
		return cast(amqp_queue_declare_ok_t*) conn.amqp_simple_rpc_decoded(channel,AMQP_QUEUE_DECLARE_METHOD,AMQP_QUEUE_DECLARE_OK_METHOD,&req);
	}

	string declareReplyToQueue()
	{
		import std.string: fromStringz;
		import std.exception : enforce;
		enforce(conn !is null, "connection is null");
		enum isPassive = false;
		enum isDurable = false;
		enum isExclusive = true;
		enum autoDelete = false;
		enum noWait = false;

		auto r  = declareQueue(null,isPassive,isDurable,isExclusive,autoDelete,noWait,amqp_empty_table);
		enforce(r !is null, "declaring queue");
		die_on_amqp_error(amqp_get_rpc_reply(conn),"declaring queue");
		enforce(r.queue.bytes !is null, "reading queue name");
		return (cast(char*)r.queue.bytes).fromStringz.idup;
	}

	void basicPublish(string exchange, string routingKey, ref amqp_basic_properties_t props, string messageBody)
	{
		import std.exception : enforce;
		import std.experimental.logger: tracef;
		import std.string: toStringz;
		tracef("basicPublish - channel: %s,  exchange: %s, routingKey: %s, messageBody: %s",channel,exchange,routingKey,messageBody);
		enforce(conn !is null, "connection is null");
		enum mandatory = false;
		enum immediate = false;
		amqp_bytes_t message;
		message.bytes = cast(void*)messageBody.toStringz;
		message.len = messageBody.length+1;
		auto pExchange = (exchange.length ==0) ? amqp_empty_bytes : amqp_string(exchange);
		die_on_error(amqp_basic_publish(conn,channel,pExchange,amqp_string(routingKey),mandatory?1:0,immediate?1:0,&props,message), "publishing message");
		die_on_amqp_error(amqp_get_rpc_reply(conn),"publishing message");
	}

	static AmqpConnection newConnection()
	{
		import std.exception : enforce;
		auto c = amqp_new_connection();
		enforce(c!is null, "opening connection");
		return new AmqpConnection(AmqpConnectionState(c));
	}

	void maybeReleaseBuffers()
	{
		import std.exception : enforce;
		enforce(conn !is null, "connection is null");
		amqp_maybe_release_buffers(conn);
	}


	FrameResult simpleWaitFrame(from!"core.time".Duration duration = from!"core.time".Duration.init)
	{
		import std.exception : enforce;
		import core.time: Duration;
		import std.conv:to;
		import std.experimental.logger:trace,tracef;
		FrameResult ret;
		timeval timeout;

		if(duration != Duration.init)
		{
			auto splitDuration = duration.split!("seconds","usecs");
			timeout.tv_sec = splitDuration.seconds.to!int;
			timeout.tv_usec = splitDuration.usecs.to!int;
		}

		version(TraceFrame) tracef("waiting for frame");
		enforce(conn !is null, "connection is null");
		ret.result = (duration == Duration.init) ? 	amqp_simple_wait_frame(conn,&ret.frame) :
								amqp_simple_wait_frame_noblock(conn,&ret.frame,&timeout);
		version(TraceFrame) tracef("received frame - result: %s",ret.result);
		version(TraceFrame) tracef("Frame type: %s channel: %s", (ret.result < 0) ? '-' : ret.frame.frame_type,(ret.result<0)? 0: ret.frame.channel);
		return ret;
	}

	FrameResult getFrame(from!"core.time".Duration timeout = from!"core.time".Duration.init)
	{
		version(HaveVibe) import vibe.core.core:yield;
		import std.experimental.logger:trace,tracef;
		import core.time:dur, Duration;
		import std.datetime:Clock;
		import std.exception : enforce;
		enforce(conn !is null, "connection is null");
		FrameResult frame;
		enum duration = dur!"msecs"(100);
		auto startTime = Clock.currTime(); // TODO - monotime
		Duration elapsedTime;
		do
		{
			version(HaveVibe) yield();
			frame = simpleWaitFrame(duration);
			auto nowTime = Clock.currTime();
			elapsedTime = nowTime - startTime;
		} while(frame.result == AMQP_STATUS_TIMEOUT && ((timeout == Duration.init)||(elapsedTime<timeout)));
		if (timeout != Duration.init && elapsedTime >= timeout)
			return frame;
		if(frame.result >=0 && frame.frame.isBasicDeliverMethod)
		{
			amqp_basic_deliver_t* d= basicDeliver(frame.frame);
			tracef("Delivery: %s exchange: %s routingKey: %s", d.delivery_tag, d.getExchange, d.routingKey);
			auto p = basicProperties(frame.frame);
			if(p.hasBasicContent)
				tracef("Content-type: %s",  p.contentType);
		}
		return frame;
	}

	string getBody(size_t bodyTarget,from!"core.time".Duration timeout = from!"core.time".Duration.init)
	{
		import std.experimental.logger:trace,tracef;
		import std.array:Appender;
		import std.exception : enforce;
		import std.format: format;
		Appender!string ret;

		enforce(conn !is null, "connection is null");
		size_t bodyReceived = 0;
		FrameResult frame;
		do
		{
			frame = getFrame(timeout);
			if (frame.result <0)
			{
				tracef("result code %s when receiving frame body", frame.result);
			}
			else
			{
				enforce(frame.frame.isBodyFrame, "expected body frame");
				bodyReceived += frame.frame.bodyFragmentLength;
				ret.put(frame.frame.bodyFragment);
				enforce(bodyReceived <=bodyTarget);
			}
		}
		while(frame.result >=0 && (bodyReceived < bodyTarget));
		enforce(bodyReceived == bodyTarget, format!"bodyReceived (%s) != bodyTarget(%s)"(bodyReceived,bodyTarget));
		return ret.data;
	}
}

struct FrameResult
{
	int result;
	amqp_frame_t frame;
}

struct CorrelationID
{
	string value;
}

struct RabbitClient
{
	AmqpConnection conn;
	amqp_socket_t* socket;
	ConnectionParams params;
	string replyToQueue;

	this(ConnectionParams params)
	{
		this.params = params;
	}

	private void openSocket()
	{
		import std.exception : enforce;
		import std.experimental.logger: tracef;
		tracef("opening new socket: %s",params);
		enforce(socket is null, "trying to openSocket when it is already open");
		conn = AmqpConnection.newConnection();
		socket = conn.openSocket(params.hostname,params.port,params.useSSL,params.verifyPeer,params.verifyHostname,params.caCert,params.certFile,params.keyFile);
	}

	private void login(string user, string pass)
	{
		conn.login("/",0,131_072,0,SaslMethod.plain,user,pass);
	}

	private void openChannel(ushort channel)
	{
		conn.openChannel(channel);
	}

	private void createReplyToQueue()
	{
		import std.experimental.logger;
		enum noLocal = true;	// do not send messages to connection that published them
		enum noAck = true;	// do not expect acknowledgements to messages
		enum exclusive = true;	// only this consumer can access the queue

		tracef("creating replyToQueue");
		tracef("first declaring replyToQueue");
		replyToQueue = conn.declareReplyToQueue();
        	tracef("declare succeeded - reply to queue:%s",replyToQueue);
        	tracef("consuming queue");
		conn.consumeQueue(replyToQueue,noLocal,noAck,exclusive);
	}

	CorrelationID sendMessage(string messageBody, string routingKey, string contentType = "text/plain")
	{
		import std.experimental.logger;
		import std.uuid: randomUUID;

		auto correlationID = randomUUID().toString();
		tracef("sending message: correlationID=%s,replyTo=%s,routingKey=%s",correlationID,replyToQueue,routingKey);

		enum deliveryMode = RabbitDeliveryMode.nonPersistent;
		enum property = RabbitBasicFlag.replyTo | RabbitBasicFlag.correlationID;
		static assert( property == 0x600, "properties do not line up with discovered property using wireshark");
		// NB I thought we needed to set basicContent and basicDeliveryMode too but apparently not

		auto props = basicProperties( property, contentType, deliveryMode, replyToQueue, correlationID);
		conn.basicPublish(params.exchange,routingKey,props, messageBody);
		tracef("sent message: %s",correlationID);
		return CorrelationID(correlationID);
	}

	string getResponseBlocking(CorrelationID correlationID = CorrelationID.init,
							from!"core.time".Duration timeout = from!"core.time".Duration.init)
	{
		version(HaveVibe) import vibe.core.core:yield;
		import std.exception : enforce;
		import std.experimental.logger:trace,tracef;
		bool exhausted = false, correlationIDMatch = false;
		FrameResult frameResult, frameHeader;
		do
		{
			trace("releasing buffers");
			conn.maybeReleaseBuffers();
			frameResult = conn.getFrame(timeout);
			exhausted = (frameResult.result < 0);
			if(!exhausted && frameResult.frame.isBasicDeliverMethod)
			{
				frameHeader = conn.getFrame(timeout);
				exhausted = exhausted || (frameHeader.result < 0);
				enforce(exhausted || frameHeader.frame.isFrameHeader, "Expected header");
				correlationIDMatch = !exhausted && (correlationID.value.length ==0 || frameHeader.frame.correlationID == correlationID.value);
			}
			version(HaveVibe) yield();
		} while (!exhausted && !correlationIDMatch);

		if (frameResult.result < 0 || frameHeader.result < 0)
			return "";

		size_t bodyTarget = frameHeader.frame.fullBodyLength();
		if (bodyTarget ==0)
		{
			tracef("bodyTarget is zero");
			return "";
		}
		return conn.getBody(bodyTarget);
	}

	void connect()
	{
		import std.exception : enforce;
		enforce(conn is null, "trying to connect to an open connection");
		openSocket();
		enforce(socket !is null, "could not open socket");
		login(params.credentials.user,params.credentials.pass);
		openChannel(params.channel);
		createReplyToQueue();
	}


	auto sendMessage(bool waitForResponse = true)(const(ubyte)[] message, string routingKey,
					from!"core.time".Duration timeout = from!"core.time".Duration.init,
					string contentType = "text/plain")
	{
		import std.exception : enforce;
		enforce(conn !is null, "trying to send a message to a null connection");
		enforce(socket !is null, "sending a message to a null socket");
		CorrelationID correlationID = sendMessage((cast(char[])message).idup,routingKey, contentType);
		static if (waitForResponse)
			return getResponseBlocking(correlationID,timeout);
		else
			return correlationID;
	}
}



private string correlationID(const(amqp_frame_t) frame)
{
	auto p = basicProperties(frame);
	return p.correlationID;
}


private string contentType(amqp_basic_properties_t* p)
{
	import std.exception : enforce;
    enforce(p !is null);
    enforce(p.content_type.bytes !is null);
	return p.content_type.asString;
}

private bool hasBasicContent(amqp_basic_properties_t* p)
{
	return  (p !is null && ((p._flags & AMQP_BASIC_CONTENT_TYPE_FLAG) == AMQP_BASIC_CONTENT_TYPE_FLAG));
}

private string correlationID(amqp_basic_properties_t* p)
{
	import std.exception : enforce;
    enforce(p !is null);
	return p.correlation_id.asString;
}

private bool isBasicDeliverMethod(amqp_frame_t frame)
{
	return (frame.frame_type == AMQP_FRAME_METHOD) && (frame.payload.method.id == AMQP_BASIC_DELIVER_METHOD);
}

private bool isFrameHeader(amqp_frame_t frame)
{
	return frame.frame_type == AMQP_FRAME_HEADER;
}

private size_t fullBodyLength(amqp_frame_t frame)
{
	return cast(size_t) frame.payload.properties.body_size;
}

private string bodyFragment(amqp_frame_t frame)
{
	import std.exception : enforce;
    enforce(frame.payload.body_fragment.bytes !is null);
	return frame.payload.body_fragment.asString;
}

private size_t bodyFragmentLength(amqp_frame_t frame)
{
	return frame.payload.body_fragment.len;
}

private bool isBodyFrame(amqp_frame_t frame)
{
	return frame.frame_type == AMQP_FRAME_BODY;
}

private amqp_basic_properties_t* basicProperties(const(amqp_frame_t) frame)
{
	// enforce(frame.payload.properties.decoded !is null);
	return cast(amqp_basic_properties_t*) frame.payload.properties.decoded;
}

private string routingKey(amqp_basic_deliver_t* deliver)
{
	import std.exception : enforce;
    enforce(deliver !is null);
    enforce(deliver.routing_key.bytes !is null);
	return deliver.routing_key.asString;
}

private string getExchange(amqp_basic_deliver_t* deliver)
{
	import std.exception : enforce;
    enforce(deliver !is null);
    enforce(deliver.exchange.bytes !is null);
	return deliver.exchange.asString;
}

private amqp_basic_deliver_t* basicDeliver(const(amqp_frame_t) frame)
{
	import std.exception : enforce;
	enforce(frame.payload.method.decoded !is null);
	return cast(amqp_basic_deliver_t*) frame.payload.method.decoded;
}

private string methodName(amqp_frame_t frame)
{
	import std.exception : enforce;
	import std.string:fromStringz;
	auto p = amqp_method_name(frame.payload.method.id);
    enforce(p !is null);
	return p.fromStringz.idup;
}


