module kaleidic.api.rabbitmq;
version(OpenSSL)
{
	import deimos.openssl.x509v3;
	import deimos.openssl.bio;
}
import core.stdc.string:memcpy;
alias ssize_t= long; // FIXME
struct amqp_time_t {}
struct pthread_mutex_t {}

alias DWORD=int;

version(Posix)
{
	// import pthread;
	public import core.sys.posix.sys.time: timeval;
}

else version(Windows)
{
	public import core.sys.windows.winsock2: timeval;
}

/+
import limits;



// 7.18.1.2 Minimum-width integer types
typedef char    int_least8_t;
typedef short   int_least16_t;
typedef int   int_least32_t;
typedef long   int_least64_t;
typedef ubyte   uint_least8_t;
typedef ushort  uint_least16_t;
typedef uint  uint_least32_t;
typedef ulong  uint_least64_t;

// 7.18.1.3 Fastest minimum-width integer types
typedef char    int_fast8_t;
typedef short   int_fast16_t;
typedef int   int_fast32_t;
typedef long   int_fast64_t;
typedef ubyte   uint_fast8_t;
typedef ushort  uint_fast16_t;
typedef uint  uint_fast32_t;
typedef ulong  uint_fast64_t;

// 7.18.1.4 Integer types capable of holding object pointers
#ifdef _WIN64 // [
   typedef signed __int64    intptr_t;
   typedef unsigned __int64  uintptr_t;
#else // _WIN64 ][
   typedef _W64 signed int   intptr_t;
   typedef _W64 unsigned int uintptr_t;
#endif // _WIN64 ]

// 7.18.1.5 Greatest-width integer types
typedef long   intmax_t;
typedef ulong  uintmax_t;


// 7.18.2 Limits of specified-width integer types

#if !defined(__cplusplus) || defined(__STDC_LIMIT_MACROS) // [   See footnote 220 at page 257 and footnote 221 at page 259

// 7.18.2.1 Limits of exact-width integer types
enum INT8_MIN     ((char)_I8_MIN)
enum INT8_MAX     _I8_MAX
enum INT16_MIN    ((short)_I16_MIN)
enum INT16_MAX    _I16_MAX
enum INT32_MIN    ((int)_I32_MIN)
enum INT32_MAX    _I32_MAX
enum INT64_MIN    ((long)_I64_MIN)
enum INT64_MAX    _I64_MAX
enum UINT8_MAX    _UI8_MAX
enum UINT16_MAX   _UI16_MAX
enum UINT32_MAX   _UI32_MAX
enum UINT64_MAX   _UI64_MAX

// 7.18.2.2 Limits of minimum-width integer types
enum INT_LEAST8_MIN    INT8_MIN
enum INT_LEAST8_MAX    INT8_MAX
enum INT_LEAST16_MIN   INT16_MIN
enum INT_LEAST16_MAX   INT16_MAX
enum INT_LEAST32_MIN   INT32_MIN
enum INT_LEAST32_MAX   INT32_MAX
enum INT_LEAST64_MIN   INT64_MIN
enum INT_LEAST64_MAX   INT64_MAX
enum UINT_LEAST8_MAX   UINT8_MAX
enum UINT_LEAST16_MAX  UINT16_MAX
enum UINT_LEAST32_MAX  UINT32_MAX
enum UINT_LEAST64_MAX  UINT64_MAX

// 7.18.2.3 Limits of fastest minimum-width integer types
enum INT_FAST8_MIN    INT8_MIN
enum INT_FAST8_MAX    INT8_MAX
enum INT_FAST16_MIN   INT16_MIN
enum INT_FAST16_MAX   INT16_MAX
enum INT_FAST32_MIN   INT32_MIN
enum INT_FAST32_MAX   INT32_MAX
enum INT_FAST64_MIN   INT64_MIN
enum INT_FAST64_MAX   INT64_MAX
enum UINT_FAST8_MAX   UINT8_MAX
enum UINT_FAST16_MAX  UINT16_MAX
enum UINT_FAST32_MAX  UINT32_MAX
enum UINT_FAST64_MAX  UINT64_MAX

// 7.18.2.4 Limits of integer types capable of holding object pointers
#ifdef _WIN64 // [
#  define INTPTR_MIN   INT64_MIN
#  define INTPTR_MAX   INT64_MAX
#  define UINTPTR_MAX  UINT64_MAX
#else // _WIN64 ][
#  define INTPTR_MIN   INT32_MIN
#  define INTPTR_MAX   INT32_MAX
#  define UINTPTR_MAX  UINT32_MAX
#endif // _WIN64 ]

// 7.18.2.5 Limits of greatest-width integer types
enum INTMAX_MIN   INT64_MIN
enum INTMAX_MAX   INT64_MAX
enum UINTMAX_MAX  UINT64_MAX

// 7.18.3 Limits of other integer types

#ifdef _WIN64 // [
#  define PTRDIFF_MIN  _I64_MIN
#  define PTRDIFF_MAX  _I64_MAX
#else  // _WIN64 ][
#  define PTRDIFF_MIN  _I32_MIN
#  define PTRDIFF_MAX  _I32_MAX
#endif  // _WIN64 ]

enum SIG_ATOMIC_MIN  INT_MIN
enum SIG_ATOMIC_MAX  INT_MAX

#ifndef SIZE_MAX // [
#  ifdef _WIN64 // [
#     define SIZE_MAX  _UI64_MAX
#  else // _WIN64 ][
#     define SIZE_MAX  _UI32_MAX
#  endif // _WIN64 ]
#endif // SIZE_MAX ]

// WCHAR_MIN and WCHAR_MAX are also defined in <wchar.h>
#ifndef WCHAR_MIN // [
#  define WCHAR_MIN  0
#endif  // WCHAR_MIN ]
#ifndef WCHAR_MAX // [
#  define WCHAR_MAX  _UI16_MAX
#endif  // WCHAR_MAX ]

enum WINT_MIN  0
enum WINT_MAX  _UI16_MAX

#endif // __STDC_LIMIT_MACROS ]


// 7.18.4 Limits of other integer types

#if !defined(__cplusplus) || defined(__STDC_CONSTANT_MACROS) // [   See footnote 224 at page 260

// 7.18.4.1 Macros for minimum-width integer constants

enum INT8_C(val)  val##i8
enum INT16_C(val) val##i16
enum INT32_C(val) val##i32
enum INT64_C(val) val##i64

enum UINT8_C(val)  val##ui8
enum UINT16_C(val) val##ui16
enum UINT32_C(val) val##ui32
enum UINT64_C(val) val##ui64

// 7.18.4.2 Macros for greatest-width integer constants
enum INTMAX_C   INT64_C
enum UINTMAX_C  UINT64_C

#endif // __STDC_CONSTANT_MACROS ]


#endif // _MSC_STDINT_H_ ]


/*
 * \internal
 * Important API decorators:
 *   - a public API function
 *  AMQP_PUBLIC_VARIABLE - a public API external variable
 *  - calling convension (used on Win32)
 */

#if defined(_WIN32) && defined(_MSC_VER)
# if defined(AMQP_BUILD) && !defined(AMQP_STATIC)
#  define  __declspec(dllexport)
#  define AMQP_PUBLIC_VARIABLE __declspec(dllexport) extern
# else
#  define 
#  if !defined(AMQP_STATIC)
#   define AMQP_PUBLIC_VARIABLE __declspec(dllimport) extern
#  else
#   define AMQP_PUBLIC_VARIABLE extern
#  endif
# endif
# define __cdecl

#elif defined(_WIN32) && defined(__BORLANDC__)
# if defined(AMQP_BUILD) && !defined(AMQP_STATIC)
#  define  __declspec(dllexport)
#  define AMQP_PUBLIC_VARIABLE __declspec(dllexport) extern
# else
#  define 
#  if !defined(AMQP_STATIC)
#   define AMQP_PUBLIC_VARIABLE __declspec(dllimport) extern
#  else
#   define AMQP_PUBLIC_VARIABLE extern
#  endif
# endif
# define __cdecl

#elif defined(_WIN32) && defined(__MINGW32__)
# if defined(AMQP_BUILD) && !defined(AMQP_STATIC)
#  define  __declspec(dllexport)
#  define AMQP_PUBLIC_VARIABLE __declspec(dllexport) extern
# else
#  define 
#  if !defined(AMQP_STATIC)
#   define AMQP_PUBLIC_VARIABLE __declspec(dllimport) extern
#  else
#   define AMQP_PUBLIC_VARIABLE extern
#  endif
# endif
# define __cdecl

#elif defined(_WIN32) && defined(__CYGWIN__)
# if defined(AMQP_BUILD) && !defined(AMQP_STATIC)
#  define  __declspec(dllexport)
#  define AMQP_PUBLIC_VARIABLE __declspec(dllexport)
# else
#  define 
#  if !defined(AMQP_STATIC)
#   define AMQP_PUBLIC_VARIABLE __declspec(dllimport) extern
#  else
#   define AMQP_PUBLIC_VARIABLE extern
#  endif
# endif
# define __cdecl

