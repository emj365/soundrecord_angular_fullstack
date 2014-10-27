'use strict'

angular.module 'papaApp'

.config ($sceDelegateProvider) ->
  $sceDelegateProvider.resourceUrlWhitelist [
    # Allow same origin resource loads.
    "self"
    # Allow loading from our assets domain.  Notice the difference between * and **.
    "blob:**"
  ]
  return

.controller 'MainCtrl', ($scope, $http, socket) ->
  $scope.awesomeThings = []

  $http.get('/api/things').success (awesomeThings) ->
    $scope.awesomeThings = awesomeThings
    socket.syncUpdates 'thing', $scope.awesomeThings

  $scope.addThing = ->
    return if $scope.newThing is ''
    $http.post '/api/things',
      name: $scope.newThing

    $scope.newThing = ''

  $scope.deleteThing = (thing) ->
    $http.delete '/api/things/' + thing._id

  $scope.$on '$destroy', ->
    socket.unsyncUpdates 'thing'

.controller(
  'RecordCtrl',
  ['$scope', '$http', '$window', ($scope, $http, $window) ->

    try
      # webkit shim
      $window.AudioContext = $window.AudioContext or $window.webkitAudioContext
      navigator.getUserMedia = (
        $window.navigator.getUserMedia ||
        $window.navigator.webkitGetUserMedia ||
        $window.navigator.mozGetUserMedia ||
        $window.navigator.msGetUserMedia)
      $window.URL = $window.URL or $window.webkitURL
      audio_context = new AudioContext
      console.log "Audio context set up."
      console.log "navigator.getUserMedia " + ((if navigator.getUserMedia then "available." else "not present!"))
    catch e
      alert "No web audio support in this browser!"

    recorderObject = null

    $scope.recording = false
    $scope.url       = false

    $scope.onRecord = ->
      $scope.url       = false
      $scope.recording = true
      # do recording
      navigator.getUserMedia
        audio: true
      , ((stream) ->
        recorderObject = new MP3Recorder(audio_context, stream,
          statusContainer: null
          statusMethod: "replace"
        )
        recorderObject.start()
        return
      ), (e) ->
        # nothing
      console.log 'recording'
      return

    $scope.onStopRecord = ->
      $scope.recording = false
      recorderObject.stop()
      recorderObject.exportMP3 (url) ->
        $scope.url = url
        $scope.$apply()
        console.log 'encoded ' + $scope.url
      console.log 'stoped'

    $scope.onUpload = ->
        console.log 'sending'
        console.log $scope.url
        $http.post('/api/things', name: $scope.url)
        recorderObject.logStatus ""
        return

    return
])
