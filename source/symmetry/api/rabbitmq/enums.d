module symmetry.api.rabbitmq.enums;
import symmetry.api.rabbitmq.bindings;

enum RabbitStatus
{
  replySuccess = AMQP_REPLY_SUCCESS,
  contentTooLarge = AMQP_CONTENT_TOO_LARGE,
  noRoute = AMQP_NO_ROUTE,
  noConsumers = AMQP_NO_CONSUMERS,
  accessRefused = AMQP_ACCESS_REFUSED,
  notFound = AMQP_NOT_FOUND,
  resourceLocked = AMQP_RESOURCE_LOCKED,
  preconditionFailed = AMQP_PRECONDITION_FAILED,
  connectionForced = AMQP_CONNECTION_FORCED,
  invalidPath = AMQP_INVALID_PATH,
  frameError = AMQP_FRAME_ERROR,
  syntaxError = AMQP_SYNTAX_ERROR,
  commandInvalid = AMQP_COMMAND_INVALID,
  channelError = AMQP_CHANNEL_ERROR,
  unexpectedFrame = AMQP_UNEXPECTED_FRAME,
  resourceError = AMQP_RESOURCE_ERROR,
  notAllowed = AMQP_NOT_ALLOWED,
  notImplemented = AMQP_NOT_IMPLEMENTED,
  internalError = AMQP_INTERNAL_ERROR,
}

enum RabbitFrameFieldType
{
  method = AMQP_FRAME_METHOD,
  header = AMQP_FRAME_HEADER,
  body_ =  AMQP_FRAME_BODY,
  heartbeat = AMQP_FRAME_HEARTBEAT,
  minSize = AMQP_FRAME_MIN_SIZE,
  end = AMQP_FRAME_END,
}

enum RabbitConnectionMethod
{
  start = AMQP_CONNECTION_START_METHOD,
  startOkay = AMQP_CONNECTION_START_OK_METHOD,
  secure = AMQP_CONNECTION_SECURE_METHOD,
  secureOkay = AMQP_CONNECTION_SECURE_OK_METHOD,
  tuneMethod = AMQP_CONNECTION_TUNE_METHOD,
  tuneOkay = AMQP_CONNECTION_TUNE_OK_METHOD,
  open = AMQP_CONNECTION_OPEN_METHOD,
  openOkay = AMQP_CONNECTION_OPEN_OK_METHOD,
  close = AMQP_CONNECTION_CLOSE_METHOD,
  closeOkay = AMQP_CONNECTION_CLOSE_OK_METHOD,
}

enum RabbitChannelMethod
{
  open = AMQP_CHANNEL_OPEN_METHOD,
  openOkay = AMQP_CHANNEL_OPEN_OK_METHOD,
  flow = AMQP_CHANNEL_FLOW_METHOD,
  flowOkay = AMQP_CHANNEL_FLOW_OK_METHOD,
  close = AMQP_CHANNEL_CLOSE_METHOD,
  closeOkay = AMQP_CHANNEL_CLOSE_OK_METHOD,
}

enum RabbitAccessMethod
{
  request = AMQP_ACCESS_REQUEST_METHOD,
  requestOkay = AMQP_ACCESS_REQUEST_OK_METHOD,
}

enum RabbitExchangeMethod
{
  declare = AMQP_EXCHANGE_DECLARE_METHOD,
  declareOkay = AMQP_EXCHANGE_DECLARE_OK_METHOD,
  exchangeDelete = AMQP_EXCHANGE_DELETE_METHOD,
  deleteOkay = AMQP_EXCHANGE_DELETE_OK_METHOD,
  bind = AMQP_EXCHANGE_BIND_METHOD,
  bindOkay = AMQP_EXCHANGE_BIND_OK_METHOD,
  unbind = AMQP_EXCHANGE_UNBIND_METHOD,
  unbindOkay = AMQP_EXCHANGE_UNBIND_OK_METHOD,
}

enum RabbitQueueMethod
{
  declare = AMQP_QUEUE_DECLARE_METHOD,
  declareOkay = AMQP_QUEUE_DECLARE_OK_METHOD,
  bind = AMQP_QUEUE_BIND_METHOD,
  bindOkay = AMQP_QUEUE_BIND_OK_METHOD,
  purge = AMQP_QUEUE_PURGE_METHOD,
  purgeOkay = AMQP_QUEUE_PURGE_OK_METHOD,
  delete_ = AMQP_QUEUE_DELETE_METHOD,
  deleteOkay = AMQP_QUEUE_DELETE_OK_METHOD,
  unbind = AMQP_QUEUE_UNBIND_METHOD,
  unbindOkay = AMQP_QUEUE_UNBIND_OK_METHOD,
}

