"use strict"

# # Globbing
# for performance reasons we're only matching one level down:
# 'test/spec/{,*/}*.js'
# use this if you want to recursively match all subfolders:
# 'test/spec/**/*.js'
module.exports = (grunt) ->

  #Time how long tasks take. Can help when optimizing build times
  require('time-grunt')(grunt)

  # load all grunt tasks
  require("matchdep").filterDev("grunt-*").forEach grunt.loadNpmTasks

  # package options
  packageJson = grunt.file.readJSON('package.json')

  # configurable paths
  yeomanConfig =
    appName: "mylibsass"
    app: "src"
    templ: "../templates/markup"
    dist: "../static"

  grunt.initConfig
    yeoman: yeomanConfig
    pkg: packageJson

    # watch and livereload
    watch:
      options:
        livereload: true

      coffee:
        files: ["<%= yeoman.app %>/scripts/**/*.coffee"]
        tasks: [
          "coffeelint"
          "coffee"
          "copy:serve"
          "notify:dist"
        ]

      js:
        files: [
          # '.tmp/scripts/{,*/}*.js',
          '<%= yeoman.app %>/scripts/**/*.js'
        ]
        tasks: ["concat:serve"]

      sass:
        files: ["<%= yeoman.app %>/styles/{,*/}*.{scss,sass}"]
        tasks: [
          "sass:serve"
          "autoprefixer:dist"
          "copy:serve"
        ]

      images:
        files: ["<%= yeoman.app %>/images/{,*/}*", "<%= yeoman.app %>/fonts/{,*/}*", "<%= yeoman.app %>/images/!**/lossy/**"]
        tasks: [
          "copy:images"
        ]

    # clean working direcotry
    clean:
      options:
        force: true

      dist:
        files: [
          dot: true
          src: [".tmp", "<%= yeoman.dist %>/*", "!<%= yeoman.dist %>/.git*"]
        ]

    # lint coffeescript
    coffeelint:
      app: ['<%= yeoman.app %>/scripts/**/*.coffee', 'gruntfile.coffee']

      options:
        max_line_length:
          level: 'ignore'
        line_endings:
          level: 'error'
        space_operators:
          level: 'warn'

    jshint:
      options:
        jshintrc: ".jshintrc"
        force: true

      all: ["Gruntfile.js", "<%= yeoman.app %>/scripts/**/*.js", "!<%= yeoman.app %>/scripts/vendor/*"]

    coffee:
      dist:
        options:
          sourceMap: yes
          sourceMapDir: '.tmp/scripts/'
          bare: no
        files:
          ".tmp/scripts/main.js": [
            "<%= yeoman.app %>/scripts/plugins/**/*.coffee"
            "<%= yeoman.app %>/scripts/*.coffee"
          ]

    # compile sass with source maps
    sass:
      options:
        imagePath: '<%= yeoman.app %>/images'

      serve:
        options:
          outputStyle: "compressed"
          sourceMap: true

        files: [{
          expand: true
          cwd: '<%= yeoman.app %>/styles'
          src: ['*.{scss,sass}']
          dest: '.tmp/styles'
          ext: '.css'
        }]

      dist:
        options:
          style: "expanded"

        files: "<%= sass.serve.files %>"


    # notify messages
    notify:
      options:
        enabled: true
        max_jshint_notifications: 5

      dist:
        options:
          message: "Build complete"


    # beautify and minify code with uglify
    uglify:
      serve:
        options:
          mangle: false
          compress:
            global_defs:
              DEBUG: true
          beautify: true
        files: "<%= uglify.dist.files %>"

      dist:
        options:
          report: "min"
          compress:
            global_defs:
              DEBUG: false

        files:
          "<%= yeoman.dist %>/scripts/libs.js": [
            "<%= yeoman.app %>/scripts/lib/jquery/*.js"
            "<%= yeoman.app %>/scripts/lib/lodash/*.js"
            "<%= yeoman.app %>/scripts/lib/signals/*.js"
            "<%= yeoman.app %>/scripts/lib/**/*.js"
            "<%= yeoman.app %>/scripts/vendor/*.js"
          ]

      coffee:
        options:
          compress:
            global_defs:
              DEBUG: false
          sourceMap: yes
          sourceMapIn: ".tmp/scripts/main.js.map"
        files:
          "<%= yeoman.dist %>/scripts/main.js": '.tmp/scripts/main.js'

    concat:
      serve:
        options:
          banner: "var DEBUG = true;\n\n"
        files: "<%= uglify.dist.files %>"


    # minify images
    imagemin:
      dist:
        files: [
          expand: true
          cwd: "<%= yeoman.dist %>/images"
          src: "{,*/}*.{png,jpg,jpeg}"
          dest: "<%= yeoman.dist %>/images"
        ]


    # minify svg images
    svgmin:
      dist:
        files: [
          expand: true
          cwd: "<%= yeoman.app %>/images"
          src: "{,*/}*.svg"
          dest: "<%= yeoman.app %>/images"
        ]


    # copy files not handled in other tasks here
    copy:
      dist:
        files: [
          expand: true
          dot: true
          cwd: "<%= yeoman.app %>"
          dest: "<%= yeoman.dist %>"
          src: ["*.{ico,png,txt}", ".htaccess"]
        ]

      images:
        files: [
          expand: true
          dot: true
          cwd: "<%= yeoman.app %>"
          dest: "<%= yeoman.dist %>"
          src: ["images/{,*/}*.{png,jpg,jpeg,webp,gif,svg}", "fonts/*", "!images/**/lossy/**"]
        ]

      serve:
        files: [
          expand: true
          dot: true
          cwd: ".tmp/styles"
          dest: "<%= yeoman.dist %>/styles"
          src: ["*.{css,map}"]
        ,
          expand: true
          cwd: ".tmp/images"
          dest: "<%= yeoman.dist %>/images"
          src: ["generated/*"]
        ,
          expand: true
          dot: true
          cwd: ".tmp/scripts"
          dest: "<%= yeoman.dist %>/scripts"
          src: ["*.{js,map,coffee}"]
        ]

    #minify styles after autoprefixer
    cssmin:
      options:
        report: 'gzip'
        banner: '/*! Build <%= pkg.name %> - v<%= pkg.version %> - <%= grunt.template.today("yyyy-mm-dd") %> */'
        noAdvanced: true

      minify:
        expand: true
        cwd: "<%= yeoman.dist %>/styles"
        dest: "<%= yeoman.dist %>/styles"
        src: ["*.css"]


    #use autoprefixer for clean vendor prefixes
    autoprefixer:
      options:
        browsers: ['last 3 version', 'Opera 12.16']
        map: false

      dist:
        src: '.tmp/styles/*.css'

      serve:
        options:
          map: true

        src: '<%= autoprefixer.dist.src %>'


    # run heavy tasks here concurrently
    concurrent:
      serve: [
        "coffee"
        "sass:serve"
      ]

      dist: [
        "coffee"
        "sass:dist"
      ]


  # grunt tacks

  # $ grunt serve
  grunt.registerTask "serve", [
    "clean:dist"
    "coffeelint"
    "concurrent:serve"
    "concat:serve"
    "autoprefixer:serve"
    "copy"
    "watch"
  ]

  # $ grunt build
  grunt.registerTask "build", [
    "clean:dist"
    "concurrent:dist"
    "uglify:dist"
    "autoprefixer:dist"
    "svgmin"
    "copy"
    "cssmin"
    "notify:dist"
  ]

  # $ grunt
  grunt.registerTask "default", ["build"]

  grunt.registerTask "server", ["serve"]