#elif defined(__GNUC__) && __GNUC__ >= 4
# define  \
  __attribute__ ((visibility ("default")))
# define AMQP_PUBLIC_VARIABLE \
  __attribute__ ((visibility ("default"))) extern
# define AMQP_CALL
#else
# define 
# define AMQP_PUBLIC_VARIABLE extern
# define AMQP_CALL
#endif

#if __GNUC__ > 3 || (__GNUC__ == 3 && __GNUC_MINOR__ >= 1)
# define AMQP_DEPRECATED(function) \
  function __attribute__ ((__deprecated__))
#elif defined(_MSC_VER)
# define AMQP_DEPRECATED(function) \
  __declspec(deprecated) function
#else
# define AMQP_DEPRECATED(function)
#endif

/* Define ssize_t on Win32/64 platforms
   See: http://lists.cs.uiuc.edu/pipermail/llvmdev/2010-April/030649.html for details
   */
#if !defined(_W64)
#if !defined(__midl) && (defined(_X86_) || defined(_M_IX86)) && _MSC_VER >= 1300
enum _W64 __w64
#else
enum _W64
#endif
#endif

typedef unsigned long long size_t;
typedef long long ssize_t;

#ifdef _MSC_VER
#ifdef _WIN64
typedef __int64 ssize_t;
#else
typedef _W64 int ssize_t;
#endif
#endif

#if defined(_WIN32) && defined(__MINGW32__)
#include <sys/types.h>
#endif

/** \endcond */
+/

extern(C):


enum AMQP_VERSION_MAJOR=0;
enum AMQP_VERSION_MINOR=8;
enum AMQP_VERSION_PATCH=1;
enum AMQP_VERSION_IS_RELEASE=0;

auto AMQP_VERSION_CODE(int major, int minor, int patch, int release)
{
  return 
    ((major << 24) | 
     (minor << 16) | 
     (patch << 8)  | 
     (release));
}



uint amqp_version_number();
const(char)* amqp_version();
enum AMQP_DEFAULT_FRAME_SIZE = 131072;
enum AMQP_DEFAULT_MAX_CHANNELS=0;
enum AMQP_DEFAULT_HEARTBEAT=0;
alias amqp_boolean_t = int;
alias amqp_method_number_t = uint;
alias amqp_flags_t = uint;
alias amqp_channel_t = ushort;

struct amqp_bytes_t
{
  size_t len;   /**< length of the buffer in bytes */
  void *bytes;  /**< pointer to the beginning of the buffer */
}

struct amqp_decimal_t
{
  ubyte decimals;   /**< the location of the decimal point */
  uint value;     /**< the value before the decimal point is applied */
}

struct amqp_table_t
{
  int num_entries;                      /**< length of entries array */
  amqp_table_entry_t* entries;  /**< an array of table entries */
}

struct amqp_array_t
{
  int num_entries;                      /**< Number of entries in the table */
  amqp_field_value_t* entries;  /**< linked list of field values */
}

struct amqp_field_value_t
{
  ubyte kind;             /**< the type of the entry /sa amqp_field_value_kind_t */
  union Value
  {
    amqp_boolean_t boolean;   /**< boolean type AMQP_FIELD_KIND_BOOLEAN */
    char i8;                /**< char type AMQP_FIELD_KIND_I8 */
    ubyte u8;               /**< ubyte type AMQP_FIELD_KIND_U8 */
    short i16;              /**< short type AMQP_FIELD_KIND_I16 */
    ushort u16;             /**< ushort type AMQP_FIELD_KIND_U16 */
    int i32;              /**< int type AMQP_FIELD_KIND_I32 */
    uint u32;             /**< uint type AMQP_FIELD_KIND_U32 */
    long i64;              /**< long type AMQP_FIELD_KIND_I64 */
    ulong u64;             /**< ulong type AMQP_FIELD_KIND_U64, AMQP_FIELD_KIND_TIMESTAMP */
    float f32;                /**< float type AMQP_FIELD_KIND_F32 */
    double f64;               /**< double type AMQP_FIELD_KIND_F64 */
    amqp_decimal_t decimal;   /**< amqp_decimal_t AMQP_FIELD_KIND_DECIMAL */
    amqp_bytes_t bytes;       /**< amqp_bytes_t type AMQP_FIELD_KIND_UTF8, AMQP_FIELD_KIND_BYTES */
    amqp_table_t table;       /**< amqp_table_t type AMQP_FIELD_KIND_TABLE */
    amqp_array_t array;       /**< amqp_array_t type AMQP_FIELD_KIND_ARRAY */
  }
  Value value;              /**< a union of the value */
}


struct amqp_table_entry_t
{
  amqp_bytes_t key;           /**< the table entry key. Its a null-terminated UTF-8 string,
                               * with a maximum size of 128 bytes */
  amqp_field_value_t value;   /**< the table entry values */
}

enum amqp_field_value_kind_t
{
  AMQP_FIELD_KIND_BOOLEAN = 't',  /**< boolean type. 0 = false, 1 = true @see amqp_boolean_t */
  AMQP_FIELD_KIND_I8 = 'b',       /**< 8-bit signed integer, datatype: char */
  AMQP_FIELD_KIND_U8 = 'B',       /**< 8-bit unsigned integer, datatype: ubyte */
  AMQP_FIELD_KIND_I16 = 's',      /**< 16-bit signed integer, datatype: short */
  AMQP_FIELD_KIND_U16 = 'u',      /**< 16-bit unsigned integer, datatype: ushort */
  AMQP_FIELD_KIND_I32 = 'I',      /**< 32-bit signed integer, datatype: int */
  AMQP_FIELD_KIND_U32 = 'i',      /**< 32-bit unsigned integer, datatype: uint */
  AMQP_FIELD_KIND_I64 = 'l',      /**< 64-bit signed integer, datatype: long */
  AMQP_FIELD_KIND_U64 = 'L',      /**< 64-bit unsigned integer, datatype: ulong */
  AMQP_FIELD_KIND_F32 = 'f',      /**< single-precision floating point value, datatype: float */
  AMQP_FIELD_KIND_F64 = 'd',      /**< double-precision floating point value, datatype: double */
  AMQP_FIELD_KIND_DECIMAL = 'D',  /**< amqp-decimal value, datatype: amqp_decimal_t */
  AMQP_FIELD_KIND_UTF8 = 'S',     /**< UTF-8 null-terminated character string, datatype: amqp_bytes_t */
  AMQP_FIELD_KIND_ARRAY = 'A',    /**< field array (repeated values of another datatype. datatype: amqp_array_t */
  AMQP_FIELD_KIND_TIMESTAMP = 'T',/**< 64-bit timestamp. datatype ulong */
  AMQP_FIELD_KIND_TABLE = 'F',    /**< field table. encapsulates a table inside a table entry. datatype: amqp_table_t */
  AMQP_FIELD_KIND_VOID = 'V',     /**< empty entry */
  AMQP_FIELD_KIND_BYTES = 'x'     /**< unformatted byte string, datatype: amqp_bytes_t */
}

struct amqp_pool_blocklist_t
{
  int num_blocks;     /**< Number of blocks in the block list */
  void **blocklist;   /**< Array of memory blocks */
}

struct amqp_pool_t
{
  size_t pagesize;            /**< the size of the page in bytes.
                               *  allocations less than or equal to this size are
                               *    allocated in the pages block list
                               *  allocations greater than this are allocated in their
                               *   own block in the large_blocks block list */

  amqp_pool_blocklist_t pages;        /**< blocks that are the size of pagesize */
  amqp_pool_blocklist_t large_blocks; /**< allocations larger than the pagesize */

  int next_page;      /**< an index to the next unused page block */
  char* alloc_block;  /**< pointer to the current allocation block */
  size_t alloc_used;  /**< number of bytes in the current allocation block that has been used */
}

struct amqp_method_t
{
  amqp_method_number_t id;      /**< the method id number */
  void* decoded;                /**< pointer to the decoded method,
                                 *    cast to the appropriate type to use */
}

struct amqp_frame_t
{
  ubyte frame_type;       /**< frame type. The types:
                             * - AMQP_FRAME_METHOD - use the method union member
                             * - AMQP_FRAME_HEADER - use the properties union member
                             * - AMQP_FRAME_BODY - use the body_fragment union member
                             */
  amqp_channel_t channel;   /**< the channel the frame was received on */
  union Payload
  {
    amqp_method_t method;   /**< a method, use if frame_type == AMQP_FRAME_METHOD */
    struct Properties
    {
      ushort class_id;    /**< the class for the properties */
      ulong body_size;   /**< size of the body in bytes */
      void *decoded;        /**< the decoded properties */
      amqp_bytes_t raw;     /**< amqp-encoded properties structure */
    }
    Properties properties;           /**< message header, a.k.a., properties,
                                  use if frame_type == AMQP_FRAME_HEADER */
    amqp_bytes_t body_fragment; /**< a body fragment, use if frame_type == AMQP_FRAME_BODY */
    struct ProtocolHeader 
    {
      ubyte transport_high;           /**< @internal first byte of handshake */
      ubyte transport_low;            /**< @internal second byte of handshake */
      ubyte protocol_version_major;   /**< @internal third byte of handshake */
      ubyte protocol_version_minor;   /**< @internal fourth byte of handshake */
    }
    ProtocolHeader protocol_header;    /**< Used only when doing the initial handshake with the broker,
                                don't use otherwise */
  }
  Payload payload;              /**< the payload of the frame */
}

