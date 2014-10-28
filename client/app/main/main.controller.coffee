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
  ['$scope', '$http', '$window', '$timeout', '$upload', ($scope, $http, $window, $timeout, $upload) ->

    $scope.canRecord    = false
    $scope.name         = ''
    $scope.recording    = false
    $scope.url          = false
    $scope.secondsCount = 30

    mediaRecorder = null
    audioBlob     = null

    countSeconds = ->
      $timeout( ->
        if $scope.secondsCount > 0
          $scope.secondsCount = $scope.secondsCount - 1
          countSeconds()
        return
      , 1000 )

    onMediaSuccess = (stream) ->
      $scope.canRecord = true
      $scope.$apply()

      mediaRecorder = new MediaStreamRecorder(stream)
      mediaRecorder.mimeType = "audio/ogg"
      mediaRecorder.ondataavailable = (blob) ->
        console.log blob.length
        $scope.recording = false
        $scope.url       = URL.createObjectURL(blob)
        audioBlob        = blob
        return
      console.log "media success"

      $scope.onRecord = ->
        $scope.url          = false
        $scope.recording    = true
        $scope.secondsCount = 30
        mediaRecorder.start(30000)
        countSeconds()
        console.log 'recording'
        return

      $scope.onStopRecord = ->
        mediaRecorder.stop();
        console.log 'stoped'
        return

      $scope.onUpload = ->
        file = audioBlob
        if !$scope.name
          $scope.name = Date.now()
        $scope.upload = $upload.upload(
          headers: {'header-key': undefined},
          withCredentials: true,
          url: "/api/things"
          method: 'POST'
          data: {name: $scope.name}
          file: file
        ).progress((evt) ->
          console.log "percent: " + parseInt(100.0 * evt.loaded / evt.total)
          return
        ).success((data, status, headers, config) ->
          # file is uploaded successfully
          $scope.name = ''
          console.log data
          return
        )
        return

      return

    onMediaError = (e) ->
      console.error "media error", e
      return

    mediaConstraints = audio: true
    navigator.getUserMedia mediaConstraints, onMediaSuccess, onMediaError
    # if navigator.getUserMedia
      # $scope.support = true

    return
])
