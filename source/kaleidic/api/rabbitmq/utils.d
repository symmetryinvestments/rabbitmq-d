module kaleidic.api.rabbitmq.utils;
import kaleidic.api.rabbitmq;
public import kaleidic.api.rabbitmq.platform_utils;
import std.stdio:writeln,writef,stderr;
import std.ascii;
import core.stdc.stdarg;
import core.stdc.stdio:stderr,printf,vfprintf;
import std.exception;
import std.format:format;

/+
void die(T...)(string formatString,T args)
{
	stderr.writefln(formatString,args);
	throw new Exception("");
}

void die(const char *fmt, ...)
{
	import core.stdc.stdio:stderr;
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
+/
void die_on_error(int x, string context)
{
	import std.string:fromStringz;
	enforce(x>=0, format!"%s:%s"(context,amqp_error_string2(x).fromStringz));
}
void die_on_amqp_error(amqp_rpc_reply_t x, string context)
{
	import std.stdio:stderr;
	switch (x.reply_type) with (ResponseType)
	{
		case normal:
			return;

		case none:
			throw new Exception(format!"%s: missing RPC reply type!"(context));

/+		case libraryException:
			throw new Exception(format!"%s: %s"(context, amqp_error_string2(x.library_error)));

		case serverException:
			switch (x.reply.id) {
				case AMQP_CONNECTION_CLOSE_METHOD:
					amqp_connection_close_t *m = cast (amqp_connection_close_t *) x.reply.decoded;
					throw new Exception(format!"%s: server connection error %s, message: %.*s"(
						context, m.reply_code,
						cast(int) m.reply_text.len, cast(char *) m.reply_text.bytes));
    
				case AMQP_CHANNEL_CLOSE_METHOD:
				      amqp_channel_close_t *m = cast(amqp_channel_close_t *) x.reply.decoded;
				      throw new Exception(format!"%s: server channel error %uh, message: %.*s"(
					      context,
					      m.reply_code,
					      cast(int) m.reply_text.len, cast(char *) m.reply_text.bytes));
			    default:
			      throw new Exception(format!"%s: unknown server error, method id 0x%08X"(context, x.reply.id));
		    }
+/
		default:
		    break;
	}
	throw new Exception(format!"unknown Response Type: %s"(x.reply_type));
}
void dump_row(long count, int numinrow, int *chs)
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
      if (isAlphaNum(chs[i])) {
        printf("%c", chs[i]);
      } else {
        printf(".");
      }
    }
  }
  printf("\n");
}

int rows_eq(int *a, int *b)
{
  int i;

  for (i=0; i<16; i++)
    if (a[i] != b[i]) {
      return 0;
    }

  return 1;
}

void amqp_dump(ubyte[] buffer)
{
  char *buf = cast(char *) buffer.ptr;
  size_t len = buffer.length;
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