enum
{
  AMQP_RESPONSE_NONE = 0,         /**< the library got an EOF from the socket */
  AMQP_RESPONSE_NORMAL,           /**< response normal, the RPC completed successfully */
  AMQP_RESPONSE_LIBRARY_EXCEPTION,/**< library error, an error occurred in the library, examine the library_error */
  AMQP_RESPONSE_SERVER_EXCEPTION  /**< server exception, the broker returned an error, check replay */
}

enum ResponseType
{
	none = AMQP_RESPONSE_NONE,
	normal = AMQP_RESPONSE_NORMAL,
	libraryException = AMQP_RESPONSE_LIBRARY_EXCEPTION,
	serverException = AMQP_RESPONSE_SERVER_EXCEPTION,
}

alias amqp_response_type_enum = ResponseType;


struct amqp_rpc_reply_t
{
  amqp_response_type_enum reply_type;   /**< the reply type:
                                         * - AMQP_RESPONSE_NORMAL - the RPC completed successfully
                                         * - AMQP_RESPONSE_SERVER_EXCEPTION - the broker returned
                                         *     an exception, check the reply field
                                         * - AMQP_RESPONSE_LIBRARY_EXCEPTION - the library
                                         *    encountered an error, check the library_error field
                                         */
  amqp_method_t reply;                  /**< in case of AMQP_RESPONSE_SERVER_EXCEPTION this
                                         * field will be set to the method returned from the broker */
  int library_error;                    /**< in case of AMQP_RESPONSE_LIBRARY_EXCEPTION this
                                         *    field will be set to an error code. An error
                                         *     string can be retrieved using amqp_error_string */
}

enum SaslMethod
{
	undefined = AMQP_SASL_METHOD_UNDEFINED,
	plain = AMQP_SASL_METHOD_PLAIN,
	external = AMQP_SASL_METHOD_EXTERNAL,
}
alias amqp_sasl_method_enum = SaslMethod;

enum
{
  AMQP_SASL_METHOD_UNDEFINED = -1, /**< Invalid SASL method */
  AMQP_SASL_METHOD_PLAIN = 0,      /**< the PLAIN SASL method for authentication to the broker */
  AMQP_SASL_METHOD_EXTERNAL = 1    /**< the EXTERNAL SASL method for authentication to the broker */
}

alias amqp_connection_state_t = amqp_connection_state_t_ *;
alias amqp_status_enum = int;

enum
{
  AMQP_STATUS_OK =                         0x0,     /**< Operation successful */
  AMQP_STATUS_NO_MEMORY =                 -0x0001,  /**< Memory allocation
                                                         failed */
  AMQP_STATUS_BAD_AMQP_DATA =             -0x0002, /**< Incorrect or corrupt
                                                        data was received from
                                                        the broker. This is a
                                                        protocol error. */
  AMQP_STATUS_UNKNOWN_CLASS =             -0x0003, /**< An unknown AMQP class
                                                        was received. This is
                                                        a protocol error. */
  AMQP_STATUS_UNKNOWN_METHOD =            -0x0004, /**< An unknown AMQP method
                                                        was received. This is
                                                        a protocol error. */
  AMQP_STATUS_HOSTNAME_RESOLUTION_FAILED= -0x0005, /**< Unable to resolve the
                                                    * hostname */
  AMQP_STATUS_INCOMPATIBLE_AMQP_VERSION = -0x0006, /**< The broker advertised
                                                        an incompaible AMQP
                                                        version */
  AMQP_STATUS_CONNECTION_CLOSED =         -0x0007, /**< The connection to the
                                                        broker has been closed
                                                        */
  AMQP_STATUS_BAD_URL =                   -0x0008, /**< malformed AMQP URL */
  AMQP_STATUS_SOCKET_ERROR =              -0x0009, /**< A socket error
                                                        occurred */
  AMQP_STATUS_INVALID_PARAMETER =         -0x000A, /**< An invalid parameter
                                                        was passed into the
                                                        function */
  AMQP_STATUS_TABLE_TOO_BIG =             -0x000B, /**< The amqp_table_t object
                                                        cannot be serialized
                                                        because the output
                                                        buffer is too small */
  AMQP_STATUS_WRONG_METHOD =              -0x000C, /**< The wrong method was
                                                        received */
  AMQP_STATUS_TIMEOUT =                   -0x000D, /**< Operation timed out */
  AMQP_STATUS_TIMER_FAILURE =             -0x000E, /**< The underlying system
                                                        timer facility failed */
  AMQP_STATUS_HEARTBEAT_TIMEOUT =         -0x000F, /**< Timed out waiting for
                                                        heartbeat */
  AMQP_STATUS_UNEXPECTED_STATE =          -0x0010, /**< Unexpected protocol
                                                        state */
  AMQP_STATUS_SOCKET_CLOSED =             -0x0011, /**< Underlying socket is
                                                        closed */
  AMQP_STATUS_SOCKET_INUSE =              -0x0012, /**< Underlying socket is
                                                        already open */
  AMQP_STATUS_BROKER_UNSUPPORTED_SASL_METHOD = -0x0013, /**< Broker does not
                                                          support the requested
                                                          SASL mechanism */
  AMQP_STATUS_UNSUPPORTED =               -0x0014, /**< Parameter is unsupported
                                                     in this version */
  _AMQP_STATUS_NEXT_VALUE =               -0x0015, /**< Internal value */

  AMQP_STATUS_TCP_ERROR =                 -0x0100, /**< A generic TCP error
                                                        occurred */
  AMQP_STATUS_TCP_SOCKETLIB_INIT_ERROR =  -0x0101, /**< An error occurred trying
                                                        to initialize the
                                                        socket library*/
  _AMQP_STATUS_TCP_NEXT_VALUE =           -0x0102, /**< Internal value */

  AMQP_STATUS_SSL_ERROR =                 -0x0200, /**< A generic SSL error
                                                        occurred. */
  AMQP_STATUS_SSL_HOSTNAME_VERIFY_FAILED= -0x0201, /**< SSL validation of
                                                        hostname against
                                                        peer certificate
                                                        failed */
  AMQP_STATUS_SSL_PEER_VERIFY_FAILED =    -0x0202, /**< SSL validation of peer
                                                        certificate failed. */
  AMQP_STATUS_SSL_CONNECTION_FAILED =     -0x0203, /**< SSL handshake failed. */
  _AMQP_STATUS_SSL_NEXT_VALUE =           -0x0204  /**< Internal value */
}

enum amqp_delivery_mode_enum
{
	AMQP_DELIVERY_NONPERSISTENT = 1, /**< Non-persistent message */
	AMQP_DELIVERY_PERSISTENT = 2 /**< Persistent message */
} 

// const causes problems with prototypes of functions
// const
__gshared amqp_bytes_t amqp_empty_bytes;
__gshared amqp_table_t amqp_empty_table;
__gshared amqp_array_t amqp_empty_array;

