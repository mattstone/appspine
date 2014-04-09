EventEmitter2 = require('eventemitter2').EventEmitter2
tracer = require 'tracer'
typeOf = require 'typeof'
async = require 'async'

loggerColorFilters = require './loggerColorFilters'

module.exports = class AppSpine extends EventEmitter2
  logger: null

  constructor: (@config = {}) ->
    @config.emitter ?= {}
    super @config.emitter
    @setupLogger()
    @init() if @config.initializers?

    process.title = @config.appName if @config.appName?

  getEnvironment: ->
    @config.env or process.env.NODE_ENV or 'development'

  getEnv: ->
    @getEnvironment()

  isDevelopment: ->
    @getEnvironment() is 'development'

  isDev: ->
    @isDevelopment()

  isTesting: ->
    @getEnvironment() is 'testing'

  isStaging: ->
    @getEnvironment() is 'staging'

  isProduction: ->
    @getEnvironment() is 'production'

  isProd: ->
    @isProduction()

  configure: (env..., fn) ->
    fn() if @getEnvironment() in env

  require: (path) ->
    require(path)(@)

  setupLogger: ->
    @config.logger ?= {}
    @config.logger.format ?= require './loggerFormat'
    @config.logger.filters ?= require './loggerColorFilters'
    @config.logger.dateformat ?= "HH:MM:ss"
    @config.logger.level ?= if @isDev() then 'log' else 'warn'

    @logger = tracer.colorConsole @config.logger

  init: (initializers, cb) ->
    start = Date.now()

    switch arguments.length
      when 0
        initializers = @config.initializers
        cb = ->
      when 1
        if typeOf(arguments[0]) is 'function' and @config.initializers?
          initializers = @config.initializers
          cb = arguments[0]
        else if typeOf(arguments[0]) is 'object'
          initializers = arguments[0]
          cb = ->

    @_initializers = initializers

    wrap = (name, fn) =>
      (done) =>
        initStart = Date.now()
        fn (err) =>
          if err?
            @logger.error "#{name} Error", err if err?
            return done(err)
          @logger.info "#{name} is ready (#{Date.now() - initStart} ms)"
          done()

    tasks = {}

    for name, initializer of initializers
      tasks[name] = switch typeOf initializer
        when 'function' then wrap name, initializer
        when 'object'
          fn = wrap name, initializer.init

          if initializer.depend?
            initializer.depend.concat [fn]
          else
            fn


    async.auto tasks, (err) =>
      @logger.info "Application is ready (#{Date.now() - start} ms)"
      @emit 'ready'
      cb()

  close: (cb = ->) ->
    return unless @_initializers?
    tasks = []

    addTask = (name, initializer) =>
      tasks.push (done) =>
        start = Date.now()
        initializer.close (err) =>
          @logger.trace "#{name} has been closed (#{Date.now() - start} ms)"
          done err

    for name, initializer of @_initializers when initializer.close?
      addTask name, initializer

    async.parallel tasks, (err) =>
      cb(err)
      @logger.error err if err?

