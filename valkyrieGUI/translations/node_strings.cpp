// node_strings.cpp
// ─────────────────────────────────────────────────────────────────────────────
// THIS FILE IS ONLY FOR lupdate STRING EXTRACTION.
// It is listed in qt_add_translations(SOURCES ...) but NOT in qt_add_executable.
//
// Purpose: lupdate cannot find strings inside REGISTER_BEHAVIOUR() macros
// because they are captured as QStringLiteral at static-init time, outside any
// QObject context.  This file re-declares them using QT_TRANSLATE_NOOP3 so
// lupdate can extract them into the .ts translation files under the
// "BehaviourRegistry" context — matching the translate() call in
// BehaviourMeta::toJson().
// ─────────────────────────────────────────────────────────────────────────────

// ── Categories ────────────────────────────────────────────────────────────────
static const char* _cat_ai         = QT_TRANSLATE_NOOP3("BehaviourRegistry", "ai",         "node category");
static const char* _cat_Charts     = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Charts",     "node category");
static const char* _cat_common     = QT_TRANSLATE_NOOP3("BehaviourRegistry", "common",     "node category");
static const char* _cat_converters = QT_TRANSLATE_NOOP3("BehaviourRegistry", "converters", "node category");
static const char* _cat_data       = QT_TRANSLATE_NOOP3("BehaviourRegistry", "data",       "node category");
static const char* _cat_database   = QT_TRANSLATE_NOOP3("BehaviourRegistry", "database",   "node category");
static const char* _cat_encoding   = QT_TRANSLATE_NOOP3("BehaviourRegistry", "encoding",   "node category");
static const char* _cat_flow       = QT_TRANSLATE_NOOP3("BehaviourRegistry", "flow",       "node category");
static const char* _cat_geo        = QT_TRANSLATE_NOOP3("BehaviourRegistry", "geo",        "node category");
static const char* _cat_Generators = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Generators", "node category");
static const char* _cat_input      = QT_TRANSLATE_NOOP3("BehaviourRegistry", "input",      "node category");
static const char* _cat_io         = QT_TRANSLATE_NOOP3("BehaviourRegistry", "io",         "node category");
static const char* _cat_IO         = QT_TRANSLATE_NOOP3("BehaviourRegistry", "IO",         "node category");
static const char* _cat_logic      = QT_TRANSLATE_NOOP3("BehaviourRegistry", "logic",      "node category");
static const char* _cat_math       = QT_TRANSLATE_NOOP3("BehaviourRegistry", "math",       "node category");
static const char* _cat_Math       = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Math",       "node category");
static const char* _cat_networking = QT_TRANSLATE_NOOP3("BehaviourRegistry", "networking", "node category");
static const char* _cat_scheduling = QT_TRANSLATE_NOOP3("BehaviourRegistry", "scheduling", "node category");
static const char* _cat_script     = QT_TRANSLATE_NOOP3("BehaviourRegistry", "script",     "node category");
static const char* _cat_system     = QT_TRANSLATE_NOOP3("BehaviourRegistry", "system",     "node category");
static const char* _cat_System     = QT_TRANSLATE_NOOP3("BehaviourRegistry", "System",     "node category");
static const char* _cat_transform  = QT_TRANSLATE_NOOP3("BehaviourRegistry", "transform",  "node category");
static const char* _cat_vis        = QT_TRANSLATE_NOOP3("BehaviourRegistry", "visualization","node category");
static const char* _cat_Vis        = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Visualization","node category");

// ── ai ────────────────────────────────────────────────────────────────────────
static const char* _n001 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "AI Query",                                                                        "node display name");
static const char* _d001 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Send prompts to Claude API (claude-haiku-4-5-20251001) and receive responses",    "node description");