alias AMQP_EMPTY_BYTES= amqp_empty_bytes;
alias AMQP_EMPTY_TABLE= amqp_empty_table;
alias AMQP_EMPTY_ARRAY = amqp_empty_array;
void init_amqp_pool(amqp_pool_t *pool, size_t pagesize);
void recycle_amqp_pool(amqp_pool_t *pool);
void empty_amqp_pool(amqp_pool_t *pool);
void * amqp_pool_alloc(amqp_pool_t *pool, size_t amount);
void amqp_pool_alloc_bytes(amqp_pool_t *pool, size_t amount, amqp_bytes_t *output);
amqp_bytes_t amqp_cstring_bytes(const(char)* cstr);
amqp_bytes_t amqp_bytes_malloc_dup(amqp_bytes_t src);
amqp_bytes_t amqp_bytes_malloc(size_t amount);
void amqp_bytes_free(amqp_bytes_t bytes);
amqp_connection_state_t amqp_new_connection();
int amqp_get_sockfd(amqp_connection_state_t state);
void amqp_set_sockfd(amqp_connection_state_t state, int sockfd);
int amqp_tune_connection(amqp_connection_state_t state, int channel_max, int frame_max, int heartbeat);
int amqp_get_channel_max(amqp_connection_state_t state);
int amqp_get_frame_max(amqp_connection_state_t state);
int amqp_get_heartbeat(amqp_connection_state_t state);
int amqp_destroy_connection(amqp_connection_state_t state);
int amqp_handle_input(amqp_connection_state_t state, amqp_bytes_t received_data, amqp_frame_t *decoded_frame);
amqp_boolean_t amqp_release_buffers_ok(amqp_connection_state_t state);
void amqp_release_buffers(amqp_connection_state_t state);
void amqp_maybe_release_buffers(amqp_connection_state_t state);
void amqp_maybe_release_buffers_on_channel(amqp_connection_state_t state, amqp_channel_t channel);
int amqp_send_frame(amqp_connection_state_t state, const(amqp_frame_t)* frame);
int amqp_table_entry_cmp(const(void)* entry1, const(void)* entry2);
int amqp_open_socket(const(char)* hostname, int portnumber);
int amqp_send_header(amqp_connection_state_t state);
amqp_boolean_t amqp_frames_enqueued(amqp_connection_state_t state);
int amqp_simple_wait_frame(amqp_connection_state_t state, amqp_frame_t *decoded_frame);
int amqp_simple_wait_frame_noblock(amqp_connection_state_t state, amqp_frame_t *decoded_frame, timeval *tv);
int amqp_simple_wait_method(amqp_connection_state_t state, amqp_channel_t expected_channel, amqp_method_number_t expected_method, amqp_method_t *output);
int amqp_send_method(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t id, void *decoded);
amqp_rpc_reply_t amqp_simple_rpc(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t request_id, amqp_method_number_t *expected_reply_ids, void *decoded_request_method);
void * amqp_simple_rpc_decoded(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t request_id, amqp_method_number_t reply_id, void *decoded_request_method);
amqp_rpc_reply_t amqp_get_rpc_reply(amqp_connection_state_t state);
amqp_rpc_reply_t amqp_login(amqp_connection_state_t state, const(char)* vhost, int channel_max, int frame_max, int heartbeat, amqp_sasl_method_enum sasl_method, ...);
amqp_rpc_reply_t amqp_login_with_properties(amqp_connection_state_t state, const(char)* vhost, int channel_max, int frame_max, int heartbeat, const amqp_table_t *properties, amqp_sasl_method_enum sasl_method, ...);
int amqp_basic_publish(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t exchange, amqp_bytes_t routing_key,
                             amqp_boolean_t mandatory, amqp_boolean_t immediate, const(amqp_basic_properties_t)* properties, amqp_bytes_t body_);

amqp_rpc_reply_t amqp_channel_close(amqp_connection_state_t state, amqp_channel_t channel, int code);
amqp_rpc_reply_t amqp_connection_close(amqp_connection_state_t state, int code);
int amqp_basic_ack(amqp_connection_state_t state, amqp_channel_t channel, ulong delivery_tag, amqp_boolean_t multiple);
amqp_rpc_reply_t amqp_basic_get(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_boolean_t no_ack);
int amqp_basic_reject(amqp_connection_state_t state, amqp_channel_t channel, ulong delivery_tag, amqp_boolean_t requeue);
int amqp_basic_nack(amqp_connection_state_t state, amqp_channel_t channel, ulong delivery_tag, amqp_boolean_t multiple, amqp_boolean_t requeue);
amqp_boolean_t amqp_data_in_buffer(amqp_connection_state_t state);
char* amqp_error_string(int err);
const(char)* amqp_error_string2(int err);
int amqp_decode_table(amqp_bytes_t encoded, amqp_pool_t *pool, amqp_table_t *output, size_t *offset);
int amqp_encode_table(amqp_bytes_t encoded, amqp_table_t *input, size_t *offset);
int amqp_table_clone(const amqp_table_t *original, amqp_table_t *clone, amqp_pool_t *pool);


struct amqp_message_t
{
  amqp_basic_properties_t properties; /**< message properties */
  amqp_bytes_t body_;                  /**< message body */
  amqp_pool_t pool;                   /**< pool used to allocate properties */
}

amqp_rpc_reply_t amqp_read_message(amqp_connection_state_t state, amqp_channel_t channel, amqp_message_t *message, int flags);
void amqp_destroy_message(amqp_message_t *message);

struct amqp_envelope_t
{
  amqp_channel_t channel;           /**< channel message was delivered on */
  amqp_bytes_t consumer_tag;        /**< the consumer tag the message was delivered to */
  ulong delivery_tag;            /**< the messages delivery tag */
  amqp_boolean_t redelivered;       /**< flag indicating whether this message is being redelivered */
  amqp_bytes_t exchange;            /**< exchange this message was published to */
  amqp_bytes_t routing_key;         /**< the routing key this message was published with */
  amqp_message_t message;           /**< the message */
}

amqp_rpc_reply_t amqp_consume_message(amqp_connection_state_t state, amqp_envelope_t *envelope, timeval *timeout, int flags);
void amqp_destroy_envelope(amqp_envelope_t *envelope);


struct amqp_connection_info
{
  char *user;                 /**< the username to authenticate with the broker, default on most broker is 'guest' */
  char *password;             /**< the password to authenticate with the broker, default on most brokers is 'guest' */
  char *host;                 /**< the hostname of the broker */
  char *vhost;                /**< the virtual host on the broker to connect to, a good default is "/" */
  int port;                   /**< the port that the broker is listening on, default on most brokers is 5672 */
  amqp_boolean_t ssl;
}

void amqp_default_connection_info(amqp_connection_info* parsed);
int amqp_parse_url(char *url, amqp_connection_info* parsed);
int amqp_socket_open(amqp_socket_t *self, const(char)*host, int port);
int amqp_socket_open_noblock(amqp_socket_t *self, const(char)*host, int port, timeval* timeout);
int amqp_socket_get_sockfd(amqp_socket_t *self);
amqp_socket_t * amqp_get_socket(amqp_connection_state_t state);
amqp_table_t * amqp_get_server_properties(amqp_connection_state_t state);
amqp_table_t * amqp_get_client_properties(amqp_connection_state_t state);
timeval* amqp_get_handshake_timeout(amqp_connection_state_t state);
int amqp_set_handshake_timeout(amqp_connection_state_t state, timeval* timeout);
timeval* amqp_get_rpc_timeout(amqp_connection_state_t state);
int amqp_set_rpc_timeout(amqp_connection_state_t state, timeval* timeout);

amqp_socket_t * amqp_tcp_socket_new(amqp_connection_state_t state);
void amqp_tcp_socket_set_sockfd(amqp_socket_t *self, int sockfd);
amqp_table_entry_t amqp_table_construct_utf8_entry(const(char)*key, const(char)*value);
amqp_table_entry_t amqp_table_construct_table_entry(const(char)*key, const amqp_table_t *value);
amqp_table_entry_t amqp_table_construct_bool_entry(const(char)*key, const int value);
amqp_table_entry_t *amqp_table_get_entry_by_key(const amqp_table_t *table, const amqp_bytes_t key);

version(OpenSSL)
{
	amqp_socket_t * amqp_ssl_socket_new(amqp_connection_state_t state);
	int amqp_ssl_socket_set_cacert(amqp_socket_t *self, const(char)*cacert);
	int amqp_ssl_socket_set_key(amqp_socket_t *self, const(char)*cert, const(char)*key);
	int amqp_ssl_socket_set_key_buffer(amqp_socket_t *self, const(char)*cert, const void *key, size_t n);
	void amqp_ssl_socket_set_verify(amqp_socket_t *self, amqp_boolean_t verify);
	void amqp_ssl_socket_set_verify_peer(amqp_socket_t *self, amqp_boolean_t verify);
	void amqp_ssl_socket_set_verify_hostname(amqp_socket_t *self, amqp_boolean_t verify);

	enum  amqp_tls_version_t
	{
	  AMQP_TLSv1 = 1,
	  AMQP_TLSv1_1 = 2,
	  AMQP_TLSv1_2 = 3,
	  AMQP_TLSvLATEST = 0xFFFF
	}

	int amqp_ssl_socket_set_ssl_versions(amqp_socket_t *self, amqp_tls_version_t min, amqp_tls_version_t max);
	void amqp_set_initialize_ssl_library(amqp_boolean_t do_initialize);
}


enum amqp_socket_flag_enum
{
  AMQP_SF_NONE = 0,
  AMQP_SF_MORE = 1,
  AMQP_SF_POLLIN = 2,
  AMQP_SF_POLLOUT = 4,
  AMQP_SF_POLLERR = 8
}

enum amqp_socket_close_enum
{
  AMQP_SC_NONE = 0,
  AMQP_SC_FORCE = 1
}

int amqp_os_socket_error();
int amqp_os_socket_close(int sockfd);

/* Socket callbacks. */
alias amqp_socket_send_fn = ssize_t function(void *, const void *, size_t, int);
alias amqp_socket_recv_fn = ssize_t function(void *, void *, size_t, int);
alias amqp_socket_open_fn = int function(void *, const(char)*, int, timeval*);
alias amqp_socket_close_fn = int function(void *, amqp_socket_close_enum);
alias amqp_socket_get_sockfd_fn =  int function(void *);
alias amqp_socket_delete_fn = void function(void *);

