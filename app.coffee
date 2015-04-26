koa = require 'koa'
controller = require './controller'

app = koa()

controller(app)

app.listen 3030
console.log 'app listening 3030...'
