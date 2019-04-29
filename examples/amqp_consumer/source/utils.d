import kaleidic.api.rabbitmq;
import std.stdio;
import std.ascii;
import core.stdc.stdarg;
import std.exception;
import std.format:format;

void die(const char *fmt, ...);
extern(C)
{
  ulong now_microseconds();
  void microsleep(int usec);
}


void die(const char *fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  vfprintf(stderr, fmt, ap);
  va_end(ap);
  throw new Exception("");
}

void die_on_error(int x, const(char) *context)
{
	enforce(x>=0, format!"%s: %s\n"(context, amqp_error_string2(x)));
}

void die_on_amqp_error(amqp_rpc_reply_t x, const(char) *context)
{
  switch (x.reply_type) with (ResponseType)
  {
	  case normal:
    return;

	  case none:
    stderr.writef("%s: missing RPC reply type!\n", context);
    break;

	  case libraryException:
    stderr.writef("%s: %s\n", context, amqp_error_string2(x.library_error));
    break;

	  case serverException:
    switch (x.reply.id) {
    case AMQP_CONNECTION_CLOSE_METHOD:
      amqp_connection_close_t *m = cast (amqp_connection_close_t *) x.reply.decoded;
      stderr.writef("%s: server connection error %uh, message: %.*s\n",
              context,
              m.reply_code,
              cast(int) m.reply_text.len, cast(char *) m.reply_text.bytes);
      break;
        default:
          break;

    case AMQP_CHANNEL_CLOSE_METHOD:
      amqp_channel_close_t *m = cast(amqp_channel_close_t *) x.reply.decoded;
      stderr.writef("%s: server channel error %uh, message: %.*s\n",
              context,
              m.reply_code,
              cast(int) m.reply_text.len, cast(char *) m.reply_text.bytes);
      break;

    default:
      stderr.writef("%s: unknown server error, method id 0x%08X\n", context, x.reply.id);
      break;
    }
    break;
  }

  throw new Exception("");
}

static void dump_row(long count, int numinrow, int *chs)
{
  int i;

  printf("%08lX:", count - numinrow);

  if (numinrow > 0) {
    for (i = 0; i < numinrow; i++) {
      if (i == 8) {
        printf(" :");
      }
      printf(" %02X", chs[i]);
    }
    for (i = numinrow; i < 16; i++) {
      if (i == 8) {
        printf(" :");
      }
      printf("   ");
    }
    printf("  ");
    for (i = 0; i < numinrow; i++) {
      if (isAlphaNumeric(chs[i])) {
        printf("%c", chs[i]);
      } else {
        printf(".");
      }
    }
  }
  printf("\n");
}

static int rows_eq(int *a, int *b)
{
  int i;

  for (i=0; i<16; i++)
    if (a[i] != b[i]) {
      return 0;
    }

  return 1;
}

void amqp_dump(const(void)*buffer, size_t len)
{
  char *buf = cast(char *) buffer;
  long count = 0;
  int numinrow = 0;
  int[16] chs;
  int[16] oldchs;
  int showed_dots;
  size_t i;

  for (i = 0; i < len; i++) {
    int ch = buf[i];

    if (numinrow == 16) {
      int j;

      if (rows_eq(oldchs.ptr, chs.ptr)) {
        if (!showed_dots) {
          showed_dots = 1;
          printf("          .. .. .. .. .. .. .. .. : .. .. .. .. .. .. .. ..\n");
        }
      } else {
        showed_dots = 0;
        dump_row(count, numinrow, chs.ptr);
      }

      for (j=0; j<16; j++) {
        oldchs[j] = chs[j];
      }

      numinrow = 0;
    }

    count++;
    chs[numinrow++] = ch;
  }

  dump_row(count, numinrow, chs.ptr);

  if (numinrow != 0) {
    printf("%08lX:\n", count);
  }
}