/// V-table for amqp_socket_t
struct amqp_socket_class_t
{
  amqp_socket_send_fn send;
  amqp_socket_recv_fn recv;
  amqp_socket_open_fn open;
  amqp_socket_close_fn close;
  amqp_socket_get_sockfd_fn get_sockfd;
  amqp_socket_delete_fn delete_;
}

/** Abstract base class for amqp_socket_t */
struct amqp_socket_t
{
  amqp_socket_class_t *klass;
}

void amqp_set_socket(amqp_connection_state_t state, amqp_socket_t *socket);
ssize_t amqp_socket_send(amqp_socket_t *self, const void *buf, size_t len, int flags);
ssize_t amqp_try_send(amqp_connection_state_t state, const void *buf, size_t len, amqp_time_t deadline, int flags);
ssize_t amqp_socket_recv(amqp_socket_t *self, void *buf, size_t len, int flags);
int amqp_socket_close(amqp_socket_t *self, amqp_socket_close_enum force);
void amqp_socket_delete(amqp_socket_t *self);
int amqp_open_socket_noblock(const(char)* hostname, int portnumber, timeval* timeout);
int amqp_open_socket_inner(const(char)* hostname, int portnumber, amqp_time_t deadline);
int amqp_poll(int fd, int event, amqp_time_t deadline);
int amqp_send_method_inner(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t id, void *decoded, int flags, amqp_time_t deadline);
int amqp_queue_frame(amqp_connection_state_t state, amqp_frame_t *frame);
int amqp_put_back_frame(amqp_connection_state_t state, amqp_frame_t *frame);
int amqp_simple_wait_frame_on_channel(amqp_connection_state_t state, amqp_channel_t channel, amqp_frame_t *decoded_frame);
int sasl_mechanism_in_list(amqp_bytes_t mechanisms, amqp_sasl_method_enum method);
int amqp_merge_capabilities(const amqp_table_t *base, const amqp_table_t *add, amqp_table_t *result, amqp_pool_t *pool);
enum AMQ_COPYRIGHT = "Copyright (c) 2007-2014 VMWare Inc, Tony Garnock-Jones, and Alan Antonuk.";

enum amqp_connection_state_enum
{
  CONNECTION_STATE_IDLE = 0,
  CONNECTION_STATE_INITIAL,
  CONNECTION_STATE_HEADER,
  CONNECTION_STATE_BODY
}

enum amqp_status_private_enum
{
  /* 0x00xx . AMQP_STATUS_*/
  /* 0x01xx . AMQP_STATUS_TCP_* */
  /* 0x02xx . AMQP_STATUS_SSL_* */
  AMQP_PRIVATE_STATUS_SOCKET_NEEDREAD =  -0x1301,
  AMQP_PRIVATE_STATUS_SOCKET_NEEDWRITE = -0x1302
}

/* 7 bytes up front, then payload, then 1 byte footer */
enum HEADER_SIZE =7;
enum FOOTER_SIZE =1;
enum AMQP_PSEUDOFRAME_PROTOCOL_HEADER ='A';

struct amqp_link_t
{
  amqp_link_t* next;
  void *data;
}

enum POOL_TABLE_SIZE=16;

struct amqp_pool_table_entry_t
{
  amqp_pool_table_entry_t* next;
  amqp_pool_t pool;
  amqp_channel_t channel;
}

struct amqp_connection_state_t_
{
  amqp_pool_table_entry_t*[POOL_TABLE_SIZE] pool_table;

  amqp_connection_state_enum state;

  int channel_max;
  int frame_max;

  /* Heartbeat interval in seconds. If this is <= 0, then heartbeats are not
   * enabled, and next_recv_heartbeat and next_send_heartbeat are set to
   * infinite */
  int heartbeat;
  amqp_time_t next_recv_heartbeat;
  amqp_time_t next_send_heartbeat;

  /* buffer for holding frame headers.  Allows us to delay allocating
   * the raw frame buffer until the type, channel, and size are all known
   */
  char[HEADER_SIZE + 1]  header_buffer;
  amqp_bytes_t inbound_buffer;

  size_t inbound_offset;
  size_t target_size;

  amqp_bytes_t outbound_buffer;

  amqp_socket_t *socket;

  amqp_bytes_t sock_inbound_buffer;
  size_t sock_inbound_offset;
  size_t sock_inbound_limit;

  amqp_link_t *first_queued_frame;
  amqp_link_t *last_queued_frame;

  amqp_rpc_reply_t most_recent_api_result;

  amqp_table_t server_properties;
  amqp_table_t client_properties;
  amqp_pool_t properties_pool;

  timeval *handshake_timeout;
  timeval internal_handshake_timeout;
  timeval *rpc_timeout;
  timeval internal_rpc_timeout;
}

amqp_pool_t *amqp_get_or_create_channel_pool(amqp_connection_state_t connection, amqp_channel_t channel);
amqp_pool_t *amqp_get_channel_pool(amqp_connection_state_t state, amqp_channel_t channel);


pragma(inline,true)
int amqp_heartbeat_send(amqp_connection_state_t state)
{
  return state.heartbeat;
}

pragma(inline,true)
int amqp_heartbeat_recv(amqp_connection_state_t state)
{
  return 2 * state.heartbeat;
}


int amqp_try_recv(amqp_connection_state_t state);

pragma(inline,true)
void *amqp_offset(void *data, size_t offset)
{
  return cast(char *)data + offset;
}

/+
/* This macro defines the encoding and decoding functions associated with a
   simple type. */

enum DECLARE_CODEC_BASE_TYPE(bits, htonx, ntohx)                           \
                                                                              \
  static inline void amqp_e##bits(void *data, size_t offset,                  \
                                  uint##bits##_t val)                         \
  {                                                                           \
    /* The AMQP data might be unaligned. So we encode and then copy the       \
             result into place. */                                            \
    uint##bits##_t res = htonx(val);                                          \
    memcpy(amqp_offset(data, offset), &res, bits/8);                          \
  }                                                                           \
                                                                              \
  static inline uint##bits##_t amqp_d##bits(void *data, size_t offset)        \
  {                                                                           \
    /* The AMQP data might be unaligned.  So we copy the source value         \
             into a variable and then decode it. */                           \
    uint##bits##_t val;                                                       \
    memcpy(&val, amqp_offset(data, offset), bits/8);                          \
    return ntohx(val);                                                        \
  }                                                                           \
                                                                              \
  static inline int amqp_encode_##bits(amqp_bytes_t encoded, size_t *offset,  \
                                       uint##bits##_t input)                  \
                                                                              \
  {                                                                           \
    size_t o = *offset;                                                       \
    if ((*offset = o + bits / 8) <= encoded.len) {                            \
      amqp_e##bits(encoded.bytes, o, input);                                  \
      return 1;                                                               \
    }                                                                         \
    else {                                                                    \
      return 0;                                                               \
    }                                                                         \
  }                                                                           \
                                                                              \
  static inline int amqp_decode_##bits(amqp_bytes_t encoded, size_t *offset,  \
                                       uint##bits##_t *output)                \
                                                                              \
  {                                                                           \
    size_t o = *offset;                                                       \
    if ((*offset = o + bits / 8) <= encoded.len) {                            \
      *output = amqp_d##bits(encoded.bytes, o);                               \
      return 1;                                                               \
    }                                                                         \
    else {                                                                    \
      return 0;                                                               \
    }                                                                         \
  }

/* Determine byte order */
#if defined(__GLIBC__)
# include <endian.h>
# if (__BYTE_ORDER == __LITTLE_ENDIAN)
#  define AMQP_LITTLE_ENDIAN
# elif (__BYTE_ORDER == __BIG_ENDIAN)
#  define AMQP_BIG_ENDIAN
# else
/* Don't define anything */
# endif
#elif defined(_BIG_ENDIAN) && !defined(_LITTLE_ENDIAN) ||                   \
      defined(__BIG_ENDIAN__) && !defined(__LITTLE_ENDIAN__)
# define AMQP_BIG_ENDIAN
#elif defined(_LITTLE_ENDIAN) && !defined(_BIG_ENDIAN) ||                   \
      defined(__LITTLE_ENDIAN__) && !defined(__BIG_ENDIAN__)
# define AMQP_LITTLE_ENDIAN
#elif defined(__hppa__) || defined(__HPPA__) || defined(__hppa) ||          \
      defined(_POWER) || defined(__powerpc__) || defined(__ppc___) ||       \
      defined(_MIPSEB) || defined(__s390__) ||                              \
      defined(__sparc) || defined(__sparc__)
# define AMQP_BIG_ENDIAN
#elif defined(__alpha__) || defined(__alpha) || defined(_M_ALPHA) ||        \
      defined(__amd64__) || defined(__x86_64__) || defined(_M_X64) ||       \
      defined(__ia64) || defined(__ia64__) || defined(_M_IA64) ||           \
      defined(__arm__) || defined(_M_ARM) ||                                \
      defined(__i386__) || defined(_M_IX86)
# define AMQP_LITTLE_ENDIAN
#else
/* Don't define anything */
#endif