// ── Charts ────────────────────────────────────────────────────────────────────
static const char* _n002 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Bar Chart",                                                        "node display name");
static const char* _d002 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Multi-series bar chart with auto-scaling Y axis",                  "node description");
static const char* _n003 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Line Chart",                                                       "node display name");
static const char* _d003 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Advanced XY line chart with multi-series, zoom/pan and live stats","node description");
static const char* _n004 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Pie Chart",                                                        "node display name");
static const char* _d004 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Interactive pie/donut chart with dynamic slices",                  "node description");
static const char* _n005 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Radar Chart",                                                      "node display name");
static const char* _d005 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Spider/radar chart for multi-dimensional data comparison",         "node description");

// ── common / System / IO / Generators / Visualization ────────────────────────
static const char* _n010 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "File Opener",                                                      "node display name");
static const char* _d010 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Open and manipulate files",                                        "node description");
static const char* _n011 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Counter",                                                          "node display name");
static const char* _d011 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Simple increment/decrement counter with step control",             "node description");
static const char* _n012 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Processes Viewer",                                                 "node display name");
static const char* _d012 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Retrieves the process identifier for each process object in the system", "node description");
static const char* _n013 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Hex Viewer",                                                       "node display name");
static const char* _d013 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Hex viewer",                                                       "node description");
static const char* _n014 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Gauge",                                                            "node display name");
static const char* _d014 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Circular gauge with configurable color zones and digital readout", "node description");
static const char* _n015 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Text Display",                                                     "node display name");
static const char* _d015 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Console/log viewer — receives and displays text lines",            "node description");
static const char* _n016 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Serial Monitor",                                                   "node display name");
static const char* _d016 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Terminal-style serial port monitor with send/receive log",         "node description");
static const char* _n017 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Signal Generator",                                                 "node display name");
static const char* _d017 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Generates sine, square, triangle, sawtooth, or noise waveforms",  "node description");
static const char* _n018 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Random Generator",                                                 "node display name");
static const char* _d018 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Multi-mode random value generator with statistics",               "node description");
static const char* _n019 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Components Viewer",                                               "node display name");
static const char* _d019 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "All Components and test tool",                                     "node description");

// ── converters ────────────────────────────────────────────────────────────────
static const char* _n020 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Merge Numbers",                                                                  "node display name");
static const char* _d020 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Combines two separate numeric inputs (A, B) into multi-type pair outputs",       "node description");
static const char* _n021 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Number Cast",                                                                    "node display name");
static const char* _d021 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Converts a numeric value between int, double, bool and string types",            "node description");
static const char* _n022 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Pair Adapter",                                                                   "node display name");
static const char* _d022 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Adapts a (A, B) pair between all int/double type combinations",                  "node description");

// ── data ──────────────────────────────────────────────────────────────────────
static const char* _n030 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Data Table Viewer",                                               "node display name");
static const char* _d030 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Dynamic table with sort, filter, and row click events",           "node description");
static const char* _n031 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "JSON Parser",                                                     "node display name");
static const char* _d031 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Extract values from JSON using dot-path notation",                "node description");
static const char* _n032 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "JSON Tree Viewer",                                                "node display name");
static const char* _d032 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Display JSON as an interactive collapsible tree",                 "node description");
static const char* _n033 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Statistics Analyzer",                                             "node display name");
static const char* _d033 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Real-time descriptive statistics with outlier detection",         "node description");

// ── database ──────────────────────────────────────────────────────────────────
static const char* _n040 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "CSV Reader/Writer",                                               "node display name");
static const char* _d040 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Read and write CSV files with configurable delimiter",            "node description");
static const char* _n041 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "SQLite Query",                                                    "node display name");
static const char* _d041 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Execute SQL queries on a local SQLite database",                  "node description");

// ── encoding ──────────────────────────────────────────────────────────────────
static const char* _n050 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Base64",                                                          "node display name");
static const char* _d050 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Encode and decode Base64 strings",                                "node description");
static const char* _n051 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Hash Generator",                                                  "node display name");
static const char* _d051 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Compute MD5/SHA1/SHA256/SHA512 hash of input text",               "node description");
static const char* _n052 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Regex Processor",                                                 "node display name");
static const char* _d052 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Match, capture groups, and replace with regular expressions",     "node description");

