fs = require 'fs'
assert = require 'assert'
#path = require 'path'
BASE_DIR = './public/txt/'

#数据层 , 将底层数据操作抽象化封装 .
class Model
	constructor : ->
	read : (path) ->
		fileNames = @getNames path
		paths = []
		paths.push path + fileName for fileName in fileNames
		console.log paths
		new Promise (resolve,reject) ->
			docs  = []
			length = paths.length
			i = 0
			console.log length
			for path in paths
				fs.readFile path,'utf8',(err,data) ->
					if err then return reject err
					docs.push(data)
					i++
					if i is length then return resolve(docs)
			return
	getNames : (path) ->
		fs.readdirSync(path)

#视图层 , 将 koa 的 ctx 再抽象化封装
class View
	show : (ctx,body,status) ->
		body = @render body
		ctx.body = body
		ctx.status = status
	render : (docs) ->
		layoutTemplate = 
			'
			<html>
				<head>
					<title>simple blog</title>
					<style>
						html {width:100%}
						body {
							width : 75%;
							margin : 20px auto 20px auto;
							background : #fafafa;
						}
						span {
							margin : 10px 20px 10px 0;
							color : #949494
						}
					</style>
				</head>
				<body>
					{{body}}
				</body>
			</html>
			'
		defaultTemplate = 
			'
			<h2>{{title}}</h2>
			<div><span>{{time}}</span><span>{{author}}</span></div>
			<div>{{data}}</div>
			'
		bodys = []
		body = ''
		for data in docs
			title = data.match('(title : )(.*)')
			time = data.match('(time : )(.*)')
			author = data.match('(author : )(.*)')
			#console.log 'title:%s,time:%s,author:%s',title,time,author
			if !title or !time or !author then return docs.join('\n')
			template = defaultTemplate
			template = template.replace '{{title}}',title[2]
			template = template.replace '{{time}}',time[2]
			template = template.replace '{{author}}',author[2]
			data = data.replace /.*\r?\n/,''
			data = data.replace /.*\r?\n/,''
			data = data.replace /.*\r?\n/,''
			data = data.replace /.*\r?\n/,''
			console.log data.toString()
			data = data.replace /^/gm,'<p>'
			console.log '1data:' + data
			data = data.replace /\n/gm,'</p>'
			console.log '2data:' + data
			body = template.replace '{{data}}',data
			bodys.push body
		template = layoutTemplate.replace '{{body}}',bodys.join('')

#职责控制层 , 对接 model&view
class BlogController
	constructor : (@model,@view) ->
	index : ->
		model = @model
		view = @view
		assert (model instanceof Model) and (view instanceof View),'notice this!!!'
		->*
			ctx = @
			body = []
			body = yield model.read(BASE_DIR)
			view.show(ctx,body,200)

#init
model = new Model
view = new View
blog = new BlogController(model,view)

#总控制层 , 对接 app 并设置 route -> controller
class Controller
	constructor : (@app) ->
		if !(@ instanceof Controller) then return new Controller(app)
		@init()
	init :  ->
		app = @app
		get = @getMethod

		web = {
			get : (p,fn)->
				app.use get(p,fn)
				return @
		}

		web
			.get '/',blog.index()
			.get '/index',blog.index()
		return

	getMethod : (path,controller) ->
		(next) ->*
			if @method isnt 'GET'
				return yield next
			if @path is path
				return yield controller
			yield next

module.exports = Controller