#if defined(AMQP_LITTLE_ENDIAN)

enum DECLARE_XTOXLL(func)                        \
  static inline ulong func##ll(ulong val)     \
  {                                                 \
    union {                                         \
      ulong whole;                               \
      uint halves[2];                           \
    } u;                                            \
    uint t;                                     \
    u.whole = val;                                  \
    t = u.halves[0];                                \
    u.halves[0] = func##l(u.halves[1]);             \
    u.halves[1] = func##l(t);                       \
    return u.whole;                                 \
  }

#elif defined(AMQP_BIG_ENDIAN)

enum DECLARE_XTOXLL(func)                        \
  static inline ulong func##ll(ulong val)     \
  {                                                 \
    union {                                         \
      ulong whole;                               \
      uint halves[2];                           \
    } u;                                            \
    u.whole = val;                                  \
    u.halves[0] = func##l(u.halves[0]);             \
    u.halves[1] = func##l(u.halves[1]);             \
    return u.whole;                                 \
  }

#else
# error Endianness not known
#endif

#ifndef HAVE_HTONLL
DECLARE_XTOXLL(hton)
DECLARE_XTOXLL(ntoh)
#endif

DECLARE_CODEC_BASE_TYPE(8, (ubyte), (ubyte))
DECLARE_CODEC_BASE_TYPE(16, htons, ntohs)
DECLARE_CODEC_BASE_TYPE(32, htonl, ntohl)
DECLARE_CODEC_BASE_TYPE(64, htonll, ntohll)
+/

pragma(inline,true)
int amqp_encode_bytes(amqp_bytes_t encoded, size_t *offset, amqp_bytes_t input)
{
  size_t o = *offset;
  /* The memcpy below has undefined behavior if the input is NULL. It is valid
   * for a 0-length amqp_bytes_t to have .bytes == NULL. Thus we should check
   * before encoding.
   */
  if (input.len == 0) {
    return 1;
  }
  if ((*offset = o + input.len) <= encoded.len) {
    memcpy(amqp_offset(encoded.bytes, o), input.bytes, input.len);
    return 1;
  } else {
    return 0;
  }
}

pragma(inline,true)
int amqp_decode_bytes(amqp_bytes_t encoded, size_t *offset, amqp_bytes_t *output, size_t len)
{
  size_t o = *offset;
  if ((*offset = o + len) <= encoded.len) {
    output.bytes = amqp_offset(encoded.bytes, o);
    output.len = len;
    return 1;
  } else {
    return 0;
  }
}

void amqp_abort(const(char)*fmt, ...);
int amqp_bytes_equal(amqp_bytes_t r, amqp_bytes_t l);

pragma(inline,true)
amqp_rpc_reply_t amqp_rpc_reply_error(amqp_status_enum status)
{
  amqp_rpc_reply_t reply;
  reply.reply_type = ResponseType.libraryException;
  reply.library_error = status;
  return reply;
}

int amqp_send_frame_inner(amqp_connection_state_t state, const amqp_frame_t *frame, int flags, amqp_time_t deadline);



enum amqp_hostname_validation_result
{
  AMQP_HVR_MATCH_FOUND,
  AMQP_HVR_MATCH_NOT_FOUND,
  AMQP_HVR_NO_SAN_PRESENT,
  AMQP_HVR_MALFORMED_CERTIFICATE,
  AMQP_HVR_ERROR
}
version(OpenSSL)
{
	amqp_hostname_validation_result amqp_ssl_validate_hostname(const(char)*hostname, const X509* server_cert);
	BIO_METHOD* amqp_openssl_bio();
}
enum amqp_hostcheck_result
{
  AMQP_HCR_NO_MATCH = 0,
  AMQP_HCR_MATCH = 1
} 
amqp_hostcheck_result amqp_hostcheck(const(char)*match_pattern, const(char)*hostname);


enum AMQP_PROTOCOL_VERSION_MAJOR=0;
enum AMQP_PROTOCOL_VERSION_MINOR=9;
enum AMQP_PROTOCOL_VERSION_REVISION=1;
enum AMQP_PROTOCOL_PORT= 5672;
enum AMQP_FRAME_METHOD=1;
enum AMQP_FRAME_HEADER=2;
enum AMQP_FRAME_BODY=3;
enum AMQP_FRAME_HEARTBEAT=8;
enum AMQP_FRAME_MIN_SIZE=4096;
enum AMQP_FRAME_END=206;
enum AMQP_REPLY_SUCCESS=200;
enum AMQP_CONTENT_TOO_LARGE= 311;
enum AMQP_NO_ROUTE= 312;
enum AMQP_NO_CONSUMERS= 313;
enum AMQP_ACCESS_REFUSED= 403;
enum AMQP_NOT_FOUND= 404;
enum AMQP_RESOURCE_LOCKED= 405;
enum AMQP_PRECONDITION_FAILED= 406;
enum AMQP_CONNECTION_FORCED=320;
enum AMQP_INVALID_PATH=402;
enum AMQP_FRAME_ERROR=501;
enum AMQP_SYNTAX_ERROR=502;
enum AMQP_COMMAND_INVALID=503;
enum AMQP_CHANNEL_ERROR=504;
enum AMQP_UNEXPECTED_FRAME=505;
enum AMQP_RESOURCE_ERROR=506;
enum AMQP_NOT_ALLOWED=530;
enum AMQP_NOT_IMPLEMENTED=540;
enum AMQP_INTERNAL_ERROR=541;

alias ReplySuccess = AMQP_REPLY_SUCCESS;

const(char)*  amqp_constant_name(int constantNumber);
amqp_boolean_t amqp_constant_is_hard_error(int constantNumber);
const(char)*  amqp_method_name(amqp_method_number_t methodNumber);
amqp_boolean_t amqp_method_has_content(amqp_method_number_t methodNumber);
int amqp_decode_method(amqp_method_number_t methodNumber, amqp_pool_t *pool, amqp_bytes_t encoded, void **decoded);
int amqp_decode_properties(ushort class_id, amqp_pool_t *pool, amqp_bytes_t encoded, void **decoded);
int amqp_encode_method(amqp_method_number_t methodNumber, void *decoded, amqp_bytes_t encoded);
int amqp_encode_properties(ushort class_id, void *decoded, amqp_bytes_t encoded);
enum amqp_method_number_t AMQP_CONNECTION_START_METHOD = 0x000A000A;

struct amqp_connection_start_t
{
  ubyte version_major; /**< version-major */
  ubyte version_minor; /**< version-minor */
  amqp_table_t server_properties; /**< server-properties */
  amqp_bytes_t mechanisms; /**< mechanisms */
  amqp_bytes_t locales; /**< locales */
}

enum amqp_method_number_t  AMQP_CONNECTION_START_OK_METHOD = 0x000A000B;
struct amqp_connection_start_ok_t
{
  amqp_table_t client_properties; /**< client-properties */
  amqp_bytes_t mechanism; /**< mechanism */
  amqp_bytes_t response; /**< response */
  amqp_bytes_t locale; /**< locale */
}

enum amqp_method_number_t AMQP_CONNECTION_SECURE_METHOD= 0x000A0014;
struct amqp_connection_secure_t
{
  amqp_bytes_t challenge; /**< challenge */
}

enum amqp_method_number_t AMQP_CONNECTION_SECURE_OK_METHOD= 0x000A0015;
struct amqp_connection_secure_ok_t
{
  amqp_bytes_t response; /**< response */
}

enum amqp_method_number_t AMQP_CONNECTION_TUNE_METHOD = 0x000A001E;
struct amqp_connection_tune_t
{
  ushort channel_max; /**< channel-max */
  uint frame_max; /**< frame-max */
  ushort heartbeat; /**< heartbeat */
}

enum amqp_method_number_t AMQP_CONNECTION_TUNE_OK_METHOD= 0x000A001F;
struct amqp_connection_tune_ok_t
{
  ushort channel_max; /**< channel-max */
  uint frame_max; /**< frame-max */
  ushort heartbeat; /**< heartbeat */
}

enum amqp_method_number_tAMQP_CONNECTION_OPEN_METHOD= 0x000A0028;
struct amqp_connection_open_t
{
  amqp_bytes_t virtual_host; /**< virtual-host */
  amqp_bytes_t capabilities; /**< capabilities */
  amqp_boolean_t insist; /**< insist */
}

enum amqp_method_number_t AMQP_CONNECTION_OPEN_OK_METHOD = 0x000A0029;
struct amqp_connection_open_ok_t
{
  amqp_bytes_t known_hosts; /**< known-hosts */
}

enum amqp_method_number_t AMQP_CONNECTION_CLOSE_METHOD = 0x000A0032;
struct amqp_connection_close_t
{
  ushort reply_code; /**< reply-code */
  amqp_bytes_t reply_text; /**< reply-text */
  ushort class_id; /**< class-id */
  ushort method_id; /**< method-id */
}