// ── flow ──────────────────────────────────────────────────────────────────────
static const char* _n060 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Start",                                                      "node display name");
static const char* _d060 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Entry point of an execution flow",                                "node description");
static const char* _n061 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow End",                                                        "node display name");
static const char* _d061 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Terminal node that marks the end of an execution path",           "node description");
static const char* _n062 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Branch",                                                     "node display name");
static const char* _d062 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Routes execution based on a boolean condition (If/Else)",         "node description");
static const char* _n063 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Delay",                                                      "node display name");
static const char* _d063 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Waits a given number of milliseconds before passing execution",   "node description");
static const char* _n064 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Loop",                                                       "node display name");
static const char* _d064 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Repeats an execution path N times then fires completed",          "node description");
static const char* _n065 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Merge",                                                      "node display name");
static const char* _d065 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Passes any of three execution inputs to a single output",         "node description");
static const char* _n066 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Sequence",                                                   "node display name");
static const char* _d066 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Fires three execution outputs in order",                          "node description");
static const char* _n067 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Flow Switch",                                                     "node display name");
static const char* _d067 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Routes execution to one of N cases based on an integer value",   "node description");

// ── geo ───────────────────────────────────────────────────────────────────────
static const char* _n070 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Map Viewer",                                                                                 "node display name");
static const char* _d070 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Interactive OSM tile map — markers, GPS traces, live tracking, circles and geofence",        "node description");

// ── input ─────────────────────────────────────────────────────────────────────
static const char* _n080 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Array Input",                                                                    "node display name");
static const char* _d080 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Builds and sends a list of string values to connected nodes",                    "node description");
static const char* _n081 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Color Input",                                                                    "node display name");
static const char* _d081 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a selected color as hex string or RGB values to connected nodes",          "node description");
static const char* _n082 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "DateTime Input",                                                                 "node display name");
static const char* _d082 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a formatted date/time string or Unix timestamp to connected nodes",        "node description");
static const char* _n083 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Dict Input",                                                                     "node display name");
static const char* _d083 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Builds and sends a key/value dictionary to connected nodes",                     "node description");
static const char* _n084 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Key/Value Input",                                                                "node display name");
static const char* _d084 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a labeled value pair to connected chart/data nodes",                       "node description");
static const char* _n085 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Number Input",                                                                   "node display name");
static const char* _d085 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a numeric value (double, int, bool or string) to connected nodes",         "node description");
static const char* _n086 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Pair Input",                                                                     "node display name");
static const char* _d086 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends an (X, Y) data point to connected nodes",                                  "node description");
static const char* _n087 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Text Input",                                                                     "node display name");
static const char* _d087 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a user-defined text string to connected nodes",                            "node description");
static const char* _n088 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Vec2 Input",                                                                     "node display name");
static const char* _d088 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a 2D vector (X, Y) with graphical arrow preview to connected nodes",       "node description");
static const char* _n089 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Vec3 Input",                                                                     "node display name");
static const char* _d089 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Sends a 3D vector (X, Y, Z) with color-coded axes to connected nodes",           "node description");

// ── io ────────────────────────────────────────────────────────────────────────
static const char* _n090 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "File Watcher",                                                    "node display name");
static const char* _d090 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Monitor files and directories for real-time changes",             "node description");

// ── logic ─────────────────────────────────────────────────────────────────────
static const char* _n100 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Comparison",                                                      "node display name");
static const char* _d100 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Compares two values: ==, !=, <, >, <=, >=",                       "node description");
static const char* _n101 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Gate",                                                            "node display name");
static const char* _d101 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Conditional pass/block — forwards or blocks values based on a boolean", "node description");
static const char* _n102 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Hub",                                                             "node display name");
static const char* _d102 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Send information and broadcasts all data across each connection", "node description");
static const char* _n103 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "String Format",                                                   "node display name");
static const char* _d103 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Formats values into a string using {A}, {B}, {C} placeholders",  "node description");

