=begin
  デバッグ関連のマクロ定義 
=end
#exclude

# Assert
#ifdef :debug
#define :ITEFU_DEBUG_ASSERT, "Itefu::Debug.assert __FILE__, __LINE__, "
#else_ifdef :release
#define :ITEFU_DEBUG_ASSERT, "Itefu::Debug.assert __FILE__, __LINE__, "
#else
#define :ITEFU_DEBUG_ASSERT, :NOP_LINE
#endif

# Debug Output
#ifdef :debug
#define :ITEFU_LOGGING
#else_ifdef :release
#define :ITEFU_LOGGING
#endif

#ifdef :ITEFU_LOGGING
#define :ITEFU_DEBUG_OUTPUT,          "Itefu::Debug::Log.output"
#define :ITEFU_DEBUG_OUTPUT_FATAL,    "Itefu::Debug::Log.fatal"
#define :ITEFU_DEBUG_OUTPUT_ERROR,    "Itefu::Debug::Log.error"
#define :ITEFU_DEBUG_OUTPUT_WARNING,  "Itefu::Debug::Log.warning"
#define :ITEFU_DEBUG_OUTPUT_CAUTION,  "Itefu::Debug::Log.caution"
#define :ITEFU_DEBUG_OUTPUT_NOTICE,   "Itefu::Debug::Log.notice"
#else
#define :ITEFU_DEBUG_OUTPUT,          :NOP_LINE
#define :ITEFU_DEBUG_OUTPUT_FATAL,    :NOP_LINE
#define :ITEFU_DEBUG_OUTPUT_ERROR,    :NOP_LINE
#define :ITEFU_DEBUG_OUTPUT_WARNING,  :NOP_LINE
#define :ITEFU_DEBUG_OUTPUT_CAUTION,  :NOP_LINE
#define :ITEFU_DEBUG_OUTPUT_NOTICE,   :NOP_LINE
#endif