enum amqp_method_number_t AMQP_CONNECTION_CLOSE_OK_METHOD = 0x000A0033;
struct amqp_connection_close_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_CONNECTION_BLOCKED_METHOD = 0x000A003C;
struct amqp_connection_blocked_t
{
  amqp_bytes_t reason; /**< reason */
}

enum amqp_method_number_t AMQP_CONNECTION_UNBLOCKED_METHOD = 0x000A003D;
struct amqp_connection_unblocked_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_CHANNEL_OPEN_METHOD = 0x0014000A;
struct amqp_channel_open_t
{
  amqp_bytes_t out_of_band; /**< out-of-band */
}

enum amqp_method_number_t AMQP_CHANNEL_OPEN_OK_METHOD = 0x0014000B;
struct amqp_channel_open_ok_t
{
  amqp_bytes_t channel_id; /**< channel-id */
}

enum amqp_method_number_t AMQP_CHANNEL_FLOW_METHOD = 0x00140014;
struct amqp_channel_flow_t
{
  amqp_boolean_t active; /**< active */
}

enum amqp_method_number_t AMQP_CHANNEL_FLOW_OK_METHOD  = 0x00140015;
struct amqp_channel_flow_ok_t
{
  amqp_boolean_t active; /**< active */
}

enum amqp_method_number_t AMQP_CHANNEL_CLOSE_METHOD =  0x00140028;
struct amqp_channel_close_t
{
  ushort reply_code; /**< reply-code */
  amqp_bytes_t reply_text; /**< reply-text */
  ushort class_id; /**< class-id */
  ushort method_id; /**< method-id */
}

enum amqp_method_number_t AMQP_CHANNEL_CLOSE_OK_METHOD = 0x00140029;
struct amqp_channel_close_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_ACCESS_REQUEST_METHOD = 0x001E000A;
struct amqp_access_request_t
{
  amqp_bytes_t realm; /**< realm */
  amqp_boolean_t exclusive; /**< exclusive */
  amqp_boolean_t passive; /**< passive */
  amqp_boolean_t active; /**< active */
  amqp_boolean_t write; /**< write */
  amqp_boolean_t read; /**< read */
}

enum amqp_method_number_t AMQP_ACCESS_REQUEST_OK_METHOD= 0x001E000B;
struct amqp_access_request_ok_t
{
  ushort ticket; /**< ticket */
}

enum amqp_method_number_t AMQP_EXCHANGE_DECLARE_METHOD  = 0x0028000A;
struct amqp_exchange_declare_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t type; /**< type */
  amqp_boolean_t passive; /**< passive */
  amqp_boolean_t durable; /**< durable */
  amqp_boolean_t auto_delete; /**< auto-delete */
  amqp_boolean_t internal; /**< internal */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_EXCHANGE_DECLARE_OK_METHOD = 0x0028000B;
struct amqp_exchange_declare_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_EXCHANGE_DELETE_METHOD = 0x00280014;
struct amqp_exchange_delete_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t exchange; /**< exchange */
  amqp_boolean_t if_unused; /**< if-unused */
  amqp_boolean_t nowait; /**< nowait */
}

enum amqp_method_number_t AMQP_EXCHANGE_DELETE_OK_METHOD = 0x00280015;
struct amqp_exchange_delete_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_EXCHANGE_BIND_METHOD =  0x0028001E;
struct amqp_exchange_bind_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t destination; /**< destination */
  amqp_bytes_t source; /**< source */
  amqp_bytes_t routing_key; /**< routing-key */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_EXCHANGE_BIND_OK_METHOD =  0x0028001F;
struct amqp_exchange_bind_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_EXCHANGE_UNBIND_METHOD = 0x00280028;
struct amqp_exchange_unbind_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t destination; /**< destination */
  amqp_bytes_t source; /**< source */
  amqp_bytes_t routing_key; /**< routing-key */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_EXCHANGE_UNBIND_OK_METHOD =  0x00280033;
struct amqp_exchange_unbind_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_QUEUE_DECLARE_METHOD = 0x0032000A;
struct amqp_queue_declare_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_boolean_t passive; /**< passive */
  amqp_boolean_t durable; /**< durable */
  amqp_boolean_t exclusive; /**< exclusive */
  amqp_boolean_t auto_delete; /**< auto-delete */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_QUEUE_DECLARE_OK_METHOD= 0x0032000B;
struct amqp_queue_declare_ok_t
{
  amqp_bytes_t queue; /**< queue */
  uint message_count; /**< message-count */
  uint consumer_count; /**< consumer-count */
}

enum amqp_method_number_t AMQP_QUEUE_BIND_METHOD = 0x00320014;
struct amqp_queue_bind_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_QUEUE_BIND_OK_METHOD = 0x00320015;
struct amqp_queue_bind_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_QUEUE_PURGE_METHOD =0x0032001E;
struct amqp_queue_purge_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_boolean_t nowait; /**< nowait */
}

enum amqp_method_number_t AMQP_QUEUE_PURGE_OK_METHOD = 0x0032001F;
struct amqp_queue_purge_ok_t
{
  uint message_count; /**< message-count */
}

enum amqp_method_number_t AMQP_QUEUE_DELETE_METHOD = 0x00320028;
struct amqp_queue_delete_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_boolean_t if_unused; /**< if-unused */
  amqp_boolean_t if_empty; /**< if-empty */
  amqp_boolean_t nowait; /**< nowait */
}

enum amqp_method_number_t AMQP_QUEUE_DELETE_OK_METHOD = 0x00320029;
struct amqp_queue_delete_ok_t{
  uint message_count; /**< message-count */
}

enum amqp_method_number_t AMQP_QUEUE_UNBIND_METHOD = 0x00320032;
struct amqp_queue_unbind_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_QUEUE_UNBIND_OK_METHOD = 0x00320033;
struct amqp_queue_unbind_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_BASIC_QOS_METHOD =  0x003C000A;
struct amqp_basic_qos_t
{
  uint prefetch_size; /**< prefetch-size */
  ushort prefetch_count; /**< prefetch-count */
  amqp_boolean_t global; /**< global */
}

enum amqp_method_number_t AMQP_BASIC_QOS_OK_METHOD = 0x003C000B;
struct amqp_basic_qos_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_BASIC_CONSUME_METHOD = 0x003C0014;
struct amqp_basic_consume_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_bytes_t consumer_tag; /**< consumer-tag */
  amqp_boolean_t no_local; /**< no-local */
  amqp_boolean_t no_ack; /**< no-ack */
  amqp_boolean_t exclusive; /**< exclusive */
  amqp_boolean_t nowait; /**< nowait */
  amqp_table_t arguments; /**< arguments */
}

enum amqp_method_number_t AMQP_BASIC_CONSUME_OK_METHOD = 0x003C0015;
struct amqp_basic_consume_ok_t
{
  amqp_bytes_t consumer_tag; /**< consumer-tag */
}

enum amqp_method_number_t AMQP_BASIC_CANCEL_METHOD= 0x003C001E;
struct amqp_basic_cancel_t
{
  amqp_bytes_t consumer_tag; /**< consumer-tag */
  amqp_boolean_t nowait; /**< nowait */
}

enum amqp_method_number_t AMQP_BASIC_CANCEL_OK_METHOD =  0x003C001F;
struct amqp_basic_cancel_ok_t
{
  amqp_bytes_t consumer_tag; /**< consumer-tag */
}

enum amqp_method_number_t AMQP_BASIC_PUBLISH_METHOD = 0x003C0028;
struct amqp_basic_publish_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
  amqp_boolean_t mandatory; /**< mandatory */
  amqp_boolean_t immediate; /**< immediate */
}

enum amqp_method_number_t AMQP_BASIC_RETURN_METHOD = 0x003C0032;
struct amqp_basic_return_t
{
  ushort reply_code; /**< reply-code */
  amqp_bytes_t reply_text; /**< reply-text */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
}

enum amqp_method_number_t AMQP_BASIC_DELIVER_METHOD =  0x003C003C;
struct amqp_basic_deliver_t
{
  amqp_bytes_t consumer_tag; /**< consumer-tag */
  ulong delivery_tag; /**< delivery-tag */
  amqp_boolean_t redelivered; /**< redelivered */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
}

enum amqp_method_number_t AMQP_BASIC_GET_METHOD = 0x003C0046;
struct amqp_basic_get_t
{
  ushort ticket; /**< ticket */
  amqp_bytes_t queue; /**< queue */
  amqp_boolean_t no_ack; /**< no-ack */
}

enum amqp_method_number_t AMQP_BASIC_GET_OK_METHOD = 0x003C0047;
struct amqp_basic_get_ok_t
{
  ulong delivery_tag; /**< delivery-tag */
  amqp_boolean_t redelivered; /**< redelivered */
  amqp_bytes_t exchange; /**< exchange */
  amqp_bytes_t routing_key; /**< routing-key */
  uint message_count; /**< message-count */
}

enum amqp_method_number_t AMQP_BASIC_GET_EMPTY_METHOD =  0x003C0048;
struct amqp_basic_get_empty_t
{
  amqp_bytes_t cluster_id; /**< cluster-id */
}

