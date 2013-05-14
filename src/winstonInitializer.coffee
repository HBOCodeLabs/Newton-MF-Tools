_ = require 'underscore'
winston = require 'winston'

# Create a file transport with options specified in config
# Use the name as the log filename (if not specified in config)
createFileTransport = (config, name) ->
  options = config?.files?[name]
  if not options
    options = {filename: "#{name}.log"}
  options = _.defaults(options, config?.defaultFileOptions)
  transport = new winston.transports.File(options)
  return transport

# Create a file transport or return a previously created fileTransport
getFileTransport = (config, name, fileTransports) ->
  if not fileTransports[name]
    fileTransports[name] = createFileTransport(config, name)
  return fileTransports[name]

# Initialize logging from configuration
initializeLogger = (config) ->
  fileTransports = {}

  # Create loggers specified in configuration
  for name,options of config?.loggers
    transports = []
    # Merge these options with the default options
    effectiveOptions = _.defaults(options, config?.loggers?.default)
    # Create a console transport if desired
    if effectiveOptions.console
      # Add 'label' parameter to the default console options
      consoleOptions = _.clone(config.defaultConsoleOptions)
      consoleOptions.label = name if name isnt 'default'
      consoleTransport = new winston.transports.Console(consoleOptions)
      transports.push(consoleTransport)
    # Create file transport if desired
    if effectiveOptions.file
      fileTransport = getFileTransport(config, effectiveOptions.file, fileTransports)
      transports.push(fileTransport)

    loggerOptions = {transports: transports}

    # Special handling for the exceptions logger
    loggerOptions.exceptionHandlers = transports if name is 'exceptions'

    logger = new winston.Logger(loggerOptions)
    
    # Register this logger with winston
    winston.loggers.add(name, null, true)

    # Special handling for the default logger
    if name is 'default'
      # Clear default transports and re-add them
      winston.clear()
      for transport in transports
        winston.add transport, null, true
      # Set the default transports when creating a new logger via winston.loggers.get
      winston.loggers.options.transports = transports

  winston.info 'logging initiazlied'

  return

module.exports = initializeLogger
