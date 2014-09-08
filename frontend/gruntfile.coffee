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
  frontendConfig =
    appName: "mylibsass"
    app: "src"
    templ: "../templates/markup"
    dist: "../static"

  grunt.initConfig
    frontend: frontendConfig
    pkg: packageJson

    # watch and livereload
    watch:
      options:
        livereload: true

      coffee:
        files: ["<%= frontend.app %>/scripts/**/*.coffee"]
        tasks: [
          "coffeelint"
          "coffee:serve"
          "copy:serve"
          "notify"
        ]

      js:
        files: [
          # '.tmp/scripts/{,*/}*.js',
          '<%= frontend.app %>/scripts/**/*.js'
        ]
        tasks: ["concat:serve"]

      sass:
        files: ["<%= frontend.app %>/styles/{,*/}*.{scss,sass}"]
        tasks: [
          "sass:serve"
          "autoprefixer:dist"
          "copy:serve"
        ]

      images:
        files: ["<%= frontend.app %>/images/{,*/}*", "<%= frontend.app %>/fonts/{,*/}*", "<%= frontend.app %>/images/!**/lossy/**"]
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
          src: [".tmp", "<%= frontend.dist %>/*", "!<%= frontend.dist %>/.git*"]
        ]

    # lint coffeescript
    coffeelint:
      app: ['<%= frontend.app %>/scripts/**/*.coffee', 'gruntfile.coffee']

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

      all: ["Gruntfile.js", "<%= frontend.app %>/scripts/**/*.js", "!<%= frontend.app %>/scripts/vendor/*"]


    coffee:
      options:
        bare: no

      dist:
        files:
          ".tmp/scripts/main.js": [
            "<%= frontend.app %>/scripts/plugins/**/*.coffee"
            "<%= frontend.app %>/scripts/*.coffee"
          ]

      serve:
        options:
          sourceMap: yes
          sourceMapDir: '.tmp/scripts/'
          bare: no
        files: "<%= coffee.dist.files %>"

    # compile sass with source maps
    sass:
      options:
        imagePath: '<%= frontend.app %>/images'
        outputStyle: "nested"

      serve:
        options:
          sourceMap: true

        files: [{
          expand: true
          cwd: '<%= frontend.app %>/styles'
          src: ['*.{scss,sass}']
          dest: '<%= frontend.dist %>/styles'
          ext: '.css'
        }]

      dist:
        options:
          sourceMap: false

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
          "<%= frontend.dist %>/scripts/libs.js": [
            "<%= frontend.app %>/scripts/lib/jquery/*.js"
            "<%= frontend.app %>/scripts/lib/lodash/*.js"
            "<%= frontend.app %>/scripts/lib/signals/*.js"
            "<%= frontend.app %>/scripts/lib/**/*.js"
            "<%= frontend.app %>/scripts/vendor/*.js"
          ]

      coffee:
        options:
          compress:
            global_defs:
              DEBUG: false
          sourceMap: yes
          sourceMapIn: ".tmp/scripts/main.js.map"
        files:
          "<%= frontend.dist %>/scripts/main.js": '.tmp/scripts/main.js'

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
          cwd: "<%= frontend.dist %>/images"
          src: "{,*/}*.{png,jpg,jpeg}"
          dest: "<%= frontend.dist %>/images"
        ]


    # minify svg images
    svgmin:
      dist:
        files: [
          expand: true
          cwd: "<%= frontend.app %>/images"
          src: "{,*/}*.svg"
          dest: "<%= frontend.app %>/images"
        ]


    # copy files not handled in other tasks here
    copy:
      dist:
        files: [
          expand: true
          dot: true
          cwd: "<%= frontend.app %>"
          dest: "<%= frontend.dist %>"
          src: ["*.{ico,png,txt}", ".htaccess"]
        ]

      images:
        files: [
          expand: true
          dot: true
          cwd: "<%= frontend.app %>"
          dest: "<%= frontend.dist %>"
          src: ["images/{,*/}*.{png,jpg,jpeg,webp,gif,svg}", "fonts/*", "!images/**/lossy/**"]
        ]

      serve:
        files: [
          expand: true
          dot: true
          cwd: ".tmp/scripts"
          dest: "<%= frontend.dist %>/scripts"
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
        cwd: "<%= frontend.dist %>/styles"
        dest: "<%= frontend.dist %>/styles"
        src: ["*.css"]


    #use autoprefixer for clean vendor prefixes
    autoprefixer:
      options:
        browsers: ['last 3 version', 'Opera 12.16']
        map: false

      dist:
        src: '<%= frontend.dist %>/styles/*.css'

      serve:
        options:
          map: true

        src: '<%= autoprefixer.dist.src %>'


    # run heavy tasks here concurrently
    concurrent:
      serve: [
        "coffee:serve"
        "sass:serve"
      ]

      dist: [
        "coffee:dist"
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
    "notify"
  ]

  # $ grunt
  grunt.registerTask "default", ["build"]

  grunt.registerTask "server", ["serve"]


