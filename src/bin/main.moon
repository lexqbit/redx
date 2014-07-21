export redis = require 'redis'

lapis = require "lapis"

process_request = (@) ->
    frontend = redis.fetch_frontend(@, 3)
    if frontend == nil
        ngx.req.set_header("X-Redx-Frontend-Cache-Hit", "false")
    else
        ngx.req.set_header("X-Redx-Frontend-Cache-Hit", "true")
        ngx.req.set_header("X-Redx-Frontend-Name", frontend['frontend_key'])
        ngx.req.set_header("X-Redx-Backend-Name", frontend['backend_key'])
        server = redis.fetch_server(@, frontend['backend_key'], false)
        if server == nil
            ngx.req.set_header("X-Redx-Backend-Cache-Hit", "false")
        else
            ngx.req.set_header("X-Redx-Frontend-Cache-Hit", "true")
            ngx.req.set_header("X-Redx-Backend-Server", server)
            print("SERVER: " .. server)
            ngx.var.upstream = server

webserver = class extends lapis.Application
    '/': =>
        process_request(@)
        layout: false

    default_route: =>
        process_request(@)
        layout: false

lapis.serve(webserver)