enum RabbitBasicMethod
{
  qos  = AMQP_BASIC_QOS_METHOD,
  qosOkay = AMQP_BASIC_QOS_OK_METHOD,
  consume = AMQP_BASIC_CONSUME_METHOD,
  consumeOkay = AMQP_BASIC_CONSUME_OK_METHOD,
  basicCancel = AMQP_BASIC_CANCEL_METHOD,
  cancelOkay = AMQP_BASIC_CANCEL_OK_METHOD,
  publish = AMQP_BASIC_PUBLISH_METHOD,
  return_ = AMQP_BASIC_RETURN_METHOD,
  deliver = AMQP_BASIC_DELIVER_METHOD,
  get = AMQP_BASIC_GET_METHOD,
  getOkay = AMQP_BASIC_GET_OK_METHOD,
  getEmpty = AMQP_BASIC_GET_EMPTY_METHOD,
  ack = AMQP_BASIC_ACK_METHOD,
  reject = AMQP_BASIC_REJECT_METHOD,
  recoverAsync = AMQP_BASIC_RECOVER_ASYNC_METHOD,
  recover = AMQP_BASIC_RECOVER_METHOD,
  recoverOkay = AMQP_BASIC_RECOVER_OK_METHOD,
  nack = AMQP_BASIC_NACK_METHOD,
}

enum RabbitTxMethod
{
  select = AMQP_TX_SELECT_METHOD,
  selectOkay = AMQP_TX_SELECT_OK_METHOD,
  commit = AMQP_TX_COMMIT_METHOD,
  commitOkay = AMQP_TX_COMMIT_OK_METHOD,
  rollback = AMQP_TX_ROLLBACK_METHOD,
  rollbackOkay = AMQP_TX_ROLLBACK_OK_METHOD,
}

enum RabbitConfirmMethod
{
  select = AMQP_CONFIRM_SELECT_METHOD,
  selectOkay = AMQP_CONFIRM_SELECT_OK_METHOD,
}

enum RabbitClass
{
  connection = AMQP_CONNECTION_CLASS,
  channel = AMQP_CHANNEL_CLASS,
  access = AMQP_ACCESS_CLASS,
  exchange = AMQP_EXCHANGE_CLASS,
  queue = AMQP_QUEUE_CLASS,
  basic = AMQP_BASIC_CLASS,
  tx = AMQP_TX_CLASS,
  confirm = AMQP_CONFIRM_CLASS,
}

enum RabbitBasicFlag
{
  contentType = AMQP_BASIC_CONTENT_TYPE_FLAG,
  contentEncoding = AMQP_BASIC_CONTENT_ENCODING_FLAG,
  headers = AMQP_BASIC_HEADERS_FLAG,
  deliveryMode = AMQP_BASIC_DELIVERY_MODE_FLAG,
  priority = AMQP_BASIC_PRIORITY_FLAG,
  correlationID = AMQP_BASIC_CORRELATION_ID_FLAG,
  replyTo = AMQP_BASIC_REPLY_TO_FLAG,
  expiration = AMQP_BASIC_EXPIRATION_FLAG,
  messageID = AMQP_BASIC_MESSAGE_ID_FLAG,
  timeStamp = AMQP_BASIC_TIMESTAMP_FLAG,
  type = AMQP_BASIC_TYPE_FLAG,
  userID = AMQP_BASIC_USER_ID_FLAG,
  appID = AMQP_BASIC_APP_ID_FLAG,
  clusterID = AMQP_BASIC_CLUSTER_ID_FLAG,
}

enum RabbitFieldValueKind
{
  boolean = AMQP_FIELD_KIND_BOOLEAN,
  i8 = AMQP_FIELD_KIND_I8,
  u8 = AMQP_FIELD_KIND_U8,
  i16 = AMQP_FIELD_KIND_I16,
  u16 = AMQP_FIELD_KIND_U16,
  i32 = AMQP_FIELD_KIND_I32,
  u32 = AMQP_FIELD_KIND_U32,
  i64 = AMQP_FIELD_KIND_I64,
  u64 = AMQP_FIELD_KIND_U64,
  f32 = AMQP_FIELD_KIND_F32,
  f64 = AMQP_FIELD_KIND_F64,
  decimal = AMQP_FIELD_KIND_DECIMAL,
  utf8 = AMQP_FIELD_KIND_UTF8,
  array = AMQP_FIELD_KIND_ARRAY,
  timeStamp = AMQP_FIELD_KIND_TIMESTAMP,
  table = AMQP_FIELD_KIND_TABLE,
  void_ = AMQP_FIELD_KIND_VOID,
  bytes = AMQP_FIELD_KIND_BYTES,
}
enum RabbitResponseType
{
  none = AMQP_RESPONSE_NONE,
  normal = AMQP_RESPONSE_NORMAL,
  libraryException = AMQP_RESPONSE_LIBRARY_EXCEPTION,
  serverException = AMQP_RESPONSE_SERVER_EXCEPTION
}

enum RabbitSaslMethod
{
  plain = AMQP_SASL_METHOD_PLAIN
}

enum RabbitDeliveryMode:ubyte
{
    nonPersistent = 1,
    persistent = 2,
}