enum amqp_method_number_t AMQP_BASIC_ACK_METHOD = 0x003C0050;
struct amqp_basic_ack_t
{
  ulong delivery_tag; /**< delivery-tag */
  amqp_boolean_t multiple; /**< multiple */
}

enum amqp_method_number_t AMQP_BASIC_REJECT_METHOD = 0x003C005A;
struct amqp_basic_reject_t
{
  ulong delivery_tag; /**< delivery-tag */
  amqp_boolean_t requeue; /**< requeue */
}

enum amqp_method_number_t AMQP_BASIC_RECOVER_ASYNC_METHOD =  0x003C0064;
struct amqp_basic_recover_async_t
{
  amqp_boolean_t requeue; /**< requeue */
}

enum amqp_method_number_t AMQP_BASIC_RECOVER_METHOD = 0x003C006E;
struct amqp_basic_recover_t
{
  amqp_boolean_t requeue; /**< requeue */
}

enum amqp_method_number_t AMQP_BASIC_RECOVER_OK_METHOD = 0x003C006F;
struct amqp_basic_recover_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_BASIC_NACK_METHOD =  0x003C0078;
struct amqp_basic_nack_t
{
  ulong delivery_tag; /**< delivery-tag */
  amqp_boolean_t multiple; /**< multiple */
  amqp_boolean_t requeue; /**< requeue */
}

enum amqp_method_number_t AMQP_TX_SELECT_METHOD = 0x005A000A;
struct amqp_tx_select_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_TX_SELECT_OK_METHOD= 0x005A000B;
struct amqp_tx_select_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_TX_COMMIT_METHOD = 0x005A0014;
struct amqp_tx_commit_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_TX_COMMIT_OK_METHOD= 0x005A0015;
struct amqp_tx_commit_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_TX_ROLLBACK_METHOD =  0x005A001E;
struct amqp_tx_rollback_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_TX_ROLLBACK_OK_METHOD= 0x005A001F;
struct amqp_tx_rollback_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

enum amqp_method_number_t AMQP_CONFIRM_SELECT_METHOD=  0x0055000A;
struct amqp_confirm_select_t
{
  amqp_boolean_t nowait; /**< nowait */
}

enum amqp_method_number_t AMQP_CONFIRM_SELECT_OK_METHOD= 0x0055000B;
struct amqp_confirm_select_ok_t
{
  char dummy; /**< Dummy field to avoid empty struct */
}

/* Class property records. */
enum AMQP_CONNECTION_CLASS = 0x000A;
/** connection class properties */
struct amqp_connection_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_CHANNEL_CLASS = 0x0014;
struct amqp_channel_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_ACCESS_CLASS = 0x001E;
struct amqp_access_properties_t_
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_EXCHANGE_CLASS = 0x0028;
struct amqp_exchange_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_QUEUE_CLASS = 0x0032;
struct amqp_queue_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_BASIC_CLASS = 0x003C;
enum AMQP_BASIC_CONTENT_TYPE_FLAG =(1 << 15); /**< basic.content-type property flag */
enum AMQP_BASIC_CONTENT_ENCODING_FLAG= (1 << 14); /**< basic.content-encoding property flag */
enum AMQP_BASIC_HEADERS_FLAG=(1 << 13); /**< basic.headers property flag */
enum AMQP_BASIC_DELIVERY_MODE_FLAG=(1 << 12); /**< basic.delivery-mode property flag */
enum AMQP_BASIC_PRIORITY_FLAG=(1 << 11); /**< basic.priority property flag */
enum AMQP_BASIC_CORRELATION_ID_FLAG=(1 << 10); /**< basic.correlation-id property flag */
enum AMQP_BASIC_REPLY_TO_FLAG=(1 << 9); /**< basic.reply-to property flag */
enum AMQP_BASIC_EXPIRATION_FLAG=(1 << 8); /**< basic.expiration property flag */
enum AMQP_BASIC_MESSAGE_ID_FLAG=(1 << 7); /**< basic.message-id property flag */
enum AMQP_BASIC_TIMESTAMP_FLAG=(1 << 6); /**< basic.timestamp property flag */
enum AMQP_BASIC_TYPE_FLAG=(1 << 5); /**< basic.type property flag */
enum AMQP_BASIC_USER_ID_FLAG=(1 << 4); /**< basic.user-id property flag */
enum AMQP_BASIC_APP_ID_FLAG=(1 << 3); /**< basic.app-id property flag */
enum AMQP_BASIC_CLUSTER_ID_FLAG=(1 << 2); /**< basic.cluster-id property flag */

/** basic class properties */
struct amqp_basic_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  amqp_bytes_t content_type; /**< content-type */
  amqp_bytes_t content_encoding; /**< content-encoding */
  amqp_table_t headers; /**< headers */
  ubyte delivery_mode; /**< delivery-mode */
  ubyte priority; /**< priority */
  amqp_bytes_t correlation_id; /**< correlation-id */
  amqp_bytes_t reply_to; /**< reply-to */
  amqp_bytes_t expiration; /**< expiration */
  amqp_bytes_t message_id; /**< message-id */
  ulong timestamp; /**< timestamp */
  amqp_bytes_t type; /**< type */
  amqp_bytes_t user_id; /**< user-id */
  amqp_bytes_t app_id; /**< app-id */
  amqp_bytes_t cluster_id; /**< cluster-id */
}

enum AMQP_TX_CLASS = 0x005A;
/** tx class properties */
struct amqp_tx_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

enum AMQP_CONFIRM_CLASS = 0x0055;
struct amqp_confirm_properties_t
{
  amqp_flags_t _flags; /**< bit-mask of set fields */
  char dummy; /**< Dummy field to avoid empty struct */
}

amqp_channel_open_ok_t * amqp_channel_open(amqp_connection_state_t state, amqp_channel_t channel);
amqp_channel_flow_ok_t * amqp_channel_flow(amqp_connection_state_t state, amqp_channel_t channel, amqp_boolean_t active);
amqp_exchange_declare_ok_t* amqp_exchange_declare(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t exchange, amqp_bytes_t type, amqp_boolean_t passive, amqp_boolean_t durable, amqp_boolean_t auto_delete, amqp_boolean_t internal, amqp_table_t arguments);
amqp_exchange_delete_ok_t * amqp_exchange_delete(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t exchange, amqp_boolean_t if_unused);
amqp_exchange_bind_ok_t * amqp_exchange_bind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t destination, amqp_bytes_t source, amqp_bytes_t routing_key, amqp_table_t arguments);
amqp_exchange_unbind_ok_t * amqp_exchange_unbind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t destination, amqp_bytes_t source, amqp_bytes_t routing_key, amqp_table_t arguments);
amqp_queue_declare_ok_t * amqp_queue_declare(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_boolean_t passive, amqp_boolean_t durable, amqp_boolean_t exclusive, amqp_boolean_t auto_delete, amqp_table_t arguments);
amqp_queue_bind_ok_t * amqp_queue_bind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t exchange, amqp_bytes_t routing_key, amqp_table_t arguments);
amqp_queue_purge_ok_t * amqp_queue_purge(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue);
amqp_queue_delete_ok_t * amqp_queue_delete(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_boolean_t if_unused, amqp_boolean_t if_empty);
amqp_queue_unbind_ok_t * amqp_queue_unbind(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t exchange, amqp_bytes_t routing_key, amqp_table_t arguments);
amqp_basic_qos_ok_t * amqp_basic_qos(amqp_connection_state_t state, amqp_channel_t channel, uint prefetch_size, ushort prefetch_count, amqp_boolean_t global);
amqp_basic_consume_ok_t * amqp_basic_consume(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t queue, amqp_bytes_t consumer_tag, amqp_boolean_t no_local, amqp_boolean_t no_ack, amqp_boolean_t exclusive, amqp_table_t arguments);
amqp_basic_cancel_ok_t * amqp_basic_cancel(amqp_connection_state_t state, amqp_channel_t channel, amqp_bytes_t consumer_tag);
amqp_basic_recover_ok_t * amqp_basic_recover(amqp_connection_state_t state, amqp_channel_t channel, amqp_boolean_t requeue);
amqp_tx_select_ok_t * amqp_tx_select(amqp_connection_state_t state, amqp_channel_t channel);
amqp_tx_commit_ok_t * amqp_tx_commit(amqp_connection_state_t state, amqp_channel_t channel);
amqp_tx_rollback_ok_t * amqp_tx_rollback(amqp_connection_state_t state, amqp_channel_t channel);
amqp_confirm_select_ok_t * amqp_confirm_select(amqp_connection_state_t state, amqp_channel_t channel);

//typedef SRWLOCK pthread_mutex_t;
//enum PTHREAD_MUTEX_INITIALIZER SRWLOCK_INIT;
DWORD pthread_self();
int pthread_mutex_init(pthread_mutex_t *, void *attr);
int pthread_mutex_lock(pthread_mutex_t *);
int pthread_mutex_unlock(pthread_mutex_t *);


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