// ── math ──────────────────────────────────────────────────────────────────────
static const char* _n110 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Clamp",                                                                        "node display name");
static const char* _d110 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Constrains a value between min and max, outputs normalized 0..1",              "node description");
static const char* _n111 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Expression Evaluator",                                                         "node display name");
static const char* _d111 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Evaluate a custom math/JS expression with up to 4 inputs (a,b,c,d)",           "node description");
static const char* _n112 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Filter",                                                                       "node display name");
static const char* _d112 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Signal filter: moving average, EMA, median, or low-pass",                      "node description");
static const char* _n113 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Map Range",                                                                    "node display name");
static const char* _d113 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Maps a value from one numeric range to another with optional clamping",        "node description");
static const char* _n114 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Math Function",                                                                "node display name");
static const char* _d114 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Unary math function: sin, cos, abs, sqrt, log, exp, etc.",                     "node description");
static const char* _n115 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Math Operation",                                                               "node display name");
static const char* _d115 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Binary arithmetic operation: +, -, ×, ÷, %, pow",                    "node description");

// ── networking ────────────────────────────────────────────────────────────────
static const char* _n120 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "HTTP Requester",                                                  "node display name");
static const char* _d120 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "REST client: GET/POST/PUT/DELETE with custom headers",            "node description");
static const char* _n121 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "WebSocket Client",                                                "node display name");
static const char* _d121 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Bidirectional WebSocket connection for real-time streaming",      "node description");

// ── scheduling ────────────────────────────────────────────────────────────────
static const char* _n130 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Cron Trigger",                                                                   "node display name");
static const char* _d130 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Fire execOut based on a full cron expression",                                   "node description");
static const char* _n131 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Interval Trigger",                                                               "node display name");
static const char* _d131 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Fire execOut at a configurable days/hours/minutes/seconds interval",             "node description");
static const char* _n132 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Script Scheduler",                                                               "node display name");
static const char* _d132 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Schedule N Python scripts with individual triggers (Interval, DateTime, Cron, MultiDate)", "node description");

// ── script ────────────────────────────────────────────────────────────────────
static const char* _n140 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Python Script",                                                           "node display name");
static const char* _d140 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Execute custom Python code with injected inputs and variables",           "node description");
static const char* _n141 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Variable Monitor",                                                        "node display name");
static const char* _d141 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Real-time dashboard displaying selected global variables inside the workspace", "node description");
static const char* _n142 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Variable Reader",                                                         "node display name");
static const char* _d142 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Read a global variable and emit its value into the graph",                "node description");
static const char* _n143 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Variable Writer",                                                         "node display name");
static const char* _d143 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Write an incoming value into a global variable",                          "node description");

// ── system ────────────────────────────────────────────────────────────────────
static const char* _n150 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Clipboard",                                                       "node display name");
static const char* _d150 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Read and write system clipboard text",                            "node description");
static const char* _n151 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Network Interfaces",                                              "node display name");
static const char* _d151 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "List all network interfaces with IP and MAC addresses",           "node description");
static const char* _n152 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Process Launcher",                                                "node display name");
static const char* _d152 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Launch system commands and capture stdout/stderr",                "node description");

// ── transform ─────────────────────────────────────────────────────────────────
static const char* _n160 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Buffer Accumulator",                                              "node display name");
static const char* _d160 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Collect N values then emit as a batch list",                      "node description");
static const char* _n161 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Rate Limiter",                                                    "node display name");
static const char* _d161 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Throttle or debounce high-frequency signal inputs",               "node description");
static const char* _n162 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Unit Converter",                                                  "node display name");
static const char* _d162 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Convert between length, mass, temperature, and speed units",      "node description");

// ── visualization ─────────────────────────────────────────────────────────────
static const char* _n170 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Heat Map",                                                        "node display name");
static const char* _d170 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "2D intensity grid with configurable color gradient",              "node description");
static const char* _n171 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Node Graph Viewer",                                               "node display name");
static const char* _d171 = QT_TRANSLATE_NOOP3("BehaviourRegistry", "Visualize graph topology with force-directed layout",             "node description");
