EventEmitter2 = require('eventemitter2').EventEmitter2
tracer = require('tracer')

module.exports = class AppSpine extends EventEmitter2
  logger: null

  constructor: (@config = {}) ->
    @config.emitter ?= {}
    @config.logger ?= {}

    unless @config.logger.level?
      @config.logger.level = if @isDev() then 'log' else 'warn'

    super @config.emitter

    @logger = tracer.colorConsole @config.logger

  isDev: -> @getEnv() is 'development'

  getEnv: ->
    process.env.NODE_ENV or 'development'

  require: (path) -> require(path)(@)
