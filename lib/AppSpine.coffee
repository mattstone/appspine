colors = require('colors')
EventEmitter2 = require('eventemitter2').EventEmitter2
tracer = require('tracer')

loggerColorFilters =
  # log : colors.black,
  trace : colors.magenta,
  debug : colors.blue,
  info : colors.green,
  warn : colors.yellow,
  error : [ colors.red, colors.bold ]

module.exports = class AppSpine extends EventEmitter2
  logger: null

  constructor: (@config = {}) ->
    @config.emitter ?= {}
    super @config.emitter
    @setupLogger()

  isDev: -> @getEnv() is 'development'

  configure: (env, fn) -> fn() if @getEnv() is env

  getEnv: ->
    process.env.NODE_ENV or 'development'

  require: (path) ->
    require(path)(@)

  setupLogger: ->
    @config.logger ?= {}
    @config.logger.format ?= "[{{title}}] {{timestamp}} ({{file}}:{{line}}): {{message}}"
    @config.logger.filters ?= loggerColorFilters
    @config.logger.dateformat ?= "HH:MM:ss"

    unless @config.logger.level?
      @config.logger.level = if @isDev() then 'log' else 'warn'

    @logger = tracer.colorConsole @config.logger